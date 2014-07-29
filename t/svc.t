use strict;
use Bio::KBase::GWAS::Client;


my $ws_id="kbasetest:home";
my $gc = Bio::KBase::GWAS::Client->new("http://localhost:7086");
my $job_id = $gc->prepare_variation({ws_id => $ws_id, inobj_id => 'atpopvar1', outobj_id => 'atpopvar1.filtered', minor_allele_frequency => "0.05", comment => 'test'});

print "$$job_id[0] $$job_id[1]\n";

$job_id = $gc->calculate_kinship_matrix({ws_id => $ws_id, inobj_id => 'atpopvar1.filtered', outobj_id => 'atpopvar1.filtered.kinship', comment => 'test'});
print "$$job_id[0] $$job_id[1]\n";

$job_id = $gc->run_gwas({ws_id => $ws_id, variation_id => 'atpopvar1.filtered', trait_id => 'FLC', kinship_id => 'atpopvar1.filtered.kinship', out_id => 'FLC.topvariations', comment => 'test'});
print "$$job_id[0] $$job_id[1]\n";

$job_id = $gc->variations_to_genes({ws_id => $ws_id, variation_id => 'FLC.topvariations',out_id => 'FLC.genelist', num2snps => "100", pmin => "3", distance => "1000", comment => 'test'});
print "$job_id\n";
