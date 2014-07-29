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
use Bio::KBase::AuthToken;
use Getopt::Long;
use Data::Dumper;

use Bio::KBase::CDMI::CDMIClient;
use Bio::KBase::Utilities::ScriptThing;
my $kbO = Bio::KBase::CDMI::CDMIClient->new_for_script();


my $ws_url                   = $ARGV[0];
my $wsid                     = $ARGV[1];
my $varinid                  = $ARGV[2];
my $outid                    = $ARGV[3];
my $numtopsnps               = $ARGV[4];
my $pmin                     = $ARGV[5];
my $distance                 = $ARGV[6];
my $comment                  = $ARGV[7];
#my $token                    = $ENV{KB_AUTH_TOKEN};


#TODO: Fix the token
my $to = Bio::KBase::AuthToken->new();
our $token = $to->{token};

use Bio::KBase::IdMap::Client;
#my $ic = Bio::KBase::IdMap::Client->new("http://140.221.85.181:7111");
my $ic = Bio::KBase::IdMap::Client->new("http://kbase.us/services/id_map");

my $wc = Bio::KBase::workspace::Client->new($ws_url, token => $token);

#Get Topvariation data
my $hash_gwas = $wc->get_object({id => $varinid, type => 'KBaseGwasData.GwasTopVariations', workspace => $wsid});



my %hcdstolocus;
my %hashlocation;


my $contigs = $hash_gwas->{'data'}{'contigs'};
my $index=0;
my %hash_contigs;
my %scontigs;
foreach my $contig(@$contigs)
{
  my $kbid = $contig->{"kbase_contig_id"};
  $hash_contigs{$index}=$kbid;
  $scontigs{$kbid}=$contig->{"id"};
  $index++;
}


my $chromosomal_positions;
my $variations = $hash_gwas->{'data'}{'variations'};

my @results;
my @results2;

my $count=0;

open (FILEX, ">tmp.txt") or die ("nnc");

foreach my $snp_array(@$variations){
  my($index, $position, $pvalue, $snp_id) = @$snp_array;
  my $kb_contig_id = $hash_contigs{$index};
 print FILEX "$kb_contig_id\t$position\t$pvalue\n";

}
close (FILEX);

my $cmd =`sort -r  -gk3,3 tmp.txt |head -n $numtopsnps `;
my @variations = split ("\n", $cmd);
foreach my $snp_array(@variations)
{


$count++;
  last if ($count > $numtopsnps);
  my ($kb_contig_id,$position, $pvalue) = split ("\t", $snp_array);
  my @array_position = ($kb_contig_id,$position, $pvalue);

push(@$chromosomal_positions,\@array_position) if($pvalue > $pmin);
}

my %uniquegenes;
my %hash_snp2gene;
my %hash_seen;

foreach my $positions (@$chromosomal_positions) {
  my ($kb_chromosome, $position, $pvalx)  = (@$positions[0], @$positions[1], @$positions[2]);


my $res1 = region_to_locus_information($kb_chromosome, $position, $distance);

my $l = @$res1;
if ($l){
my $res=get_gene_info($res1);

  my @snp_gene;


  foreach my $generef(@$res)
  {
    my($cid, $sid, $fid, $func, $source_id) = @$generef;
#    print "$cid, $sid, $fid, $func, $source_id\n";
   my $locus = $hcdstolocus{$fid};
   my ($b,$e) = ($hashlocation{$locus}{b}, $hashlocation{$locus}{e});

my $pvalue_1 =$pvalx + 0.01;
    my $b1=int($b);
    my $e1=int($e);

    
    my @mq = ($cid,$sid, $fid, int ($position) ,$func, $pvalue_1, $source_id, $b1, $e1);
    push(@results, \@mq);
    next if($hash_seen{$sid});
    push(@results2, $generef);
    $hash_seen{$sid}=1;
  }

}
}

#Create object
my %hash;
$hash{"GwasTopVariations_obj_id"}=$wsid . "/" . $varinid;
$hash{"pvaluecutoff"}=int ($pmin);
$hash{"genes_snp_list"}=\@results;
my $distance1 = int ($distance);
$hash{"distance_cutoff"}=$distance1;




$hash{"genes"}=\@results2;


my $metadata = $wc->save_object({workspace => $wsid,
    id => $outid,
    type => "KBaseGwasData.GwasGeneList",
    data => \%hash});




sub get_gene_info {
  my ($res)=@_;


  my @locus_ids;
  foreach my $generef(@$res)
  {
    my($cid, $sid, $fid, $func, $source_id) = @$generef;
push (@locus_ids,$fid);
  }

my $rst;

eval{ $rst = $ic->longest_cds_from_locus(\@locus_ids)};

  my @res1=();
if ($rst){

my $hlocustocds = {};
  while (my ($key, $val) = each (%$rst)){
    my $cds;
    while (my ($key2, $val2) = each (%$val)){
      $cds=$key2; 
    }
    $hlocustocds->{$key}=$cds;
    $hcdstolocus{$cds}=$key;
  }

  foreach my $generef(@$res)
  {
    my @mq = ();

    my($cid, $sid, $fid, $func, $source_id) = @$generef;
     $generef->[2]=$hlocustocds->{$fid};
    push (@res1, $generef) if ($hlocustocds->{$fid}); 
  }
  }
  return \@res1;

}

sub region_to_locus_information {
  my ($contig, $position, $distance) = @_;

  my $beg =$position-$distance;
  my $strand="+";
  my $ln = 2*$distance;
  my $fids = $kbO->region_to_fids([$contig,$beg,$strand,$ln]);

  my @locus;
  foreach my $line (@$fids){
    push (@locus, $line) if ($line=~/locus/);
  }
 


  my @res = ();

  my $l=@locus;
  if ($l){
  my @fields = (  'source_id',  'function' );
  my $functions = $kbO->get_entity_Feature(\@locus, \@fields);
  my $locations = $kbO->fids_to_locations(\@locus);

  foreach my $line (@locus){
  my $info = $locations->{$line}->[0];
my ($chr, $st, $str,$length) =@$info;
  my ($fb, $fe);
  if ($str eq "-"){
    $fb=$st-$length+1;
    $fe=$st;
}
  if ($str eq "+"){
    $fb=$st;
    $fe=$st+$length;
  }
$hashlocation{$line}{b}=$fb;
$hashlocation{$line}{e}=$fe;

  my @info =($contig, $functions->{$line}{source_id}, $line, $functions->{$line}{function}, $scontigs{$contig});
  push (@res, \@info);
 } 
}
  #print to_json ($locations);
  #print to_json ($functions);
return \@res;


}




