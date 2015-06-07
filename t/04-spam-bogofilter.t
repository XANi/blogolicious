use lib 'lib';

use Test::More;
use Blogolicious::Plugin::Spam::Bogofilter;
my $s = Blogolicious::Plugin::Spam::Bogofilter->new(
    db_dir => 'tmp/.bogofilter_test',
    feedback => 0, # to not mess with test DB too much
);

my $spam = {
    headers => {
        user => "jspam",
    },
    data => "buy spam now! special offer",
};

my $ham = {
    headers => {
        user => "jham",
    },
    data => "this article is very ham, but did you consider just getting a bacon ?",
};
# feed our filter some spam and gam

$s->spam($spam);
$s->ham($ham);

ok( $s->rate($ham) < 0.3 ,"Hammed messages return ham");
ok( $s->rate($spam) > 0.7 ,"Spammed messages return spam");

done_testing();
