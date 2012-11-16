package Blogolicious;
use Mojo::Base 'Mojolicious';
use YAML::XS;
use File::Slurp qw(read_file);
use Data::Dumper;
use Cwd;

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
    $self->plugin('xslate_renderer');
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

    # Router
    my $r = $self->routes;
    $r->get(
       '/' => sub {
           my $self = shift;
           opendir (my $posts_dir, $self->app->config('repo_dir') . '/posts/');
           my @posts = grep(/^\d{4}-\d{2}-\d{2}/ ,readdir($posts_dir));
            $self->stash(
                title     => $self->app->config('title'),
                posts     => Blogolicious::Blogpost->get_sorted_post_list($self->app->config('repo_dir') . '/posts/'),
                error     => $self->flash('error'),
            );
           $self->render(template=>'index');
       },
   );
    $r->get('/blog/*blogpost')
       ->to(controller => 'blogpost', action => 'get');
}

1;
