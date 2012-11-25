package Blogolicious::Feed;
use common::sense;

use Mojo::Base 'Mojolicious::Controller';

use Text::Markdown::Discount qw(markdown);
use XML::Feed;
use DateTime;
use List::Util qw(min max);

sub atom {
    my $self = shift;

    my $feed = XML::Feed->new('Atom');
    $feed->id($self->app->config->{'base_url'} . '/');
    $feed->title($self->app->config->{'title'});
    $feed->link($self->app->config->{'base_url'});
    $feed->self_link($self->app->config->{'base_url'} . '/blog/feed');
    # TODO should be defaulting to latest post!
    $feed->modified(DateTime->now);
    my $post_limit = min (
        scalar @{ $self->app->{'cache'}{'posts'} },
        $self->app->config->{'rss_item_count'} - 1 );
    my @posts =  @{ $self->app->{'cache'}{'posts'} }[0, ( $post_limit - 1 )];
    foreach my $post(@posts) {
        # TODO handle that when loading post, not in postprocessing
        my $post_date;
        if($post->{'date'} =~ /(\d{4})\-(\d{2})\-(\d{2})/) {
            $post_date = DateTime->new(
                year => $1,
                month => $2,
                day => $3,
            );
        }
        else {
            $post_date = DateTime->now();
        }
        my $entry = XML::Feed::Entry->new();
        $entry->id($self->app->config->{'base_url'} . '/blog/post/' . $post->{'filename'});
        $entry->link($self->app->config->{'base_url'} . '/blog/post/' . $post->{'filename'});
        $entry->title($post->{'title'});
        $entry->summary($post->{'summary'});
#        $entry->content("Foo");
        $entry->issued($post_date);
        $entry->modified($post_date);
        $entry->author($post->{'author'});
        $feed->add_entry($entry);
    }
    my $mime = ("Atom" eq $feed->format) ? "application/atom+xml" : "application/rss+xml";
    # TODO "proper" content type
    $self->render(text => $feed->as_xml);
};

1;
