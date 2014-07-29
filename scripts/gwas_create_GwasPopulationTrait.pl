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

use Data::Dumper;
use Bio::KBase::CDMI::CDMIClient;
use Bio::KBase::Utilities::ScriptThing;
my $cdmie = Bio::KBase::CDMI::Client->new("https://kbase.us/services/cdmi_api");



umask 000;

#TODO: Fix usage
if(@ARGV != 5) {
  print_usage();
  exit __LINE__;
}

my $ws_url              = $ARGV[0];
my $ws1                 = $ARGV[1];
my $metadata_file       = $ARGV[2];
my $uploaded_trait_file = $ARGV[3];
my $environment         = $ARGV[4];

my $token               = $ENV{KB_AUTH_TOKEN};
#my $to = Bio::KBase::AuthToken->new();
#$token = $to->{token};
my $wsc = Bio::KBase::workspace::Client->new($ws_url, token=>$token );





my %trait_data_input = ();

#Fill trait_data_input with trait_measurements for individuals in the population 

open (FILETRAIT, $uploaded_trait_file)|| &return_error("Could not open file '$uploaded_trait_file' for reading.");
my @filetrait = <FILETRAIT>;
close (FILETRAIT);

my $header_line=shift @filetrait; #skip header line

chomp ($header_line);
my ($id, @trait_list) = split ("\t", $header_line);

my $i=1;
foreach my $trait (@trait_list){
  $i++;
  my $data = `cat $uploaded_trait_file |cut -f1,$i`;
  my @datax = split ("\n", $data);
  shift @datax; #skip the first line with id
  my @trait_data= ();

  foreach my $newline (@datax){
    chomp ($newline);
    next if ($newline=~/^\s*$/);
    my @data = split ("\t", $newline);
    push (@trait_data, \@data);
  }
  $trait_data_input{$trait}=\@trait_data; #Fill trait_data input with trait measurements
}



my $hash_metadata = {};


if ($environment eq "local"){

open (FILE, $metadata_file) || &return_error("Could not open file '$metadata_file' for reading.");
 my @file = <FILE>;
 close (FILE);

shift @file; #Remove header line
#my %hash_metadata = ();
my @trait_metadata = ();

foreach my $line (@file){
  chomp($line);
  my ($trait_name, $protocol, $trait_ontology_id, $gwaspopulation_object_id, $originator, $pubmed_id, $unit_of_measurement) = split ("\t", $line);  
  my %trait_meta = ();
  $trait_meta{'trait_name'}=$trait_name;
  $trait_meta{'protocol'}=$protocol;
  $trait_meta{'trait_ontology_id'}=$trait_ontology_id;
  $trait_meta{'GwasPopulation_obj_id'}=$gwaspopulation_object_id;
  $trait_meta{'originator'}=$originator;
  $trait_meta{'pubmed_id'}=$pubmed_id;
  $trait_meta{'unit_of_measure'}=$unit_of_measurement;

  push (@trait_metadata, \%trait_meta);
}

$hash_metadata->{"BasicTraitInfo"}=\@trait_metadata;
$hash_metadata = $hash_metadata->{'BasicTraitInfo'};

my @listOfTraits = @$hash_metadata;
foreach my $trait (@listOfTraits){
 &createIndividualTraitObject ($trait);
}


}


elsif ($environment eq "web"){

open (FILE, $metadata_file) || &return_error("Could not open file '$metadata_file' for reading.");
my $metadata_json = join ("", <FILE>);
close (FILE);

$hash_metadata = from_json($metadata_json);
$hash_metadata = $hash_metadata->{'BasicTraitInfo'};

my @listOfTraits = @$hash_metadata;
foreach my $trait (@listOfTraits){
 &createIndividualTraitObject ($trait);
}
}








sub createIndividualTraitObject {
  my ($hash_metadata) = @_;
  my $trait_name = $hash_metadata->{'trait_name'};
  my $population_obj=$hash_metadata->{'GwasPopulation_obj_id'};

  $population_obj=~s/\s*$//;
  $population_obj=~s/^\s*//;


  my $type = "KBaseGwasData.GwasPopulation";
  my $object_data = $wsc->get_object({id => $population_obj,
      type => $type,
      workspace => $ws1,
      auth => $token});

  my $ecotype_details  = $object_data->{'data'}{'observation_unit_details'};
  my $genome  = $object_data->{'data'}{'genome'};
  my %hash_germplasms = ();

  foreach my $ecotype (@$ecotype_details){
    my $germplasm = $ecotype->{'source_id'};
    $hash_germplasms{$germplasm}++;
  }

my @list_germplasm_not_found = ();
foreach my $line (@filetrait){

  next if ($line=~/^\s*$/);
  $line=~s/\s*$//;
  my ($germplasm, $value) = split ("\t", $line);
  push (@list_germplasm_not_found, $germplasm) if (!$hash_germplasms{$germplasm}); 
}

my $list_germplasm_not_found = join (",", @list_germplasm_not_found);

if ($list_germplasm_not_found){
  &return_error ("List of germplasms that were not found for trait '$trait_name' in the population '$population_obj': $list_germplasm_not_found");
}




  my $ws_doc;

  $ws_doc->{'protocol'}=$hash_metadata->{'protocol'};
  my $population_obj_ref = $ws1 . "/" .$hash_metadata->{'GwasPopulation_obj_id'}; 
  $ws_doc->{'popid'}= $population_obj_ref;
  $ws_doc->{'GwasPopulation_obj_id'}= $ws1 . "/" . $hash_metadata->{'GwasPopulation_obj_id'};
  $ws_doc->{'originator'}= $hash_metadata->{'originator'};
  $ws_doc->{'trait_ontology_id'}= $hash_metadata->{'trait_ontology_id'};
  $ws_doc->{'trait_name'}= $trait_name;
  $ws_doc->{'genome'}= $genome;
  
  my $comment = $hash_metadata->{'comment'}; 
  $comment = "NA" if (!$comment);
  $ws_doc->{'comment'}= $comment;
  $ws_doc->{'unit_of_measure'}= $hash_metadata->{'unit_of_measure'};
  $ws_doc->{'trait_measurements'}= $trait_data_input{$trait_name};

#  open OUT, ">T$trait_name.json" || &return_error("Cannot open document.json for writing.");
#  print OUT to_json($ws_doc, { ascii => 1, pretty => 1 });
#  close OUT;


my $metadata = $wsc->save_object({id =>"$trait_name", type =>"KBaseGwasData.GwasPopulationTrait" , auth => $token,  data => $ws_doc, workspace => $ws1});


}




exit(0);

sub print_usage {
  &return_error("USAGE: gwas_create_GwasPopulationTrait-4.0.pl  population_data_workspace_url population_data_workspace metadata_json_file uploaded_trait_file shockid shockurl token");
}

sub return_error {
  my ($str) = @_;
  print STDERR "$str\n";
  exit(1);
}

