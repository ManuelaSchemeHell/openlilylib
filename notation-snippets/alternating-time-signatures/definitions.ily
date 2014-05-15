\version "2.18.2"

\include "../../general-tools/lilypond-version-predicates/definitions.ily"

\header {
  snippet-title = "Print (irregularly) changing meters"
  snippet-author = "Urs Liska"
  snippet-description = \markup {
    This snippet allows you to print a list of time signatures
    indicating (irregularly) changing meters.
  }
  % add comma-separated tags to make searching more effective:
  tags = "polymetrics, time signature"
  % is this snippet ready?  See meta/status-values.md
  status = "unfinished, buggy"


  %{
    TODO:
    - Complete documentation
  %}
}

%%%%%%%%%%%%%%%%%%%%%%%%%%
% here goes the snippet: %
%%%%%%%%%%%%%%%%%%%%%%%%%%

% This is the core function that should go into LilyPond
% It's recommended in Behind Bars to use hyphen
% between time signatures for irregular alternation,
% but we want that to be optional
%
% For LilyPond versions before 2.19.7 the function fractionList
% is defined, for later versions the built-in function is used
fractionList =
#(if (lilypond-less-than? '(2 19 7))
     (define-scheme-function (parser location timesigs) (list?)
       (_i "A list of time signature markups to override TimeSignature.stencil with
in order to indicate irregularly changing meters.  If the first list element is
#t then hyphens are printed between the time signatures.")
       (let* ((hyphen (and (boolean? (car timesigs))
                           (car timesigs)))         ;; #t if the first list element is #t
              (used-signatures
               (if hyphen
                   (cdr timesigs)
                   timesigs)))                      ;; timesigs stripped of a possible boolean
         (if (memv #f (map (lambda sig           ;; check for well-formed timesig lists
                             (and (list? (car sig))
                                  (= 2 (length (car sig))))) used-signatures))
              (ly:input-message location (_i "Error in \\fractionList.
 Please use time signatures with two elements."))
             (lambda (grob)
               (grob-interpret-markup grob
                 #{
                   \markup \override #'(baseline-skip . 0)
                   \number
                   #(map (lambda (x)
                           #{ \markup {
                             \center-column #(map number->string x)
                             #(if hyphen
                                  (if (eq? x (last timesigs))
                                      ""
                                      (markup
                                       #:line
                                       (#:hspace -0.25
                                         (#:override
                                          (cons (quote thickness) 3.4)
                                          (#:draw-line (cons 0.9 0)))
                                         #:hspace -0.15)))
                                  "")
                              }
                           #}) used-signatures)
                 #}))
             )))
     fractionList)

% This is a function to make it more accessible in standard cases
alternatingTimeSignatures =
#(define-music-function (parser location timesigs) (list?)
   (let* ((hyphen (and (boolean? (car timesigs))
                       (car timesigs)))         ;; #t if the first list element is #t
          (used-signatures (if hyphen
                               (cdr timesigs)
                               timesigs))
          (first-effective-timesig
           (cons
            (caar used-signatures)
            (cadar used-signatures))))
     #{
       \once \override Score.TimeSignature.stencil = \fractionList #timesigs
       \time #first-effective-timesig
     #}))
