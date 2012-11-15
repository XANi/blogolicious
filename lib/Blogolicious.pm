package Blogolicious;
use Mojo::Base 'Mojolicious';
our $VERSION = '0.01';

use YAML::XS;
use File::Slurp qw(read_file);
use Data::Dumper;
use Mojolicious::Plugin::TtRenderer;
use Cwd;

# This method will run once at server start
sub startup {
    my $self = shift;

    # TODO /dev/urandom!!!
    $self->secret(rand(1000000000000000));
    $self->plugin(PoweredBy => (name => "Blogolicious $VERSION"));
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
                title     => 'Blog',
                posts     => \@posts,
                error     => $self->flash('error'),
            );
           $self->render(template=>'index');
       },
   );
    $r->get('/blog/*blogpost')
       ->to(controller => 'blogpost', action => 'get');
}

1;
