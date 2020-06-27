#!/usr/bin/env perl

use v5.18;

my %tokens;
my @order;

my $rule_re = qr<
  ( (?:[^{] | '{ | {')*? )
  \s*
  (/[*] .*? [*]/)?
  \s*
  (?: { (.*) } )?
  \s*
  ;?
  \s*
  $
  >xms;

while (<>)
{
  chomp;
  if (m/%start \s grammar/xms .. m/^%%/xms)
  {
    if (m/^%(token | type | nonassoc | left | right)/xms)
    {
      my $type = $1;
      my @syms = split;

      shift @syms;
      shift @syms
        if $syms[0] =~ m/<\w+>/xms;
      
      foreach my $sym (@syms)
      {
        my $re = $sym;
        $re =~ s/^'(.*)'$/$1/g;
        $re =~ s/([\*+?.()[\]{}$ ])/[$1]/xmsg;
        $re =~ s/(\^)/\$1/xmsg;

        $tokens{$sym} = { type => $type, sym => $sym, rules => [qr/$re/i], };
        push @order, $sym;
      }
    }
  }

  if (my $seq = m/^\w+ \s* :/xms .. m!^(?: [/][*] | (?:\t|[ ]{0,8}); )!xms)
  {
    state $rule = '';
    if ($seq == 1)
    {
      #say $rule;
      $rule = '';
    }

    $rule .= "$_\n";

    if ($seq =~ m/E0$/xms)
    {
      my ($sym, $rules) = $rule =~ m/^(\w+) \s* : (.*)/xms;
      my $token = { type => 'nonterm', sym => $sym };
      $tokens{$sym} = $token;
      push @order, $sym;

      #map { my %a = ( line => $_ ); @a{qw/raw_rule comment code/} = $_ =~ m/ $rule_re /xms; \%a }
      
      my @rules =
        map { { line => $_, raw_rule => '', comment => '', code => '', } }
        map { $_ =~ s/\s+/ /xmsg; $_ }
        map { $_ =~ s/; \s* $//xmsg; $_ }
        split(m/^(?:\t|\s{0,8})[|]/xms, $rules);

      foreach my $rule ( @rules )
      {
        my @stack;
        my @line = split //, $rule->{line};
        for (my $i; $i < $#line; $i++)
        {
          my $chr = $line[$i];

          if ( @stack )
          {
            if ( $stack[0] eq 'comment')
            {
              $rule->{comment} .= $chr;
              if ( $chr eq '*' && $line[$i+1] eq '/')
              {
                $rule->{comment} .= '/';
                $i++;
                shift @stack;
              }
              next;
            }

            if ( $stack[0] eq 'code')
            {
              $rule->{code} .= $chr;
              if ($chr eq q[\\])
              {
                $rule->{code} .= $line[$i+1];
                $i++;
                next;
              }

              if ($chr eq '/' && $line[$i+1] eq '*')
              {
                unshift @stack, 'comment';
                $rule->{comment} .= '/*';
                $i++;
                next;
              }

              if ( @stack == 1 && $chr eq '}')
              {
                $rule->{code} .= ' ';
                pop @stack;
              }
              elsif ( $stack[-1] eq $chr )
              {
                pop @stack;
              }
              elsif ( $chr eq q['] )
              {
                push @stack, q['];
              }
              elsif ( $chr eq q["] )
              {
                push @stack, q["];
              }
              elsif ( $chr eq q[{] )
              {
                push @stack, q[}];
              }
              next;
            }

            if ( $stack[0] eq 'rule')
            {
              if ($chr eq q[\\])
              {
                $rule->{raw_rule} .= $line[$i+1];
                $i++;
                next;
              }

              if ( $stack[-1] eq $chr )
              {
                pop @stack;
              }

              if ( @stack == 1 )
              {
                pop @stack;
                next;
              }

              $rule->{raw_rule} .= $chr;
              next;
            }
          }

          if ($chr eq '/' && $line[$i+1] eq '*')
          {
            push @stack, 'comment';
            $rule->{comment} .= '/*';
            $i++;
            next;
          }

          if ($chr eq q['] )
          {
            push @stack, 'rule';
            push @stack, q['];
            next;
          }

          if ($chr eq '{' )
          {
            push @stack, 'code';
            $rule->{code} .= '{';
            next;
          }

          $rule->{raw_rule} .= $chr;
        }

        my @terms = split m/\s+/, $rule->{raw_rule};
        #warn Dumper(\@terms);
        my $result = [];

        while (@terms)
        {
          my $term = shift @terms;

          if ($term eq '')
          {
          }
          elsif ($term =~ m/^% prec $/xms)
          {
            push @$result, "{prec " . shift(@terms) . "}";
          }
          elsif ( $term =~ m/(['"])(.*)\1/xms)
          {
            push @$result, $2;
          }
          elsif (exists $tokens{$term})
          {
            push @$result, "<$term>";
          }
          else
          {
            push @$result, "$term";
          }
        }
        $rule->{rule} = join(" ", @$result);
      }

      #say Dumper(\@rules);
      #say $rules;
      $token->{rules} = [ @rules ];
    }
  }
};

use Data::Dumper;
#warn Dumper(@order);

say 'my $grammar = {';
my %seen;
foreach my $sym (@order)
{
  next
    if $seen{$sym};
  $seen{$sym} = 1;

  local $Data::Dumper::Indent = 1;
  #local $Data::Dumper::Varname = $sym;
  local $Data::Dumper::Sortkeys = 1;

  my $re = $sym;
  $re =~ s/^'(.*)'$/$1/g;
  $re =~ s/([\^*+?.()[\]{}$ ])/[$1]/xmsg;
  my $token = $tokens{$sym};
  my @rules = ( "qr/$re/i" );

  @rules = @{ $token->{rules} }
    if defined $token->{rules};

  my $dump = Dumper($token);
  $dump =~ s[[*]/][\\*\\/]xmsg;
  #$dump =~ s/^/#    /xmsg;
  $dump =~ s/\A\$VAR1\s=\s{/ {/xms;
  $dump =~ s/;\Z/,/xms;
  #$dump =~ s[\A][\n=c\n]xms;
  #$dump =~ s[\Z][\n=cut\n]xms;

  #say $dump;
  #say sprintf(qq[  %-16s => \[], qq["$sym"]);
  $sym =~ s/^'|'$//g;
  say qq['$sym' => $dump\n];

  foreach my $rule ( @rules )
  {
    #say qq[\t\t       ] . (ref $rule ? qq['$rule->{rule}'] : $rule) . qq[,];
  }

  #say "\t\t     ],";
}

say "};";
#say "\nmodule.exports = grammar";
