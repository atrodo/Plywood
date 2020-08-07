package Plywood::Gmrs::p5;
use v5.28;
use Plywood::Gmrs;

sub scan_str
{
  my $src = shift;
  my $open = shift;
  my $close = $open;

  return
    if $open =~ m/\w/;

  my $inverts = "([{< )]}> )]}>";
  my $n = index $inverts, $open;
  if ($n != -1)
  {
    $close = substr $inverts, $n + 5, 1;
  }

  my $result = '';

  my @stack = ($close);
  my $lhs = pos $$src;
  my $i = ($lhs + length $open) - 1;
  while( @stack )
  {
    $i++;
    my $c = substr $$src, $i, 1;
    if ( $i > length $$src )
    {
      return;
    }

    if ( $c eq $open && $close != $open )
    {
      unshift @stack, $close;
      next;
    }
    if ($c eq $stack[0])
    {
      shift @stack;
      next;
    }
    if ($c eq '\\')
    {
      $i++;
    }
  }
  my $rhs = $i;
  return substr $$src, $lhs, $rhs-$lhs+1;
}


my $grammar = {
  '$ws_trim' => sub
  {
    my ($input) = @_;
    $$input =~ m/\G\s*/g;
    warn pos $$input;
    return;
  },
  '$BEGIN' => sub
  {
    parse_begin;
  },
  '$END' => sub
  {
    parse_end;
  },

  'GRAMPROG' => {
    'rules' => [ sub { my $src = shift; return pos($$src) == 0 ? '' : undef } ],
    'sym'   => 'GRAMPROG',
    'type'  => 'token'
  },

  'GRAMEXPR' => {
    'rules' => [ qr/(?^ui:GRAMEXPR)/ ],
    'sym'   => 'GRAMEXPR',
    'type'  => 'token'
  },

  'GRAMBLOCK' => {
    'rules' => [ qr/(?^ui:GRAMBLOCK)/ ],
    'sym'   => 'GRAMBLOCK',
    'type'  => 'token'
  },

  'GRAMBARESTMT' => {
    'rules' => [ qr/(?^ui:GRAMBARESTMT)/ ],
    'sym'   => 'GRAMBARESTMT',
    'type'  => 'token'
  },

  'GRAMFULLSTMT' => {
    'rules' => [ qr/(?^ui:GRAMFULLSTMT)/ ],
    'sym'   => 'GRAMFULLSTMT',
    'type'  => 'token'
  },

  'GRAMSTMTSEQ' => {
    'rules' => [ qr/(?^ui:GRAMSTMTSEQ)/ ],
    'sym'   => 'GRAMSTMTSEQ',
    'type'  => 'token'
  },

  'GRAMSUBSIGNATURE' => {
    'rules' => [ qr/(?^ui:GRAMSUBSIGNATURE)/ ],
    'sym'   => 'GRAMSUBSIGNATURE',
    'type'  => 'token'
  },

  '{' => {
    'rules' => [ qr/\{/ ],
    'sym'   => '\'{\'',
    'type'  => 'left'
  },

  '}' => {
    'rules' => [ qr/\}/ ],
    'sym'   => '\'}\'',
    'type'  => 'token'
  },

  '[' => {
    'rules' => [ qr/\[/ ],
    'sym'   => '\'[\'',
    'type'  => 'left'
  },

  ']' => {
    'rules' => [ qr/\]/ ],
    'sym'   => '\']\'',
    'type'  => 'token'
  },

  '-' => {
    'rules' => [ qr/\-/ ],
    'sym'   => '\'-\'',
    'type'  => 'token'
  },

  '+' => {
    'rules' => [ qr/\+/ ],
    'sym'   => '\'+\'',
    'type'  => 'token'
  },

  '@' => {
    'rules' => [ qr/\@/ ],
    'sym'   => '\'@\'',
    'type'  => 'token'
  },

  '%' => {
    'rules' => [ qr/\%/ ],
    'sym'   => '\'%\'',
    'type'  => 'token'
  },

  '&' => {
    'rules' => [ qr/\&/ ],
    'sym'   => '\'&\'',
    'type'  => 'token'
  },

  '=' => {
    'rules' => [ qr/\=/ ],
    'sym'   => '\'=\'',
    'type'  => 'token'
  },

  '.' => {
    'rules' => [ qr/\./ ],
    'sym'   => '\'.\'',
    'type'  => 'token'
  },

  'BAREWORD' => {
    'rules' => [ qr/[A-Za-z_](?:[A-Za-z0-9_]|::|')*/ ],
    'sym'   => 'BAREWORD',
    'type'  => 'token'
  },

  'METHOD' => {
    'rules' => [ qr/(?^ui:METHOD)/ ],
    'sym'   => 'METHOD',
    'type'  => 'token'
  },

  'FUNCMETH' => {
    'rules' => [ qr/(?^ui:FUNCMETH)/ ],
    'sym'   => 'FUNCMETH',
    'type'  => 'token'
  },

  'THING' => {
    'rules' => [
                       qr/\d(_?\d)*(\.(?!\.)(\d(_?\d)*)?)?([Ee][\+\-]?(\d(_?\d)*))?/i,
                       qr/\.\d(_?\d)*([Ee][\+\-]?(\d(_?\d)*))?/i,
                       qr/0b[01](_?[01])*/i,
                       qr/0[0-7](_?[0-7])*/i,
                       qr/0x[0-9A-Fa-f](_?[0-9A-Fa-f])*/i,
                       qr/0x[0-9A-Fa-f](_?[0-9A-Fa-f])*(?:\.\d*)?p[+-]?[0-9]+/i,
                       qr/inf/i,
                       qr/nan/i,

                       # Strings
                       sub {
                         my $src = shift;
                         $$src =~ m/\G\s*/g;
                         my $pos = pos $$src;
                         my ($mean, $delim, $flags);
                         if ( ($mean) = $$src =~ m[\G(['"/])]g )
                         {
                           #$DB::single = 1;
                           pos $$src = $pos;
                           my $result = scan_str($src, $mean);
                           #$result = substr $result, 1, -1;
                           return $result;
                         }
                         return;
                       },
                       
                       # Here-doc
                       sub {
                       },
<<'=cut'
                       [
                         function str_scan(input)
                         {
                           var tmp = input.dup();
                           var spaces = /^\s*/.exec(tmp);
                           var i = spaces[0].length;
                           tmp = tmp.toString();

                           var delim;
                           var mean;
                           var flags;
                           switch (tmp[i])
                           {
                             case "'":
                             case '"':
                             case '/':
                               delim = i;
                               mean  = tmp[i];
                               break;
                             case 'm':
                             case 's':
                             case 'y':
                               delim = i+1;
                               mean  = tmp[i];
                               flags = true;
                               break;
                             case 't':
                               if (tmp[i+1] == 'r')
                               {
                                 delim = i+2;
                                 mean  = 'tr';
                                 flags = true;
                               }
                               break;
                             case 'q':
                               switch (tmp[i+1])
                               {
                                 case 'r':
                                   flags = true;
                                 case 'q':
                                 case 'w':
                                   delim = i+2;
                                   mean  = tmp[i+0] + tmp[i+1];
                                   break;
                                 default:
                                   delim = i+1;
                                   mean  = "q";
                               }
                               break;
                           };

                           mean = mean == 'qq' ? '"'
                                : mean == 'q'  ? "'"
                                :                mean;

                           if (delim == null)
                           {
                             return false;
                           }
                           while (/\s/.test(tmp[delim]))
                           {
                             delim++;
                           }

                           var i = delim;
                           var open = tmp[delim];
                           var close = open;

                           if (/\w/.test(open))
                           {
                             return false;
                           }


                           var inverts = "([{< )]}> )]}>";
                           var n = inverts.indexOf(open);
                           if (n != -1)
                           {
                             close = inverts[n + 5];
                           }

                           var result = '';
                           var lhs, rhs;

                           var stack_read = function()
                           {
                             var stack = [close];
                             input.debug('thing', stack, tmp[i], i);
                             while( stack.length )
                             {
                               i++;
                               if ( i > tmp.length)
                               {
                                 //throw "Unterminated string, started at: " + input.short;
                                 return false;
                               }

                               if (close != open && tmp[i] == open)
                               {
                                 stack.unshift(close);
                                 continue;
                               }
                               if (tmp[i] == stack[0])
                               {
                                 stack.shift();
                               }
                               if (tmp[i] == '\\')
                               {
                                 i++;
                               }
                               if (stack.length > 0)
                               {
                                 result = result + tmp[i];
                               }
                             }
                           }

                           stack_read()
                           lhs = tmp.slice(delim+1, i);
                           //input.debug(tmp[i], i);
                           delim = i;

                           if (mean == 's' || mean == 'y' || mean == 'tr')
                           {
                             if (open != close)
                             {
                               var empty_space = /\s*/.exec(tmp.substr(i+1));
                               i += empty_space[0].length + 1;
                               if (tmp[i] != open)
                               {
                                 return false;
                               }
                             }
                             stack_read();
                             rhs = tmp.slice(delim+1, i);
                           }

                           if (flags)
                           {
                             flags = /^\w*/.exec(tmp.substr(i+1));
                             flags = flags[0];
                             i += flags.length;
                           }

                           switch (mean)
                           {
                             case '"':
                               return gen_interpolate(lhs, flags, i+1);
                             case "'":
                               return mk_snode([lhs], '', GNodes.str, i+1);
                             default:
                               return {
                                 len: i + 1,
                                 matched: {
                                   lhs: lhs,
                                   rhs: rhs,
                                   mean: mean,
                                   flags: flags,
                                 },
                               };
                           }
                         },
                         /*
                         mk_gen({
                           js: function(args)
                           {
                             var $1 = args[0];
                             switch ($1.mean)
                             {
                               case "'":
                                 return "'" + $1.lhs + "'";
                                 break;
                               case '"':
                                 return gen_interpolate($1.lhs, 'js');
                                 break;
                               default:
                                 throw "Bad meaning: " + $1.mean;
                             }
                             throw $1;
                           },
                         }),
                         */
                       ],

                       function heredoc_scan(input)
                       {
                         var tmp = input.dup().toString();
                         var heredoc_start = /^\s*[<][<]/.exec(tmp);
                         if (heredoc_start == null)
                         {
                           return false;
                         }

                         var i = heredoc_start[0].length;
                         var delim = '';
                         if (tmp[i] == "'" || tmp[i] == '"')
                         {
                           delim = tmp[i];
                           i++;
                         }
                         var heredoc_term = /^(\w*)/.exec(tmp.substr(i));
                         i += heredoc_term[0].length;

                         if (delim && tmp[i] != delim)
                         {
                           return false;
                         }
                         
                         i += delim.length;

                         if ( input.lex_memory.heredoc == null )
                         {
                           input.lex_memory.heredoc = [];
                         }
                         input.lex_memory.heredoc.push({
                           term: heredoc_term[1],
                           delim: delim, 
                         });

                         return i;
                       },
=cut
    ],
    'sym'   => 'THING',
    'type'  => 'token'
  },

  'PMFUNC' => {
    'rules' => [ qr/(?^ui:PMFUNC)/ ],
    'sym'   => 'PMFUNC',
    'type'  => 'token'
  },

  'PRIVATEREF' => {
    'rules' => [ qr/(?^ui:PRIVATEREF)/ ],
    'sym'   => 'PRIVATEREF',
    'type'  => 'token'
  },

  'QWLIST' => {
    'rules' => [ qr/(?^ui:QWLIST)/ ],
    'sym'   => 'QWLIST',
    'type'  => 'token'
  },

  'FUNC0OP' => {
    'rules' => [ qr/(?^ui:FUNC0OP)/ ],
    'sym'   => 'FUNC0OP',
    'type'  => 'token'
  },

  'FUNC0SUB' => {
    'rules' => [ qr/(?^ui:FUNC0SUB)/ ],
    'sym'   => 'FUNC0SUB',
    'type'  => 'token'
  },

  'UNIOPSUB' => {
    'rules' => [ qr/(?^ui:UNIOPSUB)/ ],
    'sym'   => 'UNIOPSUB',
    'type'  => 'nonassoc'
  },

  'LSTOPSUB' => {
    'rules' => [ qr/(?^ui:LSTOPSUB)/ ],
    'sym'   => 'LSTOPSUB',
    'type'  => 'nonassoc'
  },

  'PLUGEXPR' => {
    'rules' => [ qr/(?^ui:PLUGEXPR)/ ],
    'sym'   => 'PLUGEXPR',
    'type'  => 'token'
  },

  'PLUGSTMT' => {
    'rules' => [ qr/(?^ui:PLUGSTMT)/ ],
    'sym'   => 'PLUGSTMT',
    'type'  => 'token'
  },

  'LABEL' => {
    'rules' => [ qr/(?^ui:LABEL)/ ],
    'sym'   => 'LABEL',
    'type'  => 'token'
  },

  'FORMAT' => {
    'rules' => [ qr/(?^ui:FORMAT)/ ],
    'sym'   => 'FORMAT',
    'type'  => 'token'
  },

  'SUB' => {
    'rules' => [ qr/(?^ui:SUB)/ ],
    'sym'   => 'SUB',
    'type'  => 'token'
  },

  'SIGSUB' => {
    'rules' => [ qr/(?^ui:SIGSUB)/ ],
    'sym'   => 'SIGSUB',
    'type'  => 'token'
  },

  'ANONSUB' => {
    'rules' => [ qr/(?^ui:ANONSUB)/ ],
    'sym'   => 'ANONSUB',
    'type'  => 'token'
  },

  'ANON_SIGSUB' => {
    'rules' => [ qr/(?^ui:ANON_SIGSUB)/ ],
    'sym'   => 'ANON_SIGSUB',
    'type'  => 'token'
  },

  'PACKAGE' => {
    'rules' => [ qr/(?^ui:PACKAGE)/ ],
    'sym'   => 'PACKAGE',
    'type'  => 'token'
  },

  'USE' => {
    'rules' => [ qr/(?^ui:USE)/ ],
    'sym'   => 'USE',
    'type'  => 'token'
  },

  'WHILE' => {
    'rules' => [ qr/(?^ui:WHILE)/ ],
    'sym'   => 'WHILE',
    'type'  => 'token'
  },

  'UNTIL' => {
    'rules' => [ qr/(?^ui:UNTIL)/ ],
    'sym'   => 'UNTIL',
    'type'  => 'token'
  },

  'IF' => {
    'rules' => [ qr/(?^ui:IF)/ ],
    'sym'   => 'IF',
    'type'  => 'token'
  },

  'UNLESS' => {
    'rules' => [ qr/(?^ui:UNLESS)/ ],
    'sym'   => 'UNLESS',
    'type'  => 'token'
  },

  'ELSE' => {
    'rules' => [ qr/(?^ui:ELSE)/ ],
    'sym'   => 'ELSE',
    'type'  => 'token'
  },

  'ELSIF' => {
    'rules' => [ qr/(?^ui:ELSIF)/ ],
    'sym'   => 'ELSIF',
    'type'  => 'token'
  },

  'CONTINUE' => {
    'rules' => [ qr/(?^ui:CONTINUE)/ ],
    'sym'   => 'CONTINUE',
    'type'  => 'token'
  },

  'FOR' => {
    'rules' => [ qr/(?^ui:FOR)/ ],
    'sym'   => 'FOR',
    'type'  => 'token'
  },

  'GIVEN' => {
    'rules' => [ qr/(?^ui:GIVEN)/ ],
    'sym'   => 'GIVEN',
    'type'  => 'token'
  },

  'WHEN' => {
    'rules' => [ qr/(?^ui:WHEN)/ ],
    'sym'   => 'WHEN',
    'type'  => 'token'
  },

  'DEFAULT' => {
    'rules' => [ qr/(?^ui:DEFAULT)/ ],
    'sym'   => 'DEFAULT',
    'type'  => 'token'
  },

  'LOOPEX' => {
    'rules' => [ qr/(?^ui:LOOPEX)/ ],
    'sym'   => 'LOOPEX',
    'type'  => 'nonassoc'
  },

  'DOTDOT' => {
    'rules' => [ qr/(?^ui:DOTDOT)/ ],
    'sym'   => 'DOTDOT',
    'type'  => 'nonassoc'
  },

  'YADAYADA' => {
    'rules' => [ qr/(?^ui:YADAYADA)/ ],
    'sym'   => 'YADAYADA',
    'type'  => 'token'
  },

  'FUNC0' => {
    'rules' => [ qr/(?^ui:FUNC0)/ ],
    'sym'   => 'FUNC0',
    'type'  => 'token'
  },

  'FUNC1' => {
    'rules' => [ qr/(?^ui:FUNC1)/ ],
    'sym'   => 'FUNC1',
    'type'  => 'token'
  },

  'FUNC' => {
    'rules' => [ qr/[A-Za-z_](?:[A-Za-z0-9_]|::|')* (?=\s*[(])/x ],
    'sym'   => 'FUNC',
    'type'  => 'token'
  },

  'UNIOP' => {
    'rules' => [ qr/(?^ui:UNIOP)/ ],
    'sym'   => 'UNIOP',
    'type'  => 'nonassoc'
  },

  'LSTOP' => {
    'rules' => [ qr/[A-Za-z_](?:[A-Za-z0-9_]|::|')* (?!\s*[(])/x ],
    'sym'   => 'LSTOP',
    'type'  => 'nonassoc'
  },

  'MULOP' => {
    'rules' => [ qr/(?^ui:MULOP)/ ],
    'sym'   => 'MULOP',
    'type'  => 'left'
  },

  'ADDOP' => {
    'rules' => [ qr/(?^ui:ADDOP)/ ],
    'sym'   => 'ADDOP',
    'type'  => 'left'
  },

  'DOLSHARP' => {
    'rules' => [ qr/(?^ui:DOLSHARP)/ ],
    'sym'   => 'DOLSHARP',
    'type'  => 'token'
  },

  'DO' => {
    'rules' => [ qr/(?^ui:DO)/ ],
    'sym'   => 'DO',
    'type'  => 'token'
  },

  'HASHBRACK' => {
    'rules' => [ qr/(?^ui:HASHBRACK)/ ],
    'sym'   => 'HASHBRACK',
    'type'  => 'token'
  },

  'NOAMP' => {
    'rules' => [ qr/(?^ui:NOAMP)/ ],
    'sym'   => 'NOAMP',
    'type'  => 'token'
  },

  'LOCAL' => {
    'rules' => [ qr/(?^ui:LOCAL)/ ],
    'sym'   => 'LOCAL',
    'type'  => 'token'
  },

  'MY' => {
    'rules' => [ qr/(?^ui:MY)/ ],
    'sym'   => 'MY',
    'type'  => 'token'
  },

  'REQUIRE' => {
    'rules' => [ qr/(?^ui:REQUIRE)/ ],
    'sym'   => 'REQUIRE',
    'type'  => 'nonassoc'
  },

  'COLONATTR' => {
    'rules' => [ qr/(?^ui:COLONATTR)/ ],
    'sym'   => 'COLONATTR',
    'type'  => 'token'
  },

  'FORMLBRACK' => {
    'rules' => [ qr/(?^ui:FORMLBRACK)/ ],
    'sym'   => 'FORMLBRACK',
    'type'  => 'token'
  },

  'FORMRBRACK' => {
    'rules' => [ qr/(?^ui:FORMRBRACK)/ ],
    'sym'   => 'FORMRBRACK',
    'type'  => 'token'
  },

  'SUBLEXSTART' => {
    'rules' => [ qr/(?^ui:SUBLEXSTART)/ ],
    'sym'   => 'SUBLEXSTART',
    'type'  => 'token'
  },

  'SUBLEXEND' => {
    'rules' => [ qr/(?^ui:SUBLEXEND)/ ],
    'sym'   => 'SUBLEXEND',
    'type'  => 'token'
  },

  'grammar' => {
    'rules' => [
      {
        'code' =>
            '{ parser->expect = XSTATE $<ival>$ = 0 } { newPROG(block_end($3,$4)) PL_compiling.cop_seq = 0 $$ = 0 } ',
         code => sub { newPROG(block_end($_[1],$_[2])) ;  0 },
         #code => sub { init_named_cv('asdf'); newATTRSUB($_[1], 'asdf', $_[2]); 0; },
        'comment' => '',
        'line' =>
            ' GRAMPROG { parser->expect = XSTATE $<ival>$ = 0 } remember stmtseq { newPROG(block_end($3,$4)) PL_compiling.cop_seq = 0 $$ = 0 } ',
        'raw_rule' => ' GRAMPROG  remember stmtseq ',
        'rule'     => '<GRAMPROG> <remember> <stmtseq>'
      },
      {
        'code' =>
            '{ parser->expect = XTERM $<ival>$ = 0 } { PL_eval_root = $3 $$ = 0 } ',
        'comment' => '',
        'line' =>
            ' GRAMEXPR { parser->expect = XTERM $<ival>$ = 0 } optexpr { PL_eval_root = $3 $$ = 0 } ',
        'raw_rule' => ' GRAMEXPR  optexpr ',
        'rule'     => '<GRAMEXPR> <optexpr>'
      },
      {
        'code' =>
            '{ parser->expect = XBLOCK $<ival>$ = 0 } { PL_pad_reset_pending = TRUE PL_eval_root = $3 $$ = 0 yyunlex() parser->yychar = yytoken = YYEOF } ',
        'comment' => '',
        'line' =>
            ' GRAMBLOCK { parser->expect = XBLOCK $<ival>$ = 0 } block { PL_pad_reset_pending = TRUE PL_eval_root = $3 $$ = 0 yyunlex() parser->yychar = yytoken = YYEOF } ',
        'raw_rule' => ' GRAMBLOCK  block ',
        'rule'     => '<GRAMBLOCK> <block>'
      },
      {
        'code' =>
            '{ parser->expect = XSTATE $<ival>$ = 0 } { PL_pad_reset_pending = TRUE PL_eval_root = $3 $$ = 0 yyunlex() parser->yychar = yytoken = YYEOF } ',
        'comment' => '',
        'line' =>
            ' GRAMBARESTMT { parser->expect = XSTATE $<ival>$ = 0 } barestmt { PL_pad_reset_pending = TRUE PL_eval_root = $3 $$ = 0 yyunlex() parser->yychar = yytoken = YYEOF } ',
        'raw_rule' => ' GRAMBARESTMT  barestmt ',
        'rule'     => '<GRAMBARESTMT> <barestmt>'
      },
      {
        'code' =>
            '{ parser->expect = XSTATE $<ival>$ = 0 } { PL_pad_reset_pending = TRUE PL_eval_root = $3 $$ = 0 yyunlex() parser->yychar = yytoken = YYEOF } ',
        'comment' => '',
        'line' =>
            ' GRAMFULLSTMT { parser->expect = XSTATE $<ival>$ = 0 } fullstmt { PL_pad_reset_pending = TRUE PL_eval_root = $3 $$ = 0 yyunlex() parser->yychar = yytoken = YYEOF } ',
        'raw_rule' => ' GRAMFULLSTMT  fullstmt ',
        'rule'     => '<GRAMFULLSTMT> <fullstmt>'
      },
      {
        'code' =>
            '{ parser->expect = XSTATE $<ival>$ = 0 } { PL_eval_root = $3 $$ = 0 } ',
        'comment' => '',
        'line' =>
            ' GRAMSTMTSEQ { parser->expect = XSTATE $<ival>$ = 0 } stmtseq { PL_eval_root = $3 $$ = 0 } ',
        'raw_rule' => ' GRAMSTMTSEQ  stmtseq ',
        'rule'     => '<GRAMSTMTSEQ> <stmtseq>'
      },
      {
        'code' =>
            '{ parser->expect = XSTATE $<ival>$ = 0 } { PL_eval_root = $3 $$ = 0 } ',
        'comment' => '',
        'line' =>
            ' GRAMSUBSIGNATURE { parser->expect = XSTATE $<ival>$ = 0 } subsigguts { PL_eval_root = $3 $$ = 0 } ',
        'raw_rule' => ' GRAMSUBSIGNATURE  subsigguts ',
        'rule'     => '<GRAMSUBSIGNATURE> <subsigguts>'
      }
    ],
    'sym'  => 'grammar',
    'type' => 'nonterm'
  },

  'remember' => {
    'rules' => [
      {
        'code'    => '{ $$ = block_start(TRUE) parser->parsed_sub = 0; } ',
        code => sub { block_start(1) },
        'comment' => '/* NULL \*\//* start a full lexical scope \*\/',
        'line' =>
            ' /* NULL \*\/ /* start a full lexical scope \*\/ { $$ = block_start(TRUE) parser->parsed_sub = 0; } ',
        'raw_rule' => '   ',
        'rule'     => ''
      }
    ],
    'sym'  => 'remember',
    'type' => 'nonterm'
  },

  'mremember' => {
    'rules' => [
      {
        'code'    => '{ $$ = block_start(FALSE) parser->parsed_sub = 0; } ',
        'comment' => '/* NULL \*\//* start a partial lexical scope \*\/',
        'line' =>
            ' /* NULL \*\/ /* start a partial lexical scope \*\/ { $$ = block_start(FALSE) parser->parsed_sub = 0; } ',
        'raw_rule' => '   ',
        'rule'     => ''
      }
    ],
    'sym'  => 'mremember',
    'type' => 'nonterm'
  },

  'startsub' => {
    'rules' => [
      {
        'code' => '{ $$ = start_subparse(FALSE, 0) SAVEFREESV(PL_compcv); } ',
        'comment' => '/* NULL \*\//* start a regular subroutine scope \*\/',
        'line' =>
            ' /* NULL \*\/ /* start a regular subroutine scope \*\/ { $$ = start_subparse(FALSE, 0) SAVEFREESV(PL_compcv); } ',
        'raw_rule' => '   ',
        'rule'     => ''
      }
    ],
    'sym'  => 'startsub',
    'type' => 'nonterm'
  },

  'startanonsub' => {
    'rules' => [
      {
        'code' =>
            '{ $$ = start_subparse(FALSE, CVf_ANON) SAVEFREESV(PL_compcv); } ',
        'comment' =>
            '/* NULL \*\//* start an anonymous subroutine scope \*\/',
        'line' =>
            ' /* NULL \*\/ /* start an anonymous subroutine scope \*\/ { $$ = start_subparse(FALSE, CVf_ANON) SAVEFREESV(PL_compcv); } ',
        'raw_rule' => '   ',
        'rule'     => ''
      }
    ],
    'sym'  => 'startanonsub',
    'type' => 'nonterm'
  },

  'startformsub' => {
    'rules' => [
      {
        'code' => '{ $$ = start_subparse(TRUE, 0) SAVEFREESV(PL_compcv); } ',
        'comment' => '/* NULL \*\//* start a format subroutine scope \*\/',
        'line' =>
            ' /* NULL \*\/ /* start a format subroutine scope \*\/ { $$ = start_subparse(TRUE, 0) SAVEFREESV(PL_compcv); } ',
        'raw_rule' => '   ',
        'rule'     => ''
      }
    ],
    'sym'  => 'startformsub',
    'type' => 'nonterm'
  },

  'mintro' => {
    'rules' => [
      {
        'code' =>
            '{ $$ = (PL_min_intro_pending && PL_max_intro_pending >= PL_min_intro_pending) intro_my(); } ',
        'comment' => '/* NULL \*\//* Normal expression \*\/',
        'line' =>
            ' /* NULL \*\/ { $$ = (PL_min_intro_pending && PL_max_intro_pending >= PL_min_intro_pending) intro_my(); } /* Normal expression \*\/ ',
        'raw_rule' => '   ',
        'rule'     => ''
      }
    ],
    'sym'  => 'mintro',
    'type' => 'nonterm'
  },

  'stmtseq' => {
    'rules' => [
      {
        'code'     => '{ $$ = NULL; } ',
        code => sub { undef },
        'comment'  => '/* NULL \*\/',
        'line'     => ' /* NULL \*\/ { $$ = NULL; } ',
        'raw_rule' => '  ',
        'rule'     => '',
      },
      {
        'code' =>
            '{ $$ = op_append_list(OP_LINESEQ, $1, $2) PL_pad_reset_pending = TRUE if ($1 && $2) PL_hints |= HINT_BLOCK_SCOPE } ',
        code => sub {
          my $result = op_append_list('LINESEQ', $_[0], $_[1]);
        },
        'comment' => '',
        'line' =>
            ' stmtseq fullstmt { $$ = op_append_list(OP_LINESEQ, $1, $2) PL_pad_reset_pending = TRUE if ($1 && $2) PL_hints |= HINT_BLOCK_SCOPE } ',
        'raw_rule' => ' stmtseq fullstmt ',
        'rule'     => '<stmtseq> <fullstmt>'
      }
    ],
    'sym'  => 'stmtseq',
    'type' => 'nonterm'
  },

  'fullstmt' => {
    'rules' => [
      {
        'code'    => '{ $$ = $1 ? newSTATEOP(0, NULL, $1) : NULL } ',
        code => sub { defined $_[0] ? newSTATEOP(0, undef, $_[0]) : undef },
        'comment' => '',
        'line' => ' barestmt { $$ = $1 ? newSTATEOP(0, NULL, $1) : NULL } ',
        'raw_rule' => ' barestmt ',
        'rule'     => '<barestmt>'
      },
      {
        'code'     => '{ $$ = $1; } ',
        'comment'  => '',
        'line'     => ' labfullstmt { $$ = $1; } ',
        'raw_rule' => ' labfullstmt ',
        'rule'     => '<labfullstmt>'
      }
    ],
    'sym'  => 'fullstmt',
    'type' => 'nonterm'
  },

  'labfullstmt' => {
    'rules' => [
      {
        'code' =>
            '{ SV *label = cSVOPx_sv($1) $$ = newSTATEOP(SvFLAGS(label) & SVf_UTF8, savepv(SvPVX_const(label)), $2) op_free($1) } ',
        'comment' => '',
        'line' =>
            ' LABEL barestmt { SV *label = cSVOPx_sv($1) $$ = newSTATEOP(SvFLAGS(label) & SVf_UTF8, savepv(SvPVX_const(label)), $2) op_free($1) } ',
        'raw_rule' => ' LABEL barestmt ',
        'rule'     => '<LABEL> <barestmt>'
      },
      {
        'code' =>
            '{ SV *label = cSVOPx_sv($1) $$ = newSTATEOP(SvFLAGS(label) & SVf_UTF8, savepv(SvPVX_const(label)), $2) op_free($1) } ',
        'comment' => '',
        'line' =>
            ' LABEL labfullstmt { SV *label = cSVOPx_sv($1) $$ = newSTATEOP(SvFLAGS(label) & SVf_UTF8, savepv(SvPVX_const(label)), $2) op_free($1) } ',
        'raw_rule' => ' LABEL labfullstmt ',
        'rule'     => '<LABEL> <labfullstmt>'
      }
    ],
    'sym'  => 'labfullstmt',
    'type' => 'nonterm'
  },

  'barestmt' => {
    'rules' => [
      {
        'code'     => '{ $$ = $1; } ',
        'comment'  => '',
        'line'     => ' PLUGSTMT { $$ = $1; } ',
        'raw_rule' => ' PLUGSTMT ',
        'rule'     => '<PLUGSTMT>'
      },
      {
        'code' =>
            '{ CV *fmtcv = PL_compcv newFORM($2, $3, $4) $$ = NULL if (CvOUTSIDE(fmtcv) && !CvEVAL(CvOUTSIDE(fmtcv))) { pad_add_weakref(fmtcv) } parser->parsed_sub = 1 } ',
        'comment' => '',
        'line' =>
            ' FORMAT startformsub formname formblock { CV *fmtcv = PL_compcv newFORM($2, $3, $4) $$ = NULL if (CvOUTSIDE(fmtcv) && !CvEVAL(CvOUTSIDE(fmtcv))) { pad_add_weakref(fmtcv) } parser->parsed_sub = 1 } ',
        'raw_rule' => ' FORMAT startformsub formname formblock ',
        'rule'     => '<FORMAT> <startformsub> <formname> <formblock>'
      },
      {
        'code' =>
            '{ init_named_cv(PL_compcv, $2) parser->in_my = 0 parser->in_my_stash = NULL } { SvREFCNT_inc_simple_void(PL_compcv) $2->op_type == OP_CONST ? newATTRSUB($3, $2, $5, $6, $7) : newMYSUB($3, $2, $5, $6, $7) $$ = NULL intro_my() parser->parsed_sub = 1 } ',
        'comment' =>
            '/* sub declaration or definition not within scope of \'use feature "signatures"\'\*\/',
        'line' =>
            ' SUB subname startsub /* sub declaration or definition not within scope of \'use feature "signatures"\'\*\/ { init_named_cv(PL_compcv, $2) parser->in_my = 0 parser->in_my_stash = NULL } proto subattrlist optsubbody { SvREFCNT_inc_simple_void(PL_compcv) $2->op_type == OP_CONST ? newATTRSUB($3, $2, $5, $6, $7) : newMYSUB($3, $2, $5, $6, $7) $$ = NULL intro_my() parser->parsed_sub = 1 } ',
        'raw_rule' => ' SUB subname startsub   proto subattrlist optsubbody ',
        'rule' =>
            '<SUB> <subname> <startsub> <proto> <subattrlist> <optsubbody>'
      },
      {
        'code' =>
            '{ init_named_cv(PL_compcv, $2) parser->in_my = 0 parser->in_my_stash = NULL } { SvREFCNT_inc_simple_void(PL_compcv) $2->op_type == OP_CONST ? newATTRSUB($3, $2, NULL, $5, $6) : newMYSUB( $3, $2, NULL, $5, $6) $$ = NULL intro_my() parser->parsed_sub = 1 } ',
        'comment' =>
            '/* sub declaration or definition under \'use feature * "signatures"\'. (Note that a signature isn\'t * allowed in a declaration) \*\/',
        'line' =>
            ' SIGSUB subname startsub /* sub declaration or definition under \'use feature * "signatures"\'. (Note that a signature isn\'t * allowed in a declaration) \*\/ { init_named_cv(PL_compcv, $2) parser->in_my = 0 parser->in_my_stash = NULL } subattrlist optsigsubbody { SvREFCNT_inc_simple_void(PL_compcv) $2->op_type == OP_CONST ? newATTRSUB($3, $2, NULL, $5, $6) : newMYSUB( $3, $2, NULL, $5, $6) $$ = NULL intro_my() parser->parsed_sub = 1 } ',
        'raw_rule' => ' SIGSUB subname startsub   subattrlist optsigsubbody ',
        'rule' =>
            '<SIGSUB> <subname> <startsub> <subattrlist> <optsigsubbody>'
      },
      {
        'code'    => '{ package($3) if ($2) package_version($2) $$ = NULL } ',
        'comment' => '',
        'line' =>
            ' PACKAGE BAREWORD BAREWORD \';\' { package($3) if ($2) package_version($2) $$ = NULL } ',
        'raw_rule' => ' PACKAGE BAREWORD BAREWORD ; ',
        'rule'     => '<PACKAGE> <BAREWORD> <BAREWORD> ;'
      },
      {
        'code' =>
            '{ CvSPECIAL_on(PL_compcv); / } { SvREFCNT_inc_simple_void(PL_compcv) utilize($1, $2, $4, $5, $6) parser->parsed_sub = 1 $$ = NULL } ',
        'comment' => '/* It\'s a BEGIN {} \*\/',
        'line' =>
            ' USE startsub { CvSPECIAL_on(PL_compcv); /* It\'s a BEGIN {} \*\/ } BAREWORD BAREWORD optlistexpr \';\' { SvREFCNT_inc_simple_void(PL_compcv) utilize($1, $2, $4, $5, $6) parser->parsed_sub = 1 $$ = NULL } ',
        'raw_rule' => ' USE startsub  BAREWORD BAREWORD optlistexpr ; ',
        'rule'     => '<USE> <startsub> <BAREWORD> <BAREWORD> <optlistexpr> ;'
      },
      {
        'code' =>
            '{ $$ = block_end($3, newCONDOP(0, $4, op_scope($6), $7)) parser->copline = (line_t)$1 } ',
        'comment' => '',
        'line' =>
            ' IF \'(\' remember mexpr \')\' mblock else { $$ = block_end($3, newCONDOP(0, $4, op_scope($6), $7)) parser->copline = (line_t)$1 } ',
        'raw_rule' => ' IF ( remember mexpr ) mblock else ',
        'rule'     => '<IF> ( <remember> <mexpr> ) <mblock> <else>'
      },
      {
        'code' =>
            '{ $$ = block_end($3, newCONDOP(0, $4, $7, op_scope($6))) parser->copline = (line_t)$1 } ',
        'comment' => '',
        'line' =>
            ' UNLESS \'(\' remember mexpr \')\' mblock else { $$ = block_end($3, newCONDOP(0, $4, $7, op_scope($6))) parser->copline = (line_t)$1 } ',
        'raw_rule' => ' UNLESS ( remember mexpr ) mblock else ',
        'rule'     => '<UNLESS> ( <remember> <mexpr> ) <mblock> <else>'
      },
      {
        'code' =>
            '{ $$ = block_end($3, newGIVENOP($4, op_scope($6), 0)) parser->copline = (line_t)$1 } ',
        'comment' => '',
        'line' =>
            ' GIVEN \'(\' remember mexpr \')\' mblock { $$ = block_end($3, newGIVENOP($4, op_scope($6), 0)) parser->copline = (line_t)$1 } ',
        'raw_rule' => ' GIVEN ( remember mexpr ) mblock ',
        'rule'     => '<GIVEN> ( <remember> <mexpr> ) <mblock>'
      },
      {
        'code'    => '{ $$ = block_end($3, newWHENOP($4, op_scope($6))); } ',
        'comment' => '',
        'line' =>
            ' WHEN \'(\' remember mexpr \')\' mblock { $$ = block_end($3, newWHENOP($4, op_scope($6))); } ',
        'raw_rule' => ' WHEN ( remember mexpr ) mblock ',
        'rule'     => '<WHEN> ( <remember> <mexpr> ) <mblock>'
      },
      {
        'code'     => '{ $$ = newWHENOP(0, op_scope($2)); } ',
        'comment'  => '',
        'line'     => ' DEFAULT block { $$ = newWHENOP(0, op_scope($2)); } ',
        'raw_rule' => ' DEFAULT block ',
        'rule'     => '<DEFAULT> <block>'
      },
      {
        'code' =>
            '{ $$ = block_end($3, newWHILEOP(0, 1, NULL, $4, $7, $8, $6)) parser->copline = (line_t)$1 } ',
        'comment' => '',
        'line' =>
            ' WHILE \'(\' remember texpr \')\' mintro mblock cont { $$ = block_end($3, newWHILEOP(0, 1, NULL, $4, $7, $8, $6)) parser->copline = (line_t)$1 } ',
        'raw_rule' => ' WHILE ( remember texpr ) mintro mblock cont ',
        'rule' => '<WHILE> ( <remember> <texpr> ) <mintro> <mblock> <cont>'
      },
      {
        'code' =>
            '{ $$ = block_end($3, newWHILEOP(0, 1, NULL, $4, $7, $8, $6)) parser->copline = (line_t)$1 } ',
        'comment' => '',
        'line' =>
            ' UNTIL \'(\' remember iexpr \')\' mintro mblock cont { $$ = block_end($3, newWHILEOP(0, 1, NULL, $4, $7, $8, $6)) parser->copline = (line_t)$1 } ',
        'raw_rule' => ' UNTIL ( remember iexpr ) mintro mblock cont ',
        'rule' => '<UNTIL> ( <remember> <iexpr> ) <mintro> <mblock> <cont>'
      },
      {
        'code' =>
            '{ parser->expect = XTERM; } { parser->expect = XTERM; } { OP *initop = $4 OP *forop = newWHILEOP(0, 1, NULL, scalar($7), $13, $11, $10) if (initop) { forop = op_prepend_elem(OP_LINESEQ, initop, op_append_elem(OP_LINESEQ, newOP(OP_UNSTACK, OPf_SPECIAL), forop)) } PL_hints |= HINT_BLOCK_SCOPE $$ = block_end($3, forop) parser->copline = (line_t)$1 } ',
        'comment' => '',
        'line' =>
            ' FOR \'(\' remember mnexpr \';\' { parser->expect = XTERM; } texpr \';\' { parser->expect = XTERM; } mintro mnexpr \')\' mblock { OP *initop = $4 OP *forop = newWHILEOP(0, 1, NULL, scalar($7), $13, $11, $10) if (initop) { forop = op_prepend_elem(OP_LINESEQ, initop, op_append_elem(OP_LINESEQ, newOP(OP_UNSTACK, OPf_SPECIAL), forop)) } PL_hints |= HINT_BLOCK_SCOPE $$ = block_end($3, forop) parser->copline = (line_t)$1 } ',
        'raw_rule' =>
            ' FOR ( remember mnexpr ;  texpr ;  mintro mnexpr ) mblock ',
        'rule' =>
            '<FOR> ( <remember> <mnexpr> ; <texpr> ; <mintro> <mnexpr> ) <mblock>'
      },
      {
        'code' =>
            '{ $$ = block_end($3, newFOROP(0, $4, $6, $8, $9)) parser->copline = (line_t)$1 } ',
        'comment' => '',
        'line' =>
            ' FOR MY remember my_scalar \'(\' mexpr \')\' mblock cont { $$ = block_end($3, newFOROP(0, $4, $6, $8, $9)) parser->copline = (line_t)$1 } ',
        'raw_rule' => ' FOR MY remember my_scalar ( mexpr ) mblock cont ',
        'rule' =>
            '<FOR> <MY> <remember> <my_scalar> ( <mexpr> ) <mblock> <cont>'
      },
      {
        'code' =>
            '{ $$ = block_end($4, newFOROP(0, op_lvalue($2, OP_ENTERLOOP), $5, $7, $8)) parser->copline = (line_t)$1 } ',
        'comment' => '',
        'line' =>
            ' FOR scalar \'(\' remember mexpr \')\' mblock cont { $$ = block_end($4, newFOROP(0, op_lvalue($2, OP_ENTERLOOP), $5, $7, $8)) parser->copline = (line_t)$1 } ',
        'raw_rule' => ' FOR scalar ( remember mexpr ) mblock cont ',
        'rule'     => '<FOR> <scalar> ( <remember> <mexpr> ) <mblock> <cont>'
      },
      {
        'code' =>
            '{ parser->in_my = 0; $<opval>$ = my($4); } { $$ = block_end( $3, newFOROP(0, op_lvalue( newUNOP(OP_REFGEN, 0, $<opval>5), OP_ENTERLOOP), $7, $9, $10) ) parser->copline = (line_t)$1 } ',
        'comment' => '',
        'line' =>
            ' FOR my_refgen remember my_var { parser->in_my = 0; $<opval>$ = my($4); } \'(\' mexpr \')\' mblock cont { $$ = block_end( $3, newFOROP(0, op_lvalue( newUNOP(OP_REFGEN, 0, $<opval>5), OP_ENTERLOOP), $7, $9, $10) ) parser->copline = (line_t)$1 } ',
        'raw_rule' =>
            ' FOR my_refgen remember my_var  ( mexpr ) mblock cont ',
        'rule' =>
            '<FOR> <my_refgen> <remember> <my_var> ( <mexpr> ) <mblock> <cont>'
      },
      {
        'code' =>
            '{ $$ = block_end($5, newFOROP( 0, op_lvalue(newUNOP(OP_REFGEN, 0, $3), OP_ENTERLOOP), $6, $8, $9)) parser->copline = (line_t)$1 } ',
        'comment' => '',
        'line' =>
            ' FOR REFGEN refgen_topic \'(\' remember mexpr \')\' mblock cont { $$ = block_end($5, newFOROP( 0, op_lvalue(newUNOP(OP_REFGEN, 0, $3), OP_ENTERLOOP), $6, $8, $9)) parser->copline = (line_t)$1 } ',
        'raw_rule' =>
            ' FOR REFGEN refgen_topic ( remember mexpr ) mblock cont ',
        'rule' =>
            '<FOR> <REFGEN> <refgen_topic> ( <remember> <mexpr> ) <mblock> <cont>'
      },
      {
        'code' =>
            '{ $$ = block_end($3, newFOROP(0, NULL, $4, $6, $7)) parser->copline = (line_t)$1 } ',
        'comment' => '',
        'line' =>
            ' FOR \'(\' remember mexpr \')\' mblock cont { $$ = block_end($3, newFOROP(0, NULL, $4, $6, $7)) parser->copline = (line_t)$1 } ',
        'raw_rule' => ' FOR ( remember mexpr ) mblock cont ',
        'rule'     => '<FOR> ( <remember> <mexpr> ) <mblock> <cont>'
      },
      {
        'code'    => '{ / $$ = newWHILEOP(0, 1, NULL, NULL, $1, $2, 0) } ',
        'comment' => '/* a block is a loop that happens once \*\/',
        'line' =>
            ' block cont { /* a block is a loop that happens once \*\/ $$ = newWHILEOP(0, 1, NULL, NULL, $1, $2, 0) } ',
        'raw_rule' => ' block cont ',
        'rule'     => '<block> <cont>'
      },
      {
        'code' =>
            '{ package($3) if ($2) { package_version($2) } } { / $$ = newWHILEOP(0, 1, NULL, NULL, block_end($5, $7), NULL, 0) if (parser->copline > (line_t)$4) parser->copline = (line_t)$4 } ',
        'comment' => '/* a block is a loop that happens once \*\/',
        'line' =>
            ' PACKAGE BAREWORD BAREWORD \'{\' remember { package($3) if ($2) { package_version($2) } } stmtseq \'}\' { /* a block is a loop that happens once \*\/ $$ = newWHILEOP(0, 1, NULL, NULL, block_end($5, $7), NULL, 0) if (parser->copline > (line_t)$4) parser->copline = (line_t)$4 } ',
        'raw_rule' => ' PACKAGE BAREWORD BAREWORD { remember  stmtseq } ',
        'rule' => '<PACKAGE> <BAREWORD> <BAREWORD> { <remember> <stmtseq> }'
      },
      {
        #'code'     => '{ $$ = $1 } ',
        code => sub { $_[0] },
        'comment'  => '',
        'line'     => ' sideff \';\' { $$ = $1 } ',
        'raw_rule' => ' sideff ; ',
        'rule'     => '<sideff> ;'
      },
      {
        'code' =>
            '{ $$ = newLISTOP(OP_DIE, 0, newOP(OP_PUSHMARK, 0), newSVOP(OP_CONST, 0, newSVpvs("Unimplemented"))) } ',
        'comment' => '',
        'line' =>
            ' YADAYADA \';\' { $$ = newLISTOP(OP_DIE, 0, newOP(OP_PUSHMARK, 0), newSVOP(OP_CONST, 0, newSVpvs("Unimplemented"))) } ',
        'raw_rule' => ' YADAYADA ; ',
        'rule'     => '<YADAYADA> ;'
      },
      {
        'code'     => '{ $$ = NULL parser->copline = NOLINE } ',
        'comment'  => '',
        'line'     => ' \';\' { $$ = NULL parser->copline = NOLINE } ',
        'raw_rule' => ' ; ',
        'rule'     => ';'
      }
    ],
    'sym'  => 'barestmt',
    'type' => 'nonterm'
  },

  'block' => {
    'rules' => [
      {
        'code' =>
            '{ if (parser->copline > (line_t)$1) parser->copline = (line_t)$1 $$ = block_end($2, $3) } ',
        'comment' => '',
        'line' =>
            ' \'{\' remember stmtseq \'}\' { if (parser->copline > (line_t)$1) parser->copline = (line_t)$1 $$ = block_end($2, $3) } ',
        'raw_rule' => ' { remember stmtseq } ',
        'rule'     => '{ <remember> <stmtseq> }'
      }
    ],
    'sym'  => 'block',
    'type' => 'nonterm'
  },

  'mblock' => {
    'rules' => [
      {
        'code' =>
            '{ if (parser->copline > (line_t)$1) parser->copline = (line_t)$1 $$ = block_end($2, $3) } ',
        'comment' => '',
        'line' =>
            ' \'{\' mremember stmtseq \'}\' { if (parser->copline > (line_t)$1) parser->copline = (line_t)$1 $$ = block_end($2, $3) } ',
        'raw_rule' => ' { mremember stmtseq } ',
        'rule'     => '{ <mremember> <stmtseq> }'
      }
    ],
    'sym'  => 'mblock',
    'type' => 'nonterm'
  },

  'else' => {
    'rules' => [
      {
        'code'     => '{ $$ = NULL; } ',
        'comment'  => '/* NULL \*\/',
        'line'     => ' /* NULL \*\/ { $$ = NULL; } ',
        'raw_rule' => '  ',
        'rule'     => ''
      },
      {
        'code'    => '{ ($2)->op_flags |= OPf_PARENS $$ = op_scope($2) } ',
        'comment' => '',
        'line' =>
            ' ELSE mblock { ($2)->op_flags |= OPf_PARENS $$ = op_scope($2) } ',
        'raw_rule' => ' ELSE mblock ',
        'rule'     => '<ELSE> <mblock>'
      },
      {
        'code' =>
            '{ parser->copline = (line_t)$1 $$ = newCONDOP(0, newSTATEOP(OPf_SPECIAL,NULL,$3), op_scope($5), $6) PL_hints |= HINT_BLOCK_SCOPE } ',
        'comment' => '',
        'line' =>
            ' ELSIF \'(\' mexpr \')\' mblock else { parser->copline = (line_t)$1 $$ = newCONDOP(0, newSTATEOP(OPf_SPECIAL,NULL,$3), op_scope($5), $6) PL_hints |= HINT_BLOCK_SCOPE } ',
        'raw_rule' => ' ELSIF ( mexpr ) mblock else ',
        'rule'     => '<ELSIF> ( <mexpr> ) <mblock> <else>'
      }
    ],
    'sym'  => 'else',
    'type' => 'nonterm'
  },

  'expr' => {
    'rules' => [
      {
        'code'    => '{ $$ = newLOGOP(OP_AND, 0, $1, $3); } ',
        'comment' => '',
        'line' => ' expr ANDOP expr { $$ = newLOGOP(OP_AND, 0, $1, $3); } ',
        'raw_rule' => ' expr ANDOP expr ',
        'rule'     => '<expr> <ANDOP> <expr>'
      },
      {
        'code'     => '{ $$ = newLOGOP($2, 0, $1, $3); } ',
        'comment'  => '',
        'line'     => ' expr OROP expr { $$ = newLOGOP($2, 0, $1, $3); } ',
        'raw_rule' => ' expr OROP expr ',
        'rule'     => '<expr> <OROP> <expr>'
      },
      {
        'code'    => '{ $$ = newLOGOP(OP_DOR, 0, $1, $3); } ',
        'comment' => '',
        'line' => ' expr DOROP expr { $$ = newLOGOP(OP_DOR, 0, $1, $3); } ',
        'raw_rule' => ' expr DOROP expr ',
        'rule'     => '<expr> <DOROP> <expr>'
      },
      {
        'code'     => '',
        'comment'  => '',
        'line'     => ' listexpr %prec PREC_LOW ',
        'raw_rule' => ' listexpr %prec PREC_LOW',
        'rule'     => '<listexpr> {prec PREC_LOW}'
      }
    ],
    'sym'  => 'expr',
    'type' => 'nonterm'
  },

  'term' => {
    'rules' => [
      {
        'code'     => '',
        'comment'  => '',
        'line'     => ' termbinop ',
        'raw_rule' => ' termbinop',
        'rule'     => '<termbinop>'
      },
      {
        'code'     => '',
        'comment'  => '',
        'line'     => ' termunop ',
        'raw_rule' => ' termunop',
        'rule'     => '<termunop>'
      },
      {
        'code'     => '',
        'comment'  => '',
        'line'     => ' anonymous ',
        'raw_rule' => ' anonymous',
        'rule'     => '<anonymous>'
      },
      {
        'code'     => '',
        'comment'  => '',
        'line'     => ' termdo ',
        'raw_rule' => ' termdo',
        'rule'     => '<termdo>'
      },
      {
        'code'    => '{ $$ = newCONDOP(0, $1, $3, $5); } ',
        'comment' => '',
        'line' =>
            ' term \'?\' term \':\' term { $$ = newCONDOP(0, $1, $3, $5); } ',
        'raw_rule' => ' term ? term : term ',
        'rule'     => '<term> ? <term> : <term>'
      },
      {
        'code'    => '{ $$ = newUNOP(OP_REFGEN, 0, $2); } ',
        'comment' => '/* \\$x, \\@y, \\%z \*\/',
        'line' =>
            ' REFGEN term /* \\$x, \\@y, \\%z \*\/ { $$ = newUNOP(OP_REFGEN, 0, $2); } ',
        'raw_rule' => ' REFGEN term  ',
        'rule'     => '<REFGEN> <term>'
      },
      {
        'code'    => '{ $$ = newUNOP(OP_REFGEN, 0, localize($3,1)); } ',
        'comment' => '',
        'line' =>
            ' MY REFGEN term { $$ = newUNOP(OP_REFGEN, 0, localize($3,1)); } ',
        'raw_rule' => ' MY REFGEN term ',
        'rule'     => '<MY> <REFGEN> <term>'
      },
      {
        'code'     => '{ $$ = $1; } ',
        'comment'  => '',
        'line'     => ' myattrterm %prec UNIOP { $$ = $1; } ',
        'raw_rule' => ' myattrterm %prec UNIOP ',
        'rule'     => '<myattrterm> {prec UNIOP}'
      },
      {
        'code'     => '{ $$ = localize($2,0); } ',
        'comment'  => '',
        'line'     => ' LOCAL term %prec UNIOP { $$ = localize($2,0); } ',
        'raw_rule' => ' LOCAL term %prec UNIOP ',
        'rule'     => '<LOCAL> <term> {prec UNIOP}'
      },
      {
        'code'     => '{ $$ = sawparens($2); } ',
        'comment'  => '',
        'line'     => ' \'(\' expr \')\' { $$ = sawparens($2); } ',
        'raw_rule' => ' ( expr ) ',
        'rule'     => '( <expr> )'
      },
      {
        'code'     => '{ $$ = $1; } ',
        'comment'  => '',
        'line'     => ' QWLIST { $$ = $1; } ',
        'raw_rule' => ' QWLIST ',
        'rule'     => '<QWLIST>'
      },
      {
        'code'     => '{ $$ = sawparens(newNULLLIST()); } ',
        'comment'  => '',
        'line'     => ' \'(\' \')\' { $$ = sawparens(newNULLLIST()); } ',
        'raw_rule' => ' ( ) ',
        'rule'     => '( )'
      },
      {
        'code'     => '{ $$ = $1; } ',
        'comment'  => '',
        'line'     => ' scalar %prec \'(\' { $$ = $1; } ',
        'raw_rule' => ' scalar %prec ( ',
        'rule'     => '<scalar> {prec (}'
      },
      {
        'code'     => '{ $$ = $1; } ',
        'comment'  => '',
        'line'     => ' star %prec \'(\' { $$ = $1; } ',
        'raw_rule' => ' star %prec ( ',
        'rule'     => '<star> {prec (}'
      },
      {
        'code'     => '{ $$ = $1; } ',
        'comment'  => '',
        'line'     => ' hsh %prec \'(\' { $$ = $1; } ',
        'raw_rule' => ' hsh %prec ( ',
        'rule'     => '<hsh> {prec (}'
      },
      {
        'code'     => '{ $$ = $1; } ',
        'comment'  => '',
        'line'     => ' ary %prec \'(\' { $$ = $1; } ',
        'raw_rule' => ' ary %prec ( ',
        'rule'     => '<ary> {prec (}'
      },
      {
        'code' => '{ $$ = newUNOP(OP_AV2ARYLEN, 0, ref($1, OP_AV2ARYLEN));} ',
        'comment' => '/* $#x, $#{ something } \*\/',
        'line' =>
            ' arylen %prec \'(\' /* $#x, $#{ something } \*\/ { $$ = newUNOP(OP_AV2ARYLEN, 0, ref($1, OP_AV2ARYLEN));} ',
        'raw_rule' => ' arylen %prec (  ',
        'rule'     => '<arylen> {prec (}'
      },
      {
        'code'     => '{ $$ = $1; } ',
        'comment'  => '',
        'line'     => ' subscripted { $$ = $1; } ',
        'raw_rule' => ' subscripted ',
        'rule'     => '<subscripted>'
      },
      {
        'code' =>
            '{ $$ = op_prepend_elem(OP_ASLICE, newOP(OP_PUSHMARK, 0), newLISTOP(OP_ASLICE, 0, list($3), ref($1, OP_ASLICE))) if ($$ && $1) $$->op_private |= $1->op_private & OPpSLICEWARNING } ',
        'comment' => '/* array slice \*\/',
        'line' =>
            ' sliceme \'[\' expr \']\' /* array slice \*\/ { $$ = op_prepend_elem(OP_ASLICE, newOP(OP_PUSHMARK, 0), newLISTOP(OP_ASLICE, 0, list($3), ref($1, OP_ASLICE))) if ($$ && $1) $$->op_private |= $1->op_private & OPpSLICEWARNING } ',
        'raw_rule' => ' sliceme [ expr ]  ',
        'rule'     => '<sliceme> [ <expr> ]'
      },
      {
        'code' =>
            '{ $$ = op_prepend_elem(OP_KVASLICE, newOP(OP_PUSHMARK, 0), newLISTOP(OP_KVASLICE, 0, list($3), ref(oopsAV($1), OP_KVASLICE))) if ($$ && $1) $$->op_private |= $1->op_private & OPpSLICEWARNING } ',
        'comment' => '/* array key/value slice \*\/',
        'line' =>
            ' kvslice \'[\' expr \']\' /* array key/value slice \*\/ { $$ = op_prepend_elem(OP_KVASLICE, newOP(OP_PUSHMARK, 0), newLISTOP(OP_KVASLICE, 0, list($3), ref(oopsAV($1), OP_KVASLICE))) if ($$ && $1) $$->op_private |= $1->op_private & OPpSLICEWARNING } ',
        'raw_rule' => ' kvslice [ expr ]  ',
        'rule'     => '<kvslice> [ <expr> ]'
      },
      {
        'code' =>
            '{ $$ = op_prepend_elem(OP_HSLICE, newOP(OP_PUSHMARK, 0), newLISTOP(OP_HSLICE, 0, list($3), ref(oopsHV($1), OP_HSLICE))) if ($$ && $1) $$->op_private |= $1->op_private & OPpSLICEWARNING } ',
        'comment' => '/* @hash{@keys} \*\/',
        'line' =>
            ' sliceme \'{\' expr \';\' \'}\' /* @hash{@keys} \*\/ { $$ = op_prepend_elem(OP_HSLICE, newOP(OP_PUSHMARK, 0), newLISTOP(OP_HSLICE, 0, list($3), ref(oopsHV($1), OP_HSLICE))) if ($$ && $1) $$->op_private |= $1->op_private & OPpSLICEWARNING } ',
        'raw_rule' => ' sliceme { expr ; }  ',
        'rule'     => '<sliceme> { <expr> ; }'
      },
      {
        'code' =>
            '{ $$ = op_prepend_elem(OP_KVHSLICE, newOP(OP_PUSHMARK, 0), newLISTOP(OP_KVHSLICE, 0, list($3), ref($1, OP_KVHSLICE))) if ($$ && $1) $$->op_private |= $1->op_private & OPpSLICEWARNING } ',
        'comment' => '/* %hash{@keys} \*\/',
        'line' =>
            ' kvslice \'{\' expr \';\' \'}\' /* %hash{@keys} \*\/ { $$ = op_prepend_elem(OP_KVHSLICE, newOP(OP_PUSHMARK, 0), newLISTOP(OP_KVHSLICE, 0, list($3), ref($1, OP_KVHSLICE))) if ($$ && $1) $$->op_private |= $1->op_private & OPpSLICEWARNING } ',
        'raw_rule' => ' kvslice { expr ; }  ',
        'rule'     => '<kvslice> { <expr> ; }'
      },
      {
        #'code'     => '{ $$ = $1; } ',
        'comment'  => '',
        'line'     => ' THING %prec \'(\' { $$ = $1; } ',
        'raw_rule' => ' THING %prec ( ',
        'rule'     => '<THING> {prec (}'
      },
      {
        'code'    => '{ $$ = newUNOP(OP_ENTERSUB, 0, scalar($1)); } ',
        'comment' => '/* &foo; \*\/',
        'line' =>
            ' amper /* &foo; \*\/ { $$ = newUNOP(OP_ENTERSUB, 0, scalar($1)); } ',
        'raw_rule' => ' amper  ',
        'rule'     => '<amper>'
      },
      {
        'code' => '{ $$ = newUNOP(OP_ENTERSUB, OPf_STACKED, scalar($1)) } ',
        'comment' => '/* &foo() or foo() \*\/',
        'line' =>
            ' amper \'(\' \')\' /* &foo() or foo() \*\/ { $$ = newUNOP(OP_ENTERSUB, OPf_STACKED, scalar($1)) } ',
        'raw_rule' => ' amper ( )  ',
        'rule'     => '<amper> ( )'
      },
      {
        'code' =>
            '{ $$ = newUNOP(OP_ENTERSUB, OPf_STACKED, op_append_elem(OP_LIST, $3, scalar($1))) } ',
        'comment' => '/* &foo(@args) or foo(@args) \*\/',
        'line' =>
            ' amper \'(\' expr \')\' /* &foo(@args) or foo(@args) \*\/ { $$ = newUNOP(OP_ENTERSUB, OPf_STACKED, op_append_elem(OP_LIST, $3, scalar($1))) } ',
        'raw_rule' => ' amper ( expr )  ',
        'rule'     => '<amper> ( <expr> )'
      },
      {
        'code' =>
            '{ $$ = newUNOP(OP_ENTERSUB, OPf_STACKED, op_append_elem(OP_LIST, $3, scalar($2))) } ',
        'comment' => '/* foo @args (no parens) \*\/',
        'line' =>
            ' NOAMP subname optlistexpr /* foo @args (no parens) \*\/ { $$ = newUNOP(OP_ENTERSUB, OPf_STACKED, op_append_elem(OP_LIST, $3, scalar($2))) } ',
        'raw_rule' => ' NOAMP subname optlistexpr  ',
        'rule'     => '<NOAMP> <subname> <optlistexpr>'
      },
      {
        'code'     => '{ $$ = newSVREF($1); } ',
        'comment'  => '',
        'line'     => ' term ARROW \'$\' \'*\' { $$ = newSVREF($1); } ',
        'raw_rule' => ' term ARROW $ * ',
        'rule'     => '<term> <ARROW> $ *'
      },
      {
        'code'     => '{ $$ = newAVREF($1); } ',
        'comment'  => '',
        'line'     => ' term ARROW \'@\' \'*\' { $$ = newAVREF($1); } ',
        'raw_rule' => ' term ARROW @ * ',
        'rule'     => '<term> <ARROW> @ *'
      },
      {
        'code'     => '{ $$ = newHVREF($1); } ',
        'comment'  => '',
        'line'     => ' term ARROW \'%\' \'*\' { $$ = newHVREF($1); } ',
        'raw_rule' => ' term ARROW % * ',
        'rule'     => '<term> <ARROW> % *'
      },
      {
        'code' =>
            '{ $$ = newUNOP(OP_ENTERSUB, 0, scalar(newCVREF($3,$1))); } ',
        'comment' => '',
        'line' =>
            ' term ARROW \'&\' \'*\' { $$ = newUNOP(OP_ENTERSUB, 0, scalar(newCVREF($3,$1))); } ',
        'raw_rule' => ' term ARROW & * ',
        'rule'     => '<term> <ARROW> & *'
      },
      {
        'code'    => '{ $$ = newGVREF(0,$1); } ',
        'comment' => '',
        'line' =>
            ' term ARROW \'*\' \'*\' %prec \'(\' { $$ = newGVREF(0,$1); } ',
        'raw_rule' => ' term ARROW * * %prec ( ',
        'rule'     => '<term> <ARROW> * * {prec (}'
      },
      {
        'code' =>
            '{ $$ = newOP($1, OPf_SPECIAL) PL_hints |= HINT_BLOCK_SCOPE; } ',
        'comment' => '/* loop exiting command (goto, last, dump, etc) \*\/',
        'line' =>
            ' LOOPEX /* loop exiting command (goto, last, dump, etc) \*\/ { $$ = newOP($1, OPf_SPECIAL) PL_hints |= HINT_BLOCK_SCOPE; } ',
        'raw_rule' => ' LOOPEX  ',
        'rule'     => '<LOOPEX>'
      },
      {
        'code'     => '{ $$ = newLOOPEX($1,$2); } ',
        'comment'  => '',
        'line'     => ' LOOPEX term { $$ = newLOOPEX($1,$2); } ',
        'raw_rule' => ' LOOPEX term ',
        'rule'     => '<LOOPEX> <term>'
      },
      {
        'code'    => '{ $$ = newUNOP(OP_NOT, 0, scalar($2)); } ',
        'comment' => '/* not $foo \*\/',
        'line' =>
            ' NOTOP listexpr /* not $foo \*\/ { $$ = newUNOP(OP_NOT, 0, scalar($2)); } ',
        'raw_rule' => ' NOTOP listexpr  ',
        'rule'     => '<NOTOP> <listexpr>'
      },
      {
        'code'    => '{ $$ = newOP($1, 0); } ',
        'comment' => '/* Unary op, $_ implied \*\/',
        'line' =>
            ' UNIOP /* Unary op, $_ implied \*\/ { $$ = newOP($1, 0); } ',
        'raw_rule' => ' UNIOP  ',
        'rule'     => '<UNIOP>'
      },
      {
        'code'    => '{ $$ = newUNOP($1, 0, $2); } ',
        'comment' => '/* eval { foo }* \*\/',
        'line' =>
            ' UNIOP block /* eval { foo }* \*\/ { $$ = newUNOP($1, 0, $2); } ',
        'raw_rule' => ' UNIOP block  ',
        'rule'     => '<UNIOP> <block>'
      },
      {
        'code'    => '{ $$ = newUNOP($1, 0, $2); } ',
        'comment' => '/* Unary op \*\/',
        'line' =>
            ' UNIOP term /* Unary op \*\/ { $$ = newUNOP($1, 0, $2); } ',
        'raw_rule' => ' UNIOP term  ',
        'rule'     => '<UNIOP> <term>'
      },
      {
        'code'    => '{ $$ = newOP(OP_REQUIRE, $1 ? OPf_SPECIAL : 0); } ',
        'comment' => '/* require, $_ implied \*\/',
        'line' =>
            ' REQUIRE /* require, $_ implied \*\/ { $$ = newOP(OP_REQUIRE, $1 ? OPf_SPECIAL : 0); } ',
        'raw_rule' => ' REQUIRE  ',
        'rule'     => '<REQUIRE>'
      },
      {
        'code' => '{ $$ = newUNOP(OP_REQUIRE, $1 ? OPf_SPECIAL : 0, $2); } ',
        'comment' => '/* require Foo \*\/',
        'line' =>
            ' REQUIRE term /* require Foo \*\/ { $$ = newUNOP(OP_REQUIRE, $1 ? OPf_SPECIAL : 0, $2); } ',
        'raw_rule' => ' REQUIRE term  ',
        'rule'     => '<REQUIRE> <term>'
      },
      {
        'code' => '{ $$ = newUNOP(OP_ENTERSUB, OPf_STACKED, scalar($1)); } ',
        'comment' => '',
        'line' =>
            ' UNIOPSUB { $$ = newUNOP(OP_ENTERSUB, OPf_STACKED, scalar($1)); } ',
        'raw_rule' => ' UNIOPSUB ',
        'rule'     => '<UNIOPSUB>'
      },
      {
        'code' =>
            '{ $$ = newUNOP(OP_ENTERSUB, OPf_STACKED, op_append_elem(OP_LIST, $2, scalar($1))); } ',
        'comment' => '/* Sub treated as unop \*\/',
        'line' =>
            ' UNIOPSUB term /* Sub treated as unop \*\/ { $$ = newUNOP(OP_ENTERSUB, OPf_STACKED, op_append_elem(OP_LIST, $2, scalar($1))); } ',
        'raw_rule' => ' UNIOPSUB term  ',
        'rule'     => '<UNIOPSUB> <term>'
      },
      {
        'code'    => '{ $$ = newOP($1, 0); } ',
        'comment' => '/* Nullary operator \*\/',
        'line' => ' FUNC0 /* Nullary operator \*\/ { $$ = newOP($1, 0); } ',
        'raw_rule' => ' FUNC0  ',
        'rule'     => '<FUNC0>'
      },
      {
        'code'     => '{ $$ = newOP($1, 0);} ',
        'comment'  => '',
        'line'     => ' FUNC0 \'(\' \')\' { $$ = newOP($1, 0);} ',
        'raw_rule' => ' FUNC0 ( ) ',
        'rule'     => '<FUNC0> ( )'
      },
      {
        'code'    => '{ $$ = $1; } ',
        'comment' => '/* Same as above, but op created in toke.c \*\/',
        'line' =>
            ' FUNC0OP /* Same as above, but op created in toke.c \*\/ { $$ = $1; } ',
        'raw_rule' => ' FUNC0OP  ',
        'rule'     => '<FUNC0OP>'
      },
      {
        'code'     => '{ $$ = $1; } ',
        'comment'  => '',
        'line'     => ' FUNC0OP \'(\' \')\' { $$ = $1; } ',
        'raw_rule' => ' FUNC0OP ( ) ',
        'rule'     => '<FUNC0OP> ( )'
      },
      {
        'code' => '{ $$ = newUNOP(OP_ENTERSUB, OPf_STACKED, scalar($1)); } ',
        'comment' => '/* Sub treated as nullop \*\/',
        'line' =>
            ' FUNC0SUB /* Sub treated as nullop \*\/ { $$ = newUNOP(OP_ENTERSUB, OPf_STACKED, scalar($1)); } ',
        'raw_rule' => ' FUNC0SUB  ',
        'rule'     => '<FUNC0SUB>'
      },
      {
        'code' =>
            '{ $$ = ($1 == OP_NOT) ? newUNOP($1, 0, newSVOP(OP_CONST, 0, newSViv(0))) : newOP($1, OPf_SPECIAL); } ',
        'comment' => '/* not () \*\/',
        'line' =>
            ' FUNC1 \'(\' \')\' /* not () \*\/ { $$ = ($1 == OP_NOT) ? newUNOP($1, 0, newSVOP(OP_CONST, 0, newSViv(0))) : newOP($1, OPf_SPECIAL); } ',
        'raw_rule' => ' FUNC1 ( )  ',
        'rule'     => '<FUNC1> ( )'
      },
      {
        'code'    => '{ $$ = newUNOP($1, 0, $3); } ',
        'comment' => '/* not($foo) \*\/',
        'line' =>
            ' FUNC1 \'(\' expr \')\' /* not($foo) \*\/ { $$ = newUNOP($1, 0, $3); } ',
        'raw_rule' => ' FUNC1 ( expr )  ',
        'rule'     => '<FUNC1> ( <expr> )'
      },
      {
        'code' =>
            '{ if ( $1->op_type != OP_TRANS && $1->op_type != OP_TRANSR && (((PMOP*)$1)->op_pmflags & PMf_HAS_CV)) { $<ival>$ = start_subparse(FALSE, CVf_ANON) SAVEFREESV(PL_compcv) } else $<ival>$ = 0 } { $$ = pmruntime($1, $4, $5, 1, $<ival>2); } ',
        'comment' => '/* m//, s///, qr//, tr/// \*\/',
        'line' =>
            ' PMFUNC /* m//, s///, qr//, tr/// \*\/ { if ( $1->op_type != OP_TRANS && $1->op_type != OP_TRANSR && (((PMOP*)$1)->op_pmflags & PMf_HAS_CV)) { $<ival>$ = start_subparse(FALSE, CVf_ANON) SAVEFREESV(PL_compcv) } else $<ival>$ = 0 } SUBLEXSTART listexpr optrepl SUBLEXEND { $$ = pmruntime($1, $4, $5, 1, $<ival>2); } ',
        'raw_rule' => ' PMFUNC   SUBLEXSTART listexpr optrepl SUBLEXEND ',
        'rule' => '<PMFUNC> <SUBLEXSTART> <listexpr> <optrepl> <SUBLEXEND>'
      },
      #{
      #  'code'     => '',
      #  'comment'  => '',
      #  'line'     => ' BAREWORD ',
      #  'raw_rule' => ' BAREWORD',
      #  'rule'     => '<BAREWORD>'
      #},
      {
        'code'     => '',
        'comment'  => '',
        'line'     => ' listop ',
        'raw_rule' => ' listop',
        'rule'     => '<listop>'
      },
      {
        'code'     => '',
        'comment'  => '',
        'line'     => ' PLUGEXPR ',
        'raw_rule' => ' PLUGEXPR',
        'rule'     => '<PLUGEXPR>'
      }
    ],
    'sym'  => 'term',
    'type' => 'nonterm'
  },

  'subscripted' => {
    'rules' => [
      {
        'code' => '{ $$ = newBINOP(OP_GELEM, 0, $1, scalar($3)); } ',
        'comment' =>
            '/* *main::{something} \*\//* In this and all the hash accessors, \';\' is * provided by the tokeniser \*\/',
        'line' =>
            ' gelem \'{\' expr \';\' \'}\' /* *main::{something} \*\/ /* In this and all the hash accessors, \';\' is * provided by the tokeniser \*\/ { $$ = newBINOP(OP_GELEM, 0, $1, scalar($3)); } ',
        'raw_rule' => ' gelem { expr ; }   ',
        'rule'     => '<gelem> { <expr> ; }'
      },
      {
        'code' => '{ $$ = newBINOP(OP_AELEM, 0, oopsAV($1), scalar($3)) } ',
        'comment' => '/* $array[$element] \*\/',
        'line' =>
            ' scalar \'[\' expr \']\' /* $array[$element] \*\/ { $$ = newBINOP(OP_AELEM, 0, oopsAV($1), scalar($3)) } ',
        'raw_rule' => ' scalar [ expr ]  ',
        'rule'     => '<scalar> [ <expr> ]'
      },
      {
        'code' =>
            '{ $$ = newBINOP(OP_AELEM, 0, ref(newAVREF($1),OP_RV2AV), scalar($4)) } ',
        'comment' => '/* somearef->[$element] \*\/',
        'line' =>
            ' term ARROW \'[\' expr \']\' /* somearef->[$element] \*\/ { $$ = newBINOP(OP_AELEM, 0, ref(newAVREF($1),OP_RV2AV), scalar($4)) } ',
        'raw_rule' => ' term ARROW [ expr ]  ',
        'rule'     => '<term> <ARROW> [ <expr> ]'
      },
      {
        'code' =>
            '{ $$ = newBINOP(OP_AELEM, 0, ref(newAVREF($1),OP_RV2AV), scalar($3)) } ',
        'comment' => '/* $foo->[$bar]->[$baz] \*\/',
        'line' =>
            ' subscripted \'[\' expr \']\' /* $foo->[$bar]->[$baz] \*\/ { $$ = newBINOP(OP_AELEM, 0, ref(newAVREF($1),OP_RV2AV), scalar($3)) } ',
        'raw_rule' => ' subscripted [ expr ]  ',
        'rule'     => '<subscripted> [ <expr> ]'
      },
      {
        'code' => '{ $$ = newBINOP(OP_HELEM, 0, oopsHV($1), jmaybe($3)) } ',
        'comment' => '/* $foo{bar();} \*\/',
        'line' =>
            ' scalar \'{\' expr \';\' \'}\' /* $foo{bar();} \*\/ { $$ = newBINOP(OP_HELEM, 0, oopsHV($1), jmaybe($3)) } ',
        'raw_rule' => ' scalar { expr ; }  ',
        'rule'     => '<scalar> { <expr> ; }'
      },
      {
        'code' =>
            '{ $$ = newBINOP(OP_HELEM, 0, ref(newHVREF($1),OP_RV2HV), jmaybe($4)); } ',
        'comment' => '/* somehref->{bar();} \*\/',
        'line' =>
            ' term ARROW \'{\' expr \';\' \'}\' /* somehref->{bar();} \*\/ { $$ = newBINOP(OP_HELEM, 0, ref(newHVREF($1),OP_RV2HV), jmaybe($4)); } ',
        'raw_rule' => ' term ARROW { expr ; }  ',
        'rule'     => '<term> <ARROW> { <expr> ; }'
      },
      {
        'code' =>
            '{ $$ = newBINOP(OP_HELEM, 0, ref(newHVREF($1),OP_RV2HV), jmaybe($3)); } ',
        'comment' => '/* $foo->[bar]->{baz;} \*\/',
        'line' =>
            ' subscripted \'{\' expr \';\' \'}\' /* $foo->[bar]->{baz;} \*\/ { $$ = newBINOP(OP_HELEM, 0, ref(newHVREF($1),OP_RV2HV), jmaybe($3)); } ',
        'raw_rule' => ' subscripted { expr ; }  ',
        'rule'     => '<subscripted> { <expr> ; }'
      },
      {
        'code' =>
            '{ $$ = newUNOP(OP_ENTERSUB, OPf_STACKED, newCVREF(0, scalar($1))) if (parser->expect == XBLOCK) parser->expect = XOPERATOR } ',
        'comment' => '/* $subref->() \*\/',
        'line' =>
            ' term ARROW \'(\' \')\' /* $subref->() \*\/ { $$ = newUNOP(OP_ENTERSUB, OPf_STACKED, newCVREF(0, scalar($1))) if (parser->expect == XBLOCK) parser->expect = XOPERATOR } ',
        'raw_rule' => ' term ARROW ( )  ',
        'rule'     => '<term> <ARROW> ( )'
      },
      {
        'code' =>
            '{ $$ = newUNOP(OP_ENTERSUB, OPf_STACKED, op_append_elem(OP_LIST, $4, newCVREF(0, scalar($1)))) if (parser->expect == XBLOCK) parser->expect = XOPERATOR } ',
        'comment' => '/* $subref->(@args) \*\/',
        'line' =>
            ' term ARROW \'(\' expr \')\' /* $subref->(@args) \*\/ { $$ = newUNOP(OP_ENTERSUB, OPf_STACKED, op_append_elem(OP_LIST, $4, newCVREF(0, scalar($1)))) if (parser->expect == XBLOCK) parser->expect = XOPERATOR } ',
        'raw_rule' => ' term ARROW ( expr )  ',
        'rule'     => '<term> <ARROW> ( <expr> )'
      },
      {
        'code' =>
            '{ $$ = newUNOP(OP_ENTERSUB, OPf_STACKED, op_append_elem(OP_LIST, $3, newCVREF(0, scalar($1)))) if (parser->expect == XBLOCK) parser->expect = XOPERATOR } ',
        'comment' => '/* $foo->{bar}->(@args) \*\/',
        'line' =>
            ' subscripted \'(\' expr \')\' /* $foo->{bar}->(@args) \*\/ { $$ = newUNOP(OP_ENTERSUB, OPf_STACKED, op_append_elem(OP_LIST, $3, newCVREF(0, scalar($1)))) if (parser->expect == XBLOCK) parser->expect = XOPERATOR } ',
        'raw_rule' => ' subscripted ( expr )  ',
        'rule'     => '<subscripted> ( <expr> )'
      },
      {
        'code' =>
            '{ $$ = newUNOP(OP_ENTERSUB, OPf_STACKED, newCVREF(0, scalar($1))) if (parser->expect == XBLOCK) parser->expect = XOPERATOR } ',
        'comment' => '/* $foo->{bar}->() \*\/',
        'line' =>
            ' subscripted \'(\' \')\' /* $foo->{bar}->() \*\/ { $$ = newUNOP(OP_ENTERSUB, OPf_STACKED, newCVREF(0, scalar($1))) if (parser->expect == XBLOCK) parser->expect = XOPERATOR } ',
        'raw_rule' => ' subscripted ( )  ',
        'rule'     => '<subscripted> ( )'
      },
      {
        'code'    => '{ $$ = newSLICEOP(0, $5, $2); } ',
        'comment' => '/* list slice \*\/',
        'line' =>
            ' \'(\' expr \')\' \'[\' expr \']\' /* list slice \*\/ { $$ = newSLICEOP(0, $5, $2); } ',
        'raw_rule' => ' ( expr ) [ expr ]  ',
        'rule'     => '( <expr> ) [ <expr> ]'
      },
      {
        'code'    => '{ $$ = newSLICEOP(0, $3, $1); } ',
        'comment' => '/* list literal slice \*\/',
        'line' =>
            ' QWLIST \'[\' expr \']\' /* list literal slice \*\/ { $$ = newSLICEOP(0, $3, $1); } ',
        'raw_rule' => ' QWLIST [ expr ]  ',
        'rule'     => '<QWLIST> [ <expr> ]'
      },
      {
        'code'    => '{ $$ = newSLICEOP(0, $4, NULL); } ',
        'comment' => '/* empty list slice! \*\/',
        'line' =>
            ' \'(\' \')\' \'[\' expr \']\' /* empty list slice! \*\/ { $$ = newSLICEOP(0, $4, NULL); } ',
        'raw_rule' => ' ( ) [ expr ]  ',
        'rule'     => '( ) [ <expr> ]'
      }
    ],
    'sym'  => 'subscripted',
    'type' => 'nonterm'
  },

  'scalar' => {
    'rules' => [
      {
        'code'     => '{ $$ = newSVREF($2); } ',
        'comment'  => '',
        'line'     => ' \'$\' indirob { $$ = newSVREF($2); } ',
        'raw_rule' => ' $ indirob ',
        'rule'     => '$ <indirob>'
      }
    ],
    'sym'  => 'scalar',
    'type' => 'nonterm'
  },

  'ary' => {
    'rules' => [
      {
        'code'    => '{ $$ = newAVREF($2) if ($$) $$->op_private |= $1 } ',
        'comment' => '',
        'line' =>
            ' \'@\' indirob { $$ = newAVREF($2) if ($$) $$->op_private |= $1 } ',
        'raw_rule' => ' @ indirob ',
        'rule'     => '@ <indirob>'
      }
    ],
    'sym'  => 'ary',
    'type' => 'nonterm'
  },

  'hsh' => {
    'rules' => [
      {
        'code'    => '{ $$ = newHVREF($2) if ($$) $$->op_private |= $1 } ',
        'comment' => '',
        'line' =>
            ' \'%\' indirob { $$ = newHVREF($2) if ($$) $$->op_private |= $1 } ',
        'raw_rule' => ' % indirob ',
        'rule'     => '% <indirob>'
      }
    ],
    'sym'  => 'hsh',
    'type' => 'nonterm'
  },

  'arylen' => {
    'rules' => [
      {
        'code'     => '{ $$ = newAVREF($2); } ',
        'comment'  => '',
        'line'     => ' DOLSHARP indirob { $$ = newAVREF($2); } ',
        'raw_rule' => ' DOLSHARP indirob ',
        'rule'     => '<DOLSHARP> <indirob>'
      },
      {
        'code'     => '{ $$ = newAVREF($1); } ',
        'comment'  => '',
        'line'     => ' term ARROW DOLSHARP \'*\' { $$ = newAVREF($1); } ',
        'raw_rule' => ' term ARROW DOLSHARP * ',
        'rule'     => '<term> <ARROW> <DOLSHARP> *'
      }
    ],
    'sym'  => 'arylen',
    'type' => 'nonterm'
  },

  'star' => {
    'rules' => [
      {
        'code'     => '{ $$ = newGVREF(0,$2); } ',
        'comment'  => '',
        'line'     => ' \'*\' indirob { $$ = newGVREF(0,$2); } ',
        'raw_rule' => ' * indirob ',
        'rule'     => '* <indirob>'
      }
    ],
    'sym'  => 'star',
    'type' => 'nonterm'
  },

  'amper' => {
    'rules' => [
      {
        'code'     => '{ $$ = newCVREF($1,$2); } ',
        'comment'  => '',
        'line'     => ' \'&\' indirob { $$ = newCVREF($1,$2); } ',
        'raw_rule' => ' & indirob ',
        'rule'     => '& <indirob>'
      }
    ],
    'sym'  => 'amper',
    'type' => 'nonterm'
  },

  'sideff' => {
    'rules' => [
      {
        'code'     => '{ $$ = NULL; } ',
        'comment'  => '',
        'line'     => ' error { $$ = NULL; } ',
        'raw_rule' => ' error ',
        'rule'     => 'error'
      },
      {
        #'code'     => '{ $$ = $1; } ',
        'comment'  => '',
        'line'     => ' expr { $$ = $1; } ',
        'raw_rule' => ' expr ',
        'rule'     => '<expr>'
      },
      {
        'code'     => '{ $$ = newLOGOP(OP_AND, 0, $3, $1); } ',
        'comment'  => '',
        'line'     => ' expr IF expr { $$ = newLOGOP(OP_AND, 0, $3, $1); } ',
        'raw_rule' => ' expr IF expr ',
        'rule'     => '<expr> <IF> <expr>'
      },
      {
        'code'    => '{ $$ = newLOGOP(OP_OR, 0, $3, $1); } ',
        'comment' => '',
        'line' => ' expr UNLESS expr { $$ = newLOGOP(OP_OR, 0, $3, $1); } ',
        'raw_rule' => ' expr UNLESS expr ',
        'rule'     => '<expr> <UNLESS> <expr>'
      },
      {
        'code'    => '{ $$ = newLOOPOP(OPf_PARENS, 1, scalar($3), $1); } ',
        'comment' => '',
        'line' =>
            ' expr WHILE expr { $$ = newLOOPOP(OPf_PARENS, 1, scalar($3), $1); } ',
        'raw_rule' => ' expr WHILE expr ',
        'rule'     => '<expr> <WHILE> <expr>'
      },
      {
        'code'    => '{ $$ = newLOOPOP(OPf_PARENS, 1, $3, $1); } ',
        'comment' => '',
        'line' =>
            ' expr UNTIL iexpr { $$ = newLOOPOP(OPf_PARENS, 1, $3, $1); } ',
        'raw_rule' => ' expr UNTIL iexpr ',
        'rule'     => '<expr> <UNTIL> <iexpr>'
      },
      {
        'code' =>
            '{ $$ = newFOROP(0, NULL, $3, $1, NULL) parser->copline = (line_t)$2; } ',
        'comment' => '',
        'line' =>
            ' expr FOR expr { $$ = newFOROP(0, NULL, $3, $1, NULL) parser->copline = (line_t)$2; } ',
        'raw_rule' => ' expr FOR expr ',
        'rule'     => '<expr> <FOR> <expr>'
      },
      {
        'code'    => '{ $$ = newWHENOP($3, op_scope($1)); } ',
        'comment' => '',
        'line'    => ' expr WHEN expr { $$ = newWHENOP($3, op_scope($1)); } ',
        'raw_rule' => ' expr WHEN expr ',
        'rule'     => '<expr> <WHEN> <expr>'
      }
    ],
    'sym'  => 'sideff',
    'type' => 'nonterm'
  },

  'sliceme' => {
    'rules' => [
      {
        'code'     => '',
        'comment'  => '',
        'line'     => ' ary ',
        'raw_rule' => ' ary',
        'rule'     => '<ary>'
      },
      {
        'code'     => '{ $$ = newAVREF($1); } ',
        'comment'  => '',
        'line'     => ' term ARROW \'@\' { $$ = newAVREF($1); } ',
        'raw_rule' => ' term ARROW @ ',
        'rule'     => '<term> <ARROW> @'
      }
    ],
    'sym'  => 'sliceme',
    'type' => 'nonterm'
  },

  'kvslice' => {
    'rules' => [
      {
        'code'     => '',
        'comment'  => '',
        'line'     => ' hsh ',
        'raw_rule' => ' hsh',
        'rule'     => '<hsh>'
      },
      {
        'code'     => '{ $$ = newHVREF($1); } ',
        'comment'  => '',
        'line'     => ' term ARROW \'%\' { $$ = newHVREF($1); } ',
        'raw_rule' => ' term ARROW % ',
        'rule'     => '<term> <ARROW> %'
      }
    ],
    'sym'  => 'kvslice',
    'type' => 'nonterm'
  },

  'gelem' => {
    'rules' => [
      {
        'code'     => '',
        'comment'  => '',
        'line'     => ' star ',
        'raw_rule' => ' star',
        'rule'     => '<star>'
      },
      {
        'code'     => '{ $$ = newGVREF(0,$1); } ',
        'comment'  => '',
        'line'     => ' term ARROW \'*\' { $$ = newGVREF(0,$1); } ',
        'raw_rule' => ' term ARROW * ',
        'rule'     => '<term> <ARROW> *'
      }
    ],
    'sym'  => 'gelem',
    'type' => 'nonterm'
  },

  'listexpr' => {
    'rules' => [
      {
        'code'     => '{ $$ = $1; } ',
        'code'     => sub { return $_[0] },
        'comment'  => '',
        'line'     => ' listexpr \',\' { $$ = $1; } ',
        'raw_rule' => ' listexpr , ',
        'rule'     => '<listexpr> ,'
      },
      {
        'code' => '{ OP* term = $3 $$ = op_append_elem(OP_LIST, $1, term) } ',
        code => sub { op_append_elem('LIST', $_[0], $_[2]) },
        'comment' => '',
        'line' =>
            ' listexpr \',\' term { OP* term = $3 $$ = op_append_elem(OP_LIST, $1, term) } ',
        'raw_rule' => ' listexpr , term ',
        'rule'     => '<listexpr> , <term>'
      },
      {
        'code'     => '',
        'comment'  => '',
        'line'     => ' term %prec PREC_LOW ',
        'raw_rule' => ' term %prec PREC_LOW',
        'rule'     => '<term> {prec PREC_LOW}'
      }
    ],
    'sym'  => 'listexpr',
    'type' => 'nonterm'
  },

  'nexpr' => {
    'rules' => [
      {
        'code'     => '{ $$ = NULL; } ',
        'comment'  => '/* NULL \*\/',
        'line'     => ' /* NULL \*\/ { $$ = NULL; } ',
        'raw_rule' => '  ',
        'rule'     => ''
      },
      {
        'code'     => '',
        'comment'  => '',
        'line'     => ' sideff ',
        'raw_rule' => ' sideff',
        'rule'     => '<sideff>'
      }
    ],
    'sym'  => 'nexpr',
    'type' => 'nonterm'
  },

  'texpr' => {
    'rules' => [
      {
        'code' =>
            '{ YYSTYPE tmplval (void)scan_num("1", &tmplval) $$ = tmplval.opval; } ',
        'comment' => '/* NULL means true \*\/',
        'line' =>
            ' /* NULL means true \*\/ { YYSTYPE tmplval (void)scan_num("1", &tmplval) $$ = tmplval.opval; } ',
        'raw_rule' => '  ',
        'rule'     => ''
      },
      {
        'code'     => '',
        'comment'  => '',
        'line'     => ' expr ',
        'raw_rule' => ' expr',
        'rule'     => '<expr>'
      }
    ],
    'sym'  => 'texpr',
    'type' => 'nonterm'
  },

  'iexpr' => {
    'rules' => [
      {
        'code'     => '{ $$ = invert(scalar($1)); } ',
        'comment'  => '',
        'line'     => ' expr { $$ = invert(scalar($1)); } ',
        'raw_rule' => ' expr ',
        'rule'     => '<expr>'
      }
    ],
    'sym'  => 'iexpr',
    'type' => 'nonterm'
  },

  'mexpr' => {
    'rules' => [
      {
        'code'     => '{ $$ = $1; intro_my(); } ',
        'comment'  => '',
        'line'     => ' expr { $$ = $1; intro_my(); } ',
        'raw_rule' => ' expr ',
        'rule'     => '<expr>'
      }
    ],
    'sym'  => 'mexpr',
    'type' => 'nonterm'
  },

  'mnexpr' => {
    'rules' => [
      {
        'code'     => '{ $$ = $1; intro_my(); } ',
        'comment'  => '',
        'line'     => ' nexpr { $$ = $1; intro_my(); } ',
        'raw_rule' => ' nexpr ',
        'rule'     => '<nexpr>'
      }
    ],
    'sym'  => 'mnexpr',
    'type' => 'nonterm'
  },

  'optlistexpr' => {
    'rules' => [
      {
        'code'     => sub { undef },
        'comment'  => '/* NULL \*\/',
        'line'     => ' /* NULL \*\/ %prec PREC_LOW { $$ = NULL; } ',
        'raw_rule' => '  %prec PREC_LOW ',
        'rule'     => '{prec PREC_LOW}'
      },
      {
        'code'     => sub { $_[0] },
        'comment'  => '',
        'line'     => ' listexpr %prec PREC_LOW { $$ = $1; } ',
        'raw_rule' => ' listexpr %prec PREC_LOW ',
        'rule'     => '<listexpr> {prec PREC_LOW}'
      }
    ],
    'sym'  => 'optlistexpr',
    'type' => 'nonterm'
  },

  'optexpr' => {
    'rules' => [
      {
        'code'     => '{ $$ = NULL; } ',
        'comment'  => '/* NULL \*\/',
        'line'     => ' /* NULL \*\/ { $$ = NULL; } ',
        'raw_rule' => '  ',
        'rule'     => ''
      },
      {
        'code'     => '{ $$ = $1; } ',
        'comment'  => '',
        'line'     => ' expr { $$ = $1; } ',
        'raw_rule' => ' expr ',
        'rule'     => '<expr>'
      }
    ],
    'sym'  => 'optexpr',
    'type' => 'nonterm'
  },

  'optrepl' => {
    'rules' => [
      {
        'code'     => '{ $$ = NULL; } ',
        'comment'  => '/* NULL \*\/',
        'line'     => ' /* NULL \*\/ { $$ = NULL; } ',
        'raw_rule' => '  ',
        'rule'     => ''
      },
      {
        'code'     => '{ $$ = $2; } ',
        'comment'  => '',
        'line'     => ' \'/\' expr { $$ = $2; } ',
        'raw_rule' => ' / expr ',
        'rule'     => '/ <expr>'
      }
    ],
    'sym'  => 'optrepl',
    'type' => 'nonterm'
  },

  'indirob' => {
    'rules' => [
      {
        'code'     => '{ $$ = scalar($1); } ',
        'comment'  => '',
        'line'     => ' BAREWORD { $$ = scalar($1); } ',
        'raw_rule' => ' BAREWORD ',
        'rule'     => '<BAREWORD>'
      },
      {
        'code'     => '{ $$ = scalar($1); } ',
        'comment'  => '',
        'line'     => ' scalar %prec PREC_LOW { $$ = scalar($1); } ',
        'raw_rule' => ' scalar %prec PREC_LOW ',
        'rule'     => '<scalar> {prec PREC_LOW}'
      },
      {
        'code'     => '{ $$ = op_scope($1); } ',
        'comment'  => '',
        'line'     => ' block { $$ = op_scope($1); } ',
        'raw_rule' => ' block ',
        'rule'     => '<block>'
      },
      {
        'code'     => '{ $$ = $1; } ',
        'comment'  => '',
        'line'     => ' PRIVATEREF { $$ = $1; } ',
        'raw_rule' => ' PRIVATEREF ',
        'rule'     => '<PRIVATEREF>'
      }
    ],
    'sym'  => 'indirob',
    'type' => 'nonterm'
  },

  'listop' => {
    'rules' => [
      {
        'code' =>
            '{ $$ = op_convert_list($1, OPf_STACKED, op_prepend_elem(OP_LIST, newGVREF($1,$2), $3) ) } ',
        'comment' => '/* map {...} @args or print $fh @args \*\/',
        'line' =>
            ' LSTOP indirob listexpr /* map {...} @args or print $fh @args \*\/ { $$ = op_convert_list($1, OPf_STACKED, op_prepend_elem(OP_LIST, newGVREF($1,$2), $3) ) } ',
        'raw_rule' => ' LSTOP indirob listexpr  ',
        'rule'     => '<LSTOP> <indirob> <listexpr>'
      },
      {
        'code' =>
            '{ $$ = op_convert_list($1, OPf_STACKED, op_prepend_elem(OP_LIST, newGVREF($1,$3), $4) ) } ',
        'comment' => '/* print ($fh @args \*\/',
        'line' =>
            ' FUNC \'(\' indirob expr \')\' /* print ($fh @args \*\/ { $$ = op_convert_list($1, OPf_STACKED, op_prepend_elem(OP_LIST, newGVREF($1,$3), $4) ) } ',
        'raw_rule' => ' FUNC ( indirob expr )  ',
        'rule'     => '<FUNC> ( <indirob> <expr> )'
      },
      {
        'code' =>
            '{ $$ = op_convert_list(OP_ENTERSUB, OPf_STACKED, op_append_elem(OP_LIST, op_prepend_elem(OP_LIST, scalar($1), $5), newMETHOP(OP_METHOD, 0, $3))) } ',
        'comment' => '/* $foo->bar(list) \*\/',
        'line' =>
            ' term ARROW method \'(\' optexpr \')\' /* $foo->bar(list) \*\/ { $$ = op_convert_list(OP_ENTERSUB, OPf_STACKED, op_append_elem(OP_LIST, op_prepend_elem(OP_LIST, scalar($1), $5), newMETHOP(OP_METHOD, 0, $3))) } ',
        'raw_rule' => ' term ARROW method ( optexpr )  ',
        'rule'     => '<term> <ARROW> <method> ( <optexpr> )'
      },
      {
        'code' =>
            '{ $$ = op_convert_list(OP_ENTERSUB, OPf_STACKED, op_append_elem(OP_LIST, scalar($1), newMETHOP(OP_METHOD, 0, $3))) } ',
        'comment' => '/* $foo->bar \*\/',
        'line' =>
            ' term ARROW method /* $foo->bar \*\/ { $$ = op_convert_list(OP_ENTERSUB, OPf_STACKED, op_append_elem(OP_LIST, scalar($1), newMETHOP(OP_METHOD, 0, $3))) } ',
        'raw_rule' => ' term ARROW method  ',
        'rule'     => '<term> <ARROW> <method>'
      },
      {
        'code' =>
            '{ $$ = op_convert_list(OP_ENTERSUB, OPf_STACKED, op_append_elem(OP_LIST, op_prepend_elem(OP_LIST, $2, $3), newMETHOP(OP_METHOD, 0, $1))) } ',
        'comment' => '/* new Class @args \*\/',
        'line' =>
            ' METHOD indirob optlistexpr /* new Class @args \*\/ { $$ = op_convert_list(OP_ENTERSUB, OPf_STACKED, op_append_elem(OP_LIST, op_prepend_elem(OP_LIST, $2, $3), newMETHOP(OP_METHOD, 0, $1))) } ',
        'raw_rule' => ' METHOD indirob optlistexpr  ',
        'rule'     => '<METHOD> <indirob> <optlistexpr>'
      },
      {
        'code' =>
            '{ $$ = op_convert_list(OP_ENTERSUB, OPf_STACKED, op_append_elem(OP_LIST, op_prepend_elem(OP_LIST, $2, $4), newMETHOP(OP_METHOD, 0, $1))) } ',
        'comment' => '/* method $object (@args) \*\/',
        'line' =>
            ' FUNCMETH indirob \'(\' optexpr \')\' /* method $object (@args) \*\/ { $$ = op_convert_list(OP_ENTERSUB, OPf_STACKED, op_append_elem(OP_LIST, op_prepend_elem(OP_LIST, $2, $4), newMETHOP(OP_METHOD, 0, $1))) } ',
        'raw_rule' => ' FUNCMETH indirob ( optexpr )  ',
        'rule'     => '<FUNCMETH> <indirob> ( <optexpr> )'
      },
      {
        #'code'    => '{ $$ = op_convert_list($1, 0, $2); } ',
        'code'    => sub { $DB::single=1; op_convert_list($_[0], 0, $_[1]) },
        'comment' => '/* print @args \*\/',
        'line' =>
            ' LSTOP optlistexpr /* print @args \*\/ { $$ = op_convert_list($1, 0, $2); } ',
        'raw_rule' => ' LSTOP optlistexpr  ',
        'rule'     => '<LSTOP> <optlistexpr>'
      },
      {
        'code'    => '{ $$ = op_convert_list($1, 0, $3); } ',
        'comment' => '/* print (@args) \*\/',
        'line' =>
            ' FUNC \'(\' optexpr \')\' /* print (@args) \*\/ { $$ = op_convert_list($1, 0, $3); } ',
        'raw_rule' => ' FUNC ( optexpr )  ',
        'rule'     => '<FUNC> ( <optexpr> )'
      },
      {
        'code'    => '{ $$ = op_convert_list($1, 0, $3); } ',
        'comment' => '/* uc($arg) from "\\U..." \*\/',
        'line' =>
            ' FUNC SUBLEXSTART optexpr SUBLEXEND /* uc($arg) from "\\U..." \*\/ { $$ = op_convert_list($1, 0, $3); } ',
        'raw_rule' => ' FUNC SUBLEXSTART optexpr SUBLEXEND  ',
        'rule'     => '<FUNC> <SUBLEXSTART> <optexpr> <SUBLEXEND>'
      },
      {
        'code' =>
            '{ SvREFCNT_inc_simple_void(PL_compcv) $<opval>$ = newANONATTRSUB($2, 0, NULL, $3); } { $$ = newUNOP(OP_ENTERSUB, OPf_STACKED, op_append_elem(OP_LIST, op_prepend_elem(OP_LIST, $<opval>4, $5), $1)) } ',
        'comment' => '/* sub f(&@); f { foo } ... \*\//* ... @bar \*\/',
        'line' =>
            ' LSTOPSUB startanonsub block /* sub f(&@); f { foo } ... \*\/ { SvREFCNT_inc_simple_void(PL_compcv) $<opval>$ = newANONATTRSUB($2, 0, NULL, $3); } optlistexpr %prec LSTOP /* ... @bar \*\/ { $$ = newUNOP(OP_ENTERSUB, OPf_STACKED, op_append_elem(OP_LIST, op_prepend_elem(OP_LIST, $<opval>4, $5), $1)) } ',
        'raw_rule' =>
            ' LSTOPSUB startanonsub block   optlistexpr %prec LSTOP  ',
        'rule' =>
            '<LSTOPSUB> <startanonsub> <block> <optlistexpr> {prec LSTOP}'
      }
    ],
    'sym'  => 'listop',
    'type' => 'nonterm'
  },

  'method' => {
    'rules' => [
      {
        'code'     => '',
        'comment'  => '',
        'line'     => ' METHOD ',
        'raw_rule' => ' METHOD',
        'rule'     => '<METHOD>'
      },
      {
        'code'     => '',
        'comment'  => '',
        'line'     => ' scalar ',
        'raw_rule' => ' scalar',
        'rule'     => '<scalar>'
      }
    ],
    'sym'  => 'method',
    'type' => 'nonterm'
  },

  'formname' => {
    'rules' => [
      {
        'code'     => '{ $$ = $1; } ',
        'comment'  => '',
        'line'     => ' BAREWORD { $$ = $1; } ',
        'raw_rule' => ' BAREWORD ',
        'rule'     => '<BAREWORD>'
      },
      {
        'code'     => '{ $$ = NULL; } ',
        'comment'  => '/* NULL \*\/',
        'line'     => ' /* NULL \*\/ { $$ = NULL; } ',
        'raw_rule' => '  ',
        'rule'     => ''
      }
    ],
    'sym'  => 'formname',
    'type' => 'nonterm'
  },

  'subname' => {
    'rules' => [
      {
        'code'     => '',
        'comment'  => '',
        'line'     => ' BAREWORD ',
        'raw_rule' => ' BAREWORD',
        'rule'     => '<BAREWORD>'
      },
      {
        'code'     => '',
        'comment'  => '',
        'line'     => ' PRIVATEREF ',
        'raw_rule' => ' PRIVATEREF',
        'rule'     => '<PRIVATEREF>'
      }
    ],
    'sym'  => 'subname',
    'type' => 'nonterm'
  },

  'proto' => {
    'rules' => [
      {
        'code'     => '{ $$ = NULL; } ',
        'comment'  => '/* NULL \*\/',
        'line'     => ' /* NULL \*\/ { $$ = NULL; } ',
        'raw_rule' => '  ',
        'rule'     => ''
      },
      {
        'code'     => '',
        'comment'  => '',
        'line'     => ' THING ',
        'raw_rule' => ' THING',
        'rule'     => '<THING>'
      }
    ],
    'sym'  => 'proto',
    'type' => 'nonterm'
  },

  'cont' => {
    'rules' => [
      {
        'code'     => '{ $$ = NULL; } ',
        'comment'  => '/* NULL \*\/',
        'line'     => ' /* NULL \*\/ { $$ = NULL; } ',
        'raw_rule' => '  ',
        'rule'     => ''
      },
      {
        'code'     => '{ $$ = op_scope($2); } ',
        'comment'  => '',
        'line'     => ' CONTINUE block { $$ = op_scope($2); } ',
        'raw_rule' => ' CONTINUE block ',
        'rule'     => '<CONTINUE> <block>'
      }
    ],
    'sym'  => 'cont',
    'type' => 'nonterm'
  },

  'my_scalar' => {
    'rules' => [
      {
        'code'     => '{ parser->in_my = 0; $$ = my($1); } ',
        'comment'  => '',
        'line'     => ' scalar { parser->in_my = 0; $$ = my($1); } ',
        'raw_rule' => ' scalar ',
        'rule'     => '<scalar>'
      }
    ],
    'sym'  => 'my_scalar',
    'type' => 'nonterm'
  },

  'my_var' => {
    'rules' => [
      {
        'code'     => '',
        'comment'  => '',
        'line'     => ' scalar ',
        'raw_rule' => ' scalar',
        'rule'     => '<scalar>'
      },
      {
        'code'     => '',
        'comment'  => '',
        'line'     => ' ary ',
        'raw_rule' => ' ary',
        'rule'     => '<ary>'
      },
      {
        'code'     => '',
        'comment'  => '',
        'line'     => ' hsh ',
        'raw_rule' => ' hsh',
        'rule'     => '<hsh>'
      }
    ],
    'sym'  => 'my_var',
    'type' => 'nonterm'
  },

  'refgen_topic' => {
    'rules' => [
      {
        'code'     => '',
        'comment'  => '',
        'line'     => ' my_var ',
        'raw_rule' => ' my_var',
        'rule'     => '<my_var>'
      },
      {
        'code'     => '',
        'comment'  => '',
        'line'     => ' amper ',
        'raw_rule' => ' amper',
        'rule'     => '<amper>'
      }
    ],
    'sym'  => 'refgen_topic',
    'type' => 'nonterm'
  },

  'formblock' => {
    'rules' => [
      {
        'code' =>
            '{ if (parser->copline > (line_t)$1) parser->copline = (line_t)$1 $$ = block_end($2, $5) } ',
        'comment' => '',
        'line' =>
            ' \'=\' remember \';\' FORMRBRACK formstmtseq \';\' \'.\' { if (parser->copline > (line_t)$1) parser->copline = (line_t)$1 $$ = block_end($2, $5) } ',
        'raw_rule' => ' = remember ; FORMRBRACK formstmtseq ; . ',
        'rule'     => '= <remember> ; <FORMRBRACK> <formstmtseq> ; .'
      }
    ],
    'sym'  => 'formblock',
    'type' => 'nonterm'
  },

  'subattrlist' => {
    'rules' => [
      {
        'code'     => '{ $$ = NULL; } ',
        'comment'  => '/* NULL \*\/',
        'line'     => ' /* NULL \*\/ { $$ = NULL; } ',
        'raw_rule' => '  ',
        'rule'     => ''
      },
      {
        'code'     => '{ $$ = $2; } ',
        'comment'  => '',
        'line'     => ' COLONATTR THING { $$ = $2; } ',
        'raw_rule' => ' COLONATTR THING ',
        'rule'     => '<COLONATTR> <THING>'
      },
      {
        'code'     => '{ $$ = NULL; } ',
        'comment'  => '',
        'line'     => ' COLONATTR { $$ = NULL; } ',
        'raw_rule' => ' COLONATTR ',
        'rule'     => '<COLONATTR>'
      }
    ],
    'sym'  => 'subattrlist',
    'type' => 'nonterm'
  },

  'myattrlist' => {
    'rules' => [
      {
        'code'     => '{ $$ = $2; } ',
        'comment'  => '',
        'line'     => ' COLONATTR THING { $$ = $2; } ',
        'raw_rule' => ' COLONATTR THING ',
        'rule'     => '<COLONATTR> <THING>'
      },
      {
        'code'     => '{ $$ = NULL; } ',
        'comment'  => '',
        'line'     => ' COLONATTR { $$ = NULL; } ',
        'raw_rule' => ' COLONATTR ',
        'rule'     => '<COLONATTR>'
      }
    ],
    'sym'  => 'myattrlist',
    'type' => 'nonterm'
  },

  'myattrterm' => {
    'rules' => [
      {
        'code'     => '{ $$ = my_attrs($2,$3); } ',
        'comment'  => '',
        'line'     => ' MY myterm myattrlist { $$ = my_attrs($2,$3); } ',
        'raw_rule' => ' MY myterm myattrlist ',
        'rule'     => '<MY> <myterm> <myattrlist>'
      },
      {
        'code'     => '{ $$ = localize($2,1); } ',
        'comment'  => '',
        'line'     => ' MY myterm { $$ = localize($2,1); } ',
        'raw_rule' => ' MY myterm ',
        'rule'     => '<MY> <myterm>'
      },
      {
        'code'    => '{ $$ = newUNOP(OP_REFGEN, 0, my_attrs($3,$4)); } ',
        'comment' => '',
        'line' =>
            ' MY REFGEN myterm myattrlist { $$ = newUNOP(OP_REFGEN, 0, my_attrs($3,$4)); } ',
        'raw_rule' => ' MY REFGEN myterm myattrlist ',
        'rule'     => '<MY> <REFGEN> <myterm> <myattrlist>'
      }
    ],
    'sym'  => 'myattrterm',
    'type' => 'nonterm'
  },

  'myterm' => {
    'rules' => [
      {
        'code'     => '{ $$ = sawparens($2); } ',
        'comment'  => '',
        'line'     => ' \'(\' expr \')\' { $$ = sawparens($2); } ',
        'raw_rule' => ' ( expr ) ',
        'rule'     => '( <expr> )'
      },
      {
        'code'     => '{ $$ = sawparens(newNULLLIST()); } ',
        'comment'  => '',
        'line'     => ' \'(\' \')\' { $$ = sawparens(newNULLLIST()); } ',
        'raw_rule' => ' ( ) ',
        'rule'     => '( )'
      },
      {
        'code'     => '{ $$ = $1; } ',
        'comment'  => '',
        'line'     => ' scalar %prec \'(\' { $$ = $1; } ',
        'raw_rule' => ' scalar %prec ( ',
        'rule'     => '<scalar> {prec (}'
      },
      {
        'code'     => '{ $$ = $1; } ',
        'comment'  => '',
        'line'     => ' hsh %prec \'(\' { $$ = $1; } ',
        'raw_rule' => ' hsh %prec ( ',
        'rule'     => '<hsh> {prec (}'
      },
      {
        'code'     => '{ $$ = $1; } ',
        'comment'  => '',
        'line'     => ' ary %prec \'(\' { $$ = $1; } ',
        'raw_rule' => ' ary %prec ( ',
        'rule'     => '<ary> {prec (}'
      }
    ],
    'sym'  => 'myterm',
    'type' => 'nonterm'
  },

  'termbinop' => {
    'rules' => [
      {
        'code'    => '{ $$ = newASSIGNOP(OPf_STACKED, $1, $2, $3); } ',
        'comment' => '/* $x = $y, $x += $y \*\/',
        'line' =>
            ' term ASSIGNOP term /* $x = $y, $x += $y \*\/ { $$ = newASSIGNOP(OPf_STACKED, $1, $2, $3); } ',
        'raw_rule' => ' term ASSIGNOP term  ',
        'rule'     => '<term> <ASSIGNOP> <term>'
      },
      {
        'code'    => '{ $$ = newBINOP($2, 0, scalar($1), scalar($3)); } ',
        'comment' => '/* $x ** $y \*\/',
        'line' =>
            ' term POWOP term /* $x ** $y \*\/ { $$ = newBINOP($2, 0, scalar($1), scalar($3)); } ',
        'raw_rule' => ' term POWOP term  ',
        'rule'     => '<term> <POWOP> <term>'
      },
      {
        'code' =>
            '{ if ($2 != OP_REPEAT) scalar($1) $$ = newBINOP($2, 0, $1, scalar($3)) } ',
        'comment' => '/* $x * $y, $x x $y \*\/',
        'line' =>
            ' term MULOP term /* $x * $y, $x x $y \*\/ { if ($2 != OP_REPEAT) scalar($1) $$ = newBINOP($2, 0, $1, scalar($3)) } ',
        'raw_rule' => ' term MULOP term  ',
        'rule'     => '<term> <MULOP> <term>'
      },
      {
        'code'    => '{ $$ = newBINOP($2, 0, scalar($1), scalar($3)); } ',
        'comment' => '/* $x + $y \*\/',
        'line' =>
            ' term ADDOP term /* $x + $y \*\/ { $$ = newBINOP($2, 0, scalar($1), scalar($3)); } ',
        'raw_rule' => ' term ADDOP term  ',
        'rule'     => '<term> <ADDOP> <term>'
      },
      {
        'code'    => '{ $$ = newBINOP($2, 0, scalar($1), scalar($3)); } ',
        'comment' => '/* $x >> $y, $x << $y \*\/',
        'line' =>
            ' term SHIFTOP term /* $x >> $y, $x << $y \*\/ { $$ = newBINOP($2, 0, scalar($1), scalar($3)); } ',
        'raw_rule' => ' term SHIFTOP term  ',
        'rule'     => '<term> <SHIFTOP> <term>'
      },
      {
        'code'    => '{ $$ = $1; } ',
        'comment' => '/* $x > $y, etc. \*\/',
        'line' =>
            ' termrelop %prec PREC_LOW /* $x > $y, etc. \*\/ { $$ = $1; } ',
        'raw_rule' => ' termrelop %prec PREC_LOW  ',
        'rule'     => '<termrelop> {prec PREC_LOW}'
      },
      {
        'code'    => '{ $$ = $1; } ',
        'comment' => '/* $x == $y, $x cmp $y \*\/',
        'line' =>
            ' termeqop %prec PREC_LOW /* $x == $y, $x cmp $y \*\/ { $$ = $1; } ',
        'raw_rule' => ' termeqop %prec PREC_LOW  ',
        'rule'     => '<termeqop> {prec PREC_LOW}'
      },
      {
        'code'    => '{ $$ = newBINOP($2, 0, scalar($1), scalar($3)); } ',
        'comment' => '/* $x & $y \*\/',
        'line' =>
            ' term BITANDOP term /* $x & $y \*\/ { $$ = newBINOP($2, 0, scalar($1), scalar($3)); } ',
        'raw_rule' => ' term BITANDOP term  ',
        'rule'     => '<term> <BITANDOP> <term>'
      },
      {
        'code'    => '{ $$ = newBINOP($2, 0, scalar($1), scalar($3)); } ',
        'comment' => '/* $x | $y \*\/',
        'line' =>
            ' term BITOROP term /* $x | $y \*\/ { $$ = newBINOP($2, 0, scalar($1), scalar($3)); } ',
        'raw_rule' => ' term BITOROP term  ',
        'rule'     => '<term> <BITOROP> <term>'
      },
      {
        'code'    => '{ $$ = newRANGE($2, scalar($1), scalar($3)); } ',
        'comment' => '/* $x..$y, $x...$y \*\/',
        'line' =>
            ' term DOTDOT term /* $x..$y, $x...$y \*\/ { $$ = newRANGE($2, scalar($1), scalar($3)); } ',
        'raw_rule' => ' term DOTDOT term  ',
        'rule'     => '<term> <DOTDOT> <term>'
      },
      {
        'code'    => '{ $$ = newLOGOP(OP_AND, 0, $1, $3); } ',
        'comment' => '/* $x && $y \*\/',
        'line' =>
            ' term ANDAND term /* $x && $y \*\/ { $$ = newLOGOP(OP_AND, 0, $1, $3); } ',
        'raw_rule' => ' term ANDAND term  ',
        'rule'     => '<term> <ANDAND> <term>'
      },
      {
        'code'    => '{ $$ = newLOGOP(OP_OR, 0, $1, $3); } ',
        'comment' => '/* $x || $y \*\/',
        'line' =>
            ' term OROR term /* $x || $y \*\/ { $$ = newLOGOP(OP_OR, 0, $1, $3); } ',
        'raw_rule' => ' term OROR term  ',
        'rule'     => '<term> <OROR> <term>'
      },
      {
        'code'    => '{ $$ = newLOGOP(OP_DOR, 0, $1, $3); } ',
        'comment' => '/* $x // $y \*\/',
        'line' =>
            ' term DORDOR term /* $x // $y \*\/ { $$ = newLOGOP(OP_DOR, 0, $1, $3); } ',
        'raw_rule' => ' term DORDOR term  ',
        'rule'     => '<term> <DORDOR> <term>'
      },
      {
        'code'    => '{ $$ = bind_match($2, $1, $3); } ',
        'comment' => '/* $x =~ /$y/ \*\/',
        'line' =>
            ' term MATCHOP term /* $x =~ /$y/ \*\/ { $$ = bind_match($2, $1, $3); } ',
        'raw_rule' => ' term MATCHOP term  ',
        'rule'     => '<term> <MATCHOP> <term>'
      }
    ],
    'sym'  => 'termbinop',
    'type' => 'nonterm'
  },

  'termunop' => {
    'rules' => [
      {
        'code'    => '{ $$ = newUNOP(OP_NEGATE, 0, scalar($2)); } ',
        'comment' => '/* -$x \*\/',
        'line' =>
            ' \'-\' term %prec UMINUS /* -$x \*\/ { $$ = newUNOP(OP_NEGATE, 0, scalar($2)); } ',
        'raw_rule' => ' - term %prec UMINUS  ',
        'rule'     => '- <term> {prec UMINUS}'
      },
      {
        'code'     => '{ $$ = $2; } ',
        'comment'  => '/* +$x \*\/',
        'line'     => ' \'+\' term %prec UMINUS /* +$x \*\/ { $$ = $2; } ',
        'raw_rule' => ' + term %prec UMINUS  ',
        'rule'     => '+ <term> {prec UMINUS}'
      },
      {
        'code'    => '{ $$ = newUNOP(OP_NOT, 0, scalar($2)); } ',
        'comment' => '/* !$x \*\/',
        'line' =>
            ' \'!\' term /* !$x \*\/ { $$ = newUNOP(OP_NOT, 0, scalar($2)); } ',
        'raw_rule' => ' ! term  ',
        'rule'     => '! <term>'
      },
      {
        'code'    => '{ $$ = newUNOP($1, 0, scalar($2)); } ',
        'comment' => '/* ~$x \*\/',
        'line' =>
            ' \'~\' term /* ~$x \*\/ { $$ = newUNOP($1, 0, scalar($2)); } ',
        'raw_rule' => ' ~ term  ',
        'rule'     => '~ <term>'
      },
      {
        'code' =>
            '{ $$ = newUNOP(OP_POSTINC, 0, op_lvalue(scalar($1), OP_POSTINC)); } ',
        'comment' => '/* $x++ \*\/',
        'line' =>
            ' term POSTINC /* $x++ \*\/ { $$ = newUNOP(OP_POSTINC, 0, op_lvalue(scalar($1), OP_POSTINC)); } ',
        'raw_rule' => ' term POSTINC  ',
        'rule'     => '<term> <POSTINC>'
      },
      {
        'code' =>
            '{ $$ = newUNOP(OP_POSTDEC, 0, op_lvalue(scalar($1), OP_POSTDEC));} ',
        'comment' => '/* $x-- \*\/',
        'line' =>
            ' term POSTDEC /* $x-- \*\/ { $$ = newUNOP(OP_POSTDEC, 0, op_lvalue(scalar($1), OP_POSTDEC));} ',
        'raw_rule' => ' term POSTDEC  ',
        'rule'     => '<term> <POSTDEC>'
      },
      {
        'code' =>
            '{ $$ = op_convert_list(OP_JOIN, 0, op_append_elem( OP_LIST, newSVREF(scalar( newSVOP(OP_CONST,0, newSVpvs("\\"")) )), $1 )) } ',
        'comment' => '/* implicit join after interpolated ->@ \*\/',
        'line' =>
            ' term POSTJOIN /* implicit join after interpolated ->@ \*\/ { $$ = op_convert_list(OP_JOIN, 0, op_append_elem( OP_LIST, newSVREF(scalar( newSVOP(OP_CONST,0, newSVpvs("\\"")) )), $1 )) } ',
        'raw_rule' => ' term POSTJOIN  ',
        'rule'     => '<term> <POSTJOIN>'
      },
      {
        'code' =>
            '{ $$ = newUNOP(OP_PREINC, 0, op_lvalue(scalar($2), OP_PREINC)); } ',
        'comment' => '/* ++$x \*\/',
        'line' =>
            ' PREINC term /* ++$x \*\/ { $$ = newUNOP(OP_PREINC, 0, op_lvalue(scalar($2), OP_PREINC)); } ',
        'raw_rule' => ' PREINC term  ',
        'rule'     => '<PREINC> <term>'
      },
      {
        'code' =>
            '{ $$ = newUNOP(OP_PREDEC, 0, op_lvalue(scalar($2), OP_PREDEC)); } ',
        'comment' => '/* --$x \*\/',
        'line' =>
            ' PREDEC term /* --$x \*\/ { $$ = newUNOP(OP_PREDEC, 0, op_lvalue(scalar($2), OP_PREDEC)); } ',
        'raw_rule' => ' PREDEC term  ',
        'rule'     => '<PREDEC> <term>'
      }
    ],
    'sym'  => 'termunop',
    'type' => 'nonterm'
  },

  'anonymous' => {
    'rules' => [
      {
        'code'     => '{ $$ = newANONLIST($2); } ',
        'comment'  => '',
        'line'     => ' \'[\' expr \']\' { $$ = newANONLIST($2); } ',
        'raw_rule' => ' [ expr ] ',
        'rule'     => '[ <expr> ]'
      },
      {
        'code'     => '{ $$ = newANONLIST(NULL);} ',
        'comment'  => '',
        'line'     => ' \'[\' \']\' { $$ = newANONLIST(NULL);} ',
        'raw_rule' => ' [ ] ',
        'rule'     => '[ ]'
      },
      {
        'code'    => '{ $$ = newANONHASH($2); } ',
        'comment' => '/* { foo => "Bar" } \*\/',
        'line' =>
            ' HASHBRACK expr \';\' \'}\' %prec \'(\' /* { foo => "Bar" } \*\/ { $$ = newANONHASH($2); } ',
        'raw_rule' => ' HASHBRACK expr ; } %prec (  ',
        'rule'     => '<HASHBRACK> <expr> ; } {prec (}'
      },
      {
        'code'    => '{ $$ = newANONHASH(NULL); } ',
        'comment' => '/* { } (\';\' by tokener) \*\/',
        'line' =>
            ' HASHBRACK \';\' \'}\' %prec \'(\' /* { } (\';\' by tokener) \*\/ { $$ = newANONHASH(NULL); } ',
        'raw_rule' => ' HASHBRACK ; } %prec (  ',
        'rule'     => '<HASHBRACK> ; } {prec (}'
      },
      {
        'code' =>
            '{ SvREFCNT_inc_simple_void(PL_compcv) $$ = newANONATTRSUB($2, $3, $4, $5); } ',
        'comment' => '',
        'line' =>
            ' ANONSUB startanonsub proto subattrlist subbody %prec \'(\' { SvREFCNT_inc_simple_void(PL_compcv) $$ = newANONATTRSUB($2, $3, $4, $5); } ',
        'raw_rule' =>
            ' ANONSUB startanonsub proto subattrlist subbody %prec ( ',
        'rule' =>
            '<ANONSUB> <startanonsub> <proto> <subattrlist> <subbody> {prec (}'
      },
      {
        'code' =>
            '{ SvREFCNT_inc_simple_void(PL_compcv) $$ = newANONATTRSUB($2, NULL, $3, $4); } ',
        'comment' => '',
        'line' =>
            ' ANON_SIGSUB startanonsub subattrlist sigsubbody %prec \'(\' { SvREFCNT_inc_simple_void(PL_compcv) $$ = newANONATTRSUB($2, NULL, $3, $4); } ',
        'raw_rule' =>
            ' ANON_SIGSUB startanonsub subattrlist sigsubbody %prec ( ',
        'rule' =>
            '<ANON_SIGSUB> <startanonsub> <subattrlist> <sigsubbody> {prec (}'
      }
    ],
    'sym'  => 'anonymous',
    'type' => 'nonterm'
  },

  'termdo' => {
    'rules' => [
      {
        'code'    => '{ $$ = dofile($2, $1);} ',
        'comment' => '/* do $filename \*\/',
        'line' =>
            ' DO term %prec UNIOP /* do $filename \*\/ { $$ = dofile($2, $1);} ',
        'raw_rule' => ' DO term %prec UNIOP  ',
        'rule'     => '<DO> <term> {prec UNIOP}'
      },
      {
        'code'    => '{ $$ = newUNOP(OP_NULL, OPf_SPECIAL, op_scope($2));} ',
        'comment' => '/* do { code \*\/',
        'line' =>
            ' DO block %prec \'(\' /* do { code \*\/ { $$ = newUNOP(OP_NULL, OPf_SPECIAL, op_scope($2));} ',
        'raw_rule' => ' DO block %prec (  ',
        'rule'     => '<DO> <block> {prec (}'
      }
    ],
    'sym'  => 'termdo',
    'type' => 'nonterm'
  },

  'termrelop' => {
    'rules' => [
      {
        'code'    => '{ $$ = cmpchain_finish($1); } ',
        'comment' => '',
        'line' => ' relopchain %prec PREC_LOW { $$ = cmpchain_finish($1); } ',
        'raw_rule' => ' relopchain %prec PREC_LOW ',
        'rule'     => '<relopchain> {prec PREC_LOW}'
      },
      {
        'code'    => '{ $$ = newBINOP($2, 0, scalar($1), scalar($3)); } ',
        'comment' => '',
        'line' =>
            ' term NCRELOP term { $$ = newBINOP($2, 0, scalar($1), scalar($3)); } ',
        'raw_rule' => ' term NCRELOP term ',
        'rule'     => '<term> <NCRELOP> <term>'
      },
      {
        'code'    => '{ yyerror("syntax error"); YYERROR; } ',
        'comment' => '',
        'line' => ' termrelop NCRELOP { yyerror("syntax error"); YYERROR; } ',
        'raw_rule' => ' termrelop NCRELOP ',
        'rule'     => '<termrelop> <NCRELOP>'
      },
      {
        'code'    => '{ yyerror("syntax error"); YYERROR; } ',
        'comment' => '',
        'line' => ' termrelop CHRELOP { yyerror("syntax error"); YYERROR; } ',
        'raw_rule' => ' termrelop CHRELOP ',
        'rule'     => '<termrelop> <CHRELOP>'
      }
    ],
    'sym'  => 'termrelop',
    'type' => 'nonterm'
  },

  'relopchain' => {
    'rules' => [
      {
        'code'    => '{ $$ = cmpchain_start($2, $1, $3); } ',
        'comment' => '',
        'line' => ' term CHRELOP term { $$ = cmpchain_start($2, $1, $3); } ',
        'raw_rule' => ' term CHRELOP term ',
        'rule'     => '<term> <CHRELOP> <term>'
      },
      {
        'code'    => '{ $$ = cmpchain_extend($2, $1, $3); } ',
        'comment' => '',
        'line' =>
            ' relopchain CHRELOP term { $$ = cmpchain_extend($2, $1, $3); } ',
        'raw_rule' => ' relopchain CHRELOP term ',
        'rule'     => '<relopchain> <CHRELOP> <term>'
      }
    ],
    'sym'  => 'relopchain',
    'type' => 'nonterm'
  },

  'termeqop' => {
    'rules' => [
      {
        'code'    => '{ $$ = cmpchain_finish($1); } ',
        'comment' => '',
        'line' => ' eqopchain %prec PREC_LOW { $$ = cmpchain_finish($1); } ',
        'raw_rule' => ' eqopchain %prec PREC_LOW ',
        'rule'     => '<eqopchain> {prec PREC_LOW}'
      },
      {
        'code'    => '{ $$ = newBINOP($2, 0, scalar($1), scalar($3)); } ',
        'comment' => '',
        'line' =>
            ' term NCEQOP term { $$ = newBINOP($2, 0, scalar($1), scalar($3)); } ',
        'raw_rule' => ' term NCEQOP term ',
        'rule'     => '<term> <NCEQOP> <term>'
      },
      {
        'code'    => '{ yyerror("syntax error"); YYERROR; } ',
        'comment' => '',
        'line' => ' termeqop NCEQOP { yyerror("syntax error"); YYERROR; } ',
        'raw_rule' => ' termeqop NCEQOP ',
        'rule'     => '<termeqop> <NCEQOP>'
      },
      {
        'code'    => '{ yyerror("syntax error"); YYERROR; } ',
        'comment' => '',
        'line' => ' termeqop CHEQOP { yyerror("syntax error"); YYERROR; } ',
        'raw_rule' => ' termeqop CHEQOP ',
        'rule'     => '<termeqop> <CHEQOP>'
      }
    ],
    'sym'  => 'termeqop',
    'type' => 'nonterm'
  },

  'eqopchain' => {
    'rules' => [
      {
        'code'    => '{ $$ = cmpchain_start($2, $1, $3); } ',
        'comment' => '',
        'line' => ' term CHEQOP term { $$ = cmpchain_start($2, $1, $3); } ',
        'raw_rule' => ' term CHEQOP term ',
        'rule'     => '<term> <CHEQOP> <term>'
      },
      {
        'code'    => '{ $$ = cmpchain_extend($2, $1, $3); } ',
        'comment' => '',
        'line' =>
            ' eqopchain CHEQOP term { $$ = cmpchain_extend($2, $1, $3); } ',
        'raw_rule' => ' eqopchain CHEQOP term ',
        'rule'     => '<eqopchain> <CHEQOP> <term>'
      }
    ],
    'sym'  => 'eqopchain',
    'type' => 'nonterm'
  },

  'sigslurpsigil' => {
    'rules' => [
      {
        'code'     => '{ $$ = \'@\'; } ',
        'comment'  => '',
        'line'     => ' \'@\' { $$ = \'@\'; } ',
        'raw_rule' => ' @ ',
        'rule'     => '@'
      },
      {
        'code'     => '{ $$ = \'%\'; } ',
        'comment'  => '/* @, %, @foo, %foo \*\/',
        'line'     => ' \'%\' { $$ = \'%\'; } /* @, %, @foo, %foo \*\/ ',
        'raw_rule' => ' %  ',
        'rule'     => '%'
      }
    ],
    'sym'  => 'sigslurpsigil',
    'type' => 'nonterm'
  },

  'sigvarname' => {
    'rules' => [
      {
        'code'     => '{ parser->in_my = 0; $$ = NULL; } ',
        'comment'  => '/* NULL \*\/',
        'line'     => ' /* NULL \*\/ { parser->in_my = 0; $$ = NULL; } ',
        'raw_rule' => '  ',
        'rule'     => ''
      },
      {
        'code'     => '{ parser->in_my = 0; $$ = $1; } ',
        'comment'  => '',
        'line'     => ' PRIVATEREF { parser->in_my = 0; $$ = $1; } ',
        'raw_rule' => ' PRIVATEREF ',
        'rule'     => '<PRIVATEREF>'
      }
    ],
    'sym'  => 'sigvarname',
    'type' => 'nonterm'
  },

  'sigdefault' => {
    'rules' => [
      {
        'code'     => '{ $$ = NULL; } ',
        'comment'  => '/* NULL \*\/',
        'line'     => ' /* NULL \*\/ { $$ = NULL; } ',
        'raw_rule' => '  ',
        'rule'     => ''
      },
      {
        'code'     => '{ $$ = newOP(OP_NULL, 0); } ',
        'comment'  => '',
        'line'     => ' ASSIGNOP { $$ = newOP(OP_NULL, 0); } ',
        'raw_rule' => ' ASSIGNOP ',
        'rule'     => '<ASSIGNOP>'
      },
      {
        'code' => '{ $$ = $2; } ',
        'comment' =>
            '/* subroutine signature scalar element: e.g. \'$x\', \'$=\', \'$x = $default\' \*\/',
        'line' =>
            ' ASSIGNOP term { $$ = $2; } /* subroutine signature scalar element: e.g. \'$x\', \'$=\', \'$x = $default\' \*\/ ',
        'raw_rule' => ' ASSIGNOP term  ',
        'rule'     => '<ASSIGNOP> <term>'
      }
    ],
    'sym'  => 'sigdefault',
    'type' => 'nonterm'
  },

  'sigscalarelem' => {
    'rules' => [
      {
        'code' =>
            '{ OP *var = $2 OP *defexpr = $3 if (parser->sig_slurpy) yyerror("Slurpy parameter not last") parser->sig_elems++ if (defexpr) { parser->sig_optelems++ if ( defexpr->op_type == OP_NULL && !(defexpr->op_flags & OPf_KIDS)) { / if (var) yyerror("Optional parameter " "lacks default expression") op_free(defexpr) } else { / OP *defop = (OP*)alloc_LOGOP(OP_ARGDEFELEM, defexpr, LINKLIST(defexpr)) / defop->op_targ = (PADOFFSET)(parser->sig_elems - 1) if (var) { var->op_flags |= OPf_STACKED (void)op_sibling_splice(var, NULL, 0, defop) scalar(defop) } else var = newUNOP(OP_NULL, 0, defop) LINKLIST(var) / var->op_next = defop defexpr->op_next = var } } else { if (parser->sig_optelems) yyerror("Mandatory parameter " "follows optional parameter") } $$ = var ? newSTATEOP(0, NULL, var) : NULL } ',
        'comment' =>
            '/* handle \'$=\' special case \*\//* a normal \'=default\' expression \*\//* re-purpose op_targ to hold @_ index \*\//* NB: normally the first child of a * logop is executed before the logop, * and it pushes a boolean result * ready for the logop. For ARGDEFELEM, * the op itself does the boolean * calculation, so set the first op to * it instead. \*\/',
        'line' =>
            ' \'$\' sigvarname sigdefault { OP *var = $2 OP *defexpr = $3 if (parser->sig_slurpy) yyerror("Slurpy parameter not last") parser->sig_elems++ if (defexpr) { parser->sig_optelems++ if ( defexpr->op_type == OP_NULL && !(defexpr->op_flags & OPf_KIDS)) { /* handle \'$=\' special case \*\/ if (var) yyerror("Optional parameter " "lacks default expression") op_free(defexpr) } else { /* a normal \'=default\' expression \*\/ OP *defop = (OP*)alloc_LOGOP(OP_ARGDEFELEM, defexpr, LINKLIST(defexpr)) /* re-purpose op_targ to hold @_ index \*\/ defop->op_targ = (PADOFFSET)(parser->sig_elems - 1) if (var) { var->op_flags |= OPf_STACKED (void)op_sibling_splice(var, NULL, 0, defop) scalar(defop) } else var = newUNOP(OP_NULL, 0, defop) LINKLIST(var) /* NB: normally the first child of a * logop is executed before the logop, * and it pushes a boolean result * ready for the logop. For ARGDEFELEM, * the op itself does the boolean * calculation, so set the first op to * it instead. \*\/ var->op_next = defop defexpr->op_next = var } } else { if (parser->sig_optelems) yyerror("Mandatory parameter " "follows optional parameter") } $$ = var ? newSTATEOP(0, NULL, var) : NULL } ',
        'raw_rule' => ' $ sigvarname sigdefault ',
        'rule'     => '$ <sigvarname> <sigdefault>'
      }
    ],
    'sym'  => 'sigscalarelem',
    'type' => 'nonterm'
  },

  'sigslurpelem' => {
    'rules' => [
      {
        'code' =>
            '{ I32 sigil = $1 OP *var = $2 OP *defexpr = $3 if (parser->sig_slurpy) yyerror("Multiple slurpy parameters not allowed") parser->sig_slurpy = (char)sigil if (defexpr) yyerror("A slurpy parameter may not have " "a default value") $$ = var ? newSTATEOP(0, NULL, var) : NULL } ',
        'comment' => '/* def only to catch errors \*\/',
        'line' =>
            ' sigslurpsigil sigvarname sigdefault/* def only to catch errors \*\/ { I32 sigil = $1 OP *var = $2 OP *defexpr = $3 if (parser->sig_slurpy) yyerror("Multiple slurpy parameters not allowed") parser->sig_slurpy = (char)sigil if (defexpr) yyerror("A slurpy parameter may not have " "a default value") $$ = var ? newSTATEOP(0, NULL, var) : NULL } ',
        'raw_rule' => ' sigslurpsigil sigvarname sigdefault ',
        'rule'     => '<sigslurpsigil> <sigvarname> <sigdefault>'
      }
    ],
    'sym'  => 'sigslurpelem',
    'type' => 'nonterm'
  },

  'sigelem' => {
    'rules' => [
      {
        'code'    => '{ parser->in_my = KEY_sigvar; $$ = $1; } ',
        'comment' => '',
        'line' => ' sigscalarelem { parser->in_my = KEY_sigvar; $$ = $1; } ',
        'raw_rule' => ' sigscalarelem ',
        'rule'     => '<sigscalarelem>'
      },
      {
        'code'    => '{ parser->in_my = KEY_sigvar; $$ = $1; } ',
        'comment' => '',
        'line' => ' sigslurpelem { parser->in_my = KEY_sigvar; $$ = $1; } ',
        'raw_rule' => ' sigslurpelem ',
        'rule'     => '<sigslurpelem>'
      }
    ],
    'sym'  => 'sigelem',
    'type' => 'nonterm'
  },

  'siglist' => {
    'rules' => [
      {
        'code'     => '{ $$ = $1; } ',
        'comment'  => '',
        'line'     => ' siglist \',\' { $$ = $1; } ',
        'raw_rule' => ' siglist , ',
        'rule'     => '<siglist> ,'
      },
      {
        'code'    => '{ $$ = op_append_list(OP_LINESEQ, $1, $3) } ',
        'comment' => '',
        'line' =>
            ' siglist \',\' sigelem { $$ = op_append_list(OP_LINESEQ, $1, $3) } ',
        'raw_rule' => ' siglist , sigelem ',
        'rule'     => '<siglist> , <sigelem>'
      },
      {
        'code'     => '{ $$ = $1; } ',
        'comment'  => '',
        'line'     => ' sigelem %prec PREC_LOW { $$ = $1; } ',
        'raw_rule' => ' sigelem %prec PREC_LOW ',
        'rule'     => '<sigelem> {prec PREC_LOW}'
      }
    ],
    'sym'  => 'siglist',
    'type' => 'nonterm'
  },

  'siglistornull' => {
    'rules' => [
      {
        'code'     => '{ $$ = NULL; } ',
        'comment'  => '/* NULL \*\/',
        'line'     => ' /* NULL \*\/ { $$ = NULL; } ',
        'raw_rule' => '  ',
        'rule'     => ''
      },
      {
        'code'    => '{ $$ = $1; } ',
        'comment' => '/* optional subroutine signature \*\/',
        'line' =>
            ' siglist { $$ = $1; } /* optional subroutine signature \*\/ ',
        'raw_rule' => ' siglist  ',
        'rule'     => '<siglist>'
      }
    ],
    'sym'  => 'siglistornull',
    'type' => 'nonterm'
  },

  'subsigguts' => {
    'rules' => [ qr/(?^ui:subsigguts)/ ],
    'sym'   => 'subsigguts',
    'type'  => 'type'
  },

  'subsignature' => {
    'rules' => [
      {
        'code' =>
            '{ $$ = $2; } { ENTER SAVEIV(parser->sig_elems) SAVEIV(parser->sig_optelems) SAVEI8(parser->sig_slurpy) parser->sig_elems = 0 parser->sig_optelems = 0 parser->sig_slurpy = 0 parser->in_my = KEY_sigvar } { OP *sigops = $2 struct op_argcheck_aux *aux OP *check if (!FEATURE_SIGNATURES_IS_ENABLED) Perl_croak(aTHX_ "Experimental " "subroutine signatures not enabled") / Perl_ck_warner_d(aTHX_ packWARN(WARN_EXPERIMENTAL__SIGNATURES), "The signatures feature is experimental") aux = (struct op_argcheck_aux*) PerlMemShared_malloc( sizeof(struct op_argcheck_aux)) aux->params = parser->sig_elems aux->opt_params = parser->sig_optelems aux->slurpy = parser->sig_slurpy check = newUNOP_AUX(OP_ARGCHECK, 0, NULL, (UNOP_AUX_item *)aux) sigops = op_prepend_elem(OP_LINESEQ, check, sigops) sigops = op_prepend_elem(OP_LINESEQ, newSTATEOP(0, NULL, NULL), sigops) / sigops = op_append_elem(OP_LINESEQ, sigops, newSTATEOP(0, NULL, NULL)) / $$ = newUNOP_AUX(OP_ARGCHECK, 0, sigops, NULL) op_null($$) parser->in_my = 0 / parser->expect = XATTRBLOCK parser->sig_seen = TRUE LEAVE } ',
        'comment' =>
            '/* We shouldn\'t get here otherwise \*\//* a nextstate at the end handles context * correctly for an empty sub body \*\//* wrap the list of arg ops in a NULL aux op. This serves two purposes. First, it makes the arg list a separate subtree from the body of the sub, and secondly the null op may in future be upgraded to an OP_SIGNATURE when implemented. For now leave it as ex-argcheck \*\//* tell the toker that attrributes can follow * this sig, but only so that the toker * can skip through any (illegal) trailing * attribute text then give a useful error * message about "attributes before sig", * rather than falling over ina mess at * unrecognised syntax. \*\/',
        'line' =>
            ' \'(\' subsigguts \')\' { $$ = $2; } subsigguts: { ENTER SAVEIV(parser->sig_elems) SAVEIV(parser->sig_optelems) SAVEI8(parser->sig_slurpy) parser->sig_elems = 0 parser->sig_optelems = 0 parser->sig_slurpy = 0 parser->in_my = KEY_sigvar } siglistornull { OP *sigops = $2 struct op_argcheck_aux *aux OP *check if (!FEATURE_SIGNATURES_IS_ENABLED) Perl_croak(aTHX_ "Experimental " "subroutine signatures not enabled") /* We shouldn\'t get here otherwise \*\/ Perl_ck_warner_d(aTHX_ packWARN(WARN_EXPERIMENTAL__SIGNATURES), "The signatures feature is experimental") aux = (struct op_argcheck_aux*) PerlMemShared_malloc( sizeof(struct op_argcheck_aux)) aux->params = parser->sig_elems aux->opt_params = parser->sig_optelems aux->slurpy = parser->sig_slurpy check = newUNOP_AUX(OP_ARGCHECK, 0, NULL, (UNOP_AUX_item *)aux) sigops = op_prepend_elem(OP_LINESEQ, check, sigops) sigops = op_prepend_elem(OP_LINESEQ, newSTATEOP(0, NULL, NULL), sigops) /* a nextstate at the end handles context * correctly for an empty sub body \*\/ sigops = op_append_elem(OP_LINESEQ, sigops, newSTATEOP(0, NULL, NULL)) /* wrap the list of arg ops in a NULL aux op. This serves two purposes. First, it makes the arg list a separate subtree from the body of the sub, and secondly the null op may in future be upgraded to an OP_SIGNATURE when implemented. For now leave it as ex-argcheck \*\/ $$ = newUNOP_AUX(OP_ARGCHECK, 0, sigops, NULL) op_null($$) parser->in_my = 0 /* tell the toker that attrributes can follow * this sig, but only so that the toker * can skip through any (illegal) trailing * attribute text then give a useful error * message about "attributes before sig", * rather than falling over ina mess at * unrecognised syntax. \*\/ parser->expect = XATTRBLOCK parser->sig_seen = TRUE LEAVE } ',
        'raw_rule' => ' ( subsigguts )  subsigguts:  siglistornull ',
        'rule'     => '( <subsigguts> ) subsigguts: <siglistornull>'
      }
    ],
    'sym'  => 'subsignature',
    'type' => 'nonterm'
  },

  'optsubsignature' => {
    'rules' => [
      {
        'code'     => '{ $$ = NULL; } ',
        'comment'  => '/* NULL \*\/',
        'line'     => ' /* NULL \*\/ { $$ = NULL; } ',
        'raw_rule' => '  ',
        'rule'     => ''
      },
      {
        'code'    => '{ $$ = $1; } ',
        'comment' => '/* Subroutine signature \*\/',
        'line' => ' subsignature { $$ = $1; } /* Subroutine signature \*\/ ',
        'raw_rule' => ' subsignature  ',
        'rule'     => '<subsignature>'
      }
    ],
    'sym'  => 'optsubsignature',
    'type' => 'nonterm'
  },

  'subbody' => {
    'rules' => [
      {
        'code' =>
            '{ if (parser->copline > (line_t)$2) parser->copline = (line_t)$2 $$ = block_end($1, $3) } ',
        'comment' => '',
        'line' =>
            ' remember \'{\' stmtseq \'}\' { if (parser->copline > (line_t)$2) parser->copline = (line_t)$2 $$ = block_end($1, $3) } ',
        'raw_rule' => ' remember { stmtseq } ',
        'rule'     => '<remember> { <stmtseq> }'
      }
    ],
    'sym'  => 'subbody',
    'type' => 'nonterm'
  },

  'optsubbody' => {
    'rules' => [
      {
        'code'     => '{ $$ = $1; } ',
        'comment'  => '',
        'line'     => ' subbody { $$ = $1; } ',
        'raw_rule' => ' subbody ',
        'rule'     => '<subbody>'
      },
      {
        'code'     => '{ $$ = NULL; } ',
        'comment'  => '',
        'line'     => ' \';\' { $$ = NULL; } ',
        'raw_rule' => ' ; ',
        'rule'     => ';'
      }
    ],
    'sym'  => 'optsubbody',
    'type' => 'nonterm'
  },

  'sigsubbody' => {
    'rules' => [
      {
        'code' =>
            '{ if (parser->copline > (line_t)$3) parser->copline = (line_t)$3 $$ = block_end($1, op_append_list(OP_LINESEQ, $2, $4)) } ',
        'comment' => '/* Ordinary expressions; logical combinations \*\/',
        'line' =>
            ' remember optsubsignature \'{\' stmtseq \'}\' { if (parser->copline > (line_t)$3) parser->copline = (line_t)$3 $$ = block_end($1, op_append_list(OP_LINESEQ, $2, $4)) } /* Ordinary expressions; logical combinations \*\/ ',
        'raw_rule' => ' remember optsubsignature { stmtseq }  ',
        'rule'     => '<remember> <optsubsignature> { <stmtseq> }'
      }
    ],
    'sym'  => 'sigsubbody',
    'type' => 'nonterm'
  },

  'optsigsubbody' => {
    'rules' => [
      {
        'code'     => '{ $$ = $1; } ',
        'comment'  => '',
        'line'     => ' sigsubbody { $$ = $1; } ',
        'raw_rule' => ' sigsubbody ',
        'rule'     => '<sigsubbody>'
      },
      {
        'code'    => '{ $$ = NULL; } ',
        'comment' => '/* Subroutine body with optional signature \*\/',
        'line' =>
            ' \';\' { $$ = NULL; } /* Subroutine body with optional signature \*\/ ',
        'raw_rule' => ' ;  ',
        'rule'     => ';'
      }
    ],
    'sym'  => 'optsigsubbody',
    'type' => 'nonterm'
  },

  'formstmtseq' => {
    'rules' => [
      {
        'code'     => '{ $$ = NULL; } ',
        'comment'  => '/* NULL \*\/',
        'line'     => ' /* NULL \*\/ { $$ = NULL; } ',
        'raw_rule' => '  ',
        'rule'     => ''
      },
      {
        'code' =>
            '{ $$ = op_append_list(OP_LINESEQ, $1, $2) PL_pad_reset_pending = TRUE if ($1 && $2) PL_hints |= HINT_BLOCK_SCOPE } ',
        'comment' => '',
        'line' =>
            ' formstmtseq formline { $$ = op_append_list(OP_LINESEQ, $1, $2) PL_pad_reset_pending = TRUE if ($1 && $2) PL_hints |= HINT_BLOCK_SCOPE } ',
        'raw_rule' => ' formstmtseq formline ',
        'rule'     => '<formstmtseq> <formline>'
      }
    ],
    'sym'  => 'formstmtseq',
    'type' => 'nonterm'
  },

  'formline' => {
    'rules' => [
      {
        'code' =>
            '{ OP *list if ($2) { OP *term = $2 list = op_append_elem(OP_LIST, $1, term) } else { list = $1 } if (parser->copline == NOLINE) parser->copline = CopLINE(PL_curcop)-1 else parser->copline-- $$ = newSTATEOP(0, NULL, op_convert_list(OP_FORMLINE, 0, list)) } ',
        'comment' => '',
        'line' =>
            ' THING formarg { OP *list if ($2) { OP *term = $2 list = op_append_elem(OP_LIST, $1, term) } else { list = $1 } if (parser->copline == NOLINE) parser->copline = CopLINE(PL_curcop)-1 else parser->copline-- $$ = newSTATEOP(0, NULL, op_convert_list(OP_FORMLINE, 0, list)) } ',
        'raw_rule' => ' THING formarg ',
        'rule'     => '<THING> <formarg>'
      }
    ],
    'sym'  => 'formline',
    'type' => 'nonterm'
  },

  'formarg' => {
    'rules' => [
      {
        'code'     => '{ $$ = NULL; } ',
        'comment'  => '/* NULL \*\/',
        'line'     => ' /* NULL \*\/ { $$ = NULL; } ',
        'raw_rule' => '  ',
        'rule'     => ''
      },
      {
        'code'    => '{ $$ = op_unscope($2); } ',
        'comment' => '',
        'line' => ' FORMLBRACK stmtseq FORMRBRACK { $$ = op_unscope($2); } ',
        'raw_rule' => ' FORMLBRACK stmtseq FORMRBRACK ',
        'rule'     => '<FORMLBRACK> <stmtseq> <FORMRBRACK>'
      }
    ],
    'sym'  => 'formarg',
    'type' => 'nonterm'
  },

  'PREC_LOW' => {
    'rules' => [ qr/(?^ui:PREC_LOW)/ ],
    'sym'   => 'PREC_LOW',
    'type'  => 'nonassoc'
  },

  'OROP' => {
    'rules' => [ qr/(?^ui:OROP)/ ],
    'sym'   => 'OROP',
    'type'  => 'left'
  },

  'DOROP' => {
    'rules' => [ qr/(?^ui:DOROP)/ ],
    'sym'   => 'DOROP',
    'type'  => 'left'
  },

  'ANDOP' => {
    'rules' => [ qr/(?^ui:ANDOP)/ ],
    'sym'   => 'ANDOP',
    'type'  => 'left'
  },

  'NOTOP' => {
    'rules' => [ qr/(?^ui:NOTOP)/ ],
    'sym'   => 'NOTOP',
    'type'  => 'right'
  },

  ',' => {
    'rules' => [ qr/\,/ ],
    'sym'   => '\',\'',
    'type'  => 'left'
  },

  'ASSIGNOP' => {
    'rules' => [ qr/(?^ui:ASSIGNOP)/ ],
    'sym'   => 'ASSIGNOP',
    'type'  => 'right'
  },

  '?' => {
    'rules' => [ qr/\?/ ],
    'sym'   => '\'?\'',
    'type'  => 'right'
  },

  ':' => {
    'rules' => [ qr/\:/ ],
    'sym'   => '\':\'',
    'type'  => 'right'
  },

  'OROR' => {
    'rules' => [ qr/(?^ui:OROR)/ ],
    'sym'   => 'OROR',
    'type'  => 'left'
  },

  'DORDOR' => {
    'rules' => [ qr/(?^ui:DORDOR)/ ],
    'sym'   => 'DORDOR',
    'type'  => 'left'
  },

  'ANDAND' => {
    'rules' => [ qr/(?^ui:ANDAND)/ ],
    'sym'   => 'ANDAND',
    'type'  => 'left'
  },

  'BITOROP' => {
    'rules' => [ qr/(?^ui:BITOROP)/ ],
    'sym'   => 'BITOROP',
    'type'  => 'left'
  },

  'BITANDOP' => {
    'rules' => [ qr/(?^ui:BITANDOP)/ ],
    'sym'   => 'BITANDOP',
    'type'  => 'left'
  },

  'CHEQOP' => {
    'rules' => [ qr/(?^ui:CHEQOP)/ ],
    'sym'   => 'CHEQOP',
    'type'  => 'left'
  },

  'NCEQOP' => {
    'rules' => [ qr/(?^ui:NCEQOP)/ ],
    'sym'   => 'NCEQOP',
    'type'  => 'left'
  },

  'CHRELOP' => {
    'rules' => [ qr/(?^ui:CHRELOP)/ ],
    'sym'   => 'CHRELOP',
    'type'  => 'left'
  },

  'NCRELOP' => {
    'rules' => [ qr/(?^ui:NCRELOP)/ ],
    'sym'   => 'NCRELOP',
    'type'  => 'left'
  },

  'SHIFTOP' => {
    'rules' => [ qr/(?^ui:SHIFTOP)/ ],
    'sym'   => 'SHIFTOP',
    'type'  => 'left'
  },

  'MATCHOP' => {
    'rules' => [ qr/(?^ui:MATCHOP)/ ],
    'sym'   => 'MATCHOP',
    'type'  => 'left'
  },

  '!' => {
    'rules' => [ qr/\!/ ],
    'sym'   => '\'!\'',
    'type'  => 'right'
  },

  '~' => {
    'rules' => [ qr/\~/ ],
    'sym'   => '\'~\'',
    'type'  => 'right'
  },

  'UMINUS' => {
    'rules' => [ qr/(?^ui:UMINUS)/ ],
    'sym'   => 'UMINUS',
    'type'  => 'right'
  },

  'REFGEN' => {
    'rules' => [ qr/(?^ui:REFGEN)/ ],
    'sym'   => 'REFGEN',
    'type'  => 'right'
  },

  'POWOP' => {
    'rules' => [ qr/(?^ui:POWOP)/ ],
    'sym'   => 'POWOP',
    'type'  => 'right'
  },

  'PREINC' => {
    'rules' => [ qr/(?^ui:PREINC)/ ],
    'sym'   => 'PREINC',
    'type'  => 'nonassoc'
  },

  'PREDEC' => {
    'rules' => [ qr/(?^ui:PREDEC)/ ],
    'sym'   => 'PREDEC',
    'type'  => 'nonassoc'
  },

  'POSTINC' => {
    'rules' => [ qr/(?^ui:POSTINC)/ ],
    'sym'   => 'POSTINC',
    'type'  => 'nonassoc'
  },

  'POSTDEC' => {
    'rules' => [ qr/(?^ui:POSTDEC)/ ],
    'sym'   => 'POSTDEC',
    'type'  => 'nonassoc'
  },

  'POSTJOIN' => {
    'rules' => [ qr/(?^ui:POSTJOIN)/ ],
    'sym'   => 'POSTJOIN',
    'type'  => 'nonassoc'
  },

  'ARROW' => {
    'rules' => [ qr/(?^ui:ARROW)/ ],
    'sym'   => 'ARROW',
    'type'  => 'left'
  },

  ')' => {
    'rules' => [ qr/\)/ ],
    'sym'   => '\')\'',
    'type'  => 'nonassoc'
  },

  '(' => {
    'rules' => [ qr/\(/ ],
    'sym'   => '\'(\'',
    'type'  => 'left'
  },

  'my_refgen' => {
    'rules' => [
      {
        'code'     => '',
        'comment'  => '',
        'line'     => ' MY REFGEN ',
        'raw_rule' => ' MY REFGEN',
        'rule'     => '<MY> <REFGEN>'
      },
      {
        'code'     => '',
        'comment'  => '',
        'line'     => ' REFGEN MY ',
        'raw_rule' => ' REFGEN MY',
        'rule'     => '<REFGEN> <MY>'
      }
    ],
    'sym'  => 'my_refgen',
    'type' => 'nonterm'
  },

};
