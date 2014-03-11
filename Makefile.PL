use strict;
use warnings;

use ExtUtils::MakeMaker::CPANfile;
WriteMakefile(
  VERSION   => '0.02',
  AUTHOR    => 'Mariusz Gronczewski <xani666@gmail.com>',
  test      => {TESTS => 't/*.t'}
);
