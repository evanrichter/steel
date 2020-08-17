;; Implementation of a stack in `steel`
;; Returning multiple values requires returning as a list
;; Functional data structure, is definitely verbose but is super helpful
;; Maybe look into using monadic forms in order to not have the verbosity
;; associated with a functional data structure

;; ---------------------------------------------------------------------
;; Make the same stack but instead wrap the list with a struct data type
;;
;; A little bit more boilerplate, but adds some runtime checks for us
;; ---------------------------------------------------------------------

;; destruct works like so:
;; (destruct (a b c) value)
;;  ...
;; (define a (car value))
;; (define b (car (cdr value)))
;; (define c (car (cdr (cdr value))))
(define-syntax destruct
  (syntax-rules ()
    [(destruct (var) ret-value)
     (define var (car ret-value))]
    [(destruct (var1 var2 ...) ret-value)
     (begin (define var1 (car ret-value))
            (destruct (var2 ...) (cdr ret-value)))]))

(define-syntax def-method
  (syntax-rules ()
    [(def-method struct-name (define (a this b ...) body ...))
     (define ((datum->syntax struct-name . a) this b ...)
       (unless ((datum->syntax struct-name ?) this)
         (error! (datum->syntax struct-name . a) "method takes a value of" struct-name "given" this))
       body ...)]))

;; impl block asserts that each function contains the struct type given as the first argument
;; This is why later down we use the thread first vs. the thread last given above
(define-syntax impl
  (syntax-rules ()
    [(impl struct-name (define (a this b ...) body ...) c ...)
     (begin (def-method struct-name (define (a this b ...) body ...))
            (impl struct-name c ...))]
    [(impl struct-name (define (a this b ...) body ...))
     (def-method struct-name (define (a this b ...) body ...))]))


;; There is an issue with unrolling definitions from begins
;; collecting the defines will not work correctly
;; make sure to account for those in the counting

(struct Stack (lst))
(impl Stack
      (define (pop stack)
        (define contents (Stack-lst stack))
        (if (null? contents)
            '(#f '())
            (list (car contents) (cdr contents))))

      (define (push stack value)
        (define contents (Stack-lst stack))
        (Stack (cons value contents))))

(define test-stack (Stack '()))

(destruct (pop-val-test new-stack-test)
          (-> test-stack
               (Stack.push 1)
               (Stack.push 2)
               (Stack.push 3)
               (Stack.push 4)
               (Stack.pop)))

pop-val-test ;; => 4
new-stack-test ;; => '(3 2 1)