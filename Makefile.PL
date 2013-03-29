use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  VERSION   => '0.01',
  PREREQ_PM => {
      'AnyEvent'                 => 0,
      'EV'                       => 0,
      'File::Slurp'              => 0,
      'Module::Load'             => 0,
      'Mojolicious'              => '3.57',
      'Mojolicious::Plugin::TtRenderer' => 0,
      'Test::More'               => 0,
      'Text::Markdown::Discount' => 0,
      'URI::Encode'              => 0,
      'XML::Feed'                => 0,
      'YAML::XS'                 => 0,
      'common::sense'            => 0,
  },
  test      => {TESTS => 't/*.t'}
);
