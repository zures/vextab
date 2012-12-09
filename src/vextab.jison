/*
  LALR(1) Grammar for VexTab
  Mohit Cheppudira <mohit@muthanna.com>

  Process with Jison: http://zaach.github.com/jison/

  Note: This file is new. The current parser in vextab.js is
  a hand-rolled recursive descent parser.
*/

%{
  Vex.L("Starting parser.");
%}

%lex
%s notes
%%

"notes"                        { this.begin('notes'); return 'NOTES'; }
"tabstave"                       return 'TABSTAVE'
<INITIAL>[^\s=]+                 return 'WORD'


"/"                   return '/'
"-"                   return '-'
"+"                   return '+'
":"                   return ':'
"="                   return '='
"("                   return '('
")"                   return ')'
"["                   return '['
"]"                   return ']'
"|"                   return '|'
"."                   return '.'

/* These are valid inside fret/string expressions only */
<notes>[b]            return 'b'
<notes>[s]            return 's'
<notes>[h]            return 'h'
<notes>[p]            return 'p'
<notes>[t]            return 't'
<notes>[q]            return 'q'
<notes>[w]            return 'w'
<notes>[h]            return 'h'
<notes>[d]            return 'd'
<notes>[v]            return 'v'
<notes>[V]            return 'V'
<notes>[0-9]+         return 'NUMBER'

/* New lines reset your state */
[\r\n]+               { this.begin('INITIAL'); }
\s+                   /* skip whitespace */
<<EOF>>               return 'EOF'
.                     return 'INVALID'

/lex

%start e

%%

e:
  maybe_vextab EOF
    {
      console.log($1);
      return $1;
    }
  ;

maybe_vextab
  :
    { $$ = null }
  | vextab
    { $$ = $1 }
  ;

vextab
  : stave
    { $$ = [$1] }
  | vextab stave
    { $$ = [].concat($1, $2) }
  ;

stave
  : TABSTAVE maybe_options maybe_notelist
    { $$ = { element: "stave", options: $2, notes: $3 } }
  ;

maybe_options
  :
    { $$ = null }
  | options
    { $$ = $1 }
  ;

options
  : WORD '=' WORD
    { $$ = [{key: $1, value: $3}] }
  | options WORD '=' WORD
    { $$ = [].concat($1, [{key: $2, value: $4}]) }
  ;

maybe_notelist
  :
    { $$ = null }
  | notelist
    { $$ = $1 }
  ;

notelist
  : NOTES notes
    { $$ = {notes: $2} }
  | notelist NOTES notes
    { $1.notes.concat($3); $$ = $1 }
  ;

notes
  : lingo
    { $$ = $1 }
  | lingo notes
    { $$ = [].concat($1, $2)  }
  | '[' lingo ']'
    { $$ = ["beam_start"].concat($2).concat(["beam_end"]) }
  | '[' lingo ']' notes
    { $$ = ["beam_start"].concat($2).concat(["beam_end"]).concat($4) }
  | '[' lingo notes ']'
    { $$ = ["beam_start"].concat($2).concat($3).concat(["beam_end"]) }
  | '[' lingo notes ']' notes
    { $$ = ["beam_start"].
              concat($2).
              concat($3).
              concat(["beam_end"]).
              concat($5)
    }
  ;

lingo
  : line
    { $$ = $1 }
  | chord
    { $$ = $1 }
  | time
    { $$ = $1 }
  ;

line
  : frets maybe_decorator '/' string
    {
      _.extend(_.last($1), {decorator: $2})
      _.each($1, function(fret) { fret['string'] = $4 })
      $$ = $1
    }
  | '|'
    { $$ = {fret: "b"} }
  ;

chord_line
  : line
    { $$ = [$1] }
  | chord_line '.' line
    { $$ = [].concat($1, $3) }
  ;

chord
  : '(' chord_line ')' maybe_decorator
    { $$ = {line: $2, decorator: $4} }
  | articulation '(' chord_line ')' maybe_decorator
    { $$ = {line: $3, articulation: $1, decorator: $5} }
  ;

frets
  : NUMBER
    { $$ = [{fret: $1}] }
  | articulation timed_fret
    { $$ = [_.extend($2, {articulation: $1})] }
  | frets maybe_decorator articulation timed_fret
    {
      _.extend(_.last($1), {decorator: $2})
      _.extend($4, {articulation: $3})
      $1.push($4)
      $$ = $1
    }
  ;

timed_fret
  : ':' time_values maybe_dot ':' NUMBER
    { $$ = {time: $2, dot: $3, fret: $5}}
  |  NUMBER
    { $$ = {fret: $1} }
  ;

time
  : ':' time_values maybe_dot
    { $$ = {time: $2, dot: $3} }
  ;

time_values
  : NUMBER  { $$ = $1 }
  | 'q'     { $$ = $1 }
  | 'w'     { $$ = $1 }
  | 'h'     { $$ = $1 }
  ;

maybe_dot
  :         { $$ = false }
  | 'd'     { $$ = true }
  ;

string
  : NUMBER
    { $$ = $1 } }
  ;

articulation
  : '-' { $$ = '-' }
  | 's' { $$ = 's' }
  | 't' { $$ = 't' }
  | 'b' { $$ = 'b' }
  | 'h' { $$ = 'h' }
  | 'p' { $$ = 'p' }
  ;

maybe_decorator
  : 'v' { $$ = 'v' }
  | 'V' { $$ = 'V' }
  |     { $$ = null }
  ;