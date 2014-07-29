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


if(@ARGV != 7) {
  print_usage();
  exit __LINE__;
}

my $ws_url                   = $ARGV[0];
my $wsid                     = $ARGV[1];
my $shock_url                = $ARGV[2];
my $inid                     = $ARGV[3];
my $outid                    = $ARGV[4];
my $minor_allele_frequency   = $ARGV[5];
my $comment                  = $ARGV[6];

my $token                    = $ENV{KB_AUTH_TOKEN};
#if (!$token){
#my $to = Bio::KBase::AuthToken->new();
#$token = $to->{token};
#}

my $output_file = "tmp.vcf";

#Minor allele frequency should be a number with value between 0 and 1
if (! (looks_like_number ($minor_allele_frequency) 
      && $minor_allele_frequency >=0
      && $minor_allele_frequency <=1 )){
  die "Minor allele frequency should be between 0 and 1. Minor allele frequency $minor_allele_frequency is not in range\n";
}


my $wc = Bio::KBase::workspace::Client->new($ws_url, token => $token);
my $obj = $wc->get_object({id => $inid, type => 'KBaseGwasData.GwasPopulationVariation', workspace => $wsid});

#$shock_url = $obj->{data}->{files}->{shock_url};
my $nodeid = $obj->{data}->{files}->{vcf_shock_id};
my $maf_ws = $obj->{data}->{minor_allele_frequency};

my $cmd = "curl -s -H \"Authorization: OAuth $token\" -X GET $shock_url/node/$nodeid"; 
my $out_shock_meta = from_json(`$cmd`);
my $fn = $out_shock_meta->{data}->{file}->{name};

my $vcftools = "vcftools";

# streaming 
$cmd = "curl -s -H \"Authorization: OAuth $token\" -X GET $shock_url/node/$nodeid?download ";
$cmd .= " | gunzip -c - " if ($fn =~ m/gz$/);
$cmd .= " | $vcftools --vcf - --maf $minor_allele_frequency   --max-alleles 2 --recode --stdout >  $output_file;";
`$cmd`;

$obj->{data}->{files}->{vcf_shock_id} = upload2shock($output_file);
$obj->{data}->{minor_allele_frequency} = $minor_allele_frequency;

$obj->{data}->{parent_variation_obj_id} = "$wsid/$inid";

my $pcode = get_pcode();
$cmd = "cat $output_file |perl -e \'$pcode\'";
`$cmd`;
$obj->{data}->{files}->{emmax_format_hapmap_shock_id} = upload2shock("out.tped");


$wc->save_objects({workspace => $wsid, objects => [{type=>'KBaseGwasData.GwasPopulationVariation',
    name=>$outid,
    data=>$obj->{data},
    meta=>{source=>"$wsid:$inid by GWAS.filter_vcf"}}]});


system ("rm -f tmp.vcf");
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







sub get_pcode {
  my $pcode=<<'ENDMESSAGE';
  my %hash = (
      "0/0" => "1\t1",
      "0/1" => "1\t2",
      "1/1" => "2\t2",
      "./." => "0\t0"
      );
  my %hash_counter = ();
  my $chr_counter = 0;
  my $buffer_size = 1000000;
  my $print_info="";
  my $length =0; 
  my $current_print_info = "";
  open (TPED, ">out.tped") or die ("Can not open out_tped for writing");

  while (<>){
    chomp ($_);
    my ($CHROM,$POS,$ID,$REF,$ALT,$QUAL,$FILTER,$INFO,$FORMAT,@info) = split ("\t",$_);
    next if ($_=~/^#/);
    if (!$hash_counter{$CHROM}){
      $chr_counter ++;
    }
    $print_info = "$chr_counter\t${CHROM}_$POS\t0\t$POS\t";
    foreach my $line (@info){
      my ($inp,$tmp) = split (":", $line);
      $print_info .= $hash{$inp} . "\t";
    }
    $print_info .= "\n";

    $current_print_info .=$print_info;
    $length += length ($print_info);
    if ($length >$buffer_size){
      print TPED $current_print_info;
      $current_print_info = "";
    }

  }

  if ($current_print_info){
    print TPED $current_print_info;
  }

  close (TPED);
ENDMESSAGE
    return $pcode;
}




#TODO:Fix the usage
sub print_usage {
  &return_error("USAGE: gwas_validate_population.pl ws_url ws_id metadata data");
}

sub return_error {
  my ($str) = @_;
  print STDERR "$str\n";
  exit(1);
}





