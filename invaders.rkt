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

;; auto start: if this is true, game will start when you press the play button
;; otherwise, run (main START)
;; may take a bit to start... there are a few check expects
(define AUTO-START false)

;; sprite downloading
;; if FROM-INTERNET is true, will attempt to download sprites from online;
;; you do not need to download them manually. if false, put the sprite folders
;; in the same directory as the game file
(define FROM-INTERNET true)
(define REPO-URL
  "https://raw.githubusercontent.com/AdenC123/SpaceInvadersISL/main/")

(define (get-sprite filename)
  (if FROM-INTERNET
      (bitmap/url (string-append REPO-URL filename))
      (bitmap/file filename)))

;; screen constants
(define WIDTH 500)
(define HEIGHT 500)

(define MTS (rectangle WIDTH HEIGHT "solid" "black"))
(define EMPTY (rectangle WIDTH HEIGHT "solid" "transparent"))

;; game constants
(define START false)

(define SHIP-SCALE 0.25)
(define SHIP (scale SHIP-SCALE (get-sprite "sprites/ship.png")))
(define SHIP-EXPLODE (scale SHIP-SCALE
                            (get-sprite "sprites/ship_exploded.png")))
(define SHIP-Y (- HEIGHT 30))
(define SHIP-X-START (/ WIDTH 2))
(define SHIP-SPEED 6)
(define MIN-SHIP-X (/ (image-width SHIP) 2))
(define MAX-SHIP-X (- WIDTH (/ (image-width SHIP) 2)))

(define LASER-MAX-Y (+ 15 HEIGHT))
(define LASER-MIN-Y -15)

(define PLAYER-LASER (rectangle 1.5 15 "solid" "white"))
(define PLAYER-LASER-SPEED 20)
(define PLAYER-LASER-Y (- HEIGHT 40))

(define ALIEN-LASER-ANIMATION-SPEED 1) ;; smaller is faster
(define ALIEN-LASER-SPEED 7)

(define ALIEN-JUMP-X 10)
(define ALIEN-JUMP-Y 30)

;; timers
(define ALIEN-TICKS-START 15) ;; initial speed of aliens
(define ALIEN-TICKS-MIN 1) ;; speed when there is 1 alien left
(define TIMER-START 15) ;; alien shot timer
(define EXPLODE-TICKS 7) ;; how many ticks to explode for

;; alien start positions
(define ALIEN-START-X 50)
(define ALIEN-START-Y 50)
(define ALIEN-SPACE-X 40)
(define ALIEN-SPACE-Y 40)
(define ALIEN-NUM 11)
(define TOTAL-ALIEN-NUM (* ALIEN-NUM 5))
(define ALIEN-START-DIR "left")

;; screen images
(define START-SCREEN
  (local [(define LOGO (scale 0.5 (get-sprite "startscreen/logo.png")))
          (define KEYS (scale 0.3 (get-sprite "startscreen/arrowkeys.png")))
          (define SPACE (scale 0.6 (get-sprite "startscreen/spacebar.png")))
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
  (local [(define R-KEY (scale 0.3 (get-sprite "startscreen/rkey.png")))
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

(define WIN-SCREEN
  (local [(define R-KEY (scale 0.3 (get-sprite "startscreen/rkey.png")))
          (define WIN (text "YOU WIN!!!" 70 "white"))
          (define PRESS (text "Press" 40 "white"))
          (define RESTART (text "to restart" 40 "white"))]
    (place-image
     WIN 250 120
     (place-image
      PRESS 120 300
      (place-image
       R-KEY 215 300
       (place-image
        RESTART 340 300 EMPTY))))))

;; alien laser images
(define ALIEN-LASER-SCALE 2.5)
(define WIGGLE1 (scale ALIEN-LASER-SCALE (get-sprite "sprites/wiggle1.png")))
(define WIGGLE2 (scale ALIEN-LASER-SCALE (get-sprite "sprites/wiggle2.png")))
(define WIGGLE3 (scale ALIEN-LASER-SCALE (get-sprite "sprites/wiggle3.png")))
(define WIGGLE4 (scale ALIEN-LASER-SCALE (get-sprite "sprites/wiggle4.png")))
(define STR1 (scale ALIEN-LASER-SCALE (get-sprite "sprites/straight1.png")))
(define STR2 (scale ALIEN-LASER-SCALE (get-sprite "sprites/straight2.png")))
(define STR3 (scale ALIEN-LASER-SCALE (get-sprite "sprites/straight3.png")))
(define STR4 (scale ALIEN-LASER-SCALE (get-sprite "sprites/straight4.png")))
(define ZIGZAG1 (scale ALIEN-LASER-SCALE (get-sprite "sprites/zigzag1.png")))
(define ZIGZAG2 (scale ALIEN-LASER-SCALE (get-sprite "sprites/zigzag2.png")))
(define ZIGZAG3 (scale ALIEN-LASER-SCALE (get-sprite "sprites/zigzag3.png")))
(define ZIGZAG4 (scale ALIEN-LASER-SCALE (get-sprite "sprites/zigzag4.png")))

;; alien images
(define ALIEN-SCALE 0.25)
(define ARMS1 (scale ALIEN-SCALE (get-sprite "sprites/arms1.png")))
(define ARMS2 (scale ALIEN-SCALE (get-sprite "sprites/arms2.png")))
(define METROID1 (scale ALIEN-SCALE (get-sprite "sprites/metroid1.png")))
(define METROID2 (scale ALIEN-SCALE (get-sprite "sprites/metroid2.png")))
(define OCTOPUS1 (scale ALIEN-SCALE (get-sprite "sprites/octopus1.png")))
(define OCTOPUS2 (scale ALIEN-SCALE (get-sprite "sprites/octopus2.png")))
(define ALIEN-EXPLODED (scale 0.25 (get-sprite "sprites/exploded.png")))

(define ALIEN-MIN-X (/ (image-width ARMS1) 2))
(define ALIEN-MAX-X (- WIDTH (/ (image-width ARMS1) 2)))

;; =================
;; Data definitions:

(@htdd Animation)
(define-struct ani (img id next))
;; Animation is (make-ani Image Natural Natural)
;; interp. an animation that cycles through a group of images
;;         img is the current frame
;;         id is the id for this frame
;;         next is the ID for the next animation in the cycle
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

(define ARMS1ANI (make-ani ARMS1 12 13))
(define ARMS2ANI (make-ani ARMS2 13 12))
(define METROID1ANI (make-ani METROID1 14 15))
(define METROID2ANI (make-ani METROID2 15 14))
(define OCTOPUS1ANI (make-ani OCTOPUS1 16 17))
(define OCTOPUS2ANI (make-ani OCTOPUS2 17 16))
(define EXPLODEDANI (make-ani ALIEN-EXPLODED 19 19))

;; exhaustive list of all animations for id checker
(define ANIS (list WIGGLE1ANI WIGGLE2ANI WIGGLE3ANI WIGGLE4ANI
                   STR1ANI STR2ANI STR3ANI STR4ANI
                   ZIGZAG1ANI ZIGZAG2ANI ZIGZAG3ANI ZIGZAG4ANI
                   ARMS1ANI ARMS2ANI
                   METROID1ANI METROID2ANI
                   OCTOPUS1ANI OCTOPUS2ANI
                   EXPLODEDANI))

;; possible laser anis for aliens to choose
(define AL-ANIS (list WIGGLE1ANI STR1ANI ZIGZAG1ANI))

;; primitive to get an ani using its id
(define (get-ani id)
  (local [(define (id? a)
            (= (ani-id a) id))
          (define l (filter id? ANIS))]
    (if (= (length l) 1)
        (first l)
        (error "No animation with id " id))))


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
(define AL4 (make-alien-laser 100 (- HEIGHT 30) WIGGLE1ANI 5))
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
(define-struct alien (x y dir ticks ani))
;; Alien is (make-alien Number Number String Natural Animation)
;; interp. an alien enemy that moves towards the player and shoots lasers
;;         x and y are the position in screen coordinates
;;         dir is "left" or "right", the direction the alien will jump next
;;         ticks is the number of ticks left until the next jump
;;         ani is the current animation, changes on jump
(define A1 (make-alien 100 200 "right" 20 ARMS1ANI))
(define A1E (make-alien 100 200 "right" EXPLODE-TICKS EXPLODEDANI))
(define A2 (make-alien 50 70 "left" 0 ARMS2ANI))
(define A2E (make-alien 50 70 "left" EXPLODE-TICKS EXPLODEDANI))
(define A3 (make-alien 10 100 "left" 0 METROID1ANI))

(define START-ALIENS
  (append (build-list ALIEN-NUM
                      (λ (i) (make-alien (+ ALIEN-START-X (* ALIEN-SPACE-X i))
                                         (+ ALIEN-START-Y (* ALIEN-SPACE-Y 0))
                                         ALIEN-START-DIR
                                         ALIEN-TICKS-START
                                         OCTOPUS1ANI)))
          (build-list ALIEN-NUM
                      (λ (i) (make-alien (+ ALIEN-START-X (* ALIEN-SPACE-X i))
                                         (+ ALIEN-START-Y (* ALIEN-SPACE-Y 1))
                                         ALIEN-START-DIR
                                         ALIEN-TICKS-START
                                         ARMS1ANI)))
          (build-list ALIEN-NUM
                      (λ (i) (make-alien (+ ALIEN-START-X (* ALIEN-SPACE-X i))
                                         (+ ALIEN-START-Y (* ALIEN-SPACE-Y 2))
                                         ALIEN-START-DIR
                                         ALIEN-TICKS-START
                                         ARMS1ANI)))
          (build-list ALIEN-NUM
                      (λ (i) (make-alien (+ ALIEN-START-X (* ALIEN-SPACE-X i))
                                         (+ ALIEN-START-Y (* ALIEN-SPACE-Y 3))
                                         ALIEN-START-DIR
                                         ALIEN-TICKS-START
                                         METROID1ANI)))
          (build-list ALIEN-NUM
                      (λ (i) (make-alien (+ ALIEN-START-X (* ALIEN-SPACE-X i))
                                         (+ ALIEN-START-Y (* ALIEN-SPACE-Y 4))
                                         ALIEN-START-DIR
                                         ALIEN-TICKS-START
                                         METROID1ANI)))))


(@htdd AL)
(define-struct al (alien lasers))
;; AL is (make-al Alien (listof PlayerLaser))
;; interp. a struct used in handle-alien-collisions to hold
;;         an alien and a list of player lasers


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
                          empty
                          START-ALIENS
                          TIMER-START
                          false))

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
(define G8 (make-game (make-ship 100 0) empty
                      (list A1)
                      0 false))
(define G9 (make-game (make-ship 100 0) empty
                      (list A1 A2)
                      10 false))
(define G10 (make-game (make-ship 100 0) empty
                       (list A1 A3)
                       10 false))


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
(check-expect (tock G3) G3)

(@template-origin Game fn-composition)
(define (tock g)
  (local [(define (tock-ship-game g)
            (make-game (tock-ship (game-ship g))
                       (game-lasers g)
                       (game-aliens g)
                       (game-timer g)
                       (game-over? g)))]
    (cond [(false? g) g]
          [(empty? (game-aliens g)) g]
          [else
           (tock-timer (tock-aliens (tock-lasers (tock-ship-game g))))])))


(@htdf tock-timer)
(@signature Game -> Game)
;; update timer, if 0, shoot from a random alien
(check-expect (tock-timer (make-game (make-ship 100 0) empty empty 10 false))
              (make-game (make-ship 100 0) empty empty 10 false))
(check-expect (tock-timer
               (make-game (make-ship 100 0)
                          (list PL1 AL1)
                          (list A1 A2)
                          1 false))
              (make-game (make-ship 100 0)
                         (list PL1 AL1)
                         (list A1 A2)
                         0 false))
(check-expect (tock-timer
               (make-game (make-ship 100 0)
                          (list PL1 AL1)
                          (list A1 A2)
                          1 false))
              (make-game (make-ship 100 0)
                         (list PL1 AL1)
                         (list A1 A2)
                         0 false))

(check-random (tock-timer
               (make-game (make-ship 100 0)
                          (list PL1 AL1)
                          (list A1)
                          0 false))
              (make-game (make-ship 100 (random 1)) ; this fixes randomness
                         (list (make-alien-laser 100 200
                                                 (choose-random AL-ANIS)
                                                 ALIEN-LASER-ANIMATION-SPEED)
                               PL1 AL1)
                         (list A1)
                         TIMER-START false))

(define (tock-timer g)
  (cond [(empty? (game-aliens g)) g]
        [(> (game-timer g) 0) (make-game (game-ship g) (game-lasers g)
                                         (game-aliens g)
                                         (sub1 (game-timer g))
                                         (game-over? g))]
        [else
         (local [(define ra (choose-random (game-aliens g)))
                 (define new-laser
                   (make-alien-laser (alien-x ra) (alien-y ra)
                                     (choose-random AL-ANIS)
                                     ALIEN-LASER-ANIMATION-SPEED))]
           (make-game (game-ship g)
                      (cons new-laser (game-lasers g))
                      (game-aliens g)
                      TIMER-START
                      (game-over? g)))]))



(@htdf choose-random)
(@signature (listof X) -> X)
;; produce a random element of lox, assume lox is not empty
(check-expect (choose-random (list 1)) 1)
(check-random (choose-random (list 1 2 3))
              (list-ref (list 1 2 3) (random 3)))
(check-random (choose-random (list "A" "B" "C" "D" "E"))
              (list-ref (list "A" "B" "C" "D" "E") (random 5)))

(define (choose-random lox)
  (list-ref lox (random (length lox))))



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
(check-expect (tock-lasers (make-game (make-ship 100 0)
                                      (list AL4)
                                      empty 3 false))
              (make-game (make-ship 100 0) empty empty 3 true))
(check-expect (tock-lasers
               (make-game (make-ship 100 0)
                          (list (make-player-laser 100 220))
                          (list A1)
                          0 false))
              (make-game (make-ship 100 0)
                         empty
                         (list A1E)
                         0 false))

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
                    (alien-laser-ani l) (alien-laser-timer l))]))

          (define (any-laser-on-ship? g)
            (ormap laser-on-ship? (filter alien-laser? lol)))
          (define (laser-on-ship? l)
            (colliding? (alien-laser-x l) (alien-laser-y l)
                        (ani-img (alien-laser-ani l))
                        (ship-x (game-ship g)) SHIP-Y SHIP))]
    (if (any-laser-on-ship? g)
        (make-game
         (game-ship g) empty (game-aliens g) (game-timer g) true)
        
        (handle-alien-collisions
         (make-game
          (game-ship g)
          (map update-alien-laser-ani
               (filter onscreen?
                       (map move-laser lol)))
          (game-aliens g) (game-timer g) (game-over? g))))))


(@htdf handle-alien-collisions)
(@signature Game -> Game)
;; explode all aliens in collision with a laser, and delete the laser
(check-expect (handle-alien-collisions
               (make-game (make-ship 100 0)
                          empty empty
                          0 false))
              (make-game (make-ship 100 0)
                         empty empty
                         0 false))
(check-expect (handle-alien-collisions
               (make-game (make-ship 100 0)
                          (list PL1)
                          empty
                          0 false))
              (make-game (make-ship 100 0)
                         (list PL1)
                         empty
                         0 false))
(check-expect (handle-alien-collisions
               (make-game (make-ship 100 0)
                          empty
                          (list A1)
                          0 false))
              (make-game (make-ship 100 0)
                         empty
                         (list A1)
                         0 false))


(check-expect (handle-alien-collisions
               (make-game (make-ship 100 0)
                          (list (make-player-laser 100 200))
                          (list A1)
                          0 false))
              (make-game (make-ship 100 0)
                         empty
                         (list A1E)
                         0 false))
(check-expect (handle-alien-collisions
               (make-game (make-ship 100 0)
                          (list (make-player-laser 100 300))
                          (list A1)
                          0 false))
              (make-game (make-ship 100 0)
                         (list (make-player-laser 100 300))
                         (list A1)
                         0 false))
(check-expect (handle-alien-collisions
               (make-game (make-ship 100 0)
                          (list (make-player-laser 100 200)
                                (make-player-laser 49 71))
                          (list A2 A1 A3)
                          0 false))
              (make-game (make-ship 100 0)
                         empty
                         (list A2E A1E A3)
                         0 false))

(check-expect (handle-alien-collisions
               (make-game (make-ship 100 0)
                          (list AL1)
                          empty 0 false))
              (make-game (make-ship 100 0)
                         (list AL1)
                         empty 0 false))
(check-expect (handle-alien-collisions
               (make-game (make-ship 100 0)
                          (list PL1 AL1)
                          (list A1E)
                          0 false))
              (make-game (make-ship 100 0)
                         (list PL1 AL1)
                         (list A1E)
                         0 false))

(@template-origin Alien (listof Alien) accumulator use-abstract-fn)
(define (handle-alien-collisions g)
  ;; wl is (listof Alien): the list of aliens we still need to check
  ;; lol-rsf is (listof Laser): the new list of lasers
  ;; loa-rsf is (listof Alien): the new list of aliens
  (local [(define (not-exploded? a)
            (not (= (ani-id (alien-ani a)) (ani-id EXPLODEDANI))))
          (define (exploded? a)
            (= (ani-id (alien-ani a)) (ani-id EXPLODEDANI)))
          
          (define pllol0 (filter player-laser? (game-lasers g)))
          (define allol0 (filter alien-laser? (game-lasers g)))
          (define loa0 (filter not-exploded? (game-aliens g)))
          (define eloa0 (filter exploded? (game-aliens g)))

          (define (fn-for-loa a-wl lol-rsf loa-rsf)
            (cond [(empty? a-wl) (make-game (game-ship g)
                                            (append lol-rsf allol0)
                                            (append (reverse loa-rsf) eloa0)
                                            (game-timer g) (game-over? g))]
                  [else
                   (local [(define result (do-collisions
                                           (make-al (first a-wl) lol-rsf)))
                           (define new-a (al-alien result))
                           (define new-lol (al-lasers result))]
                     (fn-for-loa (rest a-wl) new-lol (cons new-a loa-rsf)))]))]

    (fn-for-loa loa0 pllol0 empty)))
    

(@htdf do-collisions)
(@signature AL -> AL)
;; produce new lasers and aliens after colliding a with all lasers
(check-expect (do-collisions (make-al A1 empty))
              (make-al A1 empty))
(check-expect (do-collisions (make-al A1 (list (make-player-laser 50 50)
                                               (make-player-laser 100 200)
                                               (make-player-laser 200 200))))
              (make-al A1E (list (make-player-laser 50 50)
                                 (make-player-laser 200 200))))
(check-expect (do-collisions (make-al A2 (list (make-player-laser 100 200)
                                               (make-player-laser 200 200))))
              (make-al A2 (list (make-player-laser 100 200)
                                (make-player-laser 200 200))))

(@template-origin (listof PlayerLaser) accumulator)
(define (do-collisions al)
  ;; rsf is (listof Laser): the lasers that have been checked already
  (local [(define lol0 (al-lasers al))
          (define a (al-alien al))

          (define (fn-for-lol lol rsf)
            (cond [(empty? lol) (make-al a rsf)]
                  [(colliding? (player-laser-x (first lol))
                               (player-laser-y (first lol))
                               PLAYER-LASER
                               (alien-x a) (alien-y a)
                               (ani-img (alien-ani a)))
                   (make-al (explode a) (append rsf (rest lol)))]
                  [else
                   (fn-for-lol (rest lol) (append rsf (list (first lol))))]))

          (define (explode a)
            (make-alien (alien-x a) (alien-y a) (alien-dir a)
                        EXPLODE-TICKS
                        EXPLODEDANI))]
    (fn-for-lol lol0 empty)))
  


(@htdf colliding?)
(@signature Number Number Image Number Number Image -> Boolean)
;; given 2 images and their center position, produce true if they overlap
(check-expect (colliding? 0 0 (square 10 "solid" "purple")
                          0 0 (square 20 "solid" "purple"))
              true)

(check-expect (colliding? 30 30 (rectangle 20 10 "solid" "purple")
                          45 30 (square 10 "solid" "purple"))
              false)
(check-expect (colliding? 30 30 (rectangle 20 10 "solid" "purple")
                          45 30 (square 11 "solid" "purple"))
              true)
(check-expect (colliding? 30 30 (rectangle 20 10 "solid" "purple")
                          44 30 (square 10 "solid" "purple"))
              true)

(check-expect (colliding? 30 30 (rectangle 20 10 "solid" "purple")
                          30 35 (square 1 "solid" "purple"))
              true)
(check-expect (colliding? 30 30 (rectangle 20 10 "solid" "purple")
                          30 36 (square 1 "solid" "purple"))
              false)
(check-expect (colliding? 30 30 (rectangle 20 10 "solid" "purple")
                          30 25 (square 1 "solid" "purple"))
              true)
(check-expect (colliding? 30 30 (rectangle 20 10 "solid" "purple")
                          30 24 (square 1 "solid" "purple"))
              false)

(check-expect (colliding? 30 30 (rectangle 20 10 "solid" "purple")
                          20 30 (square 1 "solid" "purple"))
              true)
(check-expect (colliding? 30 30 (rectangle 20 10 "solid" "purple")
                          19 30 (square 1 "solid" "purple"))
              false)
(check-expect (colliding? 30 30 (rectangle 20 10 "solid" "purple")
                          40 30 (square 1 "solid" "purple"))
              true)
(check-expect (colliding? 30 30 (rectangle 20 10 "solid" "purple")
                          41 30 (square 1 "solid" "purple"))
              false)

(check-expect (colliding? 10 10 (square 10 "solid" "purple")
                          90 10 (square 10 "solid" "purple"))
              false)
(check-expect (colliding? 10 10 (square 10 "solid" "purple")
                          10 90 (square 10 "solid" "purple"))
              false)

(define (colliding? x1 y1 i1 x2 y2 i2)
  (local [(define l1 (- x1 (/ (image-width i1) 2)))
          (define r1 (+ x1 (/ (image-width i1) 2)))
          (define d1 (- y1 (/ (image-height i1) 2)))
          (define u1 (+ y1 (/ (image-height i1) 2)))
          
          (define l2 (- x2 (/ (image-width i2) 2)))
          (define r2 (+ x2 (/ (image-width i2) 2)))
          (define d2 (- y2 (/ (image-height i2) 2)))
          (define u2 (+ y2 (/ (image-height i2) 2)))]
    
    (and (overlap? l1 r1 l2 r2)
         (overlap? d1 u1 d2 u2))))


(@htdf overlap?)
(@signature Number Number Number Number -> Boolean)
;; produce true if 2 number ranges overlap
(check-expect (overlap? 10 20 20 30) false)
(check-expect (overlap? 20 30 10 20) false)
(check-expect (overlap? 10 20 19 30) true)
(check-expect (overlap? 19 30 10 20) true)
(check-expect (overlap? 50 60 30 50) false)
(check-expect (overlap? 50 60 30 51) true)
(check-expect (overlap? 10 90 30 40) true)
(check-expect (overlap? 30 40 10 90) true)

(define (overlap? l1 r1 l2 r2)
  ; check every edge to see if it is in between the other range
  ; and check if they are the exact same range
  (or (< l2 l1 r2)
      (< l2 r1 r2)
      (< l1 l2 r1)
      (< l1 r2 r1)
      (and (= l1 l2) (= r1 r2))))


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
;; update alien timers & move them, handle collisions with ship
(check-expect (tock-aliens G8)
              (make-game (make-ship 100 0) empty
                         (list
                          (make-alien 100 200 "right" 19 ARMS1ANI))
                         0 false))
(check-expect (tock-aliens G9)
              (make-game (make-ship 100 0) empty
                         (list
                          (make-alien 100 200 "right" 19 ARMS1ANI)
                          (make-alien (- 50 ALIEN-JUMP-X)
                                      70 "left" 
                                      (alien-timer G9) ARMS1ANI))
                         10 false))
(check-expect (tock-aliens G10)
              (make-game (make-ship 100 0) empty
                         (list
                          (make-alien 100 (+ 200 ALIEN-JUMP-Y)
                                      "left" (alien-timer G10) ARMS1ANI)
                          (make-alien 10 (+ 100 ALIEN-JUMP-Y)
                                      "right" (alien-timer G10) METROID1ANI))
                         10 false))

(check-expect (tock-aliens
               (make-game (make-ship 100 0) empty
                          (list (make-alien 50 50 "right" 3 EXPLODEDANI)
                                (make-alien 100 200 "right" 0 EXPLODEDANI))
                          0 false))
              (make-game (make-ship 100 0) empty
                         (list (make-alien 50 50 "right" 2 EXPLODEDANI))
                         0 false))

(check-expect (tock-aliens
               (make-game (make-ship 100 0) empty
                          (list (make-alien 100 SHIP-Y "right" 5 ARMS1ANI))
                          0 false))
              (make-game (make-ship 100 0) empty empty 0 true))
(check-expect (tock-aliens
               (make-game (make-ship 100 0) empty
                          (list (make-alien 100 SHIP-Y "right" 5 EXPLODEDANI))
                          0 false))
              (make-game (make-ship 100 0) empty
                         (list (make-alien 100 SHIP-Y "right" 4 EXPLODEDANI))
                         0 false))

(define (tock-aliens g)
  (local [(define (not-exploded? a)
            (not (= (ani-id (alien-ani a)) (ani-id EXPLODEDANI))))

          (define (not-0-and-exploded? a)
            (not (and (= (ani-id (alien-ani a)) (ani-id EXPLODEDANI))
                      (zero? (alien-ticks a)))))

          (define loa (filter not-0-and-exploded? (game-aliens g)))
          
          (define (at-edge? a)
            (or (< (next-x a) ALIEN-MIN-X)
                (> (next-x a) ALIEN-MAX-X)))
          
          (define (next-x a)
            (cond [(string=? (alien-dir a) "right")
                   (+ (alien-x a) ALIEN-JUMP-X)]
                  [else
                   (- (alien-x a) ALIEN-JUMP-X)]))
          
          (define (tock-alien a)
            (if (zero? (alien-ticks a))
                (make-alien (next-x a) (alien-y a) (alien-dir a)
                            (alien-timer g)
                            (get-ani (ani-next (alien-ani a))))
                (make-alien (alien-x a) (alien-y a) (alien-dir a)
                            (sub1 (alien-ticks a)) (alien-ani a))))
          
          (define (turn-around a)
            (make-alien (alien-x a) (+ (alien-y a) ALIEN-JUMP-Y)
                        (if (string=? (alien-dir a) "right")
                            "left"
                            "right")
                        (alien-timer g)
                        (alien-ani a)))

          (define (any-alien-on-ship? g)
            (ormap alien-on-ship? (filter not-exploded? loa)))
          (define (alien-on-ship? a)
            (colliding? (alien-x a) (alien-y a)
                        (ani-img (alien-ani a))
                        (ship-x (game-ship g)) SHIP-Y SHIP))]

    (if (any-alien-on-ship? g)
        (make-game (game-ship g) empty empty (game-timer g) true)
        
        (make-game
         (game-ship g) (game-lasers g)
         (cond [(ormap at-edge? loa) (map turn-around loa)]
               [else
                (map tock-alien loa)])
         (game-timer g) (game-over? g)))))


(@htdf alien-timer)
(@signature Game -> Natural)
;; produce the new move ticks for the aliens based on the game state
(check-expect (alien-timer GSTART) ALIEN-TICKS-START)
(check-expect (alien-timer G8) ALIEN-TICKS-MIN)

(define (alien-timer g)
  (local [(define num (length (game-aliens g)))
          (define m (/ (- ALIEN-TICKS-START ALIEN-TICKS-MIN)
                       (- TOTAL-ALIEN-NUM 1)))]
    (round (+ (* m (sub1 num)) ALIEN-TICKS-MIN))))
    


(@htdf render)
(@signature Game -> Image)
;; render start screen, game, or end screen on game
(check-expect (render G0) START-SCREEN)
(check-expect (render G1)
              (place-image WIN-SCREEN (/ WIDTH 2) (/ HEIGHT 2)
                           (place-ship G1 MTS)))
(check-expect (render G2)
              (place-image END-SCREEN
                           (/ WIDTH 2) (/ HEIGHT 2)
                           (place-image SHIP-EXPLODE 50 SHIP-Y MTS)))

(@template-origin Game)
(define (render g)
  (cond [(false? g) START-SCREEN]
        [(game-over? g) (place-image END-SCREEN (/ WIDTH 2) (/ HEIGHT 2)
                                     (place-ship g MTS))]
        [(empty? (game-aliens g))
         (place-image WIN-SCREEN (/ WIDTH 2) (/ HEIGHT 2)
                      (place-ship g MTS))]
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
(check-expect (place-aliens G8 (square 30 "solid" "purple"))
              (place-image ARMS1 100 200 (square 30 "solid" "purple")))
(check-expect (place-aliens G9 MTS)
              (place-image ARMS1 100 200
                           (place-image ARMS2 50 70 MTS)))

(define (place-aliens g i)
  (local [(define (place-alien a i)
            (place-image (ani-img (alien-ani a))
                         (alien-x a) (alien-y a) i))]
    (foldr place-alien i (game-aliens g))))


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

(check-expect (handle-key G8 "left")
              (make-game (make-ship 100 (- SHIP-SPEED)) empty
                         (list A1) 0 false))
(check-expect (handle-key G8 " ")
              (make-game (make-ship 100 0)
                         (list (make-player-laser 100 PLAYER-LASER-Y))
                         (list A1) 0 false))

(check-expect (handle-key G2 "a") G2)
(check-expect (handle-key G2 "left") G2)
(check-expect (handle-key G2 " ") G2)
(check-expect (handle-key G2 "r") GSTART)

(@template-origin Game)
(define (handle-key g ke)
  (cond [(false? g) (if (key=? ke " ")
                        GSTART
                        g)]
        [(or (game-over? g) (empty? (game-aliens g)))
         (if (key=? ke "r")
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



(if AUTO-START
    (main START)
    "auto start disabled")
    

