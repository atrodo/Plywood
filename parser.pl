use v5.28;

use Data::Dumper;
use List::Util qw/uniq/;
my $gmr = do './gmr2.pl';

my %lut;
my %tokens;
my $ws_trim = delete $gmr->{'$ws_trim'};

sub add_token
{
  my $symname = shift;
  my $rule    = shift;
  my $code    = shift;

  if ( exists $tokens{$symname} )
  {
    die "Duplicate token: $symname: $rule ne $tokens{$symname}"
        if $rule ne $tokens{$symname};
    return;
  }
  $tokens{$symname} = $rule;

  die qq{Duplicate rule "$symname"}
      if exists $lut{$symname};
  $lut{$symname} = [ { qr => $rule, sym => $symname } ];
}

foreach my $symname ( keys %$gmr )
{
  my @rules;
  my $sym = $gmr->{$symname};
  if ( $sym->{rules}->$#* == 0 && ref $sym->{rules}->[0] eq 'Regexp' )
  {
    add_token( $symname, $sym->{rules}->[0] );
    next;
  }
  foreach my $rule ( $sym->{rules}->@* )
  {
    my @atoms;
    my $rulestr = $rule->{rule};
    my $prec    = '';
    $rulestr =~ s/[{]prec (.*)[}]//;
    if ($1)
    {
      $prec = $1;
    }

    foreach my $token ( split /\s+/, $rulestr )
    {
      if ( $token =~ m/<(\w+)>/xms )
      {
        push @atoms, $1;
      }
      else
      {
        my $qr = qr/\Q$token/;
        push @atoms, $token;
        add_token( $token, $qr, $rule->{code} );
      }
    }
    my $result = { atoms => \@atoms, sym => $symname, prec => $prec,
      code => $rule->{code} };
    if ( ref $atoms[0] eq 'Regexp' )
    {
      $result->{qr} = $atoms[0];
    }
    push @rules, $result;
  }
  $lut{$symname} = \@rules;
}

my @nonterm;
my @term;
my %symnonterms;
my %symterms;
foreach my $sym ( keys %lut )
{
  foreach my $rule ( $lut{$sym}->@* )
  {
    if ( exists $rule->{qr} )
    {
      push @term, $rule;
    }
    else
    {
      push @nonterm, $rule;
    }
  }
}
@term    = uniq @term;
@nonterm = uniq @nonterm;

# Given a symbol, what are all of its terminals
foreach my $rule (@term)
{
  $symterms{ $rule->{sym} } = 1;
}
foreach my $rule (@nonterm)
{
  my $atom0 = $rule->{atoms}->[0];
  warn $atom0;
  next
      if $atom0 eq $rule->{sym};

  if ( $symterms{$atom0} )
  {
    push $symnonterms{ $rule->{sym} }->@*, $atom0;
  }
}

FINDNONTERM:
foreach (0)
{
  warn Data::Dumper::Dumper( \%symnonterms );
  foreach my $sym ( keys %symnonterms )
  {
    my @result   = $symnonterms{$sym}->@*;
    my $keycount = scalar @result;
    foreach my $atom0 ( $symnonterms{$sym}->@* )
    {
      next
          if $sym eq $atom0;
      if ( exists $symnonterms{$atom0} )
      {
        push @result, $symnonterms{$atom0}->@*;
      }
    }
    $symnonterms{$sym} = [ uniq @result ];
    if ( $keycount != scalar $symnonterms{$sym}->@* )
    {
      redo FINDNONTERM;
    }
  }
}

foreach my $sym ( keys %symnonterms )
{
  $symnonterms{$sym} = { map { $_ => 1 } $symnonterms{$sym}->@* };
}

my $src = do { local $/; <> };
my @stack;
my @result;
pos $src = 0;
PARSE:
while (1)
{
  warn pos $src;
  $ws_trim->( \$src );
  my $pos = pos $src;
  warn Data::Dumper::Dumper( $pos, \@stack );
  if ( @stack == 1 && $stack[0] eq 'grammar' )
  {
    die "finalized with more data"
        if $pos ne length $src;
    last;
  }
  if ( !defined $pos )
  {
    die "Bad parsing";
  }
TERM:
  {
    my $matched;
RULE:
    foreach my $rule (@term)
    {
      pos($src) = $pos;
      my $qr = $rule->{qr};
      if ( $src =~ m/\G($qr)/g )
      {
        warn "$qr => $1";
        unshift @stack, $rule->{sym};
        $matched = 1;
        push @result, $rule->{code};
        last RULE;
      }
    }
    die "no matches"
        if !$matched;
  }
  warn Data::Dumper::Dumper( \@stack );
NONTERM:
  {
    my $pos = pos $src;
RULE:
    foreach my $rule (@nonterm)
    {
      pos($src) = $pos;
      my @atoms   = $rule->{atoms}->@*;
      my $sym     = $rule->{sym};
      my $matched = 1;
      $DB::single = 1 if $atoms[0] eq '-';
      foreach my $i ( keys @atoms )
      {
        my $atom     = $atoms[$i];
        my $stacksym = $stack[ $#atoms - $i ];
        next
            if $atom eq $stacksym;

        #next
        #  if $symnonterms{$sym}->{$stacksym};
        undef $matched;
        last;
      }
      next RULE
          if !$matched;
      my @rm = splice @stack, 0, scalar @atoms, ($sym);
      warn qq{Matched $sym on "@rm"};
      warn Data::Dumper::Dumper( \@stack );
      push @result, $rule->{code};

      #warn Data::Dumper::Dumper($rule);
      redo NONTERM;
    }
  }

  #warn Data::Dumper::Dumper(\@stack);
  state $i= 0;
  last PARSE if $i++ == 25;
}
die Data::Dumper::Dumper( \@stack, \@result );

#die Data::Dumper::Dumper(\%lut, \@term, \@nonterm);
1;
