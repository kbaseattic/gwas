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
use Bio::KBase::AuthToken;
use Getopt::Long;
use Data::Dumper;
use Bio::KBase::CDMI::CDMIClient;
use Bio::KBase::Utilities::ScriptThing;
#TODO: Confirm if this is the right url
my $cdmie = Bio::KBase::CDMI::Client->new();

umask 000;
if(@ARGV != 8) {
  print_usage();
  exit __LINE__;
}

my $ws_url                   = $ARGV[0];
my $wsid                     = $ARGV[1];
my $shock_url                = $ARGV[2];
my $varinid                  = $ARGV[3];
my $traitinid                = $ARGV[4];
my $kinshipinid              = $ARGV[5];
my $outid                    = $ARGV[6];
my $comment                  = $ARGV[7];
my $token                    = $ENV{KB_AUTH_TOKEN};


#TODO: Fix the token
if (!$token){
my $to = Bio::KBase::AuthToken->new();
 $token = $to->{token};
}

my $output_file = "tmp.vcf";


my $wc = Bio::KBase::workspace::Client->new($ws_url, token => $token);


#Get variation data
my $obj = $wc->get_object({id => $varinid, type => 'KBaseGwasData.GwasPopulationVariation', workspace => $wsid});
#$shock_url = $obj->{data}->{files}->{shock_url};
my $nodeid = $obj->{data}->{files}->{emmax_format_hapmap_shock_id};
my $obs_units_data = $obj->{data}->{obs_units};



my $kbase_genome_id = $obj->{"data"}{"genome"}{"kbase_genome_id"};
my $gH = $cdmie->genomes_to_contigs([$kbase_genome_id]);
my $contigs = $gH->{"$kbase_genome_id"};
my $source_name = $cdmie->get_entity_Contig($contigs, ["source_id"]);
my $hashlength = $cdmie->contigs_to_lengths($contigs);

my %source_to_kb_contig;
my %source_to_length;

while (my ($key, $val) = each (%$hashlength)){
  $source_to_kb_contig{ $source_name->{$key}{"source_id"} } =$key;
  $source_to_length{ $source_name->{$key}{"source_id"} } =$val;
}


my $emmax = "emmax";
my $cmd = "curl -s -H \"Authorization: OAuth $token\" -X GET $shock_url/node/$nodeid?download >out.tped";
`$cmd`;
open (TFAM, ">out.tfam") or die ("Can not open out.tfam for writing");
foreach my $obs (@$obs_units_data){
  my ($obs_unit_id, $kbase_id) = @$obs;
  print  TFAM $obs_unit_id . "\t" . $obs_unit_id . "\t" . '0' . "\t" . '0' . "\t" . '0' . "\t" . '-9' . "\n"  ;
}
close (TFAM);


#Get kinship data
my $kinshipobj = $wc->get_object({id => $kinshipinid, type => 'KBaseGwasData.GwasPopulationKinship', workspace => $wsid});
my $kinshipnodeid = $kinshipobj->{data}->{kinship}->{kinship_matrix_shock_id};
$cmd = "curl -s -H \"Authorization: OAuth $token\" -X GET $shock_url/node/$kinshipnodeid?download >out.IBS.kinf";
`$cmd`;


#Get trait data
my $traitobj = $wc->get_object({id => $traitinid, type => 'KBaseGwasData.GwasPopulationTrait', workspace => $wsid});
my $trait_measurements = $traitobj->{data}{trait_measurements};
#TODO: Modify trait object so that this is easy to directly get it into hash
my %trait_val = ();
foreach my $line (@$trait_measurements){
  my ($id,$val) = @$line;
  $trait_val{$id}=$val;
}

open (TRAIT, ">trait.txt") or die ("Can not open out.tfam for writing");
foreach my $obs (@$obs_units_data){
  my ($obs_unit_id, $kbase_id) = @$obs;
  my $val = $trait_val{$obs_unit_id};
  $val = "NA" if (!$val);
  print  TRAIT $obs_unit_id . "\t" . $obs_unit_id . "\t" .  $val . "\n"   ;
}
close (TRAIT);



$cmd = "$emmax -v -d 10 -t out -p trait.txt -k out.IBS.kinf -o association.txt";
`$cmd`; #output is out.IBS.kinf

open (FILEA, "association.txt.ps") or die ("association.txt.ps file not found");
open (FILEOUT, ">vars.txt") or die ("can not open vars.txt for writing");

my $pvalcutoff = 0.1;
while (<FILEA>){
  $_=~s/\s*$//;
  my ($snp, $tmp, $pval) = split ("\t", $_);
  next if ($pval >$pvalcutoff);
  print FILEOUT "$snp\t$pval\n";
}
close FILEOUT;

$cmd = "sort -gk2,2 vars.txt |head -1000 >topvars.txt";
`$cmd`;

open (FILE, "topvars.txt") or die ("could not open topvars.txt for reading");
my $sid;
my $pos;
my @data = ();
while (<FILE>){
  chomp ($_);
  my ($snp, $pval) = split ("\t", $_);
  my @s = split ("_", $snp);
  my $length = @s;
  if ($length>2){
    $sid = join ("_", @s[0..$length-2]);
    $pos = $s[-1];
  }
  else {
    ($sid,$pos) = @s;
  }

  push (@data, "$sid\t$pos\t$pval\n");
}
my $last = chomp ($data[-1]);
my ($x,$y,$pvalue_cutoff) = split ("\t",$data[-1]);
if (!$pvalue_cutoff){
  $pvalue_cutoff=0;
}
my @res;
my $i=0;
my $string = "";


foreach my $line (@data){
  next if ($i==1);
  next if ($line=~/NaN/);
  next if ($line=~/Locus/);
  my @cr = split ("\t", $line);
  my ($contig, $position, $pvalue, $source_contig);
  ($source_contig, $position, $pvalue)=($cr[0], $cr[1], $cr[2]);
  $contig=$source_to_kb_contig{$source_contig};

  my @snp = ($contig, $position, $pvalue, $source_contig);
  push (@res, \@snp);
}


my @contig_data;
my @variation_data;

my %contig_map;
my %sorted_contig_map;

foreach my $line (@res) {
  my ($contig, $position, $pvalue, $source_contig) = @$line;
  $contig_map{$source_contig}=$contig   if (!$contig_map{$source_contig});

}

my @contigs = keys %contig_map;
my %data;
foreach my $data (@contigs) {
  ( my $sort= $data ) =~ s/(0*)(\d+)/
    pack("C",length($2)) . $1 . $2 /ge;
  $data{$sort}= $data;
}
my @sort_contigs= @data{ sort keys %data };


my $counter = 0;

foreach my $source_contig (@sort_contigs) {
  $sorted_contig_map{$source_contig}=$counter;
  my $pos = $source_to_length{$source_contig} +0;
  my %hashx =("kbase_contig_id" => $contig_map{$source_contig},"name" => $source_contig, "id" => $source_contig,  "len"=> $pos );
  push (@contig_data, \%hashx);
  $counter++;
}


my %hashvars = ();
my %hashcounter = ();

foreach my $line (@res){
  my ($contig, $position, $pvalue, $source_contig) = @$line;

  $hashvars{$source_contig}->[$hashcounter{$source_contig}]="$contig,$position,$pvalue,$source_contig";
  $hashcounter{$source_contig}++;
}

foreach my $chr (@sort_contigs){
  my @lines = @{$hashvars{$chr}};
  foreach my $line (@lines){
    $line=~s/\"//g;
    my ($contig, $position, $pvalue, $source_contig) = split (",", $line);

    my $pvalue_1=sprintf("%.9f", $pvalue);
    $pvalue=$pvalue+0.0;
    my $mlog = -log10($pvalue);
    my $p = $position;
    my $snpid=$contig . "_" . $p;

    my @data = ($sorted_contig_map{$chr}, int($position),$mlog, $snpid);
    push (@variation_data, \@data);
  }
}


my %hash = ();

$hash{"variations"}=\@variation_data;
$hash{"contigs"}=\@contig_data;
$hash{"source"}= "Mixed linear model analysis in kbase using emmax with :$varinid, trait:$traitinid, kinship matrix:$kinshipinid";
$hash{"protocol"}= $traitobj->{"data"}{"protocol"};
$hash{"originator"}= $traitobj->{"data"}{"originator"};
$hash{"trait_ontology_id"}= $traitobj->{"data"}{"trait_ontology_id"};
$hash{"genome"}= $obj->{"data"}{"genome"};
$hash{"GwasPopulation_obj_id"}= $obj->{"data"}{"GwasPopulation_obj_id"};
$hash{"GwasPopulationVariation_obj_id"}= $wsid . "/" . $varinid;
$hash{"unit_of_measure"}= $traitobj->{"data"}{"unit_of_measure"};
$hash{"trait_name"}= $traitobj->{"data"}{"trait_name"};
$hash{"assay"}= $obj->{"data"}{"assay"};
$hash{"comment"}= $comment;
$hash{"num_population"}= "NA";
$hash{"GwasPopulationTrait_obj_id"}= $wsid ."/" . $traitinid;
my $pvalue_cutoff1 = $pvalue_cutoff + 0.0;
$hash{"pvaluecutoff"}=$pvalue_cutoff1;
$hash{"GwasPopulationKinship_obj_id"}=$wsid . "/" . $kinshipinid;


$wc->save_object({id => $outid, type=>"KBaseGwasData.GwasTopVariations", 
    data=>\%hash, 
    workspace=>$wsid,
    meta=>{source=>"$wsid:$varinid,$traitinid,$kinshipinid by gwas_run_gwas"}});


system ("rm -f association.txt.log");  
system ("rm -f association.txt.ps "); 
system ("rm -f association.txt.reml  ");
system ("rm -f out.IBS.kinf  ");
system ("rm -f out.tfam  ");
system ("rm -f out.tped ");
system ("rm -f topvars.txt "); 
system ("rm -f trait.txt  ");
system ("rm -f vars.txt");


exit(0);


sub log10 {
  my $n = shift;
  return log($n)/log(10);
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

