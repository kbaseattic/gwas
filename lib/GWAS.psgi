use Bio::KBase::GWAS::GWASImpl;

use Bio::KBase::GWAS::Service;
use Plack::Middleware::CrossOrigin;



my @dispatch;

{
    my $obj = Bio::KBase::GWAS::GWASImpl->new;
    push(@dispatch, 'GWAS' => $obj);
}


my $server = Bio::KBase::GWAS::Service->new(instance_dispatch => { @dispatch },
				allow_get => 0,
			       );

my $handler = sub { $server->handle_input(@_) };

$handler = Plack::Middleware::CrossOrigin->wrap( $handler, origins => "*", headers => "*");
