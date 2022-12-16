A simple Space Invaders clone made in [Intermediate Student Language](https://docs.racket-lang.org/htdp-langs/index.html), a
variation of Racket used in University of British Columbia's CPSC 110 class.

(images)

## How to run
Download <a href="invaders.rkt" download>invaders.rkt</a> and run the file to play! You will need 
[DrRacket](https://download.racket-lang.org/) installed with the Systematic Program Design plugin, which you can get
[here.](https://ssc.adm.ubc.ca/sscportal/apply.xhtml)

If you don't want the game to take around 15 seconds to download the sprites every time you start, download the respository
(which includes the sprite folders) and change `FROM-INTERNET` to `false`.

## TODO (probably not by me, but feel free to have a go at it)
* Make the movement less janky (keep track of which keys are pressed, not just when keys are pressed)
* Increasing difficulty every restart
* Score counter that persists across restarts
* Shields

## Do you want to make a game in ISL?
It's a lot of fun, and very rewarding when everything starts working! It's also a great way to practice designing functions, data definitions, and programs for CPSC 110.

I would recommend doing a very good domain analysis before you start- there will always be things to change later, but editing your world state definition too much will cause some major headaches. And remember, always trust the natural recursion!

## Acknowledgements
* [lospec.com](https://lospec.com/) for the pixel art editing tools
* [spriters-resource.com](https://www.spriters-resource.com/arcade/spaceinv/) for the Space Invaders spritesheet
