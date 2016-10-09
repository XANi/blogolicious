package Blogolicious::Backend::Posts::File;

use namespace::clean;
use Moo;

use common::sense;

use YAML::XS;
use File::Slurp qw(read_file);
use Carp qw(croak carp);
use List::Util qw(min max);
use Log::Any qw($log);
use Data::Dumper;

has 'dir' => (
    is => 'ro',
    isa => sub {
        if (!defined($_[0])) {
            croak("Need file dir!")
        }
    },
);

has 'renderer' => (
    is => 'ro',
    isa => sub {
        if (!defined($_[0])) {
            $log->warn("No renderer, will decode as plaintext!");
        }
    },
);

has 'summary_tag' => (
    is => 'ro',
    default => sub { '\n\s*-- more --' },
);

sub parse {
    my $self = shift;
    my $data = shift;
    my %opts = @_;
    my ($comment, $raw_meta, $body) = split(/(?:\n|^)---\n/,$data,3);
    my $meta = {};
    my $tmp;
    # TODO handle fail condition instead of ignoring
    eval {
        $meta = Load($raw_meta);
        my $summary_tag_re = $self->summary_tag;
        ($meta->{'summary'},$tmp) = split(/$summary_tag_re/, $body,2);
        if (defined($tmp) && $tmp !~ /^\s*$/) {
            $meta->{'has_more'} = 1;
        }
        $body = $meta->{'summary'} . $tmp;
        $body = &{ $self->renderer }($body);
        $meta->{'summary'} = &{ $self->renderer }($meta->{'summary'});
    };
    if ($@) { carp($@); }

    # we want arrays to be arrays even if user specifies string
    if ( defined( $meta->{'tag'} ) && ref($meta->{'tag'}) ne 'ARRAY' ) {
        $meta->{'tag'} = [ $meta->{'tag'} ];
    }
    if ( defined( $meta->{'category'} ) && ref($meta->{'category'}) ne 'ARRAY' ) {
        $meta->{'category'} = [ $meta->{'category'} ];
    }
    if ( defined( $opts{'filename'} ) ) {
        $meta->{'filename'} = $opts{'filename'};
        $meta->{'id'} = $meta->{'filename'};
        ($meta->{'date'}) = $opts{'filename'} =~ m/(\d{4}\-\d{2}\-\d{2})/; # FIXME save in parseable format like unixtime
    }
    return ($meta, $body);
};

sub load_and_parse {
    my $self = shift;
    my $filename = shift;
    my %opts = @_;
    my $path =  $self->dir;
    my $file = read_file($path . '/'. $filename);
    my ($meta, $body) = $self->parse($file, meta_only => 1, filename => $filename);
    return ($meta, $body);
};

sub get_post_list {
    my $self = shift;
    my $posts = {};
    my $path = $self->dir;
    opendir (my $posts_dir, $path);
    my @files = grep(/^\d{4}-\d{2}-\d{2}/ ,readdir($posts_dir));
    foreach my $filename (@files) {
        my ($meta, $body) = $self->load_and_parse($filename, meta_only => 1);
        $posts->{$filename} = $meta;
     }
    return $posts;
}

sub get_sorted_post_list {
    my $self = shift;
    if (!defined( $self->{'sorted_posts'} ) ) {
        $self->update_post_list();
    }
    return $self->{'sorted_posts'};
}

sub get_tags {
    my $self = shift;
    return $self->{'tag'};
}
sub get_categories {
    my $self = shift;
    return $self->{'category'};
}

sub _sort_post_list {
    my $self = shift;
    my $posts = shift;
    my $sorted_postnames = [ reverse sort keys(%$posts) ];
    foreach (@$sorted_postnames) {
        $_ = $posts->{$_};
    }
   return $sorted_postnames;
};

sub update_post_list {
    my $self = shift;
    $self->{'posts'} = $self->get_post_list;
    $self->{'sorted_posts'} = $self->_sort_post_list( $self->{'posts'} );
    $self->{'tag'} = {};
    $self->{'category'} = {};
    foreach my $post (@{$self->{'sorted_posts'}}) {
        if (defined( $post->{'tag'} )) {
            foreach my $tag ( @{ $post->{'tag'} } ) {
                push @{ $self->{'tag'}{$tag}{'posts'} }, $post;
                $self->{'tag'}{$tag}{'count'}++;
            }
        }
        if (defined( $post->{'category'} ) ) {
            foreach my $category ( @{ $post->{'category'} } ) {
                push @{ $self->{'category'}{$category}{'posts'} }, $post;
                $self->{'category'}{$category}{'count'}++;
            }
        }
    }
}

sub get_posts_range {
    my $self = shift;
    my $start = shift;
    my $count = shift;
    return $self->_get_range($start, $count, $self->{'sorted_posts'});
}

sub get_tag_range {
    my $self = shift;
    my $tag = shift;
    my $start = shift;
    my $count = shift;
    return $self->_get_range($start, $count, $self->{'tag'}{$tag});
}

sub get_category_range {
    my $self = shift;
    my $category = shift;
    my $start = shift;
    my $count = shift;
    return $self->_get_range($start, $count, $self->{'category'}{$category});
}

sub _get_range {
    my $self = shift;
    my $start = shift;
    my $count = shift;
    my $array = shift;
    if (! defined( $array->[0] ) ) {
        return;
    }
    my $last = min( scalar @{ $array }, ( $start + $count ));
    --$last;
    return [ @$array[ $start .. $last ] ];
}


sub exists {
    my $self = shift;
    my $id = shift;
    if (defined( $self->{'posts'}{$id})) {
        return 1
    }
    else {
        return;
    }
}

;1
