use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('Blogolicious');

$t->post_form_ok(
    '/blog/comments/new' =>
        {
            author => 'bot',
            email => 'bad_email',
            postid => '2012-11-16_testpost',
            content => 'test adding comment',
        },
    'post comment')
    ->status_is(200)->content_like(qr/test adding comment/i,'check if added comment shows up');

done_testing();
