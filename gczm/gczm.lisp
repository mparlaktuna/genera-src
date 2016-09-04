;;; -*- Mode: Lisp; Syntax: ANSI-Common-Lisp; Package: GCZM; Base: 10; Lowercase: Yes -*-

(defpackage gczm
  (:use clim-lisp clim))

(in-package :gczm)

; Douglas P. Fields, Jr. - https://symbolics.lisp.engineer/
;
; GCZM - (Symbolics) Genera CLIM Z-Machine Interpreter
;
; Intended to play Version 3 Z-machine games.
; Written in Symbolics ANSI-Common-Lisp, which is actually not a fully
; ANSI-compliant Common Lisp implementation.

; Our application looks like the following:
;
; +------------------------------+
; | Menu Menu Menu Menu Menu     |
; +-+----------------------------+
; | | Game text scroll window    |
; | | with scrollbar to the left |
; | | ...                        |
; | | > User Commands echoed     |
; | | ...                        |
; +-+----------------------------+
; | > User commands entered      |
; +------------------------------+
; | Status line                  |
; +------------------------------+
;
; In addition,if possible, we will try to update the Genera
; status line as well. Not sure if that's possible in Genera
; CLIM yet.

; Implementation notes:
; (clim:accept 'string)
; If you want to accept any string.
; See docs on :accept-values pane which might be used with the above?
; To make a Genera activity: clim:define-genera-application

; Initial implementation:
; 1. Show some random text
; 2. Accept text
; 3. Put the text in the scrollback
; 4. Go to 1
; 5. Allow user to click "exit" button

(define-application-frame gc-z-machine ()
  ((z-machine :initform nil))

  (:menu-bar nil) ; disable default menu bar and show it in pane explicitly

  (:panes
    (commands  :command-menu) ; This is supplied automatically unless :menu-bar nil
    (display   :application
	       ; :text-style '(:fix :bold :very-large)
	       :display-function 'draw-the-display
               :scroll-bars :vertical
               :initial-cursor-visibility nil)
    (reader    :accept-values
               :display-function '(clim:accept-values-pane-displayer 
                                       :displayer display-reader))
    (statusbar :application
               :display-function 'draw-the-statusbar
               ; TODO: Set the height to one line of characters
	       ; TODO: Set the color to be opposite from main display
               :scroll-bars nil))
  (:command-table (gc-z-machine :inherit-from (clim:accept-values-pane)))
  (:layouts
    (main 
      (vertically () commands display reader statusbar))))

(defmethod draw-the-display ((application gc-z-machine) stream)
  (fresh-line stream)
  (write-string "Genera CLIM Z-Machine Interpreter v0.01" stream))

(defmethod draw-the-statusbar ((application gc-z-machine) stream)
  (write-string "West of House          Turn 3         Score 73" stream))

(defmethod display-reader ((frame gc-z-machine) stream)
  (clim:accept 'string :prompt "> " :stream stream))

(define-gc-z-machine-command (exit :menu t) ()
  (frame-exit *application-frame*))


#||
() ; Necessary so we can do c-sh-E to execute the below
(run-frame-top-level 
  (setq gczm1 (make-application-frame 'gc-z-machine
               :left 100 :right 600 :top 100 :bottom 500)))
||#
