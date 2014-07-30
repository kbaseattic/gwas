#!/usr/bin/env perl

# this script takes gwas population metadata json file and data text file as input
# and creates a GwasPopulation type workspace object

use strict;
use warnings;
no warnings('once');
use POSIX;
use JSON;

use Bio::KBase::workspace::Client;
use Data::Dumper;
use  Bio::KBase::AuthToken;


use Getopt::Long;
use Data::Dumper;
use Scalar::Util qw(looks_like_number);

umask 000;


if(@ARGV != 6) {
  print_usage();
  exit __LINE__;
}

my $ws_url                   = $ARGV[0];
my $wsid                     = $ARGV[1];
my $shock_url                = $ARGV[2];
my $inid                     = $ARGV[3];
my $outid                    = $ARGV[4];
my $comment                  = $ARGV[5];
#my $token                    = $ENV{KB_AUTH_TOKEN};
my $to = Bio::KBase::AuthToken->new();
our $token = $to->{token};


my $output_file = "tmp.vcf";


my $wc = Bio::KBase::workspace::Client->new($ws_url, token => $token);
my $obj = $wc->get_object({id => $inid, type => 'KBaseGwasData.GwasPopulationVariation', workspace => $wsid});

#$shock_url = $obj->{data}->{files}->{shock_url};
my $nodeid = $obj->{data}->{files}->{emmax_format_hapmap_shock_id};
my $obs_units_data = $obj->{data}->{obs_units};

#my $cmd = "curl -s -H \"Authorization: OAuth $token\" -X GET $shock_url/node/$nodeid"; 
#my $out_shock_meta = from_json(`$cmd`);
#my $fn = $out_shock_meta->{data}->{file}->{name};

my $emmax_kin = "emmax-kin";

# streaming 
my $cmd = "curl -s -H \"Authorization: OAuth $token\" -X GET $shock_url/node/$nodeid?download >out.tped";
`$cmd`;


open (TFAM, ">out.tfam") or die ("Can not open out.tfam for writing");
foreach my $obs (@$obs_units_data){

  my ($obs_unit_id, $kbase_id) = @$obs;
  print  TFAM $obs_unit_id . "\t" . $obs_unit_id . "\t" . '0' . "\t" . '0' . "\t" . '0' . "\t" . '-9' . "\n"  ;
}

close (TFAM);

<<<<<<< HEAD
#$cmd = "$emmax_kin -v -s -d 10 -o out.IBS.kinf out"; # icc version
$cmd = "$emmax_kin -v -s -d 10 out"; # gcc version
=======
$cmd = "$emmax_kin -v -s -d 10 out";
>>>>>>> e0b68d9f6d8c5bdac51f447f2cf91262007f2700
`$cmd`; #output is out.IBS.kinf


my $ws_doc;

my %files = ();
$files{'shock_url'}=$shock_url;
$files{'kinship_matrix_shock_id'}=upload2shock("out.IBS.kinf");


$ws_doc->{kinship} = \%files;
$ws_doc->{genome}=$obj->{data}->{genome};
$ws_doc->{"GwasPopulationVariation_obj_id"}="$wsid/$inid";
$ws_doc->{"GwasPopulation_obj_id"}=$obj->{data}->{GwasPopulation_obj_id}; 
$ws_doc->{"comment"}=$comment;

#TODO: REPLACE source in following
$wc->save_objects({workspace => $wsid, objects => [{type=>'KBaseGwasData.GwasPopulationKinship',
    name=>$outid,
    data=>$ws_doc,
    meta=>{source=>"$wsid:$inid by GWAS.filter_vcf"}}]});


#system ("rm -f tmp.vcf");
#system ("rm -f out.tped");
#out.IBS.kinf  out.log  out.tfam  out.tped 

system ("rm -f out.IBS.kinf");
system ("rm -f out.log");
system ("rm -f out.tfam");
system ("rm -f out.tped");


exit(0);


sub upload2shock {
  my $fn = shift; #file name to be uploaded to shock

#upload data to shock and capture node id
    my $cmd = "curl -s -H \"Authorization: OAuth $token\" -X POST -F upload=\@$fn $shock_url/node";
  my $out_shock_meta = from_json(`$cmd`);
  my $nodeid = $out_shock_meta->{data}->{id};

#read acl and owner
  my $acl = `curl -s -H \"Authorization: OAuth $token\" -X GET $shock_url/node/$nodeid/acl`; 
    my $hacl=from_json($acl);
  my $owner=$hacl->{data}->{owner};

#remove acl
   $acl = `curl -s -H \"Authorization: OAuth $token\" -X DELETE  $shock_url/node/$nodeid/acl/read?users=$owner`;

#return nodeid of upload
  return $nodeid;

}


#TODO:REPLACE usage
sub print_usage {
  &return_error("USAGE: gwas_calculate_kinship_matrix_emma ws_url ws_id shock_url inid outid comment");
}

sub return_error {
  my ($str) = @_;
  print STDERR "$str\n";
  exit(1);
}





