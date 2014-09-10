use lib 'lib';

use Test::More;
use Blogolicious::Plugin::Spam;
my $s = Blogolicious::Plugin::Spam->new(
    spam_threshold => 0.6,
    ham_threshold  => 0.4,
);

my $data = {
    headers => {
        user => 'dummy',
        ip   => '1.2.3.4',
    },
    data => "some message",
};
$s->add_plugin('Ham',{},1);
is( $s->rate($data), 0,"Ham plugins return ham");
$s->add_plugin('Spam',{},1);
is( $s->rate($data),1, "Ham and spam averaged to moderate");
$s->add_plugin('Spam',{},10);
is( $s->rate($data),2, "Spam with higher weight averaged to spam");
done_testing();
