use v5.28;

use Data::Dumper;
use Carp;
use List::Util qw/uniq max any/;
my $gmr = do './gmr2.pl';

my %lut;
my %tokens;
my $ws_trim = delete $gmr->{'$ws_trim'};

sub add_token
{
  my $symname = shift;
  my $rule    = shift;
  my $code    = shift // sub { $_[0] };

  if ( exists $tokens{$symname} )
  {
    die "Duplicate token: $symname: $rule ne $tokens{$symname}"
        if $rule ne $tokens{$symname};
    return;
  }
  $tokens{$symname} = $rule;

  die qq{Duplicate rule "$symname"}
      if exists $lut{$symname};
  $lut{$symname} = [ { qr => $rule, sym => $symname, code => $code } ];
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
        add_token( $token, $qr );
      }
    }
    my $code = $rule->{code};
    if ( ref $code eq '' )
    {
      $code = sub {@_};
    }
    if ( ref $code ne 'CODE' )
    {
      die "Illegal code block: " . ref $code;
    }
    my $result = {
      atoms => \@atoms, sym => $symname, prec => $prec,
      code  => $code
    };
    if ( ref $atoms[0] eq 'Regexp' )
    {
      $result->{qr} = $atoms[0];
    }
    push @rules, $result;
  }
  $lut{$symname} = \@rules;
}

#die Data::Dumper::Dumper(\%lut);

my @nonterm;
my @term;
foreach my $sym ( keys %lut )
{
  foreach my $rule ( $lut{$sym}->@* )
  {
    $rule->{is_term} = exists $rule->{qr};
    if ( $rule->{is_term} )
    {
      push @term, $rule;
    }
    else
    {
      push @nonterm, $rule;
    }
  }
}
@term    = sort { $a->{sym} cmp $b->{sym} } uniq @term;
@nonterm = sort { $a->{sym} cmp $b->{sym} } uniq @nonterm;

foreach my $rule (@nonterm)
{
  my $rulesym = $rule->{sym};
  my %lookahead;
  my @to_check = ([$rule->{atoms}->[0]]);
  my %chkd;
  while ( my $check = shift @to_check )
  {
    my ($sym, @parents) = $check->@*;
    next if $chkd{$sym};
    $chkd{$sym} = 1;
    foreach my $rule ( $lut{$sym}->@* )
    {
      if ( !defined $rule->{atoms} )
      {
        die 'asdf' if $lookahead{$sym};
        $lookahead{$sym} = \@parents;
        next;
      }
      next if !defined $rule->{atoms}->[0];
      push @to_check, [$rule->{atoms}->[0], @parents, $sym];
    }
  }
  $rule->{lookahead} = \%lookahead;
}
#die Data::Dumper::Dumper(\%lut);

#die Data::Dumper::Dumper(\@term, \@nonterm);

my $src = do { local $/; <> };
my @ascent = ( [ grep { $_->{sym} eq 'grammar' } @nonterm ] );
my @stack;
my @result;
pos $src = 0;

sub lookahead
{
  my $src = shift;

  if ( pos $$src == length $$src )
  {
    return { la => undef, lasym => 'EOF', match => '' };
  }
  $ws_trim->( $src );
  my $pos = pos $$src;
  if ( !defined $pos )
  {
    die "Bad parsing";
  }

  my $lookahead;
  my $match;
LOOKAHEAD:
  {
RULE:
    foreach my $rule (@term)
    {
      pos($$src) = $pos;
      my $qr = $rule->{qr};
      if ( $$src =~ m/\G($qr)/g )
      {
        $match = $1;
        warn "$qr => $match";

        #unshift @stack, $rule->{sym};
        #my $r = $rule->{code}->($match);
        #die Data::Dumper::Dumper( $r, $match )
        #    if $r ne $match;
        #unshift @result, $rule->{code}->($match);
        #$matched = 1;
        $lookahead = $rule;
        last RULE;
      }
    }
    die "no matches"
        if !defined $lookahead;
  }
  return { la => $lookahead, lasym => $lookahead->{sym}, match => $match };
}

sub reduce
{
  my @stack = @_;
}

sub can_w_lookahead
{
  my $lasym = shift;
  my $sym = shift;
  return any { $_->{lookahead}->{$lasym} } $lut{$sym}->@*;
}

sub bascend
{
  my ( $sym, $lookahead, $src ) = @_;
  #my $sym = shift;
  #my $lookahead = shift;
  #my $src = shift;

  my @stack;
  my $lasym;

  if ( ref $sym eq 'ARRAY' )
  {
    my @ascend_stack = @$sym;
    $sym = shift @ascend_stack;
    $_[0] = $sym;
    if ( @ascend_stack > 0 )
    {
      ($lookahead, $lasym, my $reduction) = bascend(\@ascend_stack, $lookahead, $src);
      $DB::single=1;
      push @stack, $reduction;
    }
  }

  $DB::single =1 if !defined $lut{$sym};
  my @rules = $lut{$sym}->@*;
  my $max_atoms = max( map { scalar $_->{atoms}->@* } @rules );

  Carp::cluck $sym;
  my $shift = sub
  {
    return
      if @rules == 0;

    my $la_atom;
    my $i = scalar @stack;
    foreach my $rule ( @rules )
    {
      my $atom = $rule->{atoms}->[$i];
      if ( !defined $la_atom )
      {
        $la_atom = $atom;
      }
      return
        if $la_atom ne $atom;
    }

    return
      if $lasym ne $la_atom;

    push @stack, $lookahead;
    undef $lookahead;
    undef $lasym;

    return 1;
  };

  my $reduce = sub
  {
    return
      if @rules != 1;

    my $rule = $rules[0];
    my @atoms   = $rule->{atoms}->@*;
    return
      if @atoms != @stack;
    foreach my $i ( keys @atoms )
    {
      die 'bad reduce'
        if $atoms[$i] ne $stack[$i]->{lasym};
    }
    my $result = $rule->{code}->( map { $_->{match} } @stack );
    @stack = { lasym => $sym, match => $result };
    @rules = grep { $_->{atoms}->[0] eq $sym } $lut{$sym}->@*;
    return 1;
  };

  if ( defined $lookahead && @stack == 0 )
  {
    $lasym = $lookahead->{lasym};
    #$DB::single = 1;
    @rules = grep { $_->{atoms}->[0] eq $lasym } @rules;
    $shift->();
    $reduce->();
  }

  while ( scalar @stack < $max_atoms )
  {
    if (!defined $lookahead)
    {
      $lookahead = lookahead($src);
    }
    $lasym = $lookahead->{lasym};

    my $i = scalar @stack;
    warn Data::Dumper::Dumper(\@stack);

    #die "Could not find reduction for $sym"
    #  if @rules == 0;
    last
      if @rules == 0;

    my @new_rules;
    RULE:
    foreach my $rule ( @rules )
    {
      my @atoms = $rule->{atoms}->@*;
      foreach my $n ( keys @atoms )
      {
        last
          if $n >= @stack;
        if ( $atoms[$n] ne $stack[$n]->{lasym} )
        {
          next RULE;
        }
      }
      if ( @atoms == @stack )
      {
        push @new_rules, $rule;
        next;
      }

      my $atom = $rule->{atoms}->[$i];
      if ( $atom eq $lasym )
      {
        push @new_rules, $rule;
        next;
      }
      if ( $i == 0 && $rule->{lookahead}->{$lasym} )
      {
        push @new_rules, $rule;
        next;
      }
      if ( can_w_lookahead($lasym, $atom) )
      {
        push @new_rules, $rule;
        next;
      }
    }
    @rules = @new_rules;

  #$DB::single = 1;
    if ( @rules == 1 )
    {
      my $atom = $i == 0 ? $rules[0]->{lookahead}->{$lasym} : $rules[0]->{atoms}->[$i];
      my $is_term = ref $atom ne '' ? 0 : $lut{$atom}->[0]->{is_term};
      if ( defined $atom && !$is_term )
      {
        #die Data::Dumper::Dumper( bascend($atom, $lookahead, $src) );
        ($lookahead, $lasym, my $reduction) = bascend($atom, $lookahead, $src);
        push @stack, $reduction;
      }
    }

    $shift->();
    $reduce->();
    #foreach my $rule ( @rules )
    #{
    #  my $tomatch = $rule->{atoms}->[$i];
    #  if ( $i == 0 )
    #  {
    #    $tomatch = $rule->{lookahead}->{$lasym};
    #  }
    #  if ( !defined $atom )
    #  {
    #    $atom = $tomatch;
    #  }
    #  if ( $atom ne $tomatch )
    #  {
    #    die 'fdsa';
    #  }
    #}
    #warn Data::Dumper::Dumper( $lookahead, \@rules, $atom);
    #die if $sym eq 'exp';
    #die Data::Dumper::Dumper( bascend($atom, $lookahead, $src) );
  }

  #$DB::single = 1;
  if ( @rules == 0 && @stack == 1 && $stack[0]->{lasym} eq $sym )
  {
    return ($lookahead, $lasym, $stack[0])
  }

  die;
  die "Could not reduce with multiple rules " . scalar @rules
    if @rules != 1;
  my $rule = $rules[0];
  my $result = $rule->{code}->( map { $_->{match} } @stack );
  return (\@stack, $lookahead, { lasym => $sym, match => $result });
}

die Data::Dumper::Dumper( bascend('grammar', undef, \$src) );

1;
