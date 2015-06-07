package Blogolicious::Comment;

use 5.010000;
use strict;
use warnings;
use Carp qw(cluck croak carp);
use Data::Dumper;
use Moo;


sub BUILD {
    my $self = shift;
}

has 'pending_moderation' => (
    is => 'rwp',
    default => sub { 1 }
);

has 'is_moderated' => (
    is => 'rwp',
    default => sub { 0 }
);

has 'is_spam' => (
    is => 'rwp',
    default => sub { 0 }
);

has 'is_ham' => (
    is => 'rwp',
    default => sub { 0 }
);



has 'author' => (
    is => 'ro',
    isa => sub {
        if ($_[0] !~ /^[\s\p{XPosixAlnum}]{2,64}$/) {
            croak("[$_[0]] doesnt look like alphanumeric string")
        }
    },
);

has 'email' => (
    is => 'ro',
    isa => sub {
        if ($_[0] !~ /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$/i) {
            croak("[$_[0]] doesnt look like email")
        }
    }
);

has 'url' => (
    is => 'ro',
    isa => sub {
        # no url is fine
        if ( !defined($_[0]) || $_[0] =~ /^\s*$/ ) { return 0 }
        # https://mathiasbynens.be/demo/url-regex
        # ph'nglui mglw'nafh Cthulhu R'lyeh wgah'nagl fhtagn
        if ($_[0] !~ /(?:(?:https?):\/\/)(?:\S+(?::\S*)?@)?(?:(?!(?:10|127)(?:\.\d{1,3}){3})(?!(?:169\.254|192\.168)(?:\.\d{1,3}){2})(?!172\.(?:1[6-9]|2\d|3[0-1])(?:\.\d{1,3}){2})(?:[1-9]\d?|1\d\d|2[01]\d|22[0-3])(?:\.(?:1?\d{1,2}|2[0-4]\d|25[0-5])){2}(?:\.(?:[1-9]\d?|1\d\d|2[0-4]\d|25[0-4]))|(?:(?:[a-z\u00a1-\uffff0-9]+-?)*[a-z\u00a1-\uffff0-9]+)(?:\.(?:[a-z\u00a1-\uffff0-9]+-?)*[a-z\u00a1-\uffff0-9]+)*(?:\.(?:[a-z\u00a1-\uffff]{2,})))(?::\d{2,5})?(?:\/[^\s]*)?$/) {
            croak('Cthulhu decided that [$_[0]] is not valid url')
        }

   },
   default => sub {undef},
);

has 'postid' => (
    is => 'ro',
);

has comment => (
    is => 'ro',
);


sub spam {
    my $self = shift;
    $self->_set_is_spam(1);
    $self->_set_is_ham(0);
    $self->_set_is_moderated(0);
    return;
}

sub ham {
    my $self = shift;
    $self->_set_is_spam(0);
    $self->_set_is_ham(1);
    $self->_set_is_moderated(0);
    return;
}

sub moderate {
    my $self = shift;
    $self->_set_is_spam(0);
    $self->_set_is_ham(0);
    $self->_set_is_moderated(1);
    return;
}

1;
__END__

=head1 NAME

Blogolicious::Comment - Comment object

=head1 SYNOPSIS

  use Module::Example;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Module::Example, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.

=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

xani, E<lt>xani@E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by XANi

This library is free software; you can redistribute it and/or modify
  it under the same terms as Perl itself, either Perl version 5.10 or,
  at your option, any later version of Perl 5 you may have available.


  =cut
