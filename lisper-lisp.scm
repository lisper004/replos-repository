;;; lisperlisp.scm
;;; LisperLisp is a Lisp dialect for REPLOS
;; ============================================================
;; 1. DEFIC - definition of SEVERAL functions
;; ============================================================
(define-syntax defic
  (syntax-rules ()
    ((defic ((name) body ...))
     (define (name) body ...))
    ((defic ((name1) body1 ...) ((name2) body2 ...))
     (begin
       (define (name1) body1 ...)
       (define (name2) body2 ...)))))

;; ============================================================
;; 2. DEFUNC — define
;; ============================================================
(define-syntax defunc
  (syntax-rules ()
    ((defunc name () body ...)
     (define (name) body ...))
    ((defunc name (arg ...) body ...)
     (define (name arg ...) body ...))))

;; ============================================================
;; 3. PRINF / PRIN — format, display
;; ============================================================
(define-syntax prinf
  (syntax-rules ()
    ((prinf fmt)
     (simple-format #t fmt))
    ((prinf fmt args ...)
     (simple-format #t fmt args ...))))

(define-syntax prin
  (syntax-rules ()
    ((prin expr)
     (display expr))
    ((prin expr1 expr2 ...)
     (begin
       (display expr1)
       (display expr2)
       ...))))

;; ============================================================
;; 4. SETV / CHAV — vars
;; ============================================================
(define-syntax setv
  (syntax-rules ()
    ((setv name value)
     (define name value))))

(define-syntax chav
  (syntax-rules ()
    ((chav name value)
     (set! name value))))

;; ============================================================
;; 5. COND-EQUAL — like if
;; ============================================================
;;(define-syntax cond-equal
;;  (syntax-rules (== else)
;;    ((cond-equal (== test))
;;     (if test #t #f))
;;    ((cond-equal (== test) then ...)
;;     (if test (begin then ...) #f))
;;    ((cond-equal (== test) then ... else else-body)
;;     (if test (begin then ...) else-body))))
;;
;; ============================================================
;; 6. LOOP
;; ============================================================
(define-syntax loop
  (syntax-rules ()
    ((loop n body ...)
     (let iter ((i 0))
       (when (< i n)
         body ...
         (iter (+ i 1)))))))

;; ============================================================
;; 7. WAIT — pause
;; ============================================================
(define-syntax wait
  (syntax-rules ()
    ((wait seconds)
     (sleep seconds))))

;; ============================================================
;; 8. SPINNER — animation (but not work yet)
;; ============================================================
;; (define-syntax spinner
;;  (syntax-rules ()
;;    ((spinner seconds)
;;     (let ((chars '("|" "/" "-" "\\")))
;;       (do ((i 0 (+ i 1)))
;;           ((>= i seconds))
;;         (for-each (lambda (ch)
;;                     (display ch)
;;                     (flush-all-ports)
;;                     (sleep 0.25)
;;                     (display "\b"))
;;                   chars))))))
;;
;; ============================================================
;; 9. LOOP-WITH — loop with index
;; ============================================================
(define-syntax loop-with
  (syntax-rules ()
    ((loop-with (var n) body ...)
     (let iter ((var 0))
       (when (< var n)
         body ...
         (iter (+ var 1)))))))

;; ============================================================
;; 10. LOOP-OVER — loop through a list
;; ============================================================
(define-syntax loop-over
  (syntax-rules (in)
    ((loop-over var in lst body ...)
     (for-each (lambda (var) body ...) lst))))

;; ============================================================
;; 11. WHILE
;; ============================================================
(define-syntax while
  (syntax-rules ()
    ((while test body ...)
     (let iter ()
       (when test
         body ...
         (iter))))))

;; ============================================================
;; 12. DEFMAC — EASY MACROS
;; ============================================================
(define-syntax defmac
  (syntax-rules ()
    ((defmac name (args ...) body ...)
     (define-syntax name
       (syntax-rules ()
         ((_ args ...)
          (begin body ...)))))))


;; ============================================================
;; PIPE
;; ============================================================
(define-syntax pp
  (syntax-rules ()
    ((pp)
     #t)
    ((pp expr)
     expr)
    ((pp expr1 expr2 ...)
     (let ((result expr1))
       (pp (proc-> result expr2) ...)))))

(define (proc-> input proc)
  (if (procedure? proc)
      (proc input)
      (error ">> pp: expected procedure, got" proc)))

;; ============================================================
;; 13. Welcome message
;; ============================================================

(display "
╔═══════════════════════════════════════════╗
║     LisperLisp v0.2 loaded!               ║
║                                           ║
║  Commands:                                ║
║    (defic ((name) body...))               ║
║    (defunc name (args) body...)           ║
║    (prinf fmt args...)                    ║
║    (prin expr...)                         ║
║    (setv var value) (chav var value)      ║
║    (loop n body...)                       ║
║    (loop-with (i n) body...)              ║
║    (loop-over var in list body...)        ║
║    (while test body...)                   ║
║    (pp (command) (command))               ║
║    (wait seconds)                         ║
╚═══════════════════════════════════════════╝
")
