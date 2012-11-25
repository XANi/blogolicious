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
    # placeholder for comment handling so we can at least test templates
    my $comments = [
        {
            author  => 'random hacker 1',
            date    => '2012-01-02',
            email   => 'some@e.mail',
            url     => 'http://poster.url',
            content => ' kjsdkas fiewhf er8hwer7h ddsfhsd',
        },
        {
            author  => 'random hacker 2',
            date    => '2012-01-03',
            email   => 'some@e.mail',
            url     => 'http://poster.url',
            content => ' kjsdkas fiewhf er8hwer7h ddsfhsd',
        },
        {
            author  => 'random hacker 3',
            date    => '2012-01-04',
            email   => 'some@e.mail',
            url     => 'http://poster.url',
            content => ' kjsdkas fiewhf er8hwer7h ddsfhsd',
        },
    ];

    $self->stash(
        title    => $post->{'title'},
        author   => $post->{'author'},
        tags     => $self->app->{'cache'}{'tags'},
        categories => $self->app->{'cache'}{'categories'},
        post     => $post,
        content  => $content,
        comments => $comments,
    );
    $self->render(template=>'blogpost');
};

1;
