/* description: Parses end executes mathematical expressions. */

/* lexical grammar */
%lex
%%

\s+                   /* skip whitespace */
[0-9]+("."[0-9]+)?    return 'NUMBER'
\w+                   return 'VARIABLE'
"/"                   return '/'
"^"                   return '^'
'='                   return '='
<<EOF>>               return 'EOF'
.                     return 'INVALID'

/lex

/* operator associations and precedence */

%left TIMES
%left '/'
%left '^'
%left UMINUS

%start expressions

%% /* language grammar */

expressions
    : VARIABLE '=' NUMBER e EOF
        {return [$1, $3, $4];}
    ;

e
    : a '/' a
        {$$ = [$1, $3];}
    | a
        {$$ = [$1, null];}
    ;
a
    : x a %prec TIMES
        {$$ = [$1].concat($2);}
    | x
        {$$ = [$1]}
    ;
x
    : VARIABLE '^' NUMBER
        {$$ = [$1, $3];}
    | VARIABLE
        {$$ = [yytext, 1];}
    ;
