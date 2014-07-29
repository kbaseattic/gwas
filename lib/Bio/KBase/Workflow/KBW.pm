package Bio::KBase::Workflow::KBW;

use strict;
use File::Spec;
use File::Find;
use Config::Simple;
use Data::Dumper;
use Digest::MD5 qw(md5_base64);
use JSON;
use Bio::KBase::workspace::Client;
use Bio::KBase::userandjobstate::Client;

sub install_path
{
  return File::Spec->catpath((File::Spec->splitpath(__FILE__))[0,1], '');
}

sub list_workflows
{
  my @list = ();
  my $wfd = install_path();
  find (sub { push @list, $File::Find::dir . "/" . $_
      unless (-d or /KBW\.pm/);
      }, $wfd);
  return @list;
}

# TODO: Improve this function later with eval
sub arg_substituting {
  my ($args, $str, $wc) = @_;
  $str = ws_pull_value($args, $str, $wc);
  foreach my $vn (keys %$args) {
    # TODO: Improve it later (not safe)
    $str =~ s/\$$vn/$args->{$vn}/g;
  }
  return $str;
}
sub ws_pull_value {
  my ($args, $str, $wc) = @_;
  
  while ($str =~ m/\s*(ws:\$[^:]+:\$[^:]+:\S+:\S+)\s*/) {
    my @ens = split /:/, $1;
    $ens[1] =~ s/^\$//;
    my $obj_id = 
    $ens[2] =~ s/^\$//;
    my $ws_id = $args->{$ens[1]};
    my $obj_id = $args->{$ens[2]};
    my $type = $ens[3];
    my $path = $ens[4];
    my $obj = $wc->get_object({id => $obj_id, type => $type, workspace => $ws_id});
    $obj = $obj->{data};

    foreach my $entry ( split /\//, $path) {
      $obj = $obj->{$entry};
    }
    $str =~ s/ws:\$[^:]+:\$[^:]+:\S+:\S+/$obj/;
  }
  return $str;
}

sub run_async {
  my $self = shift;
  my $ctx = shift;
  my $args = shift;

  my $method = $ctx->{method};
  my $package = $ctx->{module};
  my $token = $ctx->{'token'};

  my $wc = Bio::KBase::workspace::Client->new($self->{_config}->{ws_url}, token => $token);
  my $uc = Bio::KBase::userandjobstate::Client->new($self->{_config}->{ujs_url}, token => $token);
 
  my $kb_top = $ENV{'KB_TOP'};  
  $kb_top = '/kb/deployment' if ! defined $kb_top;

  my %Config = ();
  tie %Config, "Config::Simple", "$kb_top/services/$package/service.cfg";
  my %method_hash = map {$_ => $Config{$_}} grep {/^$method\./}keys %Config;
  my %package_hash = map {$_ => $Config{$_}} grep {/^$package\./}keys %Config;

  # UJS
  my $status = 'initializing';
  my $description = arg_substituting($args, $method_hash{"$method.ujs_description"}, $wc);
  my $progress = { 'ptype' => $method_hash{"$method.ujs_ptype"}, 'max' => $method_hash{"$method.ujs_mstep"} };
  # TODO: need better estimation and timestamp handling...
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time+$method_hash{'ujs_mstep'});#localtime(time);
  my $nice_timestamp = sprintf ( "%04d-%02d-%02dT%02d:%02d:%02d-0800",
                                 $year+1900,$mon+1,$mday,$hour,$min,$sec);
  my $ujs_job_id = $uc->create_and_start_job($token, $status, $description, $progress, $nice_timestamp);


  my $job_config_fn = "$kb_top/services/$package/awf/$ujs_job_id.awf";
  my $job_config = {"info" => 
                       { "pipeline" =>  $package,
                         "name" => $method,
                         "user" => $ctx->{user_id},
                         "clientgroups" => "",
                         "jobId" => $ujs_job_id
                      },
                    "tasks" => [ ]
                   };
  my @task_list = grep /^$method.task\d+_cmd_name$/, keys %method_hash;
  foreach my $task_cmd (sort @task_list) {
    $task_cmd =~ m/^$method.(task\d+)_cmd_name$/;
    my $task_id = $1;
    my $task_cmd_args = arg_substituting( $args, $method_hash{"$method.$task_id\_cmd_args"}, $wc);

    my @inputs = grep /^$method.$task_id\_inputs_[^_]+_host$/, keys %method_hash;
    my %inputs =();
    foreach my $input_host (@inputs) {
      $input_host =~ m/^$method\.$task_id\_inputs_([^_]+)_host$/;
      my $var_name = $1;
      # TODO: make the following to be safer later
      if (! $task_cmd_args =~ m/\@$var_name/) {
        print STDERR "$var_name is not shown in command args\n";
        next;
      }
      $inputs{$var_name} = {host => arg_substituting($args, $method_hash{$input_host}, $wc)};
      $inputs{$var_name}->{node} = arg_substituting($args, $method_hash{"$method.$task_id\_inputs\_$var_name\_node"}, $wc) if defined $method_hash{"$method.$task_id\_inputs\_$var_name\_node"};
    }

    my @outputs = grep /^$method\.$task_id\_outputs_[^_]+_host$/, keys %method_hash;
    my %outputs =();
    foreach my $output_host (@outputs) {
      $output_host =~ m/^$method\.$task_id\_outputs_([^_]+)_host$/;
      my $var_name = $1;
      $outputs{$var_name} = {host => arg_substituting($args, $method_hash{$output_host}, $wc)};
    }

    my $task = { "cmd" => 
                   { "args" => $task_cmd_args,
                     "description" => $method_hash{"$method.$task_id\_cmd_description"},
                     "name" => $method_hash{"$method.$task_id\_cmd_name"}
                   },
                   "inputs" => \%inputs,
                   "outputs" => \%outputs,
                   taskid => $method_hash{"$method.$task_id\_taskid"},
                   skip => int $method_hash{"$method.$task_id\_skip"},
                   totalwork => int $method_hash{"$method.$task_id\_totalwork"}
                           
               };

    if($method_hash{"$method.$task_id\_dependson"} eq "") {
      $task->{"dependsOn"} =  [];
    } else {
      my @ta = split/,/, $method_hash{"$method.$task_id\_dependson"};
      $task->{"dependsOn"} = \@ta;
    }

    if($method_hash{"$method.$task_id\_token"} eq "true") {
      $task->{cmd}->{environ} =  {private => {KB_AUTH_TOKEN => "$token"} };
    }
    
    push @{$job_config->{tasks}}, $task;
  }

  my $jcstr = to_json($job_config);
  foreach my $key (keys %package_hash) {
    $jcstr =~ s/$key/$package_hash{$key}/g;
  }

  open AJC, ">$job_config_fn" or die "Couldn't open $job_config_fn :$!\n";
  print AJC $jcstr;
  close AJC;

  my $awe_res = `curl -s -X POST -H "Authorization: OAuth $token" -H "Datatoken: $token" -F "upload=\@$job_config_fn" $self->{_config}->{awe_url}/job`;
  my $awe_ds = from_json($awe_res);

  my $job_id = [$awe_ds->{data}->{id},  $ujs_job_id];
  return $job_id;
}

sub run_sync {
  my $self = shift;
  my $ctx = shift;
  my $args = shift;

  my $status = "";

  my $method = $ctx->{method};
  my $package = $ctx->{module};
  my $token = $ctx->{'token'};
  $ENV{'KB_AUTH_TOKEN'} = $token;

  my $wc = Bio::KBase::workspace::Client->new($self->{_config}->{ws_url}, token => $token);
  my $uc = Bio::KBase::userandjobstate::Client->new($self->{_config}->{ujs_url}, token => $token);
 
  my $kb_top = $ENV{'KB_TOP'};  
  $kb_top = '/kb/deployment' if ! defined $kb_top;

  my %Config = ();
  tie %Config, "Config::Simple", "$kb_top/services/$package/service.cfg";
  my %method_hash = map {$_ => $Config{$_}} grep {/^$method\./}keys %Config;
  my %package_hash = map {$_ => $Config{$_}} grep {/^$package\./}keys %Config;

  my @task_list = grep /^$method.task\d+_cmd_name$/, keys %method_hash;
  foreach my $task_cmd (sort @task_list) {
    $task_cmd =~ m/^$method.(task\d+)_cmd_name$/;
    my $task_id = $1;
    my $task_cmd_args = arg_substituting( $args, $method_hash{"$method.$task_id\_cmd_args"}, $wc);
    
    foreach my $key (keys %package_hash) {
      $task_cmd_args =~ s/$key/$package_hash{$key}/g;
    }

    my @inputs = grep /^$method.$task_id\_inputs_[^_]+_host$/, keys %method_hash;
    my %inputs =();
    foreach my $input_host (@inputs) {
      $input_host =~ m/^$method\.$task_id\_inputs_([^_]+)_host$/;
      my $var_name = $1;
      # TODO: make the following to be safer later
      if (! $task_cmd_args =~ m/\@$var_name/) {
        print STDERR "$var_name is not shown in command args\n";
        next;
      }
      $inputs{$var_name} = {host => arg_substituting($args, $method_hash{$input_host}, $wc)};
      $inputs{$var_name}->{node} = arg_substituting($args, $method_hash{"$method.$task_id\_inputs\_$var_name\_node"}, $wc) if defined $method_hash{"$method.$task_id\_inputs\_$var_name\_node"};
    }

    # TODO: Correct this later... 
    my @outputs = grep /^$method\.$task_id\_outputs_[^_]+_host$/, keys %method_hash;
    my %outputs =();
    foreach my $output_host (@outputs) {
      $output_host =~ m/^$method\.$task_id\_outputs_([^_]+)_host$/;
      my $var_name = $1;
      $outputs{$var_name} = {host => arg_substituting($args, $method_hash{$output_host}, $wc)};
    }

    $status .= `$method_hash{"$method.$task_id\_cmd_name"} $task_cmd_args`;
  }

  return $status;
}

1;
