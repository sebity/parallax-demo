;;;; parallax-demo.asd

(asdf:defsystem #:parallax-demo
  :description "A Parallax Scrolling demo"
  :author "Jan Tatham <jan@sebity.com>"
  :license "GPL v2"
  :depends-on (#:lispbuilder-sdl)
  :serial t
  :components ((:file "package")
               (:file "parallax-demo")))

