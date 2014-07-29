#!/usr/bin/env perl

# this script takes gwas population metadata json file and data text file as input
# and creates a GwasPopulation type workspace object

use strict;
#use warnings;
#no warnings('once');
use POSIX;
use JSON;

use Bio::KBase::workspace::Client;
use Data::Dumper;
use  Bio::KBase::AuthToken;
use Bio::KBase::CDMI::CDMIClient;
use Bio::KBase::Utilities::ScriptThing;
#TODO: Confirm that following cdmie url is right
my $cdmie = Bio::KBase::CDMI::Client->new("https://kbase.us/services/cdmi_api");


umask 000;


if(@ARGV != 5) {
  print_usage();
  exit __LINE__;
}

my $ws_url                   = $ARGV[0]; #eg. https://kbase.us/services/ws
my $wsid                     = $ARGV[1]; #eg. pranjan77:testgw
my $metadata_file            = $ARGV[2]; #tab delimited for local upload, web uploader creates json automatically
my $population_data_file     = $ARGV[3]; #tab delimited file with population latitude and longitude
my $environment              = $ARGV[4]; #web for web uploader, "local" for command line uploader  
my $token                    = $ENV{KB_AUTH_TOKEN};


my $wsc = Bio::KBase::workspace::Client->new($ws_url, token=>$token );
my $metadata_json;

if ($environment eq "local"){

  open (FILE, $metadata_file) || &return_error("Could not open file '$metadata_file' for reading. ");
  my @data = <FILE>;
  shift @data; #remove header line

    my @datax = split ("\t", $data[0]);

  if (@datax != 6){
    &return_error("Please double check your metadata file and make sure they are tab delimited");
  }


  my ($kbase_genome_id, $GwasPopulation_description, $pop_object_id, $originator, $pubmed_id, $comment) = @datax;
  chomp($comment);

  my $meta = {};
  $meta->{BasicPopulationInfo}->{kbase_genome_id}= $kbase_genome_id;
  $meta->{BasicPopulationInfo}->{GwasPopulation_description}= $GwasPopulation_description;
  $meta->{BasicPopulationInfo}->{originator}= $originator;
  $meta->{BasicPopulationInfo}->{pubmed_id}= $pubmed_id;
  $meta->{BasicPopulationInfo}->{population_object_name}= $pop_object_id;
  $meta->{BasicPopulationInfo}->{comments}= $comment;
  $metadata_json = to_json($meta);
}

elsif ($environment eq "web"){
  open (FILE, $metadata_file) || &return_error("Could not open file '$metadata_file' for reading. ");
  $metadata_json = join ("", <FILE>);
  close (FILE);
}

else {
  &return_error("\$environment variable is required and should be set to local or web");
}



my $hash_metadata = from_json($metadata_json);
$hash_metadata = $hash_metadata->{'BasicPopulationInfo'};


my $kbase_genome_id = $hash_metadata->{'kbase_genome_id'};
my $gH = $cdmie->get_entity_Genome([$kbase_genome_id], ["id", "scientific_name", "source_id"]);

if (!$gH->{$kbase_genome_id}{"id"}){
  &return_error("kbase_genome_id should be a valid id in form of kb|g.3899");
}

my %genome_details = (
    "kbase_genome_id" => $gH->{$kbase_genome_id}{"id"},
    "kbase_genome_name" => $gH->{$kbase_genome_id}{"scientific_name"},
    "source_genome_name" => $gH->{$kbase_genome_id}{"source_id"},
    "source" => "KBase central store"
    );




my $ws_doc;
$ws_doc->{"genome"}=\%genome_details;
$ws_doc->{"GwasPopulation_description"}=$hash_metadata->{'GwasPopulation_description'};
$ws_doc->{"originator"}=$hash_metadata->{'originator'}; 
$ws_doc->{"pubmed_id"}=$hash_metadata->{'pubmed_id'}; ;
$ws_doc->{"comment"}=$hash_metadata->{'comments'}; 


open (FILE2, $population_data_file) || &return_error ("Could not open file '$population_data_file' for reading. ");
my @data = <FILE2>;
shift @data; #Ignore header row


my @obs_unit_details = ();

foreach my $line (@data){
  $line=~s/\s*$//;
  my ($obs_unit_source_id, $latitude,$longitude, $nativename, $region, $country, $comment) = split ("\t", $line);
  my %obs_unit = ();

  my $kbase_id = "test-kb|...."; #TODO:Get this value from a hash and fill it properly later
    $obs_unit{'source_id'}=$obs_unit_source_id;
  $obs_unit{'latitude'}=$latitude;
  $obs_unit{'longitude'}=$longitude;
  $obs_unit{'nativenames'}=$nativename;
  $obs_unit{'region'}=$region;
  $obs_unit{'country'}=$country;
  $obs_unit{'comment'}=$comment;
  $obs_unit{'kbase_obs_unit_id'}=$kbase_id;
  push (@obs_unit_details, \%obs_unit);
}

my $population_object=$hash_metadata->{'population_object_name'};

$ws_doc->{"observation_unit_details"}=\@obs_unit_details ;
my $metadata = $wsc->save_object({id =>$population_object, type =>"KBaseGwasData.GwasPopulation",  data => $ws_doc, workspace => $wsid});

#open OUT, ">document.json" || &return_error("Cannot open document.json for writing");
#print OUT to_json($ws_doc, { ascii => 1, pretty => 1 });
#close OUT;

exit(0);

sub print_usage {
  &return_error("USAGE: gwas_create_GwasPopulation.pl ws_url ws_id metadata data environment");
}

sub return_error {
  my ($str) = @_;
  print STDERR "$str\n";
  exit(1);
}



