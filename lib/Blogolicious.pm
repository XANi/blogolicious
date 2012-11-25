package Blogolicious;
use Mojo::Base 'Mojolicious';
use EV;
use AnyEvent;
use YAML::XS;
use File::Slurp qw(read_file);
use Data::Dumper;
use Cwd;
use Module::Load;
use Carp qw(carp croak);

use Blogolicious::Blogpost;


our $VERSION = '0.01';

# This method will run once at server start
sub startup {
    my $self = shift;
    # TODO /dev/urandom!!!
    $self->secret(rand(1000000000000000));
    $self->plugin(PoweredBy => (name => "Blogolicious $VERSION"));
    my $cfg = read_file(getcwd . '/cfg/config.yaml') or croak($!);
    $cfg = Load($cfg) or croak($!);
    $self->app->config($cfg);
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
    # TODO move to plugin
    $self->{'backend'}{'content'} = sub {
        use Text::Markdown::Discount qw(markdown);
        markdown(shift);
    };
    my $post_backend = 'Blogolicious::Backend::Posts::' .  ucfirst($cfg->{'backends'}{'post'}{'module'} || 'File');
    load $post_backend;
    $self->{'backend'}{'posts'} = $post_backend->new(
        dir => $cfg->{'repo_dir'} . '/posts',
        renderer => $self->{'backend'}{'content'},
    );
    # TODO move refresher to backend module
    # TODO that should be triggered by inotify
    $self->{'events'}{'post_update'} = AnyEvent->timer (
        after    => 60,
        interval => 60,
        cb       => sub {
            print "Updating posts\n";
            $self->{'backend'}{'posts'}->update_post_list;
            $self->{'cache'}{'posts'} = $self->{'backend'}{'posts'}->get_sorted_post_list();
            $self->{'cache'}{'tags'} = $self->{'backend'}{'posts'}->get_tags();
            $self->{'cache'}{'categories'} = $self->{'backend'}{'posts'}->get_categories();

        },
    );

    # pre-generate cache, we want to have it anyway as post list is needed for main page
    $self->{'backend'}{'posts'}->update_post_list;
    $self->{'cache'}{'posts'} = $self->{'backend'}{'posts'}->get_sorted_post_list();
    $self->{'cache'}{'tags'} = $self->{'backend'}{'posts'}->get_tags();
    $self->{'cache'}{'categories'} = $self->{'backend'}{'posts'}->get_categories();
    #
    # Router
    my $r = $self->routes;
    $r->get(
        '/' => sub {
            my $self = shift;
            $self->stash(
                title => $self->app->config('title'),
                posts => $self->app->{'cache'}{'posts'},
                categories => $self->app->{'cache'}{'categories'},
                tags  => $self->app->{'cache'}{'tags'},
                error => $self->flash('error'),
            );
            $self->render(template=>'index');
        },
    );
    $r->get(
        '/blog/tag/*tag' => sub {
            my $self = shift;
            if( !defined($self->app->{'cache'}{'tags'}{ $self->param('tag') }) ) {
                $self->render_not_found;
            }
            $self->stash(
                title => $self->app->config('title'),
                posts => $self->app->{'cache'}{'tags'}{ $self->param('tag') }{'posts'},
                categories => $self->app->{'cache'}{'categories'},
                tags  => $self->app->{'cache'}{'tags'},
                error => $self->flash('error'),
            );
            $self->render(template=>'index');

        }
    );
    $r->get(
        '/blog/category/*category' => sub {
            my $self = shift;
            if( !defined($self->app->{'cache'}{'categories'}{ $self->param('category') }) ) {
                $self->render_not_found;
            }
            $self->stash(
                title => $self->app->config('title'),
                posts => $self->app->{'cache'}{'categories'}{ $self->param('category') }{'posts'},
                categories => $self->app->{'cache'}{'categories'},
                tags  => $self->app->{'cache'}{'tags'},
                error => $self->flash('error'),
            );
            $self->render(template=>'index');

        }
    );
    $r->get('/blog/post/*blogpost')
        ->to(controller => 'blogpost', action => 'get');
    $r->get('/blog/feed')
        ->to(controller => 'feed', action => 'atom');

}
1;
