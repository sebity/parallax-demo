;;;; parallax-demo.lisp

(in-package #:parallax-demo)

;;;;;;;;;;;;;;;;;;;;;;;; CONFIG/PRESETS ;;;;;;;;;;;;;;;;;;;;;;;;

(defparameter *data-root* (asdf:system-source-directory 'parallax-demo))
(defparameter *gfx-root* (merge-pathnames "gfx/" *data-root*))

;;;; Game Params
(defparameter *game-width* 800)
(defparameter *game-height* 600)
(defparameter *game-ticks* 0)

(defparameter *pause* nil)

(defparameter *max-speed* 20)

(defparameter *car* nil) ; width 200
(defparameter *road* nil) ; width 1190
(defparameter *mountain-front* nil) ; width 1190
(defparameter *mountain-behind* nil) ; width 1190
(defparameter *tree* nil)

(defparameter *cells* nil)
(defparameter *ss-car* nil)

;;;; GFX Params
(defparameter *gfx-ss-car* (merge-pathnames "cars.png" *gfx-root*))
(defparameter *gfx-road* (merge-pathnames "road.png" *gfx-root*))
(defparameter *gfx-mountain-front* (merge-pathnames "mountain1.png" *gfx-root*))
(defparameter *gfx-mountain-behind* (merge-pathnames "mountain2.png" *gfx-root*))
(defparameter *gfx-tree* (merge-pathnames "tree.png" *gfx-root*))

;;;;;;;;;;;;;;;;;;;;;;;; STRUCTS ;;;;;;;;;;;;;;;;;;;;;;;;

(defstruct the-car
  (x 0)
  (y 0)
  (vx 0))

(defstruct road
  (x 0)
  (y 0))

(defstruct mountain
  (x 0)
  (y 0))

(defstruct the-tree
  (x 0)
  (y 0))

;;;;;;;;;;;;;;;;;;;;;;;; SLIME ;;;;;;;;;;;;;;;;;;;;;;;;


;;;; CONTINUABLE macro

(defmacro continuable (&body body)
  `(restart-case
       (progn ,@body)
     (continue () :report "Continue")))


;;;; UPDATE-SWANK function

(defun update-swank ()
  (continuable
   (let ((connection (or swank::*emacs-connection*
			 (swank::default-connection))))
     (when connection
       (swank::handle-requests connection t)))))



;;;;;;;;;;;;;;;;;;;;;;;; CAR ;;;;;;;;;;;;;;;;;;;;;;;;

;;;; CREATE-CAR function

(defun create-car ()
  (setf *car* (make-the-car :x 300 :y 300 :vx 0)))


;;;; DISPLAY-CAR function

(defun display-car (c)
  (sdl:draw-surface-at-* *ss-car* (the-car-x c) (the-car-y c) 
			       :cell (floor (mod *game-ticks* 19) 4)))


;;;; MOVE-CAR function

(defun move-car (c speed)
  (cond ((equal speed 'accelerate) (unless (= (the-car-vx c) *max-speed*)
				     (setf (the-car-vx c) (+ (the-car-vx c) 2))))

	((equal speed 'decelerate) (unless (zerop (the-car-vx c))
				     (setf (the-car-vx c) (- (the-car-vx c) 2))))))


;;;; UPDATE-CAR function
(defun update-car (c)
  (setf (the-car-x c) (+ (the-car-x c) (the-car-vx c))))


;;;;;;;;;;;;;;;;;;;;;;;; TREE ;;;;;;;;;;;;;;;;;;;;;;;;

;;;; CREATE-TREE function

(defun create-tree ()
  (setf *tree* (make-the-tree :x 900 :y -100)))


;;;; DISPLAY-TREE function

(defun display-tree (tr)
  (sdl:draw-surface-at-* (sdl:load-image *gfx-tree* :alpha 255) (the-tree-x tr) (the-tree-y tr)))

;;;; UPDATE-TREE function

(defun update-tree (c tr)
  (setf (the-tree-x tr) (- (the-tree-x tr) (* (the-car-vx c) 4)))
  (determine-repeat-tree tr))


;;;; DETERMINE-REPEAT-TREE function

(defun determine-repeat-tree (tr)
  (when (< (the-tree-x tr) -900)
    (setf (the-tree-x tr) 900)))

;;;;;;;;;;;;;;;;;;;;;;;; ROAD ;;;;;;;;;;;;;;;;;;;;;;;;

;;;; CREATE-ROAD function

(defun create-road ()
  (push (make-road :x 0 :y 350) *road*)
  (push (make-road :x 1190 :y 350) *road*))


;;;; DISPLAY-ROAD function

(defun display-road (roads)
  (dolist (r roads)
    (sdl:draw-surface-at-* (sdl:load-image *gfx-road* :alpha 255) (road-x r) (road-y r))))


;;;; UPDATE-ROAD function

(defun update-road (c roads)
  (dolist (r roads)
    (setf (road-x r) (- (road-x r) (the-car-vx c))))
  (determine-furthest-road))


;;;; DETERMINE-FURTHEST-ROAD function

(defun determine-furthest-road ()
  (let ((road-1 (road-x (first *road*)))
	(road-2 (road-x (second *road*))))
    (when (< road-1 -1300)
	(setf (road-x (first *road*)) (+ road-2 1190)))
    (when (< road-2 -1300)	
      (setf (road-x (second *road*)) (+ road-1 1190)))))


;;;;;;;;;;;;;;;;;;;;;;;; MOUNTIAN ;;;;;;;;;;;;;;;;;;;;;;;;

;;;; CREATE-MOUNTAIN function

(defun create-mountain ()
  ; Front Mountain
  (push (make-mountain :x 0 :y 0) *mountain-front*)
  (push (make-mountain :x 1180 :y 0) *mountain-front*)

  ; Behind Mountain
  (push (make-mountain :x 0 :y -50) *mountain-behind*)
  (push (make-mountain :x 1190 :y -50) *mountain-behind*))


;;;; DISPLAY-MOUNTAINS function

(defun display-mountains ()
  (dolist (m *mountain-behind*)
    (sdl:draw-surface-at-* (sdl:load-image *gfx-mountain-behind* :alpha 255) 
			   (mountain-x m) (mountain-y m)))
  (dolist (m *mountain-front*)
    (sdl:draw-surface-at-* (sdl:load-image *gfx-mountain-front* :alpha 255) 
			   (mountain-x m) (mountain-y m))))


;;;; UPDATE-MOUNTAINS function

(defun update-mountains (c)
  (dolist (m *mountain-front*)
    (setf (mountain-x m) (- (mountain-x m) (the-car-vx c))))

  (dolist (m *mountain-behind*)
    (setf (mountain-x m) (- (mountain-x m) (floor (the-car-vx c) 3))))

  (determine-furthest-mountain))


;;;; DETERMINE-FURTHEST-MOUNTAIN function

(defun determine-furthest-mountain ()
  (let ((mountain-1 (mountain-x (first *mountain-front*)))
	(mountain-2 (mountain-x (second *mountain-front*)))
	(mountain-3 (mountain-x (first *mountain-behind*)))
	(mountain-4 (mountain-x (second *mountain-behind*))))

    (when (< mountain-1 -1300)
      (setf (mountain-x (first *mountain-front*)) (+ mountain-2 1180)))
    (when (< mountain-2 -1300)
      (setf (mountain-x (second *mountain-front*)) (+ mountain-1 1180)))

    (when (< mountain-3 -1300)
      (setf (mountain-x (first *mountain-behind*)) (+ mountain-4 1180)))
    (when (< mountain-4 -1300)
      (setf (mountain-x (second *mountain-behind*)) (+ mountain-3 1180)))))



;;;;;;;;;;;;;;;;;;;;;;;; THE GAME ;;;;;;;;;;;;;;;;;;;;;;;;

;;;; UPDATE-GAME-TICKS function

(defun update-game-ticks ()
  (setf *game-ticks* (incf *game-ticks*)))


;;;; RENDER function

(defun render ()
  (update-swank)
  (sdl:clear-display sdl:*white*)

  (update-game-ticks)
  (update-road *car* *road*)
  (update-mountains *car*)
  (update-tree *car* *tree*)

  (display-mountains)
  (display-road *road*)
  (display-car *car*)
  (display-tree *tree*)

  (sdl:update-display))


;;;; INITIALIZE-GAME function

(defun initialize-game ()
  (setf *pause* nil)
  (setf *game-ticks* 0)
  (setf *car* nil)
  (setf *road* nil)
  (setf *mountain-front* nil)
  (setf *mountain-behind* nil)
  (setf *tree* nil)
  (create-car)
  (create-road)
  (create-mountain)
  (create-tree))


;;;; LOAD-SPRITE-SHEET function

(defun load-sprite-sheet ()
  ; enemy sprite sheet
  (setf *ss-car* (sdl:load-image *gfx-ss-car* :alpha 255))
  
  (setf *cells* '((0 0 200 97) (200 0 200 97) (400 0 200 97) (600 0 200 97) (800 0 200 97)))

  (setf (sdl:cells *ss-car*) *cells*))


;;;; START function

(defun start ()
  (initialize-game)
  (sdl:with-init (sdl:sdl-init-video)
    (sdl:window *game-width* *game-height* :title-caption "Parallax Demo")
    (setf (sdl:frame-rate) 30)

    (load-sprite-sheet)

    (sdl:with-events ()
      (:quit-event () t)
      (:key-down-event (:key key)
		       (case key
			 (:sdl-key-right (move-car *car* 'accelerate))
			 (:sdl-key-left (move-car *car* 'decelerate))
			 (:sdl-key-escape (sdl:push-quit-event))))
      (:key-up-event (:key key)
		     (case key))
      (:idle ()
	     ;(when (sdl:get-key-state :sdl-key-up) (move-player 'player 'up))
	     ;(when (sdl:get-key-state :sdl-key-down) (move-player 'player 'down))
	     (render)))))
