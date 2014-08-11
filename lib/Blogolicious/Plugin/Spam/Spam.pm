package Blogolicious::Plugin::Spam::Spam;

use common::sense;
use Moo;

use Log::Any;


sub rate {
    my $self = shift;
    return 1;
}

1;
__END__

=head1 NAME

Blogolicious::Plugins::Spam::Spam - spam detection plugin example

=head1 DESCRIPTION

always return spam. For testing
