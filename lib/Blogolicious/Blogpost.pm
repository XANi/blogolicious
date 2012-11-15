package Blogolicious::Blogpost;
use common::sense;

use Mojo::Base 'Mojolicious::Controller';

use Text::Markdown::Discount qw(markdown);
use YAML::XS;
use File::Slurp qw(read_file);

sub parse {
    my $self = shift;
    my $data = shift;
    my %opts = @_;
    my ($comment, $raw_meta, $raw_body) = split(/---/,$data,3);
    my ($meta, $body);
    eval {
        $meta = Load($raw_meta);
        if ( ! defined($opts{'meta_only'}) ) {
            if (defined($raw_body)) {$body = markdown($raw_body)};
        }
    };
    return ($meta, $body);
    #    return (, 'n');
};

sub get {
    my $self = shift;

    my $filename = $self->app->config->{'repo_dir'} . '/posts/' . $self->param('blogpost');
    if ( $self->param('blogpost') !~ /^[0-9a-zA-Z\-_]+$/i) {
        $self->flash({'error' => 'Invalid URL char'});
        $self->redirect_to('/');
        return;
    }
    if ( ! -f $filename ) {
#        $self->render( template => 'error/404', status => 404, path => $self->param('blogpost'));
        $self->flash({'error' => '404 could not find content ' . $self->param('blogpost')});
        $self->redirect_to('/');
        return;
    }
    # TODO ASYNC IO!!!
    my $f = read_file($filename);
    my ( $meta, $post) = $self->parse($f);
    if(!defined($meta)) {
        $self->render(template => 'error/post_error', status => 404);
        return;
    }
    $self->stash(
        title     => $meta->{'title'},
        author    => $meta->{'author'},
        content   => $post,
    );
    $self->render(template=>'blogpost');
};

sub get_post_list {
    my $self = shift;
    my $path = shift;
    my $posts = {};
    opendir (my $posts_dir, $path);
    my @files = grep(/^\d{4}-\d{2}-\d{2}/ ,readdir($posts_dir));
    foreach my $filename (@files) {
         my $file = read_file($path .'/'. $filename);
        ($posts->{$file}) = $self->parse($file, meta_only => 1);
         $posts->{$file}{'filename'} = $filename;
         ($posts->{$file}{'date'}) = $filename =~ m/(\d{4}\-\d{2}\-\d{2})/;

     }
    return $posts;
}


sub get_sorted_post_list {
    my $self = shift;
    my $path = shift;
    my $posts = $self->get_post_list($path);

    my $sorted_postnames = [ reverse sort keys $posts ];
    foreach (@$sorted_postnames) {
        $_ = $posts->{$_};
    }
   return $sorted_postnames;
};
1;
