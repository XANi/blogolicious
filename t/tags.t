use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('Blogolicious');
$t->get_ok('/blog/tag/mojolicious','posts for tag')
    ->status_is(200,'posts for tag returns 200')
    ->content_like(qr/Lorem Ipsum is simply dummy text of the/i,'summary')
    ->content_like(qr/posted by testbot/i,'author');


done_testing();
