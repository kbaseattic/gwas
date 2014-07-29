#kbase-login pranjan77
#ws-createws KBasePublicGenotypePhenotype
#ws-typespec-register --request KBaseGwasData --user pranjan77

#ws-typespec-register --user  pranjan77 --typespec genotype_phenotype_module3.spec --add 'GwasPopulation;GwasPopulationVariation;GwasPopulationTrait;GwasPopulationKinship;GwasTopVariations;GwasGeneList'  
#ws-typespec-register --user  pranjan77 --typespec genotype_phenotype_module3.spec --add 'GwasPopulation;GwasPopulationVariation;GwasPopulationTrait;GwasPopulationKinship;GwasTopVariations;GwasGeneList' --commit 
#ws-typespec-register --user  pranjan77 --typespec genotype_phenotype_module3.spec  --commit 


#ws-typespec-register --user  pranjan77 --typespec  genotype_phenotype_module_and_variations.spec --add 'VariationSample;VariantCall' --commit 
#ws-typespec-register --user  pranjan77 --typespec  gen4.spec --commit 


#06/27/2014


#ws-typespec-register --user  pranjan77 --typespec  gen5.spec --add 'GwasExperimentSummary'  
#ws-typespec-register --user  pranjan77 --typespec  gen5.spec --add 'GwasExperimentSummary' --commit 
ws-typespec-register --user  pranjan77 --typespec KBaseGwasData.spec   --commit 
ws-typespec-register --release KBaseGwasData --user pranjan77

#exit

