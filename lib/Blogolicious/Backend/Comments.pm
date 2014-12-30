package Blogolicious::Backend::Comments;
use common::sense;

use namespace::clean;
use Moo;

use YAML::XS;
use File::Slurp qw(read_file);
use File::Path qw(make_path);
use Carp qw(croak carp);
use URI::Escape;
use DateTime;
use Digest::MD5 qw(md5_hex);


has 'backend' => (
    is => 'ro',
    isa => sub {
        if (ref($_[0]) ne 'CODE') {
            croak("Need coderef!")
        }
    },
);

has 'moderate_if_unsure' => (
    is => 'ro',
    isa => sub {
        if ($_[0] < 0 || $_[0] > 1) {    
            croak("moderate if unsure needs 0 or 1");
       }
    },
    default => sub { 1 },
);

has 'anonymize_email' => (
    is => 'ro',
    isa => sub [
        if ($_[0] < 0 || $_[0] > 1) {    
            croak("anonymize_email needs 0 or 1");
       }
    },
    default => sub { 0 },
);

has 'spam_filter' => (
    is => 'ro',
    isa => sub {
        if (ref($_[0]) ne 'CODE') {
            croak("Need coderef!")
        }
    },
    default => sub { return sub {return 0 }}
);

sub BUILD {
    my $self = shift;
    $self->{back
}

__END__

=head1 NAME

Blogolicious::Backend::Comments - get, validate, filter, save comments

=head1 SYNOPSIS

use Blogolicious::Backend::Comments

    my $c = Blogolicious::Backend::Comments->new (
        backend     => Blogolicious::Backend::File->new($cfg->{'comments'}{'backend'}),
        spam_filter => Blogolicious::Backend::File->new($cfg->{'spam'}{'backend'}),
        moderate_if_unsure => 1, # we want to moderate posts that have "unsure" spam status
    );
    $c->add($post, $comment);
    $post_comments = $c->get($post);

=head1 DESCRIPTION

L<Blogolicious::Backend::Comments manages adding and retrieving comments

=head1 ATTRIBUTES

=head2 backend

backend to use to store/retrieve comments. Coderef

=head2 spam_filter

backend to use as spamfilter. Coderef.

=head2 anonymize_email

save only hash of email even if provided with real one. Defaults to 0

=head2 moderate_if_unsure

send email to moderation of spam filter results is "unsure". Defaults to 1

=head1 COMMENT FORMAT
{
    author   => 'bar',
    email    => 'bar@foo.org',
    emailmd5 => '6270fe9feacf3f45f2164918fba8a684'
    url      => undef
    date     => 1419971812,
 }

* B<author> - required
* B<email>, B<emailmd5> - one of these is required (gravatars), if you specify only email, hash will be auto-generated

=head1 METHODS

=head2 add

    $c->add(
        "My_new_blog",
 
    )
        
Validate->spamfilter->add blogpost

returns hash with status of chain, or undef if something (Backend dead etc.) critically failed

* B<ok> - all steps passed
* B<valid> - content is valid
* B<moderation> - comment is held for moderation
* B<spam> - comment is considered spam
* B<spam_level> -  0 for ham, 1 for unsure (usually moderation), 2 for spam

successful comment:

    {
       ok         => 1, # all steps passed
       valid      => 1, # passed content validation
       moderation => 0,
       spam       => 0, # passed spam filter
       spam_level => 0,
    }

comment in moderation

    {
       ok         => 0, # all steps passed
       valid      => 1, # passed content validation
       moderation => 0,
       spam       => 0, # passed spam filter
       spam_level => 1,
    }

if a given step was not passed result from it wont be included:

comment did not pass validation:

    {
       ok         => 0, # all steps passed
       valid      => 0, # passed content validation
    }

=head2 validate

    $c->validate($comment)

Pass comment thru validation phase. Returns 1 if OK

=head2 is_spam

Pass comment thru spamcheck. 0 for ham/moderate, 1 for spam
