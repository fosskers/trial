#|
 This file is a part of trial
 (c) 2016 Shirakumo http://tymoon.eu (shinmera@tymoon.eu)
 Author: Nicolas Hafner <shinmera@tymoon.eu>
|#

(in-package #:org.shirakumo.fraf.trial)
(in-readtable :qtools)

(define-subject camera (located-subject)
  ((target :initarg :target :accessor target)
   (up :initarg :up :accessor up))
  (:default-initargs
   :target (vec 0 0 0)
   :up (vec 0 1 0)
   :location (vec 0 30 200)))

(define-handler (camera tick) (ev)
  (look-at (location camera) (target camera) (up camera)))

(defun look-at (eye target up)
  (let* ((z (nvunit (v- eye target)))
         (x (nvunit (vc up z)))
         (y (nvunit (vc z x))))
    (gl:mult-matrix
     (matrix-4x4
      (vx x) (vx y) (vx z) 0.0f0
      (vy x) (vy y) (vy z) 0.0f0
      (vz x) (vz y) (vz z) 0.0f0
      (- (vx eye)) (- (vy eye)) (- (vz eye)) 1.0f0))))

(define-subject pivot-camera (camera)
  ()
  (:default-initargs
   :target NIL))

(define-handler (pivot-camera tick) (ev)
  (when (target pivot-camera)
    (look-at (location pivot-camera)
             (location (target pivot-camera))
             (up pivot-camera))))

(define-subject following-camera (camera)
  ()
  (:default-initargs
   :target NIL))

(define-handler (following-camera tick) (ev)
  (when (target following-camera)
    (look-at (v+ (location following-camera)
                 (location (target following-camera)))
             (location (target following-camera))
             (up following-camera))))
