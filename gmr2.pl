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
        'comment'  => '/* empty string \*\/',
        'line'     => ' /* empty string \*\/ ',
        'raw_rule' => ' ',
        'rule'     => qr/^$/,
      },
      {
        'comment'  => '',
        'line'     => ' input line ',
        'raw_rule' => ' input line',
        'rule'     => '<input> <line>'
      },
      {
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
        'comment'  => '',
        'line'     => ' \'\\n\' ',
        'raw_rule' => ' n',
        'rule'     => '\n'
      },
      {
        'code'     => sub { printf ("\t%.10f\n", $_[0]); },
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
        'code'     => sub { $_[0]; },
        'comment'  => '',
        'line'     => ' NUM { $$ = $1; } ',
        'raw_rule' => ' NUM ',
        'rule'     => '<NUM>'
      },
      {
        'code'     => sub { $_[0] + $_[2] },
        'comment'  => '',
        'line'     => ' exp \'+\' exp { $$ = $1 + $3; } ',
        'raw_rule' => ' exp + exp ',
        'rule'     => '<exp> + <exp>'
      },
      {
        'code'     => sub { $_[0] - $_[2]; },
        'comment'  => '',
        'line'     => ' exp \'-\' exp { $$ = $1 - $3; } ',
        'raw_rule' => ' exp - exp ',
        'rule'     => '<exp> - <exp>'
      },
      {
        'code'     => sub { $_[0] * $_[2] },
        'comment'  => '',
        'line'     => ' exp \'*\' exp { $$ = $1 * $3; } ',
        'raw_rule' => ' exp * exp ',
        'rule'     => '<exp> * <exp>'
      },
      {
        'code'     => sub { $_[0] / $_[2] },
        'comment'  => '',
        'line'     => ' exp \'/\' exp { $$ = $1 / $3; } ',
        'raw_rule' => ' exp / exp ',
        'rule'     => '<exp> / <exp>'
      },
      {
        'code'     => sub { -$_[1] },
        'comment'  => '',
        'line'     => ' \'-\' exp %prec NEG { $$ = -$2; } ',
        'raw_rule' => ' - exp %prec NEG ',
        'rule'     => '- <exp> {prec NEG}'
      },
      {
        'code'     => sub { $_[0] ** $_[2] },
        'comment'  => '',
        'line'     => ' exp \'^\' exp { $$ = pow ($1, $3); } ',
        'raw_rule' => ' exp ^ exp ',
        'rule'     => '<exp> ^ <exp>'
      },
      {
        'code'     => sub { $_[1] },
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
