package Blogolicious::Plugin::Spam::Random;

use common::sense;
use Moo;

use Log::Any;


sub rate {
    my $self = shift;
    return rand(1);
}

1;
__END__

=head1 NAME

Blogolicious::Plugins::Spam::Random - spam detection plugin example

=head1 DESCRIPTION

just randomly rates data, used for testing/prototyping
