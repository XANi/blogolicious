use lib 'lib';
use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('Blogolicious');

$t->post_form_ok(
    '/blog/comments/new' =>
        {
            author => 'bot',
            email => 'testmail@example.com',
            postid => '2012-11-16_testpost',
            comment => 'test adding comment',
        },
    'post comment')
    ->status_is(200)->content_like(qr/comment added/i,'post returns ok');

$t->post_form_ok(
        '/blog/comments/new' =>
        {
            author => 'bot',
            email => 'bad_email',
            postid => '2012-11-16_testpost',
            comment => 'test adding comment',
        })
    ->status_is(500, 'invalid comment not accepted');
$t->post_form_ok(
        '/blog/comments/new' =>
        {
            email => 'testmail@example.com',
            postid => '2012-11-16_testpost',
            comment => 'test adding comment',
        })
    ->status_is(500, 'comment with missing field not accepted');
$t->post_form_ok(
        '/blog/comments/new' =>
        {
            author => 'bot',
            email => 'testmail@example.com',
            postid => '1901-11-16_testpost',
            comment => 'test adding comment',
        })
    ->status_is(500, 'comment to nonexisting blogpost not accepted');
done_testing();
