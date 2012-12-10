use Mojo::Base -strict;

use Test::More tests => 2;
use Test::Mojo;

my $t = Test::Mojo->new('Blogolicious');



$t->post_form_ok(
        '/blog/comments/new' =>
        {
            author => 'bot',
            email => 'bad_email',
            postid => 'dummy_post',
            content => 'dummy',
        }
    )->status_is(200);



