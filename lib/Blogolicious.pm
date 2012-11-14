package Blogolicious;
use Mojo::Base 'Mojolicious';

use YAML::XS;
use File::Slurp qw(read_file);


# This method will run once at server start
sub startup {
    my $self = shift;
    my $cfg = read_file('cfg/config.yaml');
    $cfg = Load($cfg) or die;
    print "\n----- started: " . scalar localtime(time()) . "----\n";
    print "Config:\n" . Dump($cfg);
    $self->plugin(
        tt_renderer => {
            template_options => {
                INCLUDE_PATH => $cfg->{'repo_dir'},
                COMPILE_DIR => $cfg->{'tmp_dir'} . '/tt_cache',
                COMPILE_EXT => '.ttc',
                CACHE_SIZE =>0, # 0 means no cache
            }
        }
    );

    $self->renderer->default_handler('tt');
    # Documentation browser under "/perldoc"
    $self->plugin('PODRenderer');

    # Router
    my $r = $self->routes;

    # Normal route to controller
#    $r->get('/')->to('example#welcome');
    $r->get(
       '/' => sub {
           my $self = shift;
           $self->render(template=>'index');
       });
}
1;
