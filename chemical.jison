/* description: Parses end executes mathematical expressions. */

/* lexical grammar */
%lex
%%

[0-9]+                return 'COUNT'
[A-Z][a-z]*           return 'ATOM'
'('                   return '('
')'                   return ')'
<<EOF>>               return 'EOF'

/lex

/* operator associations and precedence */

%start expressions

%% /* language grammar */

expressions
    : e EOF
        {return $1;}
    ;

e
  : a COUNT e
        {$$ = [[$1, $2]].concat($3);}
  | a e
        {$$ = [[$1, 1]].concat($2);}
  |
        {$$ = []}

  ;

a
  : ATOM
        {$$ = yytext;}
  | '(' e ')'
        {$$ = $2}
  ;
