#+gcl (allocate 'cons (round (* 800 (/ 2048.0 si::lisp-pagesize))))

;;there is no way this file will run in non common lisps...!!
(pushnew :cl *features*)
;; no cursor positioning.
#+gcl (push :nocp *features*)
 ;; clean up make stuff
(if (find-package "MAKE")
 (sloop::sloop for v in-package 'make do (unintern v)))
 #+gcl (setq si::*top-level-hook* 'user::run)
 (in-package "MAXIMA")

(proclaim '(optimize (safety 0) (speed 3) (space 0)))
 (defun maxima-path (dir file)
   (if (symbolp file) (setq file (stripdollar file)))
   (format nil "~a~a/~a" maxima::*maxima-directory*
	   dir file))
 (load "version.lisp") 
 (load "autol.lisp") 
 (load "max_ext.lisp")



(in-package "MAXIMA")
;
;; the following is just a hack to make the c and d intern
;; as small letters in maxima.
'(|$c| |$d|)

;; make sure these are defined...
(defvar $plot_options '((mlist)
			((mlist) |$x| -3 3)
			((mlist) |$y| -3 3)
			((mlist) $grid 30 30)
			((mlist) $view_direction 1 1 1)
			((mlist) $colour_z nil)
			((mlist) $transform_xy nil)
			((mlist) $run_viewer t)
			((mlist) $plot_format $openmath)
			((mlist) $nticks 100)
			))

(defun set-pathnames ()
  ;; need to get one when were are.
  
  (let* ((tem (system::getenv "MAXIMA_DIRECTORY"))
	 (n (length tem)))
    (setq *maxima-directory* tem)
    (cond ((> n 0)
	   (or (eql (aref tem (- n 1)) #\/)
	       (setq tem (format nil "~a/" tem)))
	   (setq *maxima-directory* tem))
   #+gcl  ((si::set-dir '*maxima-directory* "-dir"))
   #+gcl  (t (setq
	      *maxima-directory*
	      (namestring
	       (truename
		(concatenate 'string
			     (namestring (make-pathname :name nil :defaults
                                   (si::argv 0)))
			     "../"))))))

    (or (boundp 'SYSTEM::*INFO-PATHS*) (setq SYSTEM::*INFO-PATHS* nil) )
    (push  (maxima-path "info" "") SYSTEM::*INFO-PATHS*)
    (setq $file_search_lisp
        (list '(mlist)
              "./###.{o,lsp,lisp}"
             (maxima-path "{src,share1,sym}" "###.o")
	     (maxima-path "{src,share1,sym}" "###.o")
	     (maxima-path "{src,share1}" "###.lisp")
	     (maxima-path "{sym}" "###.lsp")))
    (setq $file_search_maxima
       (list '(mlist)
           "./###.{mc,mac}"
           (maxima-path "{mac,sym}" "###.mac")
	   (maxima-path "{share,share1,share2,tensor}" "###.mc")))
    (setq $file_search_demo (list '(mlist)
               (maxima-path "{demo,share,share1,share2}"
         "###.{dem,dm1,dm2,dm3,dmt}")))
    (setq $file_search_usage (list '(mlist)
               (maxima-path "{demo,share,share1,share2}"
         "###.{usg,texi}")
	       (maxima-path "doc"
			    "###.{mac}")
	       ))
    (setq $chemin
	  (maxima-path "sym" ""))

    ))
(defun user::run ()
  (in-package "MAXIMA")
  (catch 'to-lisp
    (set-pathnames)
    (macsyma-top-level)
  ))
(import 'user::run)
($setup_autoload "eigen.mc" '$eigenvectors '$eigenvalues)
#+gcl
(defun $tkconnect() (si::tkconnect))
(defun $to_lisp ()
  (format t "~%Type (run) to restart~%")
  (throw 'to-lisp t)
  )
(defvar $help "type describe(topic) or example(topic);")
(defun $help() $help);
#+gcl (load "init_max2.lisp")


  
