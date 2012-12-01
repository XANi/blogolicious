package {[
#          'libmojolicious-perl', should go from cpan
          'libfile-slurp-perl',
          'libfile-path-perl',
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



notify { 'please install Mojolicious::Plugin::TtRenderer (and Mojolicious itself) from cpanm':;}
