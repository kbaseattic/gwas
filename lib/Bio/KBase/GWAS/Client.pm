package Bio::KBase::GWAS::Client;

use JSON::RPC::Client;
use strict;
use Data::Dumper;
use URI;
use Bio::KBase::Exceptions;
use Bio::KBase::AuthToken;

# Client version should match Impl version
# This is a Semantic Version number,
# http://semver.org
our $VERSION = "0.1.0";

=head1 NAME

Bio::KBase::GWAS::Client

=head1 DESCRIPTION





=cut

sub new
{
    my($class, $url, @args) = @_;
    

    my $self = {
	client => Bio::KBase::GWAS::Client::RpcClient->new,
	url => $url,
    };

    #
    # This module requires authentication.
    #
    # We create an auth token, passing through the arguments that we were (hopefully) given.

    {
	my $token = Bio::KBase::AuthToken->new(@args);
	
	if (!$token->error_message)
	{
	    $self->{token} = $token->token;
	    $self->{client}->{token} = $token->token;
	}
        else
        {
	    #
	    # All methods in this module require authentication. In this case, if we
	    # don't have a token, we can't continue.
	    #
	    die "Authentication failed: " . $token->error_message;
	}
    }

    my $ua = $self->{client}->ua;	 
    my $timeout = $ENV{CDMI_TIMEOUT} || (30 * 60);	 
    $ua->timeout($timeout);
    bless $self, $class;
    #    $self->_validate_version();
    return $self;
}




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
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function prepare_variation (received $n, expecting 1)");
    }
    {
	my($args) = @args;

	my @_bad_arguments;
        (ref($args) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"args\" (value was \"$args\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to prepare_variation:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'prepare_variation');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "GWAS.prepare_variation",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'prepare_variation',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method prepare_variation",
					    status_line => $self->{client}->status_line,
					    method_name => 'prepare_variation',
				       );
    }
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
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function calculate_kinship_matrix (received $n, expecting 1)");
    }
    {
	my($args) = @args;

	my @_bad_arguments;
        (ref($args) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"args\" (value was \"$args\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to calculate_kinship_matrix:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'calculate_kinship_matrix');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "GWAS.calculate_kinship_matrix",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'calculate_kinship_matrix',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method calculate_kinship_matrix",
					    status_line => $self->{client}->status_line,
					    method_name => 'calculate_kinship_matrix',
				       );
    }
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
	out_id has a value which is a string
	num2snps has a value which is a string
	pmin has a value which is a string
	distance has a value which is a string
	comment has a value which is a string

</pre>

=end html

=begin text

$args is a RunGWASParams
$job_id is a reference to a list where each element is a string
RunGWASParams is a reference to a hash where the following keys are defined:
	ws_id has a value which is a string
	variation_id has a value which is a string
	out_id has a value which is a string
	num2snps has a value which is a string
	pmin has a value which is a string
	distance has a value which is a string
	comment has a value which is a string


=end text

=item Description

gwas_run_gwas_emma_async Runs genome wide association analysis and takes kinship, variation, trait file, and method as input.
Currently the method support emma and will support different methods.

=back

=cut

sub run_gwas
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function run_gwas (received $n, expecting 1)");
    }
    {
	my($args) = @args;

	my @_bad_arguments;
        (ref($args) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"args\" (value was \"$args\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to run_gwas:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'run_gwas');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "GWAS.run_gwas",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'run_gwas',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method run_gwas",
					    status_line => $self->{client}->status_line,
					    method_name => 'run_gwas',
				       );
    }
}



=head2 variations_to_genes

  $status = $obj->variations_to_genes($args)

=over 4

=item Parameter and return types

=begin html

<pre>
$args is a RunGWASParams
$status is a string
RunGWASParams is a reference to a hash where the following keys are defined:
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

$args is a RunGWASParams
$status is a string
RunGWASParams is a reference to a hash where the following keys are defined:
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
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function variations_to_genes (received $n, expecting 1)");
    }
    {
	my($args) = @args;

	my @_bad_arguments;
        (ref($args) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"args\" (value was \"$args\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to variations_to_genes:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'variations_to_genes');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "GWAS.variations_to_genes",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'variations_to_genes',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method variations_to_genes",
					    status_line => $self->{client}->status_line,
					    method_name => 'variations_to_genes',
				       );
    }
}



sub version {
    my ($self) = @_;
    my $result = $self->{client}->call($self->{url}, {
        method => "GWAS.version",
        params => [],
    });
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(
                error => $result->error_message,
                code => $result->content->{code},
                method_name => 'variations_to_genes',
            );
        } else {
            return wantarray ? @{$result->result} : $result->result->[0];
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(
            error => "Error invoking method variations_to_genes",
            status_line => $self->{client}->status_line,
            method_name => 'variations_to_genes',
        );
    }
}

sub _validate_version {
    my ($self) = @_;
    my $svr_version = $self->version();
    my $client_version = $VERSION;
    my ($cMajor, $cMinor) = split(/\./, $client_version);
    my ($sMajor, $sMinor) = split(/\./, $svr_version);
    if ($sMajor != $cMajor) {
        Bio::KBase::Exceptions::ClientServerIncompatible->throw(
            error => "Major version numbers differ.",
            server_version => $svr_version,
            client_version => $client_version
        );
    }
    if ($sMinor < $cMinor) {
        Bio::KBase::Exceptions::ClientServerIncompatible->throw(
            error => "Client minor version greater than Server minor version.",
            server_version => $svr_version,
            client_version => $client_version
        );
    }
    if ($sMinor > $cMinor) {
        warn "New client version available for Bio::KBase::GWAS::Client\n";
    }
    if ($sMajor == 0) {
        warn "Bio::KBase::GWAS::Client version is $svr_version. API subject to change.\n";
    }
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



=head2 RunGWASParams

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



=cut

package Bio::KBase::GWAS::Client::RpcClient;
use base 'JSON::RPC::Client';

#
# Override JSON::RPC::Client::call because it doesn't handle error returns properly.
#

sub call {
    my ($self, $uri, $obj) = @_;
    my $result;

    if ($uri =~ /\?/) {
       $result = $self->_get($uri);
    }
    else {
        Carp::croak "not hashref." unless (ref $obj eq 'HASH');
        $result = $self->_post($uri, $obj);
    }

    my $service = $obj->{method} =~ /^system\./ if ( $obj );

    $self->status_line($result->status_line);

    if ($result->is_success) {

        return unless($result->content); # notification?

        if ($service) {
            return JSON::RPC::ServiceObject->new($result, $self->json);
        }

        return JSON::RPC::ReturnObject->new($result, $self->json);
    }
    elsif ($result->content_type eq 'application/json')
    {
        return JSON::RPC::ReturnObject->new($result, $self->json);
    }
    else {
        return;
    }
}


sub _post {
    my ($self, $uri, $obj) = @_;
    my $json = $self->json;

    $obj->{version} ||= $self->{version} || '1.1';

    if ($obj->{version} eq '1.0') {
        delete $obj->{version};
        if (exists $obj->{id}) {
            $self->id($obj->{id}) if ($obj->{id}); # if undef, it is notification.
        }
        else {
            $obj->{id} = $self->id || ($self->id('JSON::RPC::Client'));
        }
    }
    else {
        # $obj->{id} = $self->id if (defined $self->id);
	# Assign a random number to the id if one hasn't been set
	$obj->{id} = (defined $self->id) ? $self->id : substr(rand(),2);
    }

    my $content = $json->encode($obj);

    $self->ua->post(
        $uri,
        Content_Type   => $self->{content_type},
        Content        => $content,
        Accept         => 'application/json',
	($self->{token} ? (Authorization => $self->{token}) : ()),
    );
}



1;
