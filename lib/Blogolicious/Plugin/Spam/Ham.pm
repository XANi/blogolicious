package Blogolicious::Plugin::Spam::Ham;

use common::sense;
use Moo;

use Log::Any;


sub rate {
    my $self = shift;
    return 0;
}

1;
__END__

=head1 NAME

Blogolicious::Plugins::Spam::Ham - spam detection plugin example

=head1 DESCRIPTION

Always return ham. For testing
