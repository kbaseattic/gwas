use strict;
use Bio::KBase::GWAS::Client;
use Test::More tests => 10;
use Data::Dumper;
use Test::Cmd;
use JSON;
use Bio::KBase::AuthToken;
use Config::Simple;
my $ws_id="kbasetest:pdemo";
my $token  = $ENV{KB_AUTH_TOKEN};
if (!$token){
my $to = Bio::KBase::AuthToken->new();
$token = $to->{token};
}

#`ws-delete kbasetest:pdemo/atpopvar1.filtered.kinship`;


my $job_id;


print "This test requires the atpopvar1 and FLC objects are stored in kbasetest:pdemo(workspace)\n";
print "It also requires read and write ability in the kbasetest:pdemo(workspace)\n";
print "Change gwas service url below or make it to localhost:7086\n";



my $gc = Bio::KBase::GWAS::Client->new("http://localhost:7086");
ok( defined $gc, "Check if the server is working" );




=comment
`ws-delete kbasetest:pdemo/atpopvar1.filtered`;
$job_id = $gc->prepare_variation({ws_id => $ws_id, inobj_id => 'atpopvar1', outobj_id => 'atpopvar1.filtered', minor_allele_frequency => "0.05", comment => 'test'});
ok(ref($job_id) eq "ARRAY","prepare_variation returns an array");
ok(@{$job_id} eq 2, "returns two job ids for prepare_variation");
my $x = check_object ("kbasetest:pdemo/atpopvar1.filtered");
ok ($x==1, "prepare_variation creates atpopvar1.filtered object in kbasetest:pdemo\n");


`ws-delete kbasetest:pdemo/atpopvar1.filtered.kinship`;
$job_id = $gc->calculate_kinship_matrix({ws_id => $ws_id, inobj_id => 'atpopvar1.filtered', outobj_id => 'atpopvar1.filtered.kinship', comment => 'test'});
print "$$job_id[0] $$job_id[1]\n";
ok(ref($job_id) eq "ARRAY","calculate_kinship_matrix returns an array");
ok(@{$job_id} eq 2, "returns two job ids for calculate_kinship_matrix");
my $x = check_object ("kbasetest:pdemo/atpopvar1.filtered.kinship");
ok ($x==1, "calculate_kinship_matrix creates atpopvar1.filtered.kinship object in kbasetest:pdemo\n");

`ws-delete kbasetest:pdemo/FLC.topvariations`;
$job_id = $gc->run_gwas({ws_id => $ws_id, variation_id => 'atpopvar1.filtered', trait_id => 'FLC', kinship_id => 'atpopvar1.filtered.kinship', out_id => 'FLC.topvariations', comment => 'test'});
print "$$job_id[0] $$job_id[1]\n";
ok(ref($job_id) eq "ARRAY","run_gwas returns an array");
ok(@{$job_id} eq 2, "returns two job ids for run_gwas");
my $x = check_object ("kbasetest:pdemo/FLC.topvariations");
ok ($x==1, "run_gwas creates FLC.topvariations object in kbasetest:pdemo\n");

=cut
=comment
`ws-delete kbasetest:pdemo/FLC.genelist`;
$job_id= $gc->variations_to_genes({ws_id => $ws_id, variation_id => 'FLC.topvariations',out_id => 'FLC.genelist', num2snps => "100", pmin => "1", distance => "1000", comment => 'test'});
 my $x = check_object ("kbasetest:pdemo/FLC.genelist");
ok ($x==1, "variations_to_genes creates FLC.genelist object in kbasetest:pdemo\n");
=cut

#`ws-delete kbasetest:pdemo/FLC.network`;
$job_id = $gc->genelist_to_networks({ws_id => $ws_id, inobj_id => 'FLC.genelist',outobj_id => 'FLC.network'});
print to_json ($job_id);
exit;
ok(ref($job_id) eq "ARRAY","genelist_to_networks returns an array");
ok(@{$job_id} eq 2, "returns two job ids for genelist_to_networks");
 my $x = check_object ("kbasetest:pdemo/FLC.network");
ok ($x==1, "genelist_to_networks creates FLC.network object in kbasetest:pdemo\n");







sub check_object {
my ($out_obj) = @_;
for (my $i=1; $i <5; $i++){
 print "\nRound $i: checking if $out_obj is created\n";
my $data;
  eval {$data=from_json(`ws-get $out_obj`)};
  if ($data->{genome}){
   return 1;
  }

  if ($data->{distance_cutoff}){
      return 1;
  }
sleep (60);
}
return 0;
}

