package {[
#          'libmojolicious-perl', should go from cpan
          'libfile-slurp-perl',
          'liburi-encode-perl',
          'libtext-markdown-discount-perl',
          'libjson-xs-perl',
          'libyaml-libyaml-perl',
          'libtemplate-perl',
          'libev-perl', # fastest ev backend
          'libxml-feed-perl',
          'libdigest-sha-perl',
          'libdatetime-format-iso8601-perl'

          ]:
              ensure => installed,
}


# ugly but good enougth
exec {'install-mojolicious-ttrenderer':
    command   => '/usr/bin/env cpan Mojolicious::Plugin::TtRenderer',
    unless    => '/usr/bin/env perl -e"use Mojolicious::Plugin::TtRenderer"',
    logoutput => true,
}

# just in case it isnt in required
exec {'install-mojolicious':
    command   => '/usr/bin/env cpan Mojolicious',
    unless    => '/usr/bin/env perl -e"use Mojolicious"',
    logoutput => true,
}




# notify { 'please install Mojolicious::Plugin::TtRenderer (and Mojolicious itself) from cpanm':;}
