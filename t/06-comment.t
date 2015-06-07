use lib 'lib';

use Test::More;
use Test::Exception;
use Blogolicious::Comment;



lives_ok {
    my $c = Blogolicious::Comment->new(
        author => 'Joe Blog',
        email  => 'joeblog@example.com',
        postid => 'some-post',
        comment => 'some random comment'
    );
    $c->spam;
    ok($c->is_spam && !$c->is_ham && !$c->is_moderated, "Comment marked as spam have correct flags");
    $c->ham;
    ok(!$c->is_spam && $c->is_ham && !$c->is_moderated, "Comment marked as ham have correct flags");
    $c->moderate;
    ok(!$c->is_spam && !$c->is_ham && $c->is_moderated, "Comment marked as moderated have correct flags");
} "correct coment is created";

lives_ok {
    my $c = Blogolicious::Comment->new(
        author => 'Joe Blog',
        email  => 'joeblog@example.com',
        url => 'http://blog.example.com/page',
        postid => 'some-post',
        comment => 'comment data'
    );
    is ($c->author, 'Joe Blog', 'correct author'),
    is ($c->email, 'joeblog@example.com', 'correct email'),
    is ($c->url, 'http://blog.example.com/page', 'correct author'),
    is ($c->postid, 'some-post', "correct post id");
    is ($c->comment, 'comment data', "correct comment data");

} "correct coment with url is created";

dies_ok {
    my $c = Blogolicious::Comment->new(
        author => '[bad potato]',
        email  => 'potato@example.com',
        postid => 'some-post',
        comment => 'some random comment'
    );
} 'dies on bad author name';

dies_ok {
    my $c = Blogolicious::Comment->new(
        author => '[bad potato]',
        email  => 'potat[]o@example.com',
        postid => 'some-post',
        comment => 'some random comment'
    );
} 'dies on bad email';


dies_ok {
    my $c = Blogolicious::Comment->new(
        author => 'evil potato',
        email  => 'potato@example.com',
        url    => 'gopher://example.com',
        postid => 'some-post',
        comment => 'some random comment'
    );
} 'dies on invalid url';

done_testing()
