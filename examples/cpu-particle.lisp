(in-package #:org.shirakumo.fraf.trial.examples)

(define-example cpu-particle
  :title "CPU Particle Simulation"
  (gl:clear-color 0 0 0 0)
  (enter (make-instance 'display-controller) scene)
  (enter (make-instance 'cpu-particle-emitter
                        :name :emitter :max-particles 200 :particle-rate 60
                        :particle-force-fields `((:type :direction :strength -5.0)
                                                 (:type :vortex :strength 10.0))
                        :texture (assets:// :circle-05)
                        :orientation (qfrom-angle +vx+ (deg->rad 90))
                        :particle-options `(:velocity 10.0 :randomness 0.5 :size 0.1 :scaling 1.0
                                            :lifespan 3.0 :lifespan-randomness 0.5)) scene)
  (observe! (live-particles (node :emitter T)) :title "Alive Particles")
  (enter (make-instance 'vertex-entity :vertex-array (// 'trial 'grid)) scene)
  (enter (make-instance 'editor-camera :location (VEC3 0.0 2.3 7.3) :fov 50 :move-speed 0.1) scene)
  (enter (make-instance 'phong-render-pass) scene))

;;;; This is all UI crap.
(defclass grid-layout* (alloy:grid-layout alloy:renderable)
  ())

(presentations:define-realization (ui grid-layout*)
  ((:bg simple:rectangle)
   (alloy:margins)
   :pattern (colored:color 0 0 0 0.75)))

(defclass force-field-widget (alloy:structure)
  ())

(defmethod initialize-instance :after ((widget force-field-widget) &key field i layout-parent focus-parent)
  (let ((layout (make-instance 'alloy:grid-layout :col-sizes '(120 T) :row-sizes '(30) :layout-parent layout-parent))
        (focus (make-instance 'alloy:vertical-focus-list :focus-parent focus-parent))
        (row -1))
    (alloy:enter (format NIL "Field #~a" i) layout :row (incf row) :col 0)
    (alloy:enter "Type" layout :row (incf row) :col 0)
    (alloy:represent (slot-value field 'type) 'alloy:combo-set
                     :value-set '((0 . "None")
                                  (1 . "Point")
                                  (2 . "Direction")
                                  (3 . "Plane")
                                  (4 . "Vortex")
                                  (5 . "Sphere")
                                  (6 . "Planet")
                                  (7 . "Brake"))
                     :layout-parent layout :focus-parent focus)
    (alloy:enter "Position" layout :row (incf row) :col 0)
    (alloy:represent (slot-value field 'position) T
                     :layout-parent layout :focus-parent focus)
    (alloy:enter "Normal" layout :row (incf row) :col 0)
    (alloy:represent (slot-value field 'normal) T
                     :layout-parent layout :focus-parent focus)
    (alloy:enter "Strength" layout :row (incf row) :col 0)
    (alloy:represent (slot-value field 'strength) 'alloy:ranged-wheel
                     :range '(-100.0 . 100.0) :layout-parent layout :focus-parent focus)
    (alloy:enter "Range" layout :row (incf row) :col 0)
    (let ((range (alloy:represent (slot-value field 'trial::range) 'alloy:ranged-wheel
                                  :range '(0.0 . 1000.0) :layout-parent layout :focus-parent focus)))
      (alloy:on alloy:value (v range)
        (setf (slot-value field 'trial::inv-range) (if (= 0.0 v) 0.0 (/ v)))))
    (alloy:finish-structure widget layout focus)))

(defmethod setup-ui ((scene cpu-particle-scene) panel)
  (let ((constraint (make-instance 'org.shirakumo.alloy.layouts.constraint:layout))
        (focus (make-instance 'alloy:vertical-focus-list))
        (emitter (node :emitter scene)))
    ;; Global properties panel
    (let ((layout (make-instance 'grid-layout* :col-sizes '(120 T) :row-sizes '(30)))
          (focus (make-instance 'alloy:vertical-focus-list :focus-parent focus))
          (row -1))
      (alloy:enter layout constraint :constraints `((:right 0) (:top 0) (:width 300)))
      (macrolet ((wheel (place title start end &rest args)
                   `(progn
                      (alloy:enter ,title layout :row (incf row) :col 0)
                      (alloy:represent (,place emitter) 'alloy:ranged-wheel
                                       :range '(,start . ,end) ,@args :layout-parent layout :focus-parent focus))))
        (let* ((burst 10)
               (button (make-instance 'alloy:button* :value "Burst" :focus-parent focus :on-activate
                                      (lambda () (emit emitter burst)))))
          (alloy:enter button layout :row (incf row) :col 0)
          (alloy:represent burst 'alloy:ranged-wheel :range '(1 . 200) :layout-parent layout :focus-parent focus))
        (wheel particle-rate "Particle Rate" 0 200)
        (wheel particle-lifespan "Lifespan" 0.0 100.0)
        (wheel particle-lifespan-randomness "Lifespan Random" 0.0 1.0)
        (wheel particle-velocity "Velocity" 0.0 100.0)
        (wheel particle-randomness "Randomness" 0.0 1.0)
        (wheel particle-size "Size" 0.01 10.0)
        (wheel particle-scaling "Scaling" 0.0 10.0)
        (wheel particle-rotation "Rotation" 0.0 10.0)
        (wheel particle-motion-blur "Motion Blur" 0.0 1.0)
        (alloy:enter "Texture" layout :row (incf row) :col 0)
        (alloy:represent (texture emitter) T :layout-parent layout :focus-parent focus)
        (alloy:enter "Display Mode" layout :row (incf row) :col 0)
        (alloy:represent (particle-mode emitter) 'alloy:combo-set
                         :value-set '(:quad :billboard) :layout-parent layout :focus-parent focus)
        (alloy:enter "Blend Mode" layout :row (incf row) :col 0)
        (alloy:represent (blend-mode emitter) 'alloy:combo-set
                         :value-set '(:add :normal :invert :darken :multiply :screen) :layout-parent layout :focus-parent focus)
        (alloy:enter "Texture Flip" layout :row (incf row) :col 0)
        (alloy:represent (particle-flip emitter) 'alloy:combo-set
                         :value-set '(NIL :x :y T) :layout-parent layout :focus-parent focus)
        (alloy:enter "Color" layout :row (incf row) :col 0)
        (let* ((color (particle-color emitter))
               (c (alloy:represent color T :layout-parent layout :focus-parent focus)))
          (alloy:on alloy:value (v c)
            (setf (particle-color emitter) color)))
        (alloy:enter "Emitter Shape" layout :row (incf row) :col 0)
        (let* ((shape :square)
               (c (alloy:represent shape 'alloy:combo-set
                                   :value-set '(:square :disc :sphere :cube) :layout-parent layout :focus-parent focus)))
          (alloy:on alloy:value (v c)
            (setf (vertex-array emitter)
                  (ecase v
                    (:square (// 'trial 'unit-square))
                    (:disc (// 'trial 'unit-disc))
                    (:sphere (// 'trial 'unit-sphere))
                    (:cube (// 'trial 'unit-cube))))))))
    ;; Force fields panel
    (let ((layout (make-instance 'grid-layout* :col-sizes '(T) :row-sizes '(200)))
          (focus (make-instance 'alloy:vertical-focus-list :focus-parent focus))
          (fields (particle-force-fields emitter)))
      (alloy:enter layout constraint :constraints `((:top 0) (:right 300) (:width 300) (:height 400)))
      (loop for i from 0 below (trial::particle-force-field-count fields)
            for field = (aref (trial::particle-force-fields fields) i)
            do (make-instance 'force-field-widget :field field :i (1+ i) :layout-parent layout :focus-parent focus)))
    (alloy:finish-structure panel constraint focus)))
