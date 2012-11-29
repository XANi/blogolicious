package Blogolicious::Backend::Comments::File;
use common::sense;

use YAML::XS;
use File::Slurp qw(read_file);
use Carp qw(croak carp);


sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless($self, $class);

    if (ref($_[0]) eq 'ARRAY') {
        $self->{'config'} = shift;
    }
    elsif (ref($_[0]) eq 'HASH') {
        $self->{'config'} = shift;
    }
    else {
        my %config = @_;
        $self->{'config'} = \%config;
    }
    if (!defined $self->{'config'}{'dir'}) {
        croak("You need to specify dir");
    }
}

sub add {
    my $self = shift;
    my $post = shift;
    my $data = shift;
    if (!defined( $post ) || $post =~ /^\s*$/) {
        croak("passed post name is invalid or empty");
    }
    open(my $fh, '>', $self->{'config'}{'dir'} . $post);
    print $fh Dump($data);
    close($fh);
}


