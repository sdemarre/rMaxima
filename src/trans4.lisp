;;; -*-  Mode: Lisp; Package: Maxima; Syntax: Common-Lisp; Base: 10 -*- ;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;     The data in this file contains enhancments.                    ;;;;;
;;;                                                                    ;;;;;
;;;  Copyright (c) 1984,1987 by William Schelter,University of Texas   ;;;;;
;;;     All rights reserved                                            ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;       1001 TRANSLATE properties for everyone.                        ;;;
;;;       (c) Copyright 1980 Massachusetts Institute of Technology       ;;;
;;;       Maintained by GJC                                              ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(in-package "MAXIMA")

(macsyma-module trans4)

(TRANSL-MODULE TRANS4)

;;; These are translation properties for various operators.

(DEF%TR MNCTIMES (FORM)
	(SETQ FORM (TR-ARGS (CDR FORM)))
	(COND ((= (LENGTH FORM) 2)
	       `($ANY NCMUL2 . ,FORM))
	      (T
	       `($ANY NCMULN (LIST . ,FORM) NIL))))

(DEF%TR MNCEXPT (FORM)
	`($ANY . (NCPOWER ,@(TR-ARGS (CDR FORM)))))

; maybe this ?
(COMMENT 
(DEFUN STRICT-UNION-MODE-OF-TFORMS (L)
       (DO ((M (CAAR L))
	    (L (CDR L)(CDR L)))
	   ((NULL L) M)
	   (AND (NOT (EQ M (CAAR L))) (RETURN '$ANY))))

(DEFMACRO DEF%MODAL1%TR (NAME ARGS &REST CASES)
	  `(DEF%TR ,NAME (*TR-FORM-ARGUMENT*)
		   (COND ((= (LENGTH *TR-FORM-ARGUMENT*) ,(f1+ (LENGTH ARGS)))
			  (LET* ((*TR-ARGS* (MAPCAR #'TRANSLATE
						    (CDR *TR-FORM-ARGUMENT*)))
				 (*MODE* (STRICT-UNION-MODE-OF-TFORMS  *TR-ARGS*)))
				(SETQ *TR-ARGS* (MAPCAR #'CDR *TR-ARGS*)))))))
				

(DEF-MODAL-TR $BETA (X Y)
	      ($FLOAT (//$ (*$ ($GAMMA X) ($GAMMA Y))
			    ($GAMMA (+$ X Y))))
	      ($NUMBER (QUOTIENT (TIMES ($GAMMA X) ($GAMMA Y))
				  ($GAMMA (PLUS X Y))))
	      ($ANY (SIMPLIFY (LIST '($BETA) X Y))))

(DEF-MODAL-TR $GAMMA (X)
	      ($FLOAT ($GAMMA X))
	      ($ANY (SIMPLIFY ($GAMMA X)))))

;;; end of commented out code.

(DEF%TR $REMAINDER (FORM)
	(let ((n (TR-NARGS-CHECK FORM '(2 . NIL)))
	      (tr-args (mapcar 'translate (cdr form))))
	     (cond ((and (= n 2)
			 (eq (caar tr-args) '$fixnum)
			 (EQ (CAR (CADR TR-ARGS)) '$FIXNUM))
		    `($FIXNUM . (REMAINDER ,(CDR (CAR TR-ARGS))
					   ,(CDR (CADR TR-ARGS)))))
		   (T
		    (CALL-AND-SIMP '$ANY '$REMAINDER (MAPCAR 'CDR TR-ARGS))))))

(DEF%TR $BETA (FORM)
	`($ANY . (SIMPLIFY (LIST '($BETA) ,@(TR-ARGS (CDR FORM))))))

(DEF%TR MFACTORIAL (FORM)
	(SETQ FORM (TRANSLATE (CADR FORM)))
	(COND ((EQ (CAR FORM) '$FIXNUM)
	       `($NUMBER . (FACTORIAL ,(CDR FORM))))
	      (T
	       `($ANY . (SIMPLIFY  `((MFACTORIAL) ,,(CDR FORM)))))))

(DEF%TR %SUM (FORM)
	;; this is WRONG. ---FIX--THIS--YOU--LOSER----*****
	`($ANY . (MEVAL ',FORM)))

(DEF%TR %PRODUCT (FORM)
	`($ANY . (MEVAL ',FORM)))

;(DEF%TR %BINOMIAL (FORM)
;	(TR-NARGS-CHECK FORM '(2 .2))
;	`($ANY . ($BINOMIAL ,@(TR-ARGS (CDR FORM)))))



;; From MATCOM.
;; Temp autoloads needed for pdp-10. There is a better way
;; to distribute this info, too bad I never implemented it.

(MAPC #'(LAMBDA (X)
         (LET ((OLD-PROP (GET (CDR X) 'AUTOLOAD)))
           (IF (NOT (NULL OLD-PROP))
	       (PUTPROP (CAR X) OLD-PROP 'AUTOLOAD))))
      '((PROC-$MATCHDECLARE . $MATCHDECLARE)
	(PROC-$DEFMATCH .     $DEFMATCH)
	(PROC-$DEFRULE . $DEFRULE)
	(PROC-$TELLSIMPAFTER . $TELLSIMPAFTER)
	(PROC-$TELLSIMP	 . $TELLSIMP	)))

(DEFUN YUK-SU-META-PROP (F FORM)
  (LET ((META-PROP-P T)
	(META-PROP-L NIL))
    (FUNCALL F (CDR FORM))
    `($ANY . (PROGN 'compile ,@(MAPCAR #'PATCH-UP-MEVAL-IN-FSET (NREVERSE META-PROP-L))))))

(DEF%TR $MATCHDECLARE (FORM)
  (DO ((L (CDR FORM) (CDDR L))
       (VARS ()))
      ((NULL L)
       `($ANY. (PROGN 'COMPILE
		      ,@(MAPCAR #'(LAMBDA (VAR)
				    (DTRANSLATE `(($DEFINE_VARIABLE)
						  ,VAR
						  ((MQUOTE) ,VAR)
						  $ANY)))
				VARS)
		      ,(DTRANSLATE `((SUB_$MATCHDECLARE) ,@(CDR FORM))))))
    (COND ((ATOM (CAR L))
	   (PUSH (CAR L) VARS))
	  ((EQ (CAAAR L) 'MLIST)
	   (SETQ VARS (APPEND (CDAR L) VARS))))))

(DEF%TR SUB_$MATCHDECLARE (FORM)
  (YUK-SU-META-PROP 'PROC-$MATCHDECLARE `(($MATCHDECLARE) ,@(CDR FORM))))

(DEF%TR $DEFMATCH (FORM)
  (YUK-SU-META-PROP 'PROC-$DEFMATCH FORM))

(DEF%TR $TELLSIMP (FORM)
  (YUK-SU-META-PROP 'PROC-$TELLSIMP FORM))

(DEF%TR $TELLSIMPAFTER (FORM)
  (YUK-SU-META-PROP 'PROC-$TELLSIMPAFTER FORM))

(DEF%TR $DEFRULE (FORM)
  (YUK-SU-META-PROP 'PROC-$DEFRULE FORM))

(DEFUN PATCH-UP-MEVAL-IN-FSET (FORM)
  (COND ((NOT (EQ (CAR FORM) 'FSET))
	 FORM)
	
	(T
	 (TR-FORMAT "~%Translating rule or match ~:M" (CADR (CADR FORM)))
	 (LET ((L (LISP->LISP-TR-LAMBDA (CADR (CADDR FORM)))))
	   (IF (NULL L)
	       FORM
	       `(DEFUN ,(CADR (CADR FORM)) ,@(CDR L)))))))

(DEFVAR LISP->LISP-TR-LAMBDA T)

(DEFUN LISP->LISP-TR-LAMBDA (L)
  ;; basically, a lisp->lisp translation, setting up
  ;; the proper lambda contexts for the special forms,
  ;; and calling TRANSLATE on the "lusers" generated by
  ;; Fateman braindamage, (MEVAL '$A), (MEVAL '(($F) $X)).
  (IF LISP->LISP-TR-LAMBDA
      (CATCH 'LISP->LISP-TR-LAMBDA
	(TR-LISP->LISP L))
      ()))

(DEFUN TR-LISP->LISP (EXP)
  (IF (ATOM EXP)
      (CDR (TRANSLATE-ATOM EXP))
      (LET ((OP (CAR EXP)))
	(IF (SYMBOLP OP)
	    (FUNCALL (OR (GET OP 'TR-LISP->LISP) #'TR-LISP->LISP-DEFAULT)
		     EXP)
	    (PROGN (TR-TELL "Punting: non-symbolic operator")
		   (THROW 'LISP->LISP-TR-LAMBDA ()))))))

(DEFUN TR-LISP->LISP-DEFAULT (EXP)
  (COND ((MACSYMA-SPECIAL-OP-P (CAR EXP))
	 (TR-TELL "Punting: unhandled special operator ~:@M" (CAR EXP))
	 (THROW 'LISP->LISP-TR-LAMBDA ()))
	('ELSE
	 (TR-LISP->LISP-FUN EXP))))

(DEFUN TR-LISP->LISP-FUN (EXP)
  (CONS (CAR EXP) (MAPTR-LISP->LISP (CDR EXP))))

(DEFUN MAPTR-LISP->LISP (L)
  (MAPCAR #'TR-LISP->LISP L))
(DEFUN-prop (declare TR-LISP->LISP) (FORM)
  form)

(DEFUN-prop (LAMBDA TR-LISP->LISP) (FORM)
  (LET (((() ARGLIST . BODY) FORM))
    (MAPC #'TBIND  ARGLIST)
    (SETQ BODY (MAPTR-LISP->LISP BODY))
    `(function (LAMBDA ,(TUNBINDS ARGLIST) ,@BODY))))

(DEFUN-prop (PROG TR-LISP->LISP) (FORM)
  (LET (((() ARGLIST . BODY) FORM))
    (MAPC #'TBIND ARGLIST)
    (SETQ BODY (MAPCAR #'(LAMBDA (X)
			   (IF (ATOM X) X
			       (TR-LISP->LISP X)))
		       BODY))
    `(PROG ,(TUNBINDS ARGLIST) ,@BODY)))

;;(DEFUN RETLIST FEXPR (L)
;;  (CONS '(MLIST SIMP)
;;       (MAPCAR #'(LAMBDA (Z) (LIST '(MEQUAL SIMP) Z (MEVAL Z))) L)))

(DEFUN-prop (RETLIST TR-LISP->LISP) (FORM)
  (PUSH-AUTOLOAD-DEF 'MARRAYREF '(RETLIST_TR))
  `(RETLIST_TR ,@(MAPCAN #'(LAMBDA (Z)
			     (LIST `',Z (TR-LISP->LISP Z)))
			 (CDR FORM))))

(DEFUN-prop (QUOTE TR-LISP->LISP) (FORM) FORM)
(DEFPROP CATCH TR-LISP->LISP-FUN TR-LISP->LISP)
(DEFPROP THROW TR-LISP->LISP-FUN TR-LISP->LISP)
(DEFPROP RETURN TR-LISP->LISP-FUN TR-LISP->LISP)
(DEFPROP FUNCTION TR-LISP->LISP-FUN TR-LISP->LISP)

(DEFUN-prop (SETQ TR-LISP->LISP) (FORM)
  (DO ((L (CDR FORM) (CDDR L))
       (N ()))
      ((NULL L) (CONS 'SETQ (NREVERSE N)))
    (PUSH (CAR L) N)
    (PUSH (TR-LISP->LISP (CADR L)) N)))

(DEFUN-prop (MSETQ TR-LISP->LISP) (FORM)
  (CDR (TRANSLATE `((MSETQ) ,@(CDR FORM)))))

(DEFUN-prop (COND TR-LISP->LISP) (FORM)
  (CONS 'COND (MAPCAR #'MAPTR-LISP->LISP (CDR FORM))))

(DEFPROP NOT TR-LISP->LISP-FUN TR-LISP->LISP)
(DEFPROP AND TR-LISP->LISP-FUN TR-LISP->LISP)
(DEFPROP OR TR-LISP->LISP-FUN TR-LISP->LISP)

(DEFVAR UNBOUND-MEVAL-KLUDGE-FIX T)

(DEFUN-prop (MEVAL TR-LISP->LISP) (FORM)
  (SETQ FORM (CADR FORM))
  (COND ((AND (NOT (ATOM FORM))
	      (EQ (CAR FORM) 'QUOTE))
	 (CDR (TRANSLATE (CADR FORM))))
	(UNBOUND-MEVAL-KLUDGE-FIX
	 ;; only case of unbound MEVAL is in output of DEFMATCH,
	 ;; and appears like a useless double-evaluation of arguments.
	 FORM)
	('ELSE
	 (TR-TELL "Punting: Unbound MEVAL found!")
	 (THROW 'LISP->LISP-TR-LAMBDA ()))))

(DEFUN-prop (IS TR-LISP->LISP) (FORM)
  (SETQ FORM (CADR FORM))
  (COND ((AND (NOT (ATOM FORM))
	      (EQ (CAR FORM) 'QUOTE))
	 (CDR (TRANSLATE `(($IS) ,(CADR FORM)))))
	('ELSE
	 (TR-TELL "Punting: Unbound IS found!")
	 (THROW 'LISP->LISP-TR-LAMBDA ()))))
