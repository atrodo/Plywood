package Plywood::Parser;

use v5.28;
use warnings;

use Data::Dumper;
use Carp;
use List::Util qw/uniq max any/;
my $gmr = require Plywood::Gmrs::p5;

my %lut;
my %tokens;
my $ws_trim = delete $gmr->{'$ws_trim'};
my $begin = delete $gmr->{'$BEGIN'};
my $end = delete $gmr->{'$END'};

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

sub gen_code
{
  my $symname = shift;
  my $code = shift;
  if ( ref $code eq '' )
  {
    if ( $code )
    {
      $code = sub { warn "Using default code for non-empty code sym: $symname"; $_[0] . ' - DEFUALT'; }
    }
    else
    {
      $code = sub {$_[0]};
    }
  }
  if ( ref $code ne 'CODE' )
  {
    die "Illegal code block: " . ref $code;
  }
  return $code;
}

foreach my $symname ( keys %$gmr )
{
  my @rules;
  my $sym = $gmr->{$symname};
  if ( $sym->{rules}->$#* == 0 )
  {
    if ( ref $sym->{rules}->[0] eq 'Regexp' )
    {
      add_token( $symname, $sym->{rules}->[0] );
      next;
    }
    if ( ref $sym->{rules}->[0] eq 'CODE' )
    {
      add_token( $symname, $sym->{rules}->[0] );
      next;
    }
  }
  foreach my $rule ( $sym->{rules}->@* )
  {
    if ( ref $rule eq 'Regexp' || ref $rule eq 'CODE' )
    {
      push @rules, { qr => $rule, sym => $symname, code => sub {$_[0]} };
      next;
    }
    next if ref $rule eq '';
    my @atoms;
    die ref $rule if ref $rule ne 'HASH';
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

    if ( $rulestr eq '' )
    {
      add_token( 'EMPTY', qr// );
      push @atoms, 'EMPTY';
    }

    my $code = gen_code($symname, $rule->{code});
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
      warn "Found rule for $sym that includes no atoms"
        if $rule->{atoms}->$#* == -1;
      push @nonterm, $rule;
    }
  }
}
@term    = sort { $a->{sym} cmp $b->{sym} } uniq @term;
@nonterm = sort { $a->{sym} cmp $b->{sym} } uniq @nonterm;

sub _same_check
{
  my $old = shift;
  my $new = shift;

  return
    if ref $old ne ref $new;
  if ( ref $old eq '' )
  {
    return $old eq $new
  }
  return
    if ref $old ne 'ARRAY';
  return
    if $old->$#* != $new->$#*;
  foreach my $i ( keys @$old )
  {
    return
      if $old->[$i] ne $new->[$i];
  }
  return 1;
}

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
    # Bypass the current symbol if it's the very first parent
    shift @parents
      if @parents && $parents[0] eq $rulesym;
    $chkd{$sym} = 1;
    foreach my $larule ( $lut{$sym}->@* )
    {
      if ( !defined $larule->{atoms} )
      {
        my $la = @parents == 0 ? $sym : \@parents;
        if ( $lookahead{$sym} && !_same_check( $lookahead{$sym}, $la ) )
        {
          $DB::single = 1;
          die 'asdf';
        }
        #$lookahead{$sym} = $rule->{is_term} ? $sym : \@parents;
        $lookahead{$sym} = $la;
        next;
      }
      next if !defined $larule->{atoms}->[0];
      push @to_check, [$larule->{atoms}->[0], @parents, $sym];
    }
  }
  $rule->{lookahead} = \%lookahead;
}
#die Data::Dumper::Dumper(\%lut);

#die Data::Dumper::Dumper(\@term, \@nonterm);


sub can_w_lookahead
{
  my $lasym = shift;
  my $sym = shift;
  return any { $_->{lookahead}->{$lasym} } $lut{$sym}->@*;
}

sub lookahead
{
  my $src = shift;
  my $rules = shift;
  my $rule_idx = shift;

  if ( pos $$src == length $$src )
  {
    #return { la => undef, lasym => 'EOF', match => '' };
  }

  # Reset Zero-length matches logic
  pos($$src) = pos $$src;
  $ws_trim->( $src );

  my $pos = pos $$src;
  if ( !defined $pos )
  {
    die "Bad parsing";
  }

  my %avl_syms;
  foreach my $rule ( @$rules )
  {
    if ( $rule->{is_term} )
    {
      $avl_syms{$rule->{sym}} = 1;
      next;
    }
    my $atom = $rule->{atoms}->[$rule_idx];
    next
      if !defined $atom;
    foreach my $la_rule ( $lut{$atom}->@* )
    {
      if ( $la_rule->{is_term} )
      {
        $avl_syms{$la_rule->{sym}} = 1;
      }
      foreach ( keys $la_rule->{lookahead}->%* )
      {
        $avl_syms{$_} = 1;
      }
    }
  }
  warn Data::Dumper::Dumper(\%avl_syms);

  my @la;
LOOKAHEAD:
  {
    my $chk_qr = sub
    {
      my $qr = shift;
      pos($$src) = $pos;
      if ( ref $qr eq 'CODE' )
      {
        my $match = $qr->($src);
        if ( defined $match )
        {
          return $match;
        }
      }
      elsif ( ref $qr eq 'ARRAY' )
      {
        foreach my $sub_qr (@$qr)
        {
          pos($$src) = $pos;
          my $match = __SUB__->($sub_qr);
          if ( defined $match )
          {
            return $match;
          }
        }
      }
      else
      {
        if ( $$src =~ m/\G($qr)/g )
        {
          my $match = $1;
          return $match;
        }
      }
      return;
    };
RULE:
    foreach my $rule (@term)
    {
      my $sym = $rule->{sym};
      next
        unless $avl_syms{$sym};
      my $qr = $rule->{qr};
      my $match = $chk_qr->($qr);
          if ( defined $match )
          {
          warn "$sym => $match";
          #$lookahead = $rule;
          #pos $$src = $pos + length $match;
  push @la, { la => $rule, lasym => $rule->{sym}, match => $match };
          next RULE;
          }
    }
    #die "no matches"
    #    if !defined $lookahead;
  }
  warn Data::Dumper::Dumper(@la);
  if ( my @nonzero = grep { length $_->{match} gt 0 } @la )
  {
    @la = @nonzero;
  }
  $DB::single = 1 if @la > 1;
  die "Ambgious symbols" if @la > 1;
  my $lookahead = $la[0];
  if ( !defined $lookahead )
  {
    pos $$src = $pos;
    return;
  }
  pos $$src = $pos + length $lookahead->{match};
  return $lookahead;
  #return { la => $lookahead, lasym => $lookahead->{sym}, match => $match };
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
      push @stack, $reduction;
    }
  }

  # In cases when $lasym eq $sym and $lasym is a term while the rest of the
  # rules are nonterm, we're in an odd space where it happens to work out
  # because we've entered this state, but in fact, if we had started in this
  # space, we may not have actually gotten here

  my @rules = $lut{$sym}->@*;
  my $max_atoms = max( map { scalar $_->{atoms}->@* } @rules );

  Carp::cluck $sym;
  my $shift = sub
  {
    return
      if @rules == 0;
    return
      if !defined $lookahead;

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
    #$DB::single = 1;
    my $result = $rule->{code}->( map { $_->{match} } @stack );
    @stack = ({ lasym => $sym, match => $result, rule => join(' ', $rule->{atoms}->@*), ast => [map { { $_->%{qw/lasym match ast rule/} } } @stack] });
    @rules = grep { $_->{atoms}->[0] eq $sym } $lut{$sym}->@*;
    return 1;
  };

  my $trim_rules = sub
  {
    my @new_rules;
    my $i = scalar @stack;
    my $stkcnt = $i + defined $lookahead ? 1 : 0;
    RULE:
    foreach my $rule ( @rules )
    {
      my @atoms = $rule->{atoms}->@*;
      foreach my $n ( keys @atoms )
      {
        next
          if $n >= @stack;
        if ( $atoms[$n] ne $stack[$n]->{lasym} )
        {
          next RULE;
        }
      }
      if ( @atoms == $stkcnt )
      {
        push @new_rules, $rule;
        next;
      }

      next
        if !defined $lasym;

      my $atom = $rule->{atoms}->[$i];
      if ( $atom eq $lasym )
      {
        push @new_rules, $rule;
        next;
      }
      #my @atom_rules = $lut{$atom}->@*;
      #if ( 
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
    return @new_rules;
  };

  if ( defined $lookahead && @stack == 0 )
  {
    $lasym = $lookahead->{lasym};
    @rules = grep { $_->{atoms}->[0] eq $lasym } @rules;
    $shift->();
    $reduce->();
  }

  while ( scalar @stack < $max_atoms )
  {
    if (!defined $lookahead)
    {
      $lookahead = lookahead($src, \@rules, scalar @stack);
    }
    $lasym = $lookahead->{lasym}
      if defined $lookahead;

    warn Data::Dumper::Dumper(\@stack);

    @rules = $trim_rules->();

    if ( @rules == 0 && @stack == 0 )
    {
      @rules = grep { $_->{lookahead}->{$lasym} } $lut{$sym}->@*;
      if ( @rules > 0 )
      {
        my $ascend_sym = $rules[0]->{lookahead}->{$lasym};
        ($lookahead, $lasym, my $reduction) = bascend($ascend_sym, $lookahead, $src);
        push @stack, $reduction;
        redo;
      }
    }

    #die "Could not find reduction for $sym"
    #  if @rules == 0;
    last
      if @rules == 0;

  #$DB::single = 1;
    if ( @rules == 1 )
    {
      my $i = scalar @stack;
      #my $atom = $i == 0 ? $rules[0]->{lookahead}->{$lasym} : $rules[0]->{atoms}->[$i];
      #my $is_term = ref $atom ne '' ? 0 : $lut{$atom}->[0]->{is_term};
      #my $has_nonterm = ref $atom ne '' ? 0 : any { !$_->{is_term} } $lut{$atom}->@*;
      my $atom = $rules[0]->{atoms}->[$i];
      my $has_nonterm = any { !$_->{is_term} } $lut{$atom}->@*;
      if ( defined $atom && $has_nonterm )
      {
        #die Data::Dumper::Dumper( bascend($atom, $lookahead, $src) );
        if ( $i == 0 )
        {
          #$atom = $rules[0]->{lookahead}->{$lasym};
        }
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

  die Data::Dumper::Dumper($sym, $lookahead, \@stack);
  die "Could not reduce with multiple rules " . scalar @rules
    if @rules != 1;
  my $rule = $rules[0];
  my $result = $rule->{code}->( map { $_->{match} } @stack );
  return (\@stack, $lookahead, { lasym => $sym, match => $result });
}

sub parse
{
  my $class = shift;
  my $gmr = shift;
  my $src = shift;
  pos $src = 0;

  use B::Terse;
  $begin->() if $begin;
  my $result = bascend('grammar', undef, \$src);
  $end->() if $end;
  return $result->{match};
}

1;
