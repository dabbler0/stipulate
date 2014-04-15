/* description: Parses end executes mathematical expressions. */

/* lexical grammar */
%lex
%%

\s+                   /* skip whitespace */
"{"[^}]*"}"           return 'CHEMICAL'
/* [0-9]+("."[0-9]+)?("e""-"?[0-9]+)?(" "[\w\/\^]+)?  return 'NUMBER' */
[0-9]+("."[0-9]+)?("e""-"?[0-9]+)? return 'NUMBER'
\w+                   return 'VARIABLE'
"*"                   return '*'
"/"                   return '/'
"-"                   return '-'
"+"                   return '+'
"^"                   return '^'
"("                   return '('
")"                   return ')'
":"                   return ":"
<<EOF>>               return 'EOF'
.                     return 'INVALID'

/lex

/* operator associations and precedence */

%left '+' '-'
%left '*' '/'
%left '^'
%left UMINUS
%right ":"

%start expressions

%% /* language grammar */

expressions
    : e EOF
        {return $1;}
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
    | e ":" e
        {$$ = [":", $1, $3];}
    | '(' e ')'
        {$$ = ["PARENS", $2];}
    | VARIABLE '(' e ')'
        {$$ = ['call', $1, $3];}
    | CHEMICAL
        {$$ = yytext;}
    | VARIABLE
        {$$ = yytext;}
    | NUMBER
        {$$ = Number(yytext);}
    ;
