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

(define SHIP (scale 0.4 (bitmap/file "sprites/ship.png")))
(define SHIP-Y (- HEIGHT 30))
(define SHIP-X-START (/ WIDTH 2))
(define SHIP-SPEED 5) ;; pixels per tick

;; =================
;; Data definitions:

(@htdd Game)
(define-struct game (ship-x lasers aliens over?))
;; Game is one of:
;;  - false
;;  - (make-game Number (listof Laser) (listof Alien) Boolean)
;; interp.
;;    false means game has not started yet
;;    ship-x is x position of the ship
;;    lasers is a list of all lasers on the screen
;;    aliens is a list of all aliens on the screen
;;    over? is false normally, but becomes true when the player loses
(define G0 false)
(define G1 (make-game 100 empty empty false))
(define G2 (make-game 50 empty empty true))
(define GSTART (make-game SHIP-X-START empty empty false)) ; !!! add aliens here
 
; !!! examples with aliens and lasers

; !!! (@htdd Laser)

; !!! (@htdd Alien)


;; =================
;; Functions:

(@htdf main)
(@signature Game -> Game)
;; start the world with (main START)

(@template-origin htdw-main)
(define (main g)
  (big-bang g
    (on-tick  tock)         ; Game -> Game
    (to-draw  render)       ; Game -> Image
    (on-key   handle-key))) ; Game KeyEvent -> Game



(@htdf tock)
(@signature Game -> Game)
;; advance the game state by 1 tick
;; !!! when we have lasers
(define (tock g) g)


(@htdf render)
(@signature Game -> Image)
;; render start screen, game, or end screen on game
(check-expect (render G0) START-SCREEN)
(check-expect (render G1)
              (place-image SHIP 100 SHIP-Y MTS))
(check-expect (render G2)
              (place-image SHIP 50 SHIP-Y
                           (place-image END-SCREEN
                                        (/ WIDTH 2) (/ HEIGHT 2) MTS)))

(@template-origin Game)
(define (render g)
  (cond [(false? g) START-SCREEN]
        [(game-over? g) (place-image END-SCREEN (/ WIDTH 2) (/ HEIGHT 2)
                                     (render-game g))]
        [else
         (render-game g)]))


(@htdf render-game)
(@signature Game -> Image)
;; render ship, lasers, aliens !!!
(check-expect (render-game G1)
              (place-image SHIP 100 SHIP-Y MTS))

(@template-origin Game) ; !!! this will be fn-composition when we add others
(define (render-game g)
  (place-image SHIP (game-ship-x g) SHIP-Y MTS))


(@htdf handle-key)
(@signature Game KeyEvent -> Game)
;; handle keys for start and end screens
(check-expect (handle-key G0 " ") GSTART)
(check-expect (handle-key G0 "left") G0)
(check-expect (handle-key G0 "a") G0)

(check-expect (handle-key G1 "a") G1)
(check-expect (handle-key G1 "left")
              (make-game (- 100 SHIP-SPEED) empty empty false))
(check-expect (handle-key G1 "right")
              (make-game (+ 100 SHIP-SPEED) empty empty false))

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
;; move with arrow keys, shoot with space
(check-expect (handle-key-game G1 "left")
              (make-game (- 100 SHIP-SPEED) empty empty false))
(check-expect (handle-key-game G1 "right")
              (make-game (+ 100 SHIP-SPEED) empty empty false))
(check-expect (handle-key-game G1 "a") G1)
; !!! space to shoot

(@template-origin KeyEvent)
(define (handle-key-game g ke)
  (cond [(key=? ke "left") (ship-move g (- SHIP-SPEED))]
        [(key=? ke "right") (ship-move g SHIP-SPEED)]
        [(key=? ke " ") (ship-shoot g)]
        [else g]))


(@htdf ship-move)
(@signature Game Number -> Game)
;; move ship by n, don't go past walls !!!
(check-expect (ship-move G1 5)
              (make-game (+ 100 5) empty empty false))
(check-expect (ship-move G1 -4)
              (make-game (+ 100 -4) empty empty false))

(define (ship-move g n)
  (make-game (+ (game-ship-x g) n)
             (game-lasers g) (game-aliens g) (game-over? g)))


(@htdf ship-shoot)
(@signature Game -> Game)
;; shoot a laster from the ship's position
; !!!
(define (ship-shoot g) g)
        

















