package Plywood;

use v5.28;
our $VERSION = '0.01';

# ABSTRACT: turns baubles into trinkets

sub import
{
  #use feature 'say';
  #my $key = hint_keyword();
  $^H{'Plywood/enabled'} = 'p5';
  warn "import\n";
}

sub unimport
{
  #use feature 'say';
  $^H{'Plywood/enabled'} = 0;
  warn "unimport\n";
}
sub is_enabled { warn $^H{'Plywood/enabled'}; $^H{'Plywood/enabled'} };

require XSLoader;
XSLoader::load( 'Plywood', $VERSION );

use Plywood::Parser;
use Plywood::Gmrs::p5;

sub parse
{
  my ($buffer) = (@_);
  warn "parse\n";
  warn "######\n$buffer\n######\n";
  my $result = Plywood::Parser->parse($^H{'Plywood/enabled'}, $buffer);
  return $result;
}

1;
