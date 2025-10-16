Hello and welcome to this completely new version 
of MilkyPlay - my little spare time Module player project.

----------------
*** History ***:
----------------
- 11/04/05 (0.9.7rc2):
* Improved GUI & usability
* Even more improved Protracker compatibility
* Even more improved FastTracker II compatibility
* Several minor fixes 

- 10/07/05 (0.9.7):
* added 2 new fileformats:
  DIGI: Digibooster (Note: This is not Digibooster PRO .dbm)
  ULT: UltraTracker
* Improved Protracker compatibility
* Improved FastTracker II compatibility
* Improved song end detection (also works for weird songs)

- 02/04/05 (0.9.5):
* added 4 new fileformats:
  FAR: Farandole Composer (Note: This uses the very original 
       FAR-replay routines)
  DSM: Dynamic Studio Modules
  IMF: Imago Orpheus (no filter envelopes yet)
  OKT: Oktalyzer (Plays some Oktalyzer-specific commands as well)
* Added shuffle replay
* Reorganised instrument view into tabs
  (you can now view instruments, samples and song-message)
* Possibility to repeat single song or entire playlist
* Changed lots of internal stuff, now it's possible to write
  different playing routines for different filetypes (.FAR for example)
* 669 Format is now also handled by the .FAR-player 
  (seems to be way more accurate)
* Fixed lots of bugs in the replaying routines 
  (thanks to all the people who sent modules)

- 01/07/05 (0.9.4):
* added 4 new fileformats:
  AMS (old): Extreme Tracker
  AMS (new): Velvet Studio  
  UNI: MikMod UNI Modules (UN04/UN05)
  669: Composer669 Modules
  GDM: General Digimusic (Bells, Whistles and Soundboards library)
* added option to load last playlist at startup

- 11/30/04 (0.9.3):
* got a new ICON :D
* added two new fileformats:
  MXM: Cubic Tiny XM (.MXM, old and new formats)
  PLM: DisorderTracker (.PLM)
* added support for STM arpeggio (thanks to Skaven/FC)
* added file association dialog (won't destroy previous association)
* added instruments dialog

- 11/09/04 (0.9.2c):
* mixer bugfix
* screen resized
* fixed memory leak in the ZIP loader/parser

- 10/19/04 (0.9.1c):
* fixed another "bug" in the XM loader, sorry for that one!

- 10/18/04 (0.9.1b):
* added support for compressed modules (ZIP)
* added configurable buttons for volume +/-
* improved XM loader + replay bugfixes
* rearranged playlist editor
* added recursive folder scanner 
  (will also scan zip files for playable content)

- MAJOR UPDATE: 10/03/04 (0.9.0b):
* rewrote the entire mixer (much!! faster and way better 
  click removal by using improved volume ramping)
* added four new fileformats:
  MTM: Multitracker Modules
  PTM: Polytracker Modules
  PSM: Epic Megagames MASI (old+new, thanks to Joshua C. Jensen)
  STM: Screamtracker II
  (check website for example songs)
* fixed lots of minor bugs
* added many new features to the player (playlists, 
  configurable button layout etc.)
* the milkyplay core is now also available under Mac OS X
  (CoreAudio) and might migrate to other platforms soon.

- 09/05/04 (0.6.0b):
Added two new fileformats (.DSM and .AMF) and fixed a few 
bugs in the replay routines plus you can now also play 
modules by opening them in the file explorer on your device 
(even if MilkyPlay is currently playing another module)

- 08/29/04 (0.5.0b):
Added support for Screamtracker 3 songs (might still be a
little bit buggy) and fixed some more bugs you might have
not noticed so far ;)

- 08/23/04 (0.3.0b): 
I spent the last 3 weeks rewriting the player-core to be
more implementation-friendly because i wanted to have a
robust, stable SFX API for PocketPC games and came up
with this little application. I hope you like it...
Please note that this GUI is a 2 days project and i only had
two devices to test it on. (Toshiba e310 (ARM) and 
Casio EM-500 (MIPS)). It might contain quite a few bugs
and i did not optimize the ARM version very well.
To be continued...

- Introduction:
MilkyPlay started off in 1997 when i decided to code my own 
module playing routines for Win95 - mainly for demo coding 
purposes - but unfortunately it was never used.


If you're interested in coding-talk or if you think you can
tell me how to write really fast software-mixing routines
or whatever don't hesitate to contact me!

**********************************************************
IF YOU'RE AN ARTIST AND YOU CAN PROVIDE SOME MODULES TO BE
OFFICIALLY INCLUDED IN THIS ARCHIVE PLEASE CONTACT ME !!!!
**********************************************************

----------------
*** Contact: ***
----------------
bape0016@fh-karlsruhe.de

----------------
*** Hompage: ***
----------------
http://oldschool.voodoofrog.com

Greetings to the entire PocketPC coding scene and
to Refractor for moral support!

Have a nice day...