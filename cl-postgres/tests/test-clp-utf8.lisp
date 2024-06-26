;;;; -*- Mode: LISP; Syntax: Ansi-Common-Lisp; Base: 10; Package: CL-POSTGRES-TESTS; -*-
(in-package :cl-postgres-tests)

(def-suite :cl-postgres-clp-utf8
    :description "Test suite for cl-postgres functions in trivial-utf-8.lisp"
    :in :cl-postgres)

(in-suite :cl-postgres-clp-utf8)

;; The following parameters encode "ÄÖÜÈäes8" as utf-8 octets  and utf-16 octets
;; respectively
(defparameter *test-8-octets*
  (make-array 13
              :element-type '(unsigned-byte 8)
              :initial-contents #(195 132 195 150 195 156 195 136 195 164 101 115 56)))
(defparameter *test-16-octets*
  (make-array 16
              :element-type '(unsigned-byte 8)
              :initial-contents #(196 0 214 0 220 0 200 0 228 0 101 0 115 0 56 0)))
(defparameter *test-latin1-octets*
  (make-array 9
              :element-type '(unsigned-byte 8)
              :initial-contents #(196 214 220 200 228 101 115 56 10)))

(test octet-test-1
      (is (equalp
           (clp-utf8::read-utf-8-string
            (trivial-octet-streams:make-octet-input-stream
             *test-8-octets*)
            :stop-at-eof t)
           "ÄÖÜÈäes8"))
      (signals error
               (clp-utf8::read-utf-8-string
                (trivial-octet-streams:make-octet-input-stream
                 *test-16-octets*)
                :stop-at-eof t))
      (signals error
               (clp-utf8::read-utf-8-string
                (trivial-octet-streams:make-octet-input-stream
                 *test-latin1-octets*)
                :stop-at-eof t)))

(test clp1
      (is (equalp (clp-utf8::string-to-utf-8-bytes "twelve")
                  #(116 119 101 108 118 101)))
      (is (equalp (cl-postgres::enc-string-bytes "twelve")
                  #(116 119 101 108 118 101)))
      (is (eql (cl-postgres::enc-byte-length "twelve")
               6))
      (is (equalp (clp-utf8::string-to-utf-8-bytes "twelve" :null-terminate t)
                  #(116 119 101 108 118 101 0)))
      (with-open-file (out "/tmp/data" :direction :output :if-exists :supersede
                                       :element-type '(signed-byte 16))
        (clp-utf8::write-utf-8-bytes "twelve" out))
      (is (equal (with-open-file (in "/tmp/data"  :element-type '(signed-byte 16))
                   (clp-utf8::read-utf-8-string in :stop-at-eof t))
                 "twelve"))
      (is (equal (with-open-file (in "/tmp/data"  :element-type '(signed-byte 16))
                   (clp-utf8::read-utf-8-string in :stop-at-eof t))
                 "twelve"))
      (is (equal (with-open-file (in "/tmp/data"  :element-type '(signed-byte 16))
                   (cl-postgres::enc-read-string in ))
                 "twelve"))
      (with-open-file (out "/tmp/data" :direction :output :if-exists :supersede
                                       :element-type '(signed-byte 16))
        (cl-postgres::enc-write-string "twelve" out :null-terminate t))
      (is (equal (with-open-file (in "/tmp/data"  :element-type '(signed-byte 16))
                   (cl-postgres::enc-read-string in :null-terminated t))
                 "twelve"))
      (is (equal (with-open-file (in "/tmp/data"  :element-type '(signed-byte 16))
                   (cl-postgres::enc-read-string in))
                 "twelve ")))

(test clp-utf8-tests
  (is (equal (clp-utf8::utf-8-bytes-to-string (clp-utf8::string-to-utf-8-bytes "пример"))
             "пример"))
  (is (equalp (clp-utf8::string-to-utf-8-bytes "пример")
             #(208 191 209 128 208 184 208 188 208 181 209 128)))
  (is (equal (clp-utf8::utf-8-string-length (clp-utf8::string-to-utf-8-bytes "twelve"))
             6))
  (is (equal (clp-utf8::utf-8-bytes-to-string #(116 119 101 108 118 101))
             "twelve"))
  (is (equalp (clp-utf8::string-to-utf-8-bytes "tönkösti")
             #(116 195 182 110 107 195 182 115 116 105)))
  (is (equal
       (clp-utf8::utf-8-bytes-to-string (clp-utf8::string-to-utf-8-bytes "tönkösti"))
       "tönkösti"))
  (is (equalp (clp-utf8::string-to-utf-8-bytes "Вас ждет шрифты")
              #(208 146 208 176 209 129 32 208 182 208 180 208 181 209 130 32 209 136 209 128
                208 184 209 132 209 130 209 139)))

  (is (equal (clp-utf8::utf-8-string-length
              (clp-utf8::string-to-utf-8-bytes "пример"))
             6)))
