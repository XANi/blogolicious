use lib 'lib';
use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('Blogolicious');

$t->post_ok(
    '/blog/comments/new' => form =>
        {
            author => 'bot1',
            email => 'testmail@example.com',
            postid => '2012-11-16_testpost',
             comment => 'test adding comment',
        },
    'post comment')
    ->status_is(200)->content_like(qr/comment added/i,'post returns ok');

$t->post_ok(
        '/blog/comments/new' => form =>
        {
            author => 'bot2',
            email => 'bad_email',
            postid => '2012-11-16_testpost',
            comment => 'test adding comment',
        })
    ->status_is(500, 'invalid comment not accepted');
$t->post_ok(
        '/blog/comments/new' => form =>
        {
            email => 'testmail@example.com',
            postid => '2012-11-16_testpost',
            comment => 'test adding comment',
        })
    ->status_is(500, 'comment with missing field not accepted');
$t->post_ok(
        '/blog/comments/new' => form =>
        {
            author => 'bot3',
            email => 'testmail@example.com',
            postid => '1901-11-16_testpost',
            comment => 'test adding comment',
        })
    ->status_is(500, 'comment to nonexisting blogpost not accepted');

$t->post_ok(
    '/blog/comments/new' => form =>
        {
            author => 'bot4',
            email => 'testmail@example.com',
            postid => '2012-11-16_testpost',
            comment => 'test adding another comment',
            url => 'http://example.com',
        },
    'post comment')
    ->status_is(200)->content_like(qr/comment added/i,'adding comment with url');

$t->post_ok(
    '/blog/comments/new' => form =>
        {
            author => 'bot5',
            email => 'testmail@example.com',
            postid => '2012-11-16_testpost',
            comment => 'test adding comment',
            url => 'h://example.com',
        },
    'post comment')
    ->status_is(500,'adding comment with bad url');
done_testing();
