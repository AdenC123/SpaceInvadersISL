;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-intermediate-lambda-reader.ss" "lang")((modname invaders) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #f #t none #f () #t)))
(require spd/tags)
(require 2htdp/image)
(require 2htdp/universe)

;; space invaders without shields because i am too cool for shields
(@htdw Game)

;; =================
;; Constants:

(define START false)

(define WIDTH 500)
(define HEIGHT 500)

(define MTS (rectangle WIDTH HEIGHT "solid" "black"))
(define EMPTY (rectangle WIDTH HEIGHT "solid" "transparent"))

(define START-SCREEN
  (local [(define LOGO (scale 0.5 (bitmap/file "startscreen/logo.png")))
          (define KEYS (scale 0.3 (bitmap/file "startscreen/arrowkeys.png")))
          (define SPACE (scale 0.6 (bitmap/file "startscreen/spacebar.png")))
          (define SPACE-TEXT (text "to start and shoot" 25 "white"))
          (define KEYS-TEXT (text "to move" 25 "white"))]
    (place-image
     LOGO 250 120
     (place-image
      SPACE 140 310
      (place-image
       KEYS 120 420
       (place-image
        SPACE-TEXT 320 300
        (place-image
         KEYS-TEXT 270 420 MTS)))))))

(define END-SCREEN
  (local [(define R-KEY (scale 0.3 (bitmap/file "startscreen/rkey.png")))
          (define GAME-OVER (text "GAME OVER" 70 "white"))
          (define PRESS (text "Press" 40 "white"))
          (define RESTART (text "to restart" 40 "white"))]
    (place-image
     GAME-OVER 250 120
     (place-image
      PRESS 120 300
      (place-image
       R-KEY 215 300
       (place-image
        RESTART 340 300 EMPTY))))))

(define SHIP (scale 0.3 (bitmap/file "sprites/ship.png")))
(define SHIP-EXPLODE (scale 0.3 (bitmap/file "sprites/ship_exploded.png")))
(define SHIP-Y (- HEIGHT 30))
(define SHIP-X-START (/ WIDTH 2))
(define SHIP-SPEED 7) ;; pixels per tick
(define MIN-SHIP-X (/ (image-width SHIP) 2))
(define MAX-SHIP-X (- WIDTH (/ (image-width SHIP) 2)))

;; =================
;; Data definitions:

(@htdd Ship)
(define-struct ship (x speed))
;; Ship is (make-ship Number Number)
;; interp.
;;   the ship with center x-position and speed
;;   speed is negative left, positive right
(define SSTART (make-ship SHIP-X-START 0))
(define S1 (make-ship 100 0))
(define S2 (make-ship 50 5))
(define S3 (make-ship 70 -5))

(@htdd Laser)
(define-struct laser (x y player?))
;; Laser is (make-laser Number Number Boolean)
;; interp. a laser fired by the player or an alien
;;         x and y are screen coordinates of the center,
;;         player? is true if the laser was fired by the player,
;;                    false if fired by an alien
(define L1 (make-laser 100 50 true))
(define L2 (make-laser 200 300 false))

(@htdd Alien)
;; !!!


(@htdd Game)
(define-struct game (ship lasers aliens over?))
;; Game is one of:
;;  - false
;;  - (make-game Ship (listof Laser) (listof Alien) Boolean)
;; interp. Represents the state of the game.
;;    false means game has not started yet
;;    ship-x is x position of the ship
;;    lasers is a list of all lasers on the screen
;;    aliens is a list of all aliens on the screen
;;    over? is false normally, but becomes true when the player loses
(define G0 false)
(define G1 (make-game (make-ship 100 0) empty empty false))
(define G2 (make-game (make-ship 50 5) empty empty true))
(define G3 (make-game (make-ship 70 -5) empty empty false))
(define GSTART (make-game (make-ship SHIP-X-START 0)
                          empty empty false)) ;; add aliens to this
(define G5 (make-game (make-ship 200 0)
                      (list L1 L2)
                      empty false))
;; !!! examples with aliens


;; =================
;; Functions:

(@htdf main)
(@signature Game -> Game)
;; start the world with (main START)

(@template-origin htdw-main)
(define (main g)
  (big-bang g
    (on-tick    tock)             ;; Game -> Game
    (to-draw    render)           ;; Game -> Image
    (on-key     handle-key)       ;; Game KeyEvent -> Game
    (on-release handle-release))) ;; Game KeyEvent -> Game
  


(@htdf tock)
(@signature Game -> Game)
;; advance ship, lasers, aliens by one tick
(check-expect (tock G0) G0)
(check-expect (tock G1) G1)
(check-expect (tock G2) G2)
(check-expect (tock G3)
              (make-game (make-ship 65 -5) empty empty false))

(@template-origin Game fn-composition)
(define (tock g)
  (local [(define (tock-ship-game g)
            (make-game (tock-ship (game-ship g))
                       (game-lasers g)
                       (game-aliens g)
                       (game-over? g)))]
    (cond [(false? g) g]
          [(game-over? g) g]
          [else
           (tock-aliens (tock-lasers (tock-ship-game g)))])))


(@htdf tock-ship)
(@signature Ship -> Ship)
;; move ship by speed, don't go past walls
(check-expect (tock-ship S1) S1)
(check-expect (tock-ship S2) (make-ship 55 5))
(check-expect (tock-ship S3) (make-ship 65 -5))

(check-expect (tock-ship (make-ship (+ 5 MIN-SHIP-X) -4))
              (make-ship (+ 1 MIN-SHIP-X) -4))
(check-expect (tock-ship (make-ship (+ 5 MIN-SHIP-X) -5))
              (make-ship (+ 0 MIN-SHIP-X) -5))
(check-expect (tock-ship (make-ship (+ 5 MIN-SHIP-X) -6))
              (make-ship (+ 0 MIN-SHIP-X) -6))
(check-expect (tock-ship (make-ship (+ 0 MIN-SHIP-X) 5))
              (make-ship (+ 5 MIN-SHIP-X) 5))

(check-expect (tock-ship (make-ship (- MAX-SHIP-X 3) 2))
              (make-ship (- MAX-SHIP-X 1) 2))
(check-expect (tock-ship (make-ship (- MAX-SHIP-X 2) 2))
              (make-ship (- MAX-SHIP-X 0) 2))
(check-expect (tock-ship (make-ship (- MAX-SHIP-X 1) 2))
              (make-ship (- MAX-SHIP-X 0) 2))
(check-expect (tock-ship (make-ship (- MAX-SHIP-X 0) -5))
              (make-ship (- MAX-SHIP-X 5) -5))

(@template-origin Ship)
(define (tock-ship s)
  (local [(define next-x (+ (ship-x s) (ship-speed s)))]
    (cond [(< next-x MIN-SHIP-X) (make-ship MIN-SHIP-X (ship-speed s))]
          [(> next-x MAX-SHIP-X) (make-ship MAX-SHIP-X (ship-speed s))]
          [else
           (make-ship next-x (ship-speed s))])))


(@htdf tock-lasers)
(@signature Game -> Game)
;; advance lasers by one tick
;; !!!
(define (tock-lasers g) g)


(@htdf tock-aliens)
(@signature Game -> Game)
;; advance aliens by one tick
;; !!!
(define (tock-aliens g) g)


(@htdf render)
(@signature Game -> Image)
;; render start screen, game, or end screen on game
(check-expect (render G0) START-SCREEN)
(check-expect (render G1)
              (place-image SHIP 100 SHIP-Y MTS))
(check-expect (render G2)
              (place-image END-SCREEN
                           (/ WIDTH 2) (/ HEIGHT 2)
                           (place-image SHIP-EXPLODE 50 SHIP-Y MTS)))

(@template-origin Game)
(define (render g)
  (cond [(false? g) START-SCREEN]
        [(game-over? g) (place-image END-SCREEN (/ WIDTH 2) (/ HEIGHT 2)
                                     (render-game g))]
        [else
         (render-game g)]))


(@htdf render-game)
(@signature Game -> Image)
;; render ship, lasers, aliens on MTS
(check-expect (render-game G1)
              (place-image SHIP 100 SHIP-Y MTS))
(check-expect (render-game G2)
              (place-image SHIP-EXPLODE 50 SHIP-Y MTS))

(@template-origin fn-composition)
(define (render-game g)
  (place-aliens g (place-lasers g (place-ship g MTS))))


(@htdf place-ship)
(@signature Game Image -> Image)
;; place ship/exploded ship on image, assume image is the same size as MTS
(check-expect (place-ship G1 MTS)
              (place-image SHIP 100 SHIP-Y MTS))
(check-expect (place-ship G2 MTS)
              (place-image SHIP-EXPLODE 50 SHIP-Y MTS))
(check-expect (place-ship G3
                          (rectangle WIDTH HEIGHT "solid" "purple"))
              (place-image SHIP 70 SHIP-Y
                           (rectangle WIDTH HEIGHT "solid" "purple")))

(@template-origin Ship)
(define (place-ship g i)
  (local [(define s (game-ship g))]
    (if (game-over? g)
        (place-image SHIP-EXPLODE (ship-x s) SHIP-Y i)
        (place-image SHIP (ship-x s) SHIP-Y i))))


(@htdf place-lasers)
(@signature Game Image -> Image)
;; place all lasers onto i
;; !!!
(define (place-lasers g i) i)


(@htdf place-aliens)
(@signature Game Image -> Image)
;; place all aliens onto i
;; !!!
(define (place-aliens g i) i)


(@htdf handle-release)
(@signature Game KeyEvent -> Game)
;; stop ship movement when left or right are released
(check-expect (handle-release G0 "left") G0)
(check-expect (handle-release G2 "left") G2)

(check-expect (handle-release G1 "left") G1)
(check-expect (handle-release G3 "left")
              (make-game (make-ship 70 0) empty empty false))
(check-expect (handle-release G3 "right")
              (make-game (make-ship 70 0) empty empty false))
(check-expect (handle-release G3 "a") G3)

(@template-origin Game)
(define (handle-release g ke)
  (local [(define (stop-ship g)
            (make-game (make-ship (ship-x (game-ship g)) 0)
                       (game-lasers g) (game-aliens g) (game-over? g)))]
    (cond [(false? g) g]
          [(game-over? g) g]
          [else
           (if (or (key=? ke "left") (key=? ke "right"))
               (stop-ship g)
               g)])))


(@htdf handle-key)
(@signature Game KeyEvent -> Game)
;; handle keys for start and end screens
(check-expect (handle-key G0 " ") GSTART)
(check-expect (handle-key G0 "left") G0)
(check-expect (handle-key G0 "a") G0)

(check-expect (handle-key G1 "left")
              (make-game (make-ship 100 (- SHIP-SPEED)) empty empty false))
(check-expect (handle-key G1 " ") G1)

(check-expect (handle-key G2 "a") G2)
(check-expect (handle-key G2 "left") G2)
(check-expect (handle-key G2 " ") G2)
(check-expect (handle-key G2 "r") GSTART)

(@template-origin Game)
(define (handle-key g ke)
  (cond [(false? g) (if (key=? ke " ")
                        GSTART
                        g)]
        [(game-over? g) (if (key=? ke "r")
                            GSTART
                            g)]
        [else
         (handle-key-game g ke)]))



(@htdf handle-key-game)
(@signature Game KeyEvent -> Game)
;; shoot with space!!!, set speed with arrow keys
(check-expect (handle-key-game G1 "left")
              (make-game (make-ship 100 (- SHIP-SPEED)) empty empty false))
(check-expect (handle-key-game G3 "right")
              (make-game (make-ship 70 SHIP-SPEED) empty empty false))
(check-expect (handle-key-game G1 "a") G1)

(@template-origin KeyEvent)
(define (handle-key-game g ke)
  (local [(define s (game-ship g))
          (define left-ship (make-ship (ship-x s) (- SHIP-SPEED)))
          (define right-ship (make-ship (ship-x s) SHIP-SPEED))]
    (cond [(key=? ke "left") (make-game left-ship
                                        (game-lasers g)
                                        (game-aliens g)
                                        (game-over? g))]
          [(key=? ke "right") (make-game right-ship
                                         (game-lasers g)
                                         (game-aliens g)
                                         (game-over? g))]
          [(key=? ke " ") (shoot g)]
          [else g])))


(@htdf shoot)
(@signature Game -> Game)
;; shoot a laster from the ship's position
; !!!
(define (shoot g) g)
        

















