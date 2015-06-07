use lib 'lib';
use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('Blogolicious');
$t->get_ok('/blog/tag/mojolicious','posts for tag')
    ->status_is(200,'posts for tag returns 200')
    ->content_like(qr/<strong>Lorem Ipsum<\/strong> is simply dummy text of the printing and typesetting industry/i,'summary')
    ->content_like(qr/testbot/i,'author');


done_testing();
