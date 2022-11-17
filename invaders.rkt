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
(define SHIP-SPEED 6)
(define MIN-SHIP-X (/ (image-width SHIP) 2))
(define MAX-SHIP-X (- WIDTH (/ (image-width SHIP) 2)))

(define PLAYER-LASER (rectangle 1.5 15 "solid" "white"))
(define PLAYER-LASER-SPEED 20)
(define PLAYER-LASER-Y (- HEIGHT 40))
(define LASER-MAX-Y (+ 15 HEIGHT))
(define LASER-MIN-Y -15)

(define ALIEN-LASER-ANIMATION-SPEED 1) ;; smaller is faster
(define ALIEN-LASER-SPEED 7)
(define ALIEN-LASER-SCALE 2.5)

;; alien laser images
(define WIGGLE1 (scale ALIEN-LASER-SCALE (bitmap/file "sprites/wiggle1.png")))
(define WIGGLE2 (scale ALIEN-LASER-SCALE (bitmap/file "sprites/wiggle2.png")))
(define WIGGLE3 (scale ALIEN-LASER-SCALE (bitmap/file "sprites/wiggle3.png")))
(define WIGGLE4 (scale ALIEN-LASER-SCALE (bitmap/file "sprites/wiggle4.png")))
(define STR1 (scale ALIEN-LASER-SCALE (bitmap/file "sprites/straight1.png")))
(define STR2 (scale ALIEN-LASER-SCALE (bitmap/file "sprites/straight2.png")))
(define STR3 (scale ALIEN-LASER-SCALE (bitmap/file "sprites/straight3.png")))
(define STR4 (scale ALIEN-LASER-SCALE (bitmap/file "sprites/straight4.png")))
(define ZIGZAG1 (scale ALIEN-LASER-SCALE (bitmap/file "sprites/zigzag1.png")))
(define ZIGZAG2 (scale ALIEN-LASER-SCALE (bitmap/file "sprites/zigzag2.png")))
(define ZIGZAG3 (scale ALIEN-LASER-SCALE (bitmap/file "sprites/zigzag3.png")))
(define ZIGZAG4 (scale ALIEN-LASER-SCALE (bitmap/file "sprites/zigzag4.png")))

;; =================
;; Data definitions:

(@htdd Animation)
(define-struct ani (img id next))
;; Animation is (make-ani Image Natural Natural|false)
;; interp. an animation that cycles through a group of images
;;         img is the current frame
;;         id is the id for this frame
;;         next is the ID for the next animation in the cycle, false if none
;; examples are exhaustive
(define WIGGLE1ANI (make-ani WIGGLE1 0 1))
(define WIGGLE2ANI (make-ani WIGGLE2 1 2))
(define WIGGLE3ANI (make-ani WIGGLE3 2 3))
(define WIGGLE4ANI (make-ani WIGGLE4 3 0))
(define STR1ANI (make-ani STR1 4 5))
(define STR2ANI (make-ani STR2 5 6))
(define STR3ANI (make-ani STR3 6 7))
(define STR4ANI (make-ani STR4 7 4))
(define ZIGZAG1ANI (make-ani ZIGZAG1 8 9))
(define ZIGZAG2ANI (make-ani ZIGZAG2 9 10))
(define ZIGZAG3ANI (make-ani ZIGZAG3 10 11))
(define ZIGZAG4ANI (make-ani ZIGZAG4 11 8))

(define ANIS (list WIGGLE1ANI WIGGLE2ANI WIGGLE3ANI WIGGLE4ANI
                   STR1ANI STR2ANI STR3ANI STR4ANI
                   ZIGZAG1ANI ZIGZAG2ANI ZIGZAG3ANI ZIGZAG4ANI))
; !!! add aliens
;; primitive to get an ani using its id
(define (get-ani id)
  (local [(define (id? a)
            (= (ani-id a) id))]
    (first (filter id? ANIS))))




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


(@htdd PlayerLaser)
(define-struct player-laser (x y))
;; PlayerLaser is (make-player-laser Number Number)
;; interp. a laser fired by the player with screen coords x and y
(define PL1 (make-player-laser 100 50))
(define PL2 (make-player-laser 200 300))
(define LOPL (list PL1 PL2))

  
(@htdd AlienLaser)
(define-struct alien-laser (x y ani timer))
;; AlienLaser is (make-alien-laser Number Number Animation Natural)
;; interp. a laser fired by an alien
;;         x and y are screen coordinates of the center of the laser
;;         ani is the animation, with current and next frame
;;         timer is the number of ticks left until a sprite change
(define AL1 (make-alien-laser 50 30 WIGGLE1ANI 5))
(define AL2 (make-alien-laser 60 40 WIGGLE1ANI 0))
(define AL3 (make-alien-laser 60 40 WIGGLE2ANI 5))
(define ALL-ALIEN-LASERS
  (list (make-alien-laser 100 0 WIGGLE1ANI ALIEN-LASER-ANIMATION-SPEED)
        (make-alien-laser 200 0 STR1ANI ALIEN-LASER-ANIMATION-SPEED)
        (make-alien-laser 300 0 ZIGZAG1ANI ALIEN-LASER-ANIMATION-SPEED)))


(@htdd Laser)
;; Laser is one of:
;; - PlayerLaser
;; - AlienLaser
;; interp. either a player or alien laser


(@htdd Alien)
;; !!!


(@htdd Game)
(define-struct game (ship lasers aliens timer over?))
;; Game is one of:
;;  - false
;;  - (make-game Ship (listof Laser) (listof Alien) Natural Boolean)
;; interp. Represents the state of the game.
;;    false means game has not started yet
;;    ship-x is x position of the ship
;;    lasers is a list of all lasers on the screen
;;    aliens is a list of all aliens on the screen
;;    timer is the ticks left until an alien fires a shot (if aliens not empty)
;;    over? is false normally, but becomes true when the player loses

(define GSTART (make-game (make-ship SHIP-X-START 0)
                          empty empty 0 false)) ;; add aliens to this

(define G0 false)
(define G1 (make-game (make-ship 100 0) empty empty 0 false))
(define G2 (make-game (make-ship 50 5) empty empty 0 true))
(define G3 (make-game (make-ship 70 -5) empty empty 0 false))
(define G5 (make-game (make-ship 200 0)
                      (list PL1 PL2)
                      empty 0 false))
(define G6 (make-game (make-ship 200 0)
                      (list AL1 AL3)
                      empty 0 false))
(define G7 (make-game (make-ship SHIP-X-START 0) ALL-ALIEN-LASERS
                      empty 0 false))
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
              (make-game (make-ship 65 -5) empty empty 0 false))

(@template-origin Game fn-composition)
(define (tock g)
  (local [(define (tock-ship-game g)
            (make-game (tock-ship (game-ship g))
                       (game-lasers g)
                       (game-aliens g)
                       (game-timer g)
                       (game-over? g)))]
    (cond [(false? g) g]
          [(game-over? g) g]
          [else
           (tock-timer (tock-aliens (tock-lasers (tock-ship-game g))))])))


(@htdf tock-timer)
(@signature Game -> Game)
;; subtract 1 from the timer or loop it
;; !!!
(define (tock-timer g) g)


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
;; move lasers, delete offscreen, update alien laser animation, check collisions
(check-expect (tock-lasers G1) G1)
(check-expect (tock-lasers (make-game (make-ship 0 0)
                                      (list PL1)
                                      empty 0 false))
              (make-game (make-ship 0 0)
                         (list (make-player-laser
                                100 (- 50 PLAYER-LASER-SPEED)))
                         empty 0 false))
(check-expect (tock-lasers (make-game (make-ship 0 0)
                                      (list PL2 AL1)
                                      empty 0 false))
              (make-game (make-ship 0 0)
                         (list (make-player-laser
                                200 (- 300 PLAYER-LASER-SPEED))
                               (make-alien-laser
                                50 (+ 30 ALIEN-LASER-SPEED) WIGGLE1ANI 4))
                         empty 0 false))
(check-expect (tock-lasers (make-game (make-ship 0 0)
                                      (list (make-player-laser 50 -99999)
                                            (make-alien-laser 60 99999
                                                              WIGGLE1ANI 4))
                                      empty 0 false))
              (make-game (make-ship 0 0)
                         empty
                         empty 0 false))
; !!! add game end collision test, alien collision test, laser animation test 

(define (tock-lasers g)
  (local [(define lol (game-lasers g))
          (define (onscreen? l)
            (cond [(player-laser? l) (> (player-laser-y l) LASER-MIN-Y)]
                  [else (< (alien-laser-y l) LASER-MAX-Y)]))
          (define (move-laser l)
            (cond [(player-laser? l)
                   (make-player-laser
                    (player-laser-x l)
                    (- (player-laser-y l) PLAYER-LASER-SPEED))]
                  [else
                   (make-alien-laser
                    (alien-laser-x l)
                    (+ (alien-laser-y l) ALIEN-LASER-SPEED)
                    (alien-laser-ani l) (alien-laser-timer l))]))]
    (if (laser-on-ship? g)
        (make-game
         (game-ship g) empty (game-aliens g) (game-timer g) true)
        
        (handle-alien-collision
         (make-game
          (game-ship g)
          (map update-alien-laser-ani
               (filter onscreen?
                       (map move-laser lol)))
          (game-aliens g) (game-timer g) (game-over? g))))))


(@htdf laser-on-ship?)
(@signature Game -> Boolean)
;; produce true if an alien laser is colliding with the ship
; !!!
(define (laser-on-ship? g) false)


(@htdf handle-alien-collision)
(@signature Game -> Game)
;; explode all aliens in collision with a laser, and delete the laser
; !!!
(define (handle-alien-collision g) g)


(@htdf update-alien-laser-ani)
(@signature Laser -> Laser)
;; sub1 from the animation timer, if 0, update the sprite and reset the timer
(check-expect (update-alien-laser-ani PL1) PL1)
(check-expect (update-alien-laser-ani AL1)
              (make-alien-laser 50 30 WIGGLE1ANI 4))
(check-expect (update-alien-laser-ani AL2)
              (make-alien-laser 60 40 WIGGLE2ANI ALIEN-LASER-ANIMATION-SPEED))

(define (update-alien-laser-ani l)
  (cond [(player-laser? l) l]
        [(> (alien-laser-timer l) 0)
         (make-alien-laser (alien-laser-x l) (alien-laser-y l)
                           (alien-laser-ani l) (sub1 (alien-laser-timer l)))]
        [else
         (local [(define next-ani (ani-next (alien-laser-ani l)))]
           (make-alien-laser (alien-laser-x l) (alien-laser-y l)
                             (get-ani (ani-next (alien-laser-ani l)))
                             ALIEN-LASER-ANIMATION-SPEED))]))


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
  (place-ship g (place-aliens g (place-lasers g MTS))))


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
(check-expect (place-lasers G1 (square 10 "solid" "purple"))
              (square 10 "solid" "purple"))
(check-expect (place-lasers G1 (square 10 "solid" "purple"))
              (square 10 "solid" "purple"))
(check-expect (place-lasers G2 MTS) MTS)

(check-expect (place-lasers (make-game (make-ship 0 0) (list PL1)
                                       empty 0 false) MTS)
              (place-image PLAYER-LASER 100 50 MTS))
(check-expect (place-lasers (make-game (make-ship 0 0) (list PL1 PL2)
                                       empty 0 false) MTS)
              (place-image PLAYER-LASER 100 50
                           (place-image PLAYER-LASER 200 300 MTS)))
(check-expect (place-lasers (make-game (make-ship 0 0) (list AL1 AL3)
                                       empty 0 false) MTS)
              (place-image WIGGLE1 50 30
                           (place-image WIGGLE2 60 40 MTS)))

(@template-origin use-abstract-fn fn-composition)
(define (place-lasers g i)
  (local [(define player-lasers (filter player-laser? (game-lasers g)))
          (define alien-lasers (filter alien-laser? (game-lasers g)))
          (define (place-alien-lasers lol i)
            (foldr place-alien-laser i lol))
          (define (place-player-lasers lol i)
            (foldr place-player-laser i lol))
          (define (place-alien-laser l i)
            (place-image (ani-img (alien-laser-ani l))
                         (alien-laser-x l) (alien-laser-y l)
                         i))
          (define (place-player-laser l i)
            (place-image PLAYER-LASER
                         (player-laser-x l) (player-laser-y l)
                         i))]
    (place-alien-lasers alien-lasers
                        (place-player-lasers player-lasers i))))


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
              (make-game (make-ship 70 0) empty empty 0 false))
(check-expect (handle-release G3 "right")
              (make-game (make-ship 70 0) empty empty 0 false))
(check-expect (handle-release G3 "a") G3)

(@template-origin Game)
(define (handle-release g ke)
  (local [(define (stop-ship g)
            (make-game (make-ship (ship-x (game-ship g)) 0)
                       (game-lasers g) (game-aliens g)
                       (game-timer g) (game-over? g)))]
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
              (make-game (make-ship 100 (- SHIP-SPEED)) empty empty 0 false))
(check-expect (handle-key G1 " ")
              (make-game (make-ship 100 0)
                         (list (make-player-laser 100 PLAYER-LASER-Y))
                         empty 0 false))

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
;; shoot with space, set speed with arrow keys
(check-expect (handle-key-game G1 "left")
              (make-game (make-ship 100 (- SHIP-SPEED)) empty empty 0 false))
(check-expect (handle-key-game G3 "right")
              (make-game (make-ship 70 SHIP-SPEED) empty empty 0 false))
(check-expect (handle-key-game G1 "a") G1)

(@template-origin KeyEvent)
(define (handle-key-game g ke)
  (local [(define s (game-ship g))
          (define left-ship (make-ship (ship-x s) (- SHIP-SPEED)))
          (define right-ship (make-ship (ship-x s) SHIP-SPEED))]
    (cond [(key=? ke "left") (make-game left-ship
                                        (game-lasers g)
                                        (game-aliens g)
                                        (game-timer g)
                                        (game-over? g))]
          [(key=? ke "right") (make-game right-ship
                                         (game-lasers g)
                                         (game-aliens g)
                                         (game-timer g)
                                         (game-over? g))]
          [(key=? ke " ") (shoot g)]
          [else g])))


(@htdf shoot)
(@signature Game -> Game)
;; shoot a laser from the ship's position
(check-expect (shoot G1)
              (make-game (make-ship 100 0)
                         (list (make-player-laser 100 PLAYER-LASER-Y))
                         empty 0 false))
(check-expect (shoot G5)
              (make-game (make-ship 200 0)
                         (list (make-player-laser 200 PLAYER-LASER-Y)
                               PL1 PL2)
                         empty 0 false))
 
(define (shoot g)
  (local [(define new-laser
            (make-player-laser (ship-x (game-ship g)) PLAYER-LASER-Y))]
    (make-game (game-ship g)
               (cons new-laser (game-lasers g))
               (game-aliens g) (game-timer g) (game-over? g))))





