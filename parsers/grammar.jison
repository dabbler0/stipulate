/* description: Parses end executes mathematical expressions. */

/* lexical grammar */
%lex
%%

\s+                   /* skip whitespace */
"\""[^}]*"\""           return 'STRING'
[0-9]+("."[0-9]*)?("e""-"?[0-9]+)? return 'NUMBER'
"solve"               return 'SOLVE'
[\w\\]+               return 'VARIABLE'
"*"                   return '*'
"/"                   return '/'
"-"                   return '-'
"+"                   return '+'
"^"                   return '^'
"("                   return '('
")"                   return ')'
"="                   return '='
":"                   return ':'
"<"                   return '<'
">"                   return '>'
<<EOF>>               return 'EOF'
.                     return 'INVALID'

/lex

/* operator associations and precedence */

%left '='
%left '+' '-'
%left UNIT
%left '*', '/'
%left '^'
%left UMINUS

%start expressions

%% /* language grammar */

expressions
    : e EOF
        {return $1;}

    | SOLVE '(' u ')' VARIABLE ':' e '=' e EOF
        {return ['SOLVE', $5, -1e10, 1e10, $4, $6, $3];}
    | SOLVE '(' u ')' NUMBER '<' VARIABLE '<' NUMBER ':' e '=' e EOF
        {return ['SOLVE', $7, $5, $9, $11, $13, $3];}
    | SOLVE '(' u ')' VARIABLE '<' NUMBER ':' e '=' e EOF
        {return ['SOLVE', $5, -1e10, $7, $9, $11, $3];}
    | SOLVE '(' u ')' NUMBER '<' VARIABLE ':' e '=' e EOF
        {return ['SOLVE', $7, $5, 1e10, $9, $11, $3];}

    | SOLVE VARIABLE ':' e '=' e EOF
        {return ['SOLVE', $2, -1e10, 1e10, $4, $6, null];}
    | SOLVE NUMBER '<' VARIABLE '<' NUMBER ':' e '=' e EOF
        {return ['SOLVE', $4, $2, $6, $8, $10, null];}
    | SOLVE VARIABLE '<' NUMBER ':' e '=' e EOF
        {return ['SOLVE', $2, -1e10, $4, $6, $8, null];}
    | SOLVE NUMBER '<' VARIABLE ':' e '=' e EOF
        {return ['SOLVE', $4, $2, 1e10, $6, $8, null];}

    | SET_UNITS UNIT*
        {return ['SET_UNITS', $1]}

    | VARIABLE '=' e EOF
        {return ['ASSIGN', $1, $3]}
    ;

e
    : e '+' e
        {$$ = ["+",$1,$3];}
    | e '-' e
        {$$ = ["-",$1,$3];}
    | e '*' e
        {$$ = ["*",$1,$3];}
    | e '/' e
        {$$ = ["/",$1,$3];}
    | e '^' e
        {$$ = ["^",$1,$3];}
    | '-' e %prec UMINUS
        {$$ = ["UMINUS",$2];}
    | '(' e ')'
        {$$ = ["PARENS", $2];}
    | VARIABLE '(' e ')'
        {$$ = ["CALL", $1, $3];}
    | NUMBER u %prec UNIT
        {$$ = ["UNIT", $1, $2];}
    | STRING
        {$$ = ["STRING", yytext];}
    | VARIABLE
        {$$ = ["VARIABLE", yytext];}
    | NUMBER
        {$$ = ["UNIT", yytext, [null, null]];}
    ;

u   
    : a '/' a %prec UNIT
        {$$ = [$1, $3]}
    | a %prec UNIT
        {$$ = [$1, null]}
    ;

a
    : x a %prec UNIT
        {$$ = [$1].concat($2);}
    | x %prec UNIT
        {$$ = [$1];}
    ;
x
    : VARIABLE '^' NUMBER %prec UNIT
        {$$ = [$1, $3];}
    | VARIABLE %prec UNIT
        {$$ = [$1, 1];}
    ;
