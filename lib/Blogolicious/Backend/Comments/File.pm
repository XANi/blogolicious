package Blogolicious::Backend::Comments::File;
use common::sense;

use YAML::XS;
use File::Slurp qw(read_file);
use File::Path qw(make_path);
use Carp qw(croak carp);
use URI::Escape;
use DateTime;
use Digest::MD5 qw(md5_hex);

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
}

sub add {
    my $self = shift;
    my $post = shift;
    my $data = shift;
    if (!defined( $post ) || $post =~ /^\s*$/) {
        croak("passed post name is invalid or empty");
    }
    my $dir = $self->{'config'}{'dir'} . '/' . $post;
    my $post_name = $self->_mkname($data);
    if (! -d $dir) {
        make_path($dir) or croak ('Can\'t create dir for post');
    }
    if( -e $dir . '/' . $post_name) {
        croak("post in a given second with same author already exists, wtf ?");
    }
    open(my $fh, '>', $dir . '/' . $post_name);
    print $fh Dump($data);
    close($fh);
    return 1;
}

sub load_and_parse {
    my $self = shift;
    my $file = shift;
    my $raw = read_file($file);
    my $comment = Load($raw);
    if(defined($comment->{'email'})) {
        $comment->{'gravatar'} = md5_hex($comment->{'email'});
    }
    return $comment;
};

sub get_comments {
    my $self = shift;
    my $post = shift;
    my $path = $self->{'config'}{'dir'} . '/' . $post;
    if (! -d $path) {
        return [];
    }
    opendir (my $comments_dir, $path);
    my @files = grep(/^\d{4}-\d{2}-\d{2}/ ,readdir($comments_dir));
    my $comments = {};
    foreach my $filename (@files) {
        $comments->{$filename} = $self->load_and_parse($path . '/' . $filename);
    }
    my $sorted_comments = [ sort keys(%$comments) ];
    foreach (@$sorted_comments) {
        $_ = $comments->{$_};
    }
    return $sorted_comments;
}

sub _mkname {
    my $self = shift;
    my $comment = shift;
    my $d = DateTime->now();
    return $d->ymd . '_' . $d->hms('-') . uri_escape($comment->{'author'});
}

1;
