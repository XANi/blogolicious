package {[
#          'libmojolicious-perl', should go from cpan
          'libfile-slurp-perl',
          'libtext-markdown-discount-perl',
          'libjson-xs-perl',
          'libyaml-libyaml-perl',
          'libtemplate-perl',

          ]:
              ensure => installed,
}



notify { 'please install Mojolicious::Plugin::TtRenderer (and Mojolicious itself) from cpanm':;}
