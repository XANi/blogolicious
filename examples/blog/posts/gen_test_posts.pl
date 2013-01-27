#!/usr/bin/perl
# generate test posts

use strict;
use warnings;
use YAML::XS;
use List::Util qw/shuffle/;
use Digest::SHA qw(sha1_hex);
use Data::Dumper;
my $text = q{**Lorem Ipsum** is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the _1500s_, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the _1960s_ with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like **Aldus PageMaker** including versions of Lorem Ipsum.};

my @tags = (
    'general',
    'linux',
    'debian',
    'Some Topic',
    'perl',
    'Mojolicious',
    'mojolicious',
);
my @categories = (
    'Articles',
    'Snippets',
    'Random stuff',
    'Tips',
    'Howtos',
    'HOWTOs',
);


for my $month(1..8) {
    for (1..7) {
        my $day = int(rand(28));
        my $body = &genpost;
        open(my $post, '>', '2012-' . sprintf("%02d",$month) . '-'. sprintf("%02d",$day) . '_' . sha1_hex($body));
        print $post $body;
        close $post;
    }
}


&genpost;
sub genpost {
    my $out = "test post from generator\n";
    my $tag_count = int(rand(@tags));
    my @tags = shuffle (@tags);
    @tags = @tags[1..$tag_count]; # so 2 post is also option
    my $cat_count =  int(rand(@categories));
    my @categories = shuffle ( @categories );
    @categories = @categories[1..$cat_count];
    my $post = {
        tag => \@tags,
        category => \@categories,
        title => 'Test blog post ' . int(rand(1000)) . " $cat_count categories and $tag_count tags",
        author => 'testbot',
    };
    $out .= Dump($post);
    $out .="\n---\n";
    $out .= "$text\n";
    return $out;
}

