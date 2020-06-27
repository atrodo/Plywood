package Plywood;

use v5.28;
our $VERSION = '0.01';

# ABSTRACT: turns baubles into trinkets

sub import
{
  #use feature 'say';
  #my $key = hint_keyword();
  $^H{'Plywood/enabled'} = 1;
  warn "import\n";
}

sub unimport
{
  #use feature 'say';
  $^H{'Plywood/enabled'} = 0;
  warn "unimport\n";
}
sub is_enabled { warn $^H{'Plywood/enabled'}; $^H{'Plywood/enabled'} };

sub parse
{
  my ($buffer) = (@_);
  warn "parse\n";
  warn "######\n$buffer\n######\n";
}

require XSLoader;
XSLoader::load( 'Plywood', $VERSION );

1;
