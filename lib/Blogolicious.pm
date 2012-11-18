package Blogolicious;
use Mojo::Base 'Mojolicious';
use EV;
use AnyEvent;
use YAML::XS;
use File::Slurp qw(read_file);
use Data::Dumper;
use Cwd;
use Module::Load;

use Blogolicious::Blogpost;

our $VERSION = '0.01';

# This method will run once at server start
sub startup {
    my $self = shift;
    # TODO /dev/urandom!!!
    $self->secret(rand(1000000000000000));
    $self->plugin(PoweredBy => (name => "Blogolicious $VERSION"));
    $self->app->config(hypnotoad => {workers => 16});
    my $cfg =$self->plugin(
        'yaml_config' => {
            file      => getcwd . '/cfg/config.yaml',
            class     => 'YAML::XS'
    });
    print "\n----- started: " . scalar localtime(time()) . "----\n";
    print "Config:\n" . Dump($self->app->config);
    $self->plugin(
        tt_renderer => {
            template_options => {
                INCLUDE_PATH => $cfg->{'repo_dir'},
                COMPILE_DIR => $cfg->{'tmp_dir'} . '/tt_cache',
                COMPILE_EXT => '.ttc',
                 EVAL_PERL => 0,
                CACHE_SIZE =>0, # 0 means no cache
            }
        }
    );
    $self->renderer->default_handler('tt');
    $self->renderer->paths([$cfg->{'repo_dir'}]);
    # Documentation browser under "/perldoc"
    $self->plugin('PODRenderer');

    # helpers
    $self->plugin('DefaultHelpers');

    # backends
    #
    my $post_backend = 'Blogolicious::Backend::Posts::' .  ucfirst($cfg->{'backends'}{'post'}{'module'} || 'File');
    load $post_backend;
    $self->{'backend'}{'posts'} = $post_backend->new( dir => $cfg->{'repo_dir'} . '/posts');
    # TODO move to plugin
    $self->{'backend'}{'content'} = sub {
        use Text::Markdown::Discount qw(markdown);
        markdown(shift);
    };
    # TODO move refresher to backend module
    # TODO that should be triggered by inotify
    $self->{'events'}{'post_update'} = AnyEvent->timer (
        after    => 60,
        interval => 60,
        cb       => sub {
            print "Updating posts\n";
         #   $self->{'cache'}{'post_list'} = Blogolicious::Blogpost->get_sorted_post_list($self->app->config('repo_dir') . '/posts/');
          #  $self->{'cache'}{'tags'} = Blogolicious::Blogpost->generate_tags( $self->{'cache'}{'post_list'} );
        },
    );

    # pre-generate cache, we want to have it anyway as post list is needed for main page
    $self->{'cache'}{'post_list'} = $self->{'backend'}{'posts'}->get_sorted_post_list();
    $self->{'cache'}{'tags'} = $self->{'backend'}{'posts'}->generate_tags( $self->{'cache'}{'post_list'} );
    #
    # Router
    my $r = $self->routes;
    $r->get(
       '/' => sub {
           my $self = shift;
           opendir (my $posts_dir, $self->app->config('repo_dir') . '/posts/');
           my @posts = grep(/^\d{4}-\d{2}-\d{2}/ ,readdir($posts_dir));
           $self->stash(
               title => $self->app->config('title'),
               posts => $self->app->{'cache'}{'post_list'},
               tags  => $self->app->{'cache'}{'tags'},
               error => $self->flash('error'),
           );
           $self->render(template=>'index');
       },
   );
    $r->get('/blog/*blogpost')
       ->to(controller => 'blogpost', action => 'get');
}


1;
