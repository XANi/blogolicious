package Blogolicious::Backend::Posts::File;

use common::sense;

use YAML::XS;
use File::Slurp qw(read_file);
use Carp qw(croak carp);
sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless($self, $class);

    if (ref($_[0]) eq 'ARRAY') {
        $self->{'config'} = shift;
    }
    elsif (ref($_[0]) eq 'HASH') {
        $self->{'config'} = shift;
    }
    else {
        my %config = @_;
        $self->{'config'} = \%config;
    }
    if (!defined $self->{'config'}{'dir'}) {
        croak("You need to specify dir");
    }
    if (!defined( $self->{'config'}{'renderer'} ) ) {
        carp("Renderer not specified, will render as plaintext!");
        $self->{'config'}{'renderer'} = sub { return shift; };
    }
    # this is where summary ends
    $self->{'config'}{'summary_tag'} ||= '\n\s*-- more --';
    return $self;
};


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
        ($meta->{'summary'},$tmp) = split(/$self->{'config'}{'summary_tag'}/, $body,2);
        if (defined($tmp) && $tmp !~ /^\s*$/) {
            $meta->{'has_more'} = 1;
        }
        $body = $meta->{'summary'} . $tmp;
        $body = &{ $self->{'config'}{'renderer'} }($body);
        $meta->{'summary'} = &{ $self->{'config'}{'renderer'} }($meta->{'summary'});
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
        ($meta->{'date'}) = $opts{'filename'} =~ m/(\d{4}\-\d{2}\-\d{2})/;
    }
    return ($meta, $body);
};

sub load_and_parse {
    my $self = shift;
    my $filename = shift;
    my %opts = @_;
    my $path =  $self->{'config'}{'dir'};
    my $file = read_file($path . '/'. $filename);
    my ($meta, $body) = $self->parse($file, meta_only => 1, filename => $filename);
    return ($meta, $body);
};

sub get_post_list {
    my $self = shift;
    my $posts = {};
    my $path = $self->{'config'}{'dir'};
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
    my $sorted_postnames = [ reverse sort keys $posts ];
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
