package Plywood::Gmrs;
use v5.28;

use Exporter 'import';
our @EXPORT = qw(parse_begin parse_end op_convert_list newSTATEOP newSVOP block_end newPROG op_append_list block_start newATTRSUB init_named_cv op_append_elem);

require Plywood;

use B;
my %op_lut;
{
  my $i = 0;
  while ( my $name = B::ppname($i) )
  {
    $op_lut{$name} = $i;
    $i++;
  }
}
sub _type
{
  my $type = lc shift;
  my $itype = $op_lut{"pp_$type"};
  die "Could not find OP $type"
    if !defined $itype;
  return $itype;
}

*block_start = \&_block_start;
*block_end = \&_block_end;
*newPROG = \&_newPROG;
*newATTRSUB = \&_newATTRSUB;
*init_named_cv = \&_init_named_cv;

sub op_convert_list
{
  my $type = _type shift;
  my $flags = shift;
  my $op = shift;

  if ( ref $op eq '' )
  {
    $op = newSVOP('CONST', 0, "$op");
  }
  return _op_convert_list($type, $flags, $op);
}

sub op_append_list
{
  my $type = _type shift;
  my $first = shift;
  my $last = shift;

  return _op_append_list($type, $first, $last);
}

sub op_append_elem
{
  my $type = _type shift;
  my $first = shift;
  my $last = shift;

  if ( ref $first eq '' )
  {
    $first = newSVOP('CONST', 0, "$first");
  }

  if ( ref $last eq '' )
  {
    $last = newSVOP('CONST', 0, "$last");
  }

  return _op_append_list($type, $first, $last);
}

sub newSTATEOP
{
  my $flags = shift;
  my $label = shift;
  my $sv = shift;

  return _newSTATEOP($flags, $label, $sv);
}

sub newSVOP
{
  my $type = _type shift;
  my $flags = shift;
  my $sv = shift;
  return _newSVOP($type, $flags, $sv);
}

1;
