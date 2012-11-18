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
    return $self;
};


sub parse {
    my $self = shift;
    my $data = shift;
    my %opts = @_;
    my ($comment, $raw_meta, $body) = split(/---/,$data,3);
    my $meta;
    eval {
        $meta = Load($raw_meta);
    };
    # we want arrays to be arrays even if user specifies string
    if ( defined( $meta->{'tags'} ) && ref($meta->{'tags'}) ne 'ARRAY' ) {
        $meta->{'tags'} = [ $meta->{'tags'} ];
    }

    if ( defined( $opts{'filename'} ) ) {
        $meta->{'filename'} = $opts{'filename'};
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
    my $posts = shift;
    $posts ||= $self->get_post_list();
    my $sorted_postnames = [ reverse sort keys $posts ];
    foreach (@$sorted_postnames) {
        $_ = $posts->{$_};
    }
   return $sorted_postnames;
};

sub generate_tags {
    my $self = shift;
    my $posts = shift;
    my $tags = {};
    foreach my $post (@$posts) {
        if (! defined( $post->{'tags'} )
                || scalar @{ $post->{'tags'} } < 1) {
            next; # ignore tagless posts
        }
        foreach my $tag (@{ $post->{'tags'} }) {
            if (! defined($tags->{$tag}) ) {
                $tags->{$tag} = {
                    count => 0,
                    posts => [],
                }
            }
            $tags->{$tag}{'count'}++;
            push @{ $tags->{$tag}{'posts'} }, $post->{'filename'};
        }
    }
    return $tags;
};

;1
