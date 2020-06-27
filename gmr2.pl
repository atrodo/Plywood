use v5.28;
my $grammar = {
  '$ws_trim' => sub
  {
    my ($input) = @_;
    $$input =~ m/\G\s*/g;
    warn pos $$input;
    return;
  },

  'NUM' => {
    'rules' => [
      qr/\d+[.]?\d*/,
    ],
    'sym'  => 'NUM',
    'type' => 'token'
  },

  '-' => {
    'rules' => [ qr/\Q-/ ],
    'sym'   => '\'-\'',
    'type'  => 'left'
  },

  '+' => {
    'rules' => [ qr/\Q+/ ],
    'sym'   => '\'+\'',
    'type'  => 'left'
  },

  '*' => {
    'rules' => [ qr/\*/ ],
    'sym'   => '\'*\'',
    'type'  => 'left'
  },

  '/' => {
    'rules' => [ qr[\/] ],
    'sym'   => '\'/\'',
    'type'  => 'left'
  },

  'NEG' => {
    'rules' => [ qr/NEG/ ],
    'sym'   => 'NEG',
    'type'  => 'left'
  },

  '^' => {
    'rules' => [ qr/\^/ ],
    'sym'   => '\'^\'',
    'type'  => 'right'
  },

  'EOL' => {
    'rules' => [ qr/\n|\Z/ ],
  },

  'grammar' => {
    'rules' => [
      {
        'code'     => '',
        'comment'  => '',
        'line'     => ' input ',
        'raw_rule' => ' input',
        'rule'     => '<input>'
      }
    ],
    'sym'  => 'grammar',
    'type' => 'nonterm'
  },

  'input' => {
    'rules' => [
      {
        'code'     => '',
        'comment'  => '/* empty string \*\/',
        'line'     => ' /* empty string \*\/ ',
        'raw_rule' => ' ',
        'rule'     => qr/^$/,
      },
      {
        'code'     => '',
        'comment'  => '',
        'line'     => ' input line ',
        'raw_rule' => ' input line',
        'rule'     => '<input> <line>'
      },
      {
        'code'     => '',
        'comment'  => '',
        'line'     => ' input line ',
        'raw_rule' => ' input line',
        'rule'     => '<line>'
      }
    ],
    'sym'  => 'input',
    'type' => 'nonterm'
  },

  'line' => {
    'rules' => [
      {
        'code'     => '',
        'comment'  => '',
        'line'     => ' \'\\n\' ',
        'raw_rule' => ' n',
        'rule'     => '\n'
      },
      {
        'code'     => '{ printf ("\\t%.10g\\n", $1); } ',
        'comment'  => '',
        'line'     => ' exp \'\\n\' { printf ("\\t%.10g\\n", $1); } ',
        'raw_rule' => ' exp n ',
        'rule'     => '<exp> <EOL>'
      }
    ],
    'sym'  => 'line',
    'type' => 'nonterm'
  },

  'exp' => {
    'rules' => [
      {
        'code'     => '{ $$ = $1; } ',
        'comment'  => '',
        'line'     => ' NUM { $$ = $1; } ',
        'raw_rule' => ' NUM ',
        'rule'     => '<NUM>'
      },
      {
        'code'     => '{ $$ = $1 + $3; } ',
        'comment'  => '',
        'line'     => ' exp \'+\' exp { $$ = $1 + $3; } ',
        'raw_rule' => ' exp + exp ',
        'rule'     => '<exp> + <exp>'
      },
      {
        'code'     => '{ $$ = $1 - $3; } ',
        'comment'  => '',
        'line'     => ' exp \'-\' exp { $$ = $1 - $3; } ',
        'raw_rule' => ' exp - exp ',
        'rule'     => '<exp> - <exp>'
      },
      {
        'code'     => '{ $$ = $1 * $3; } ',
        'comment'  => '',
        'line'     => ' exp \'*\' exp { $$ = $1 * $3; } ',
        'raw_rule' => ' exp * exp ',
        'rule'     => '<exp> * <exp>'
      },
      {
        'code'     => '{ $$ = $1 / $3; } ',
        'comment'  => '',
        'line'     => ' exp \'/\' exp { $$ = $1 / $3; } ',
        'raw_rule' => ' exp / exp ',
        'rule'     => '<exp> / <exp>'
      },
      {
        'code'     => '{ $$ = -$2; } ',
        'comment'  => '',
        'line'     => ' \'-\' exp %prec NEG { $$ = -$2; } ',
        'raw_rule' => ' - exp %prec NEG ',
        'rule'     => '- <exp> {prec NEG}'
      },
      {
        'code'     => '{ $$ = pow ($1, $3); } ',
        'comment'  => '',
        'line'     => ' exp \'^\' exp { $$ = pow ($1, $3); } ',
        'raw_rule' => ' exp ^ exp ',
        'rule'     => '<exp> ^ <exp>'
      },
      {
        'code'     => '{ $$ = $2; } ',
        'comment'  => '',
        'line'     => ' \'(\' exp \')\' { $$ = $2; } ',
        'raw_rule' => ' ( exp ) ',
        'rule'     => '( <exp> )'
      }
    ],
    'sym'  => 'exp',
    'type' => 'nonterm'
  },

};
