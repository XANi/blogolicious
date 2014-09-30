package Blogolicious::Plugin::Spam::Bogofilter;

use common::sense;
use Moo;

use Log::Any;


sub rate {
    my $self = shift;
    return 0;
}

has 'bogofilter_path' => (
    is => 'ro',
    isa => sub {
        if (! -x $_[0]) {
            croak("$_[0] is not executable")
        }
    },
    default => sub { `which bogofilter` } # this probably should search path via some clever module...
);

has 'db_path' => (
    is => 'ro',
#    isa => sub {};
    default => sub {'bogofilter.db'},
)

sub _format_data {
    my $self = shift;
    my $data = shift;
    my $out;
    if (defined($data->{'headers'})) {
        while(my ($k, $v) = each( %{ $data->{'headers'} } )) {
            $out .= $k . ": " . $self->_sanitize_header($v)
        }
    }
    $out .= "\n\n";
    if (defined($data->{'data'})) {
        $out .= $data->{'data'}
    }
    return $out;
}

sub _sanitize_header {
    my $self = shift;

    return;
}

1;
__END__

=head1 NAME

Blogolicious::Plugins::Spam::Bogofilter - spam detection based on bogofilter

=head1 DESCRIPTION
