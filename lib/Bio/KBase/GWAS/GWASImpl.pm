package Bio::KBase::GWAS::GWASImpl;
use strict;
use Bio::KBase::Exceptions;
# Use Semantic Versioning (2.0.0-rc.1)
# http://semver.org 
our $VERSION = "0.1.0";

=head1 NAME

GWAS

=head1 DESCRIPTION
 


=cut

#BEGIN_HEADER
use Bio::KBase::Workflow::KBW;
#END_HEADER

sub new
{
    my($class, @args) = @_;
    my $self = {
    };
    bless $self, $class;
    #BEGIN_CONSTRUCTOR
    my %params;
    my @list = qw(ujs_url awe_url shock_url ws_url);
    if ((my $e = $ENV{KB_DEPLOYMENT_CONFIG}) && -e $ENV{KB_DEPLOYMENT_CONFIG}) {  
      my $service = $ENV{KB_SERVICE_NAME};
      if (defined($service)) {
        my $c = Config::Simple->new();
        $c->read($e);
        for my $p (@list) {
          my $v = $c->param("$service.$p");
          if ($v) {
            $params{$p} = $v;
          }
        }
      }
    }
 
    # set default values for testing
    $params{'ujs_url'} = 'http://localhost:7083' if ! defined $params{'ujs_url'};
    $params{'awe_url'} = 'http://localhost:7080' if ! defined $params{'awe_url'};
    $params{'shock_url'} = 'http://kbase.us/services/shock-api' if ! defined $params{'shock_url'};
    $params{'ws_url'} = 'https://kbase.us/services/ws/' if ! defined $params{'ws_url'};
    $self->{_config} = \%params;
    #$self->{cdmi} = Bio::KBase::CDMI::CDMI->new( "dbhost" => "db1.chicago.kbase.us", "dbName" => "kbase_sapling_v1", "userData" => "kbase_sapselect/oiwn22&dmwWEe", "DBD" => "/kb/deployment/lib/KSaplingDBD.xml");

    #END_CONSTRUCTOR

    if ($self->can('_init_instance'))
    {
	$self->_init_instance();
    }
    return $self;
}

=head1 METHODS



=head2 prepare_variation

  $job_id = $obj->prepare_variation($args)

=over 4

=item Parameter and return types

=begin html

<pre>
$args is a PrepareVariationParams
$job_id is a reference to a list where each element is a string
PrepareVariationParams is a reference to a hash where the following keys are defined:
	ws_id has a value which is a string
	inobj_id has a value which is a string
	outobj_id has a value which is a string
	minor_allele_frequency has a value which is a string
	comment has a value which is a string

</pre>

=end html

=begin text

$args is a PrepareVariationParams
$job_id is a reference to a list where each element is a string
PrepareVariationParams is a reference to a hash where the following keys are defined:
	ws_id has a value which is a string
	inobj_id has a value which is a string
	outobj_id has a value which is a string
	minor_allele_frequency has a value which is a string
	comment has a value which is a string


=end text



=item Description

gwas_prepare_variation_for_gwas_async prepares variation data in proper format and allows option for minor allele frequecy based filtering

=back

=cut

sub prepare_variation
{
    my $self = shift;
    my($args) = @_;

    my @_bad_arguments;
    (ref($args) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"args\" (value was \"$args\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to prepare_variation:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'prepare_variation');
    }

    my $ctx = $Bio::KBase::GWAS::Service::CallContext;
    my($job_id);
    #BEGIN prepare_variation
    $job_id = Bio::KBase::Workflow::KBW::run_async($self, $ctx, $args);
    #END prepare_variation
    my @_bad_returns;
    (ref($job_id) eq 'ARRAY') or push(@_bad_returns, "Invalid type for return variable \"job_id\" (value was \"$job_id\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to prepare_variation:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'prepare_variation');
    }
    return($job_id);
}




=head2 calculate_kinship_matrix

  $job_id = $obj->calculate_kinship_matrix($args)

=over 4

=item Parameter and return types

=begin html

<pre>
$args is a CalculateKinshipMatrixParams
$job_id is a reference to a list where each element is a string
CalculateKinshipMatrixParams is a reference to a hash where the following keys are defined:
	ws_id has a value which is a string
	inobj_id has a value which is a string
	outobj_id has a value which is a string
	method has a value which is a string
	comment has a value which is a string

</pre>

=end html

=begin text

$args is a CalculateKinshipMatrixParams
$job_id is a reference to a list where each element is a string
CalculateKinshipMatrixParams is a reference to a hash where the following keys are defined:
	ws_id has a value which is a string
	inobj_id has a value which is a string
	outobj_id has a value which is a string
	method has a value which is a string
	comment has a value which is a string


=end text



=item Description

gwas_calculate_kinship_matrix_emma_async calculates kinship matrix from variation data.
Currently the method support emma and will support different methods.

=back

=cut

sub calculate_kinship_matrix
{
    my $self = shift;
    my($args) = @_;

    my @_bad_arguments;
    (ref($args) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"args\" (value was \"$args\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to calculate_kinship_matrix:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'calculate_kinship_matrix');
    }

    my $ctx = $Bio::KBase::GWAS::Service::CallContext;
    my($job_id);
    #BEGIN calculate_kinship_matrix
    $job_id = Bio::KBase::Workflow::KBW::run_async($self, $ctx, $args);
    #END calculate_kinship_matrix
    my @_bad_returns;
    (ref($job_id) eq 'ARRAY') or push(@_bad_returns, "Invalid type for return variable \"job_id\" (value was \"$job_id\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to calculate_kinship_matrix:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'calculate_kinship_matrix');
    }
    return($job_id);
}




=head2 run_gwas

  $job_id = $obj->run_gwas($args)

=over 4

=item Parameter and return types

=begin html

<pre>
$args is a RunGWASParams
$job_id is a reference to a list where each element is a string
RunGWASParams is a reference to a hash where the following keys are defined:
	ws_id has a value which is a string
	variation_id has a value which is a string
	trait_id has a value which is a string
	kinship_id has a value which is a string
	out_id has a value which is a string
	method has a value which is a string
	comment has a value which is a string

</pre>

=end html

=begin text

$args is a RunGWASParams
$job_id is a reference to a list where each element is a string
RunGWASParams is a reference to a hash where the following keys are defined:
	ws_id has a value which is a string
	variation_id has a value which is a string
	trait_id has a value which is a string
	kinship_id has a value which is a string
	out_id has a value which is a string
	method has a value which is a string
	comment has a value which is a string


=end text



=item Description

gwas_run_gwas_emma_async Runs genome wide association analysis and takes kinship, variation, trait file, and method as input.
Currently the method support emma and will support different methods.

=back

=cut

sub run_gwas
{
    my $self = shift;
    my($args) = @_;

    my @_bad_arguments;
    (ref($args) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"args\" (value was \"$args\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to run_gwas:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'run_gwas');
    }

    my $ctx = $Bio::KBase::GWAS::Service::CallContext;
    my($job_id);
    #BEGIN run_gwas
    $job_id = Bio::KBase::Workflow::KBW::run_async($self, $ctx, $args);
    #END run_gwas
    my @_bad_returns;
    (ref($job_id) eq 'ARRAY') or push(@_bad_returns, "Invalid type for return variable \"job_id\" (value was \"$job_id\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to run_gwas:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'run_gwas');
    }
    return($job_id);
}




=head2 variations_to_genes

  $status = $obj->variations_to_genes($args)

=over 4

=item Parameter and return types

=begin html

<pre>
$args is a Variations2GenesParams
$status is a reference to a list where each element is a string
Variations2GenesParams is a reference to a hash where the following keys are defined:
	ws_id has a value which is a string
	variation_id has a value which is a string
	out_id has a value which is a string
	num2snps has a value which is a string
	pmin has a value which is a string
	distance has a value which is a string
	comment has a value which is a string

</pre>

=end html

=begin text

$args is a Variations2GenesParams
$status is a reference to a list where each element is a string
Variations2GenesParams is a reference to a hash where the following keys are defined:
	ws_id has a value which is a string
	variation_id has a value which is a string
	out_id has a value which is a string
	num2snps has a value which is a string
	pmin has a value which is a string
	distance has a value which is a string
	comment has a value which is a string


=end text



=item Description

gwas_variations_to_genes gets genes close to the SNPs

=back

=cut

sub variations_to_genes
{
    my $self = shift;
    my($args) = @_;

    my @_bad_arguments;
    (ref($args) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"args\" (value was \"$args\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to variations_to_genes:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'variations_to_genes');
    }

    my $ctx = $Bio::KBase::GWAS::Service::CallContext;
    my($status);
    #BEGIN variations_to_genes
    $status = Bio::KBase::Workflow::KBW::run_sync($self, $ctx, $args);
    #END variations_to_genes
    my @_bad_returns;
    (ref($status) eq 'ARRAY') or push(@_bad_returns, "Invalid type for return variable \"status\" (value was \"$status\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to variations_to_genes:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'variations_to_genes');
    }
    return($status);
}




=head2 genelist_to_networks

  $status = $obj->genelist_to_networks($args)

=over 4

=item Parameter and return types

=begin html

<pre>
$args is a GeneList2NetworksParams
$status is a reference to a list where each element is a string
GeneList2NetworksParams is a reference to a hash where the following keys are defined:
	ws_id has a value which is a string
	inobj_id has a value which is a string
	outobj_id has a value which is a string

</pre>

=end html

=begin text

$args is a GeneList2NetworksParams
$status is a reference to a list where each element is a string
GeneList2NetworksParams is a reference to a hash where the following keys are defined:
	ws_id has a value which is a string
	inobj_id has a value which is a string
	outobj_id has a value which is a string


=end text



=item Description

list of genes to Network

=back

=cut

sub genelist_to_networks
{
    my $self = shift;
    my($args) = @_;

    my @_bad_arguments;
    (ref($args) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"args\" (value was \"$args\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to genelist_to_networks:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'genelist_to_networks');
    }

    my $ctx = $Bio::KBase::GWAS::Service::CallContext;
    my($status);
    #BEGIN genelist_to_networks
    $status = Bio::KBase::Workflow::KBW::run_sync($self, $ctx, $args);

    #END genelist_to_networks
    my @_bad_returns;
    (ref($status) eq 'ARRAY') or push(@_bad_returns, "Invalid type for return variable \"status\" (value was \"$status\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to genelist_to_networks:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'genelist_to_networks');
    }
    return($status);
}




=head2 gwas_genelist_to_networks

  $status = $obj->gwas_genelist_to_networks($args)

=over 4

=item Parameter and return types

=begin html

<pre>
$args is a GeneList2NetworksParams
$status is a reference to a list where each element is a string
GeneList2NetworksParams is a reference to a hash where the following keys are defined:
	ws_id has a value which is a string
	inobj_id has a value which is a string
	outobj_id has a value which is a string

</pre>

=end html

=begin text

$args is a GeneList2NetworksParams
$status is a reference to a list where each element is a string
GeneList2NetworksParams is a reference to a hash where the following keys are defined:
	ws_id has a value which is a string
	inobj_id has a value which is a string
	outobj_id has a value which is a string


=end text



=item Description

KBaseGwasData.GeneList to Network

=back

=cut

sub gwas_genelist_to_networks
{
    my $self = shift;
    my($args) = @_;

    my @_bad_arguments;
    (ref($args) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"args\" (value was \"$args\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to gwas_genelist_to_networks:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'gwas_genelist_to_networks');
    }

    my $ctx = $Bio::KBase::GWAS::Service::CallContext;
    my($status);
    #BEGIN gwas_genelist_to_networks
    $status = Bio::KBase::Workflow::KBW::run_sync($self, $ctx, $args);
    #END gwas_genelist_to_networks
    my @_bad_returns;
    (ref($status) eq 'ARRAY') or push(@_bad_returns, "Invalid type for return variable \"status\" (value was \"$status\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to gwas_genelist_to_networks:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'gwas_genelist_to_networks');
    }
    return($status);
}




=head2 version 

  $return = $obj->version()

=over 4

=item Parameter and return types

=begin html

<pre>
$return is a string
</pre>

=end html

=begin text

$return is a string

=end text

=item Description

Return the module version. This is a Semantic Versioning number.

=back

=cut

sub version {
    return $VERSION;
}

=head1 TYPES



=head2 PrepareVariationParams

=over 4



=item Description

All methods are authenticated.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
ws_id has a value which is a string
inobj_id has a value which is a string
outobj_id has a value which is a string
minor_allele_frequency has a value which is a string
comment has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
ws_id has a value which is a string
inobj_id has a value which is a string
outobj_id has a value which is a string
minor_allele_frequency has a value which is a string
comment has a value which is a string


=end text

=back



=head2 CalculateKinshipMatrixParams

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
ws_id has a value which is a string
inobj_id has a value which is a string
outobj_id has a value which is a string
method has a value which is a string
comment has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
ws_id has a value which is a string
inobj_id has a value which is a string
outobj_id has a value which is a string
method has a value which is a string
comment has a value which is a string


=end text

=back



=head2 RunGWASParams

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
ws_id has a value which is a string
variation_id has a value which is a string
trait_id has a value which is a string
kinship_id has a value which is a string
out_id has a value which is a string
method has a value which is a string
comment has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
ws_id has a value which is a string
variation_id has a value which is a string
trait_id has a value which is a string
kinship_id has a value which is a string
out_id has a value which is a string
method has a value which is a string
comment has a value which is a string


=end text

=back



=head2 Variations2GenesParams

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
ws_id has a value which is a string
variation_id has a value which is a string
out_id has a value which is a string
num2snps has a value which is a string
pmin has a value which is a string
distance has a value which is a string
comment has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
ws_id has a value which is a string
variation_id has a value which is a string
out_id has a value which is a string
num2snps has a value which is a string
pmin has a value which is a string
distance has a value which is a string
comment has a value which is a string


=end text

=back



=head2 GeneList2NetworksParams

=over 4



=item Description

inobj_id is the list of kb feature ids comma separated


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
ws_id has a value which is a string
inobj_id has a value which is a string
outobj_id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
ws_id has a value which is a string
inobj_id has a value which is a string
outobj_id has a value which is a string


=end text

=back



=cut

1;
