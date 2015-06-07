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
    url     => qr/http.*/i,
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
    # required fields
    foreach my $field (qw( author email postid comment) ) {
        if (!defined $self->param($field)) {
            $self->render( json => {'error'=> "Required field $field missing"}, status => 500);
            return;
        }
    }
    # used fields
    foreach my $field (qw( author email postid comment url) ) {
        if ( defined( $self->param($field) ) && $self->param($field) !~ $validate->{$field} ) {
            $self->render( json => {'error'=> "Validation of $field failed"}, status => 500);
            return;
        }
    }
    if (! $self->app->{'backend'}{'posts'}->exists($self->param('postid')) ) {
        $self->render( json => {'error'=> "no post with that name exists"}, status => 500);
    }
    my $t = DateTime->now;
    my $needs_moderation=0;
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
    # TODO move common stuff to some some common object
    $self->app->sessions->default_expiration(86400 * 60);
    $self->session->{'author'} = $self->param('author');
    $self->session->{'email'}  = $self->param('email');
    $self->session->{'url'}    = $self->param('url');

    if ($new_comment && !$needs_moderation) {
        $self->render(
            json => json => {
                msg    => "Comment added!",
                status => 0
            },
            text => "Comment added!"
        );
    }
    elsif ($needs_moderation) {
        $self->render(
            json => json =>{
                'msg' => "Comment waiting for moderation.",
                'status' => 1,
            },
            text => "Comment waiting for moderation",
        );
    }
    else {
        $self->render(
            json => json =>{'error' => "Adding comment failed"},
            text => "Adding comment failed!",
        );
    }
};


1;
