package Blogolicious;
use Mojo::Base 'Mojolicious';
use EV;
use AnyEvent;
use YAML::XS;
use File::Slurp qw(read_file);
use File::Path qw (mkpath);
use Data::Dumper;
use Cwd;
use Module::Load;
use Carp qw(carp croak);
use List::Util qw(max min);

our $VERSION = '0.02';

# This method will run once at server start
sub startup {
    my $self = shift;
    $self->plugin(PoweredBy => (name => "Blogolicious $VERSION"));
    my $cfg;
    if ( -e $self->home->rel_file('cfg/config.yaml') ) {
        $cfg = read_file($self->home->rel_file('cfg/config.yaml')) || croak($!);
    } else {
        print STDERR "####################\n";
        print STDERR "WARNING! Running on default config!\n";
        print STDERR "please go to cfg/ and cp config.default.yaml to config.yaml!\n";
        print STDERR "####################\n";

        $cfg = read_file($self->home->rel_file('cfg/config.default.yaml')) || croak($!);
    }
    $cfg = Load($cfg) or croak($!);

    # TODO /dev/urandom!!!
    $self->secret( $cfg->{'secret'} || rand(1000000000000000) );

    # make relative paths absolute
    my $homedir = quotemeta($self->home);
    for (
        $cfg->{'tmp_dir'},
        $cfg->{'repo_dir'},
    ) {
        s{^/}{$homedir};
    }

    # defaults
    $cfg->{'posts_per_page'} ||= 10;

    $self->app->config($cfg);
    print STDERR "\n----- started: " . scalar localtime(time()) . "----\n";
    print STDERR "Config:\n" . Dump($self->app->config);
    #defaults
    $cfg->{'debug'} ||= 0;
    if ($cfg->{'debug'}) {
        $self->defaults(debug => 1);
    }

    $self->plugin(
        tt_renderer => {
            template_options => {
                INCLUDE_PATH => $cfg->{'repo_dir'},
                COMPILE_DIR => $cfg->{'tmp_dir'} . '/tt_cache',
                COMPILE_EXT => '.ttc',
                EVAL_PERL => 0,
                CACHE_SIZE =>0, # 0 means no cache
  #              STAT_TTL => 3600,
            }
        }
    );
    $self->renderer->default_handler('tt');
    $self->renderer->paths([$cfg->{'repo_dir'}]);

    # helpers
    $self->plugin('DefaultHelpers');

    # backends
    #
    # TODO move to plugin
    use Text::Markdown::Discount qw(markdown);
    $self->{'backend'}{'content'} = sub {
        markdown(shift);
    };
    my $posts_backend = 'Blogolicious::Backend::Posts::' .  ucfirst($cfg->{'backends'}{'posts'}{'module'} || 'File');
    load $posts_backend;
    $self->{'backend'}{'posts'} = $posts_backend->new(
        dir => $cfg->{'repo_dir'} . '/posts',
        renderer => $self->{'backend'}{'content'},
    );
    my $comments_backend = 'Blogolicious::Backend::Comments::' . ucfirst($cfg->{'backends'}{'comments'}{'module'} || 'File');
    load $comments_backend;
    $self->{'backend'}{'comments'} = $comments_backend->new(
        dir => $cfg->{'repo_dir'} . '/comments',
        renderer => $self->{'backend'}{'content'},
    );
    # TODO move refresher to backend module
    # TODO that should be triggered by inotify
    $self->{'events'}{'post_update'} = AnyEvent->timer (
        after    => 60,
        interval => 60,
        cb       => sub {
            print STDERR "Updating posts\n";
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
    $self->{'blogcache'} = $self->{'cache'};

    # define some stash values used by all or almost all routes
    $self->defaults(
        title => $self->config('title'),
        blog => $self->{'cache'},
        layout => $cfg->{'default_layout'} // 'main',
    );

    #
    # Router
    my $r = $self->routes;
    $r->get(
        '/' => sub {
            my $self = shift;
            my $has_older = 0;
            if ( $self->app->{'backend'}{'posts'}->get_posts_range($self->app->config('posts_per_page'), 1) ) {
                $has_older = 1;
            }
            $self->stash(
                title => $self->app->config('title'),
                posts => $self->app->{'backend'}{'posts'}->get_posts_range(0,10),
                error => $self->flash('error'),
                has_newer => 0,  # title page, nothing newer than this
                has_older => $has_older,
            );
            $self->render(template=>'index', layout => 'main');
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
                error => $self->flash('error'),
            );
            $self->render(template=>'index');

        }
    );
    $r->get(
        '/blog/page/*page' => sub {
            my $self = shift;
            my $start = int( $self->param('page')* $self->app->config('posts_per_page') );
            my $posts =  $self->app->{'backend'}{'posts'}->get_posts_range( $start, $self->app->config('posts_per_page') + 1);
            my $has_older = 0;
            my $has_newer = 0;
            if ( $self->param('page') > 0 ) {
                $has_newer = 1;
            }

            if ( int($self->param('page')) > 0) { $has_newer = 1}
            if (scalar @$posts > $self->app->config('posts_per_page')) {
                $has_older = 1;
                pop @$posts;
            }

            $self->stash(
                posts => $posts,
                has_older => $has_older,
                has_newer => $has_newer,
                error => $self->flash('error'),
            );
            $self->render(template=>'index');
        }
    );


#    $r->route('/blog/post/*blogpost', blogpost => qr/^[0-9a-zA-Z\-_]+$/)
    $r->route('/blog/post/*blogpost', blogpost => qr/[0-9a-zA-Z\-\_]+$/)
        ->to(controller => 'blogpost', action => 'get');
    $r->get('/blog/feed')
        ->to(controller => 'feed', action => 'atom', layout => undef);
    $r->post('/blog/comments/new')
        ->to(controller => 'blogpost', action => 'new_comment');
}

1;
