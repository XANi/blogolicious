package Blogolicious::Blogpost;
use common::sense;

use Mojo::Base 'Mojolicious::Controller';

use Text::Markdown::Discount qw(markdown);
use YAML::XS;
use File::Slurp qw(read_file);
use Carp qw(cluck croak);
use Data::Dumper;
use Digest::MD5;

our $validate = {
    author => qr/^[0-9a-zA-Z\-_\ ]+$/,
    email => qr/^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$/i,
    postid => qr/^[0-9a-zA-Z\-_]+$/i,
    comment => qr/.*/i,
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
    my ( $post, $content) = $self->app->{'backend'}{'posts'}->parse($f,filename => $self->param('blogpost'));
    if(!defined($post)) {
        $self->render(template => 'error/post_error', status => 404);
        return;
    }
    my $comments = $self->app->{'backend'}{'comments'}->get_comments($post->{'id'});
    $self->stash(
        title    => $post->{'title'},
        author   => $post->{'author'},
        blog     => $self->app->{'cache'},
        post     => $post,
        content  => $content,
        comments => $comments,
    );
    $self->render(template=>'blogpost');
};

sub new_comment {
    my $self = shift;
    foreach my $field (qw( author email postid comment) ) {
        if (!defined $self->param($field)) {
            $self->render( json => {'error'=> "Required field $field missing"});
            return;
        }
        if ( $self->param($field) !~ $validate->{$field} ) {
            $self->render( json => {'error'=> "Validation of $field failed"});
            return;
        }
    }
    my $t = DateTime->now;
    my $new_comment = $self->app->{'backend'}{'comments'}->add(
        $self->param('postid'),
        {
            author  => $self->param('author'),
            post    => $self->param('postid'),
            email   => lc($self->param('email')),
            date    => $t->datetime,
            url     => $self->param('url'),
            content => $self->param('comment'),
        }
    );
    if ($new_comment) {
        $self->render(
            json => {'msg' => "Comment added!"},
            text => "Comment added!"
        );
    }
    else {
        $self->render(
            json => {'error' => "Adding comment failed"},
            text => "Adding comment failed!",
        );
    }
};


1;
