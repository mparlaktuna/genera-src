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
;
; We have our own package, GCZM, to avoid naming conflicts with our (CLIM) commands.

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
; | Status line                  |
; +------------------------------+
;
; In addition,if possible, we will try to update the Genera
; status line as well. Not sure if that's possible in Genera
; CLIM yet. (Later note: There are CLIM panes that mimic the
; Genera description pane and such that can be used.)

; Implementation notes:
; (clim:accept 'string)
; If you want to accept any string.
; See docs on :accept-values pane which might be used with the above?
; To make a Genera activity: clim:define-genera-application
; To control the application frame REPL, try: clim:default-frame-top-level
;   which has command parsers, unparsers, partial parsers, and a prompt

; To have command accelerators work, you need to specialize clim:read-frame-command.
; See below.

; Read documentation "Output Recording in CLIM".

; Initial implementation:
; 1. Show some random text
; 2. Accept text
; 3. Put the text in the scrollback
; 4. Go to 1
; 5. Allow user to click "exit" button

; Functions so we can see what's going on afterwards or in the Lisp Listener
(defparameter *log* ())
(defun addlog (message)
  (setf *log* (cons message *log*)))

; Custom command parser
; Just accept a string, and return the "Got an input" command
(defun gczm-cl-command-parser (command-table stream)
  (declare (ignore command-table stream))
  (let ((result (accept 'string)))
    (addlog (list "Got" result))
    (list 'com-input result)))

; Main application frame
; TODO: Figure out how to send initial output to the interactor prior to
; accepting the first command
(define-application-frame gc-z-machine ()
  ((z-machine :initform nil))

  ; Instead of a custom top-level, let's just have a custom read-frame-command
  ;(:top-level (clim:default-frame-top-level :prompt "> "
  ;		:command-parser gczm-cl-command-parser))

  (:menu-bar nil) ; disable default menu bar and show it in pane explicitly

  (:panes
    (commands  :command-menu) ; This is supplied automatically unless :menu-bar nil
    (display   :interactor
	       ; :text-style '(:fix :bold :very-large)
               :scroll-bars :vertical
               :initial-cursor-visibility :on)
    (statusbar :application
               :display-function 'draw-the-statusbar
               ; TODO: Set the height to one line of characters - clim:text-size,
	       ;       clim:stream-line-height
	       ; TODO: Set the color to be opposite from main display
               :scroll-bars nil))

  ; Default command table will be named gc-z-machine-command-table
  ; Commands are symbols, conventionally starting with com-
  ; (:command-table (gc-z-machine :inherit-from (clim:accept-values-pane)))

  (:layouts
    (main 
      (vertically () commands display statusbar))))

; Enable Keystroke Accelerators (hotkeys) - per Genera CLIM 2.0 Docs
; clim:read-command-using-keystrokes could have overrides for the
; :command-parser, :command-unparser and :partial-command-parser
(defmethod clim:read-frame-command ((frame gc-z-machine) &key)
  (let ((command-table (clim:find-command-table 'gc-z-machine)))
    (clim:with-command-table-keystrokes (keystrokes command-table)
      (clim:read-command-using-keystrokes command-table keystrokes))))

; Custom command reader which accepts any string
(defmethod read-frame-command ((frame gc-z-machine) &key (stream *standard-input*))
  "Specialized for GCZM, just reads a string and returns it with com-input"
  (multiple-value-bind (astring thetype)
      ; Accept returns the object and the type
      (accept 'string :stream stream :prompt nil
                      :default "" :default-type 'string)
    (declare (ignore thetype))
    ; Now that we have astring & thetype, return our command
    (list 'com-input astring)))   

; We need to figure out how to just append stuff to this each time
; rather than constantly redrawing the whole thing.
(defmethod draw-the-display ((application gc-z-machine) stream)
  (fresh-line stream)
  (write-string "Genera CLIM Z-Machine Interpreter v0.01" stream)
  (dolist (ll (reverse *log*))
    (fresh-line stream)
    (format stream "~A" ll)))

(defmethod draw-the-statusbar ((application gc-z-machine) stream)
  (write-string "West of House          Turn 3         Score 73" stream))

(define-gc-z-machine-command (com-exit :menu t       ; Show in menu
                                       :keystroke (:q :meta)
                                       :name "Exit") ; Type "Exit" to quit application
                             ()
  (frame-exit *application-frame*))

; If we get input from the command line processor, this is it...
(define-gc-z-machine-command (com-input) ((astring 'string))
  ; First, write to our interactor
  (fresh-line *standard-output*)
  (write-string "Got: " *standard-output*)
  (write-string astring *standard-output*)
  (fresh-line *standard-output*)
  ; Then store this permanently for debugging
  (addlog (list "Called com-input with" astring))
  astring)

#||
() ; Necessary so we can do c-sh-E to execute the below
(run-frame-top-level 
  (setq gczm1 (make-application-frame 'gc-z-machine
               :left 100 :right 600 :top 100 :bottom 500)))
||#
