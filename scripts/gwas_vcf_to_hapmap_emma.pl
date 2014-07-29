#!/usr/bin/env perl
use strict;

my %hash = (
    "0/0" => "1\t1",
    "0/1" => "1\t2",
    "1/1" => "2\t2"
    );
my %hash_counter = ();
my $chr_counter = 0;
my $buffer_size = 1000000;
my $print_info="";
my $length =0; 
my $current_print_info = "";



#open (TFAM, ">out.tfam") or die ("Can not open out_tfam for writing");
open (TPED, ">out.tped") or die ("Can not open out_tped for writing");

while (<>){
  chomp ($_);
  my ($CHROM,$POS,$ID,$REF,$ALT,$QUAL,$FILTER,$INFO,$FORMAT,@info) = split ("\t",$_);
=comment  
  if ($_=~/^#CHROM/){
    foreach my $line (@info){
      print TFAM $line . "\t" . $line . "\t" . '0' . "\t" . '0' . "\t" . '0' . "\t" . '-9' . "\n"  ;
    }
    close (TFAM);
  }
=cut
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
