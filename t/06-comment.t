use lib 'lib';

use Test::More;
use Test::Exception;
use Blogolicious::Comment;



lives_ok {
    my $c1 = Blogolicious::Comment->new(
        author => 'Joe Blog',
        email  => 'joeblog@example.com',
        postid => 'some-post',
        comment => 'some random comment'
    );
    $c1->spam;
    ok($c1->is_spam && !$c1->is_ham && !$c1->is_moderated, "Comment marked as spam have correct flags");
    $c1->ham;
    ok(!$c1->is_spam && $c1->is_ham && !$c1->is_moderated, "Comment marked as ham have correct flags");
    $c1->moderate;
    ok(!$c1->is_spam && !$c1->is_ham && $c1->is_moderated, "Comment marked as moderated have correct flags");
};




    done_testing()
