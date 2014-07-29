module GWAS
{

	/* All methods are authenticated. */
	authentication required;


	typedef structure {
		string ws_id;
		string inobj_id;
		string outobj_id;
		string minor_allele_frequency;
		string comment; 
	} PrepareVariationParams;

	/* gwas_prepare_variation_for_gwas_async prepares variation data in proper format and allows option for minor allele frequecy based filtering*/
	funcdef prepare_variation(PrepareVariationParams args) returns (list<string> job_id); 


	typedef structure {
		string ws_id;
		string inobj_id;
		string outobj_id;
		string method;
		string comment; 
         } CalculateKinshipMatrixParams;

	/*gwas_calculate_kinship_matrix_emma_async calculates kinship matrix from variation data.
	  Currently the method support emma and will support different methods.
	 */
	funcdef calculate_kinship_matrix(CalculateKinshipMatrixParams args) returns (list<string> job_id);


	typedef structure {
		string ws_id;
		string variation_id;
		string trait_id;
		string kinship_id;
		string out_id;
		string method;
		string comment; 
         } RunGWASParams;

	/*gwas_run_gwas_emma_async Runs genome wide association analysis and takes kinship, variation, trait file, and method as input.
	  Currently the method support emma and will support different methods.
	 */
	funcdef run_gwas(RunGWASParams args) returns (list<string> job_id);

	typedef structure {
		string ws_id;
		string variation_id;
		string out_id;
		string num2snps;
		string pmin;
		string distance;
		string comment; 
         } RunGWASParams;

	/*gwas_variations_to_genes gets genes close to the SNPs */
	funcdef variations_to_genes (RunGWASParams args) returns (string status);

};
