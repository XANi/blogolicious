package Blogolicious::Blogpost;
use common::sense;

use Mojo::Base 'Mojolicious::Controller';

use Text::Markdown::Discount qw(markdown);
use YAML::XS;
use File::Slurp qw(read_file);

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
    my ( $post, $content) = $self->app->{'backend'}{'posts'}->parse($f,filename => $self->param('blogpost'));
    if(!defined($post)) {
        $self->render(template => 'error/post_error', status => 404);
        return;
    }
    $self->stash(
        title   => $post->{'title'},
        author  => $post->{'author'},
        tags    => $self->app->{'cache'}{'tags'},
        post    => $post,
        content => $content,
    );
    $self->render(template=>'blogpost');
};

1;
