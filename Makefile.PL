use strict;
use warnings;

use ExtUtils::MakeMaker::CPANfile;
WriteMakefile(
  VERSION_FROM      => "lib/Blogolicious.pm",
  AUTHOR    => 'Mariusz Gronczewski <xani666@gmail.com>',
  test      => {TESTS => 't/*.t'}
);
