namespace eval ataxx {
  variable ataxx

  set ataxx(ready) 0
}

#################################################################
#
# TkAtaxx -- a tcl/tk implementation of the Ataxx arcade game.
# The computer uses a multi-level game tree search routine with
# alpha-beta pruning.
# by Keith P. Vetter
#
# Revision history:
# KPV 1/6/95  - Initial revision
# KPV 8/22/95 - Ported to tk 4.0
# KPV Feb 19, 2003 - cleaned up and ported to 8.4

# 2006/01/21 - Eric Hassold
#   - Small improvement and porting for better look&feel when running
#     on eTcl for Windows Mobile

package require Tk

proc ::ataxx::wjoin {parent child} {
  if {![string compare "." $parent]} {
    set r ""
  } else {
    set r [string trimright $parent "."]
  }

  append r "." [string trimleft $child "."]

  return $r
}

##################################################################
#
# Init -- sets up some global variables
#
proc ::ataxx::Init {{cs 50}} {
  variable state 
  variable newb 
  variable index

  variable ataxx

  if {$ataxx(ready)} {
    return
  }

  set state(msg) "Welcome to TkAtaxx"
  set state(cs) $cs                           ;# Size of a cell
  set state(bs) [expr {round($cs * .9)}]      ;# Size of a blob
  set state(brd) -1                           ;# Last board used
  set state(c,1) Red                          ;# Colors for each player
  set state(c,2) Green
  set state(1) 0                              ;# Human
  set state(2) 1                              ;# Computer
  set state(level,max) 4
  set state(level,0) Random
  set state(level,1) Greedy
  set state(level,2) Brainy
  set state(level,3) Genius
  set state(level,4) Einstein
  set state(level,5) Einstein5                ;# Just be safe
  set state(level,6) Einstein6
  set state(level,7) Einstein7
  set state(level) 1                          ;# Current search level
  
  # Various boards to play on
  set newb(0) {{2,0} {4,0} {2,1} {4,1} {0,2} {6,2} {0,3}
    {3,3} {6,3} {0,4} {6,4} {2,5} {4,5} {2,6} {4,6}}
  set newb(1) {{3,0} {3,1} {3,2} {0,3} {1,3} {2,3}
    {4,3} {5,3} {6,3} {3,4} {3,5} {3,6}}
  set newb(2) {{3,0} {1,2} {2,2} {4,2} {5,2} {0,3} {1,3}
    {5,3} {6,3} {1,4} {2,4} {4,4} {5,4} {3,6}}
  set newb(3) {{1,0} {5,0} {0,1} {6,1} {3,3} {0,5} {6,5} {1,6} {5,6}}
  set newb(4) {{2,0} {4,0} {2,1} {4,1} {0,3} {6,3} {2,5} {4,5} {2,6} {4,6}}
  set newb(5) {{3,0} {3,1} {0,3} {1,3} {5,3} {6,3} {3,5} {3,6}}
  set newb(6) {{3,1} {2,2} {4,2} {1,3} {5,3} {2,4} {4,4} {3,5}}
  set newb(7) {{2,0} {4,0} {0,2} {6,2} {0,4} {6,4} {2,6} {4,6}}
  set newb(8) {{3,0} {2,1} {4,1} {1,2} {5,2} {0,3} {6,3} {1,4}
    {5,4} {2,5} {4,5} {3,6}}
  set newb(9) {{2,1} {4,1} {1,2} {5,2} {1,4} {5,4} {2,5} {4,5}}
  set newb(10) {{2,0} {4,0} {2,2} {4,2} {1,3} {5,3} {2,4} {4,4} {2,6} {4,6}}
  set newb(11) {{3,1} {3,2} {1,3} {2,3} {3,3} {4,3} {5,3} {3,4} {3,5}}
  set newb(12) {{1,1} {2,1} {3,1} {4,1} {5,1} {1,2}
    {5,2} {1,3} {5,3} {1,4} {5,4} {1,5} {2,5} {3,5} {4,5} {5,5}}
  set newb(13) {{2,1} {3,1} {4,1} {1,2} {5,2} {1,3}
    {5,3} {1,4} {5,4} {2,5} {3,5} {4,5}}
  set newb(14) {{2,1} {4,1} {1,2} {2,2} {4,2} {5,2}
    {1,4} {2,4} {4,4} {5,4} {2,5} {4,5}}
  set newb(15) {{1,1} {5,5} {1,5} {5,1}}
  set newb(16) {{1,1} {2,1} {4,1} {5,1} {1,2} {5,2}
    {1,4} {5,4} {1,5} {2,5} {4,5} {5,5}}
  set newb(17) {{3,2} {2,3} {3,3} {4,3} {3,4}}
  set newb(18) {{3,2} {2,3} {4,3} {3,4}}
  set newb(19) {{3,1} {3,2} {1,3} {2,3} {4,3} {5,3} {3,4} {3,5}}
  set newb(20) {{2,0} {3,0} {4,0} {3,1} {0,2} {6,2}
    {0,3} {1,3} {5,3} {6,3} {0,4} {6,4} {3,5} {2,6} {3,6} {4,6}}
  set newb(21) {{2,0} {4,0} {3,1} {0,2} {6,2} {1,3}
    {5,3} {0,4} {6,4} {3,5} {2,6} {4,6}}
  set newb(22) {{3,1} {1,3} {3,3} {5,3} {3,5}}
  set newb(23) {{1,1} {3,1} {5,1} {1,3} {3,3} {5,3} {1,5} {3,5} {5,5}}
  set newb(24) {}
  set newb(25) {{2,2} {4,2} {3,3} {2,4} {4,4}}
  set newb(26) {{1,1} {5,1} {2,2} {4,2} {3,3} {2,4} {4,4} {1,5} {5,5}}
  set newb(27) {{2,0} {3,0} {4,0} {2,1} {4,1} {0,3}
    {6,3} {2,5} {4,5} {2,6} {3,6} {4,6}}
  set newb(28) {{1,0} {3,0} {5,0} {0,1} {2,1} {4,1} {6,1}
    {1,2} {3,2} {5,2} {0,3} {2,3} {4,3} {6,3} {1,4}
    {3,4} {5,4} {0,5} {2,5} {4,5} {6,5} {1,6} {3,6} {5,6}}
  set newb(29) {{1,1} {5,1} {2,2} {4,2} {2,4} {4,4} {1,5} {5,5}}
  set newb(30) {{3,0} {2,1} {4,1} {0,3} {6,3} {2,5} {4,5} {3,6}}
  set newb(31) {{3,0} {0,3} {6,3} {3,6}}
  set newb(32) {{3,1} {1,3} {5,3} {3,5}}
  set newb(33) {{2,0} {3,0} {4,0} {0,2} {1,2} {3,2} {5,2}
    {6,2} {0,3} {6,3} {0,4} {1,4} {3,4} {5,4} {6,4} {2,6} {3,6} {4,6}}
  set newb(34) {{2,1} {4,1} {0,2} {1,2} {3,2} {5,2} {6,2}
    {3,3} {0,4} {1,4} {3,4} {5,4} {6,4} {2,5} {4,5}}
  set state(b) 35                             ;# Number of boards
  
  for {set r 0} {$r < 7} {incr r} {           ;# Precompute index values
    for {set c 0} {$c < 7} {incr c} {
      set index($r,$c) [expr {24 + 11*$r + $c}]
    }
  }

  set ataxx(ready) 1
  return
}

###############################################
#
# Display -- Sets up the display
#
proc ::ataxx::Display {top} {
  variable state
  
  set state(top) $top

  # wm title . "TkAtaxx"
  # wm minsize .  250 250

  set fbot [wjoin $top fbot]
  pack [frame $fbot] -side bottom -fill both

  DrawMenus
  
  set wi [expr {$state(cs) * 7}]              ;# Total width
  set canvas [canvas [wjoin $top c] \
		  -background white \
		  -width $wi -height $wi \
		  -borderwidth 0 -relief flat -highlightthickness 0]

  $canvas xview moveto 0
  $canvas yview moveto 0

  bind $canvas <1> [list [namespace current]::MouseDown %x %y]
  bind $canvas <Configure> [list [namespace current]::Resize]
  pack $canvas -side top -fill both -expand 1
  ShowGrid
  
  set fmsg [wjoin $top msg]
  label $fmsg \
      -relief ridge \
      -textvariable [namespace current]::state(msg) -anchor w
  set fsc [frame [wjoin $top fsc] -bd 2 -relief ridge]

  foreach n {1 2} {
    set pc [canvas ${canvas}_p$n -width 16 -height 16]
    ${canvas}_p$n create oval 2 2 15 15 -fill $state(c,$n)

    set pl [label [wjoin $top "p$n"] \
		-text "Score: "]
    set psc [label [wjoin $top "psc_$n"] \
		 -textvariable [namespace current]::state(sc,$n) \
		 -width 2]
    grid $pc $pl $psc -in $fsc -row [expr {$n - 1}]
  }

  set flevel [wjoin $top level]
  scale $flevel \
      -orient horizontal \
      -from 0 -to $state(level,max) \
      -relief flat \
      -showvalue 0 \
      -sliderrelief raised \
      -highlightthickness 0 \
      -variable [namespace current]::state(level)

  trace variable [namespace current]::state(level) w [namespace current]::TraceLevel

  set state(level) $state(level)

  pack $fmsg -side top -fill x -in $fbot
  pack $fsc -side left -ipadx 5 -expand yes -fill y -in $fbot
  pack $flevel -side right -expand yes -in $fbot -fill both
  
  bind $flevel <2> [list [namespace current]::AfterHint -1]
  bind $flevel <3> [list [namespace current]::AfterHint -1]

  return $top
}

proc ::ataxx::AfterHint {l} {
  after 1 [list [namespace current]::hint $l]

  return -code break
}

#######################################################################
#
# DrawMenus -- Displays the menus on the screen
#
proc ::ataxx::DrawMenus {} {
  variable state
  
  set ns [namespace current]

  if {[llength [info command ::evodash]]>0} {
    package require toolbar

    set t [toolbar [wjoin $state(top) toolbar]]
    $t add button \
	-balloon "Start new game" \
	-image [evodash actionicon eventnew] \
	-command [list ${ns}::Go]
    $t add button \
	-balloon "Restart this game" \
	-image [evodash actionicon reload] \
	-command [list ${ns}::Go -1]
    $t add button \
	-balloon "Undo last move" \
	-image [evodash actionicon undo] \
	-command [list ${ns}::undo]
    $t add button \
	-balloon "Hint" \
	-image [evodash actionicon whatsnext] \
	-command [list ${ns}::hint]
    $t add button \
	-balloon "Help" \
	-image [evodash actionicon wizard] \
	-command [list ${ns}::Help]
    
    pack $t -side top -fill x -expand false
  } else {
    set menu [wjoin $state(top) mb]

    [winfo toplevel $state(top)] configure -menu ""
    catch {destroy $menu}

    menu $menu -tearoff 0
    
    $menu add cascade -menu $menu.game -label "Game"     -underline 0
    $menu add cascade -menu $menu.opp  -label "Opponent" -underline 0
    $menu add cascade -menu $menu.help -label "Help"     -underline 0
    
    menu $menu.game
    $menu.game add command -label "New Board" -under 0 -command ${ns}::Go
    $menu.game add command -label "Restart"   -under 0 -command [list ${ns}::Go -1]
    $menu.game add separator
    $menu.game add command -label "Hint" -under 0 -command ${ns}::hint
    $menu.game add command -label "Undo" -under 0 -command ${ns}::undo
    $menu.game add separator
    $menu.game add command -label "Exit" -under 0 -command exit
    
    menu $menu.opp
    $menu.opp add check \
	-label "Red - Computer" \
	-under 0 \
	-variable [namespace current]::state(1) \
	-command ${ns}::Start
    $menu.opp add check \
	-label "Green - Computer" \
	-under 0 \
	-variable [namespace current]::state(2) \
	-command ${ns}::Start
    $menu.opp add separator
    for {set lvl 0} {$lvl <= $state(level,max)} {incr lvl} {
      $menu.opp add radio \
	  -label $state(level,$lvl) \
	  -variable [namespace current]::state(level) \
	  -value $lvl \
	  -under [expr {$lvl == 3 ? 2 : 0}]
    }
    
    menu $menu.help
    $menu.help add command -label Help -under 0 -command ${ns}::Help
    $menu.help add command -label About -under 0 -command ${ns}::About

    # Workaround eTcl bug - detach then reattach menu
    [winfo toplevel $state(top)] configure -menu $menu
  }

  return
}
#####################################################
#
# TraceLevel -- Handles changes in the scale for the depth of search
#
proc ::ataxx::TraceLevel {var1 var2 op} {
  variable state

  set level $state(level)
  set skill $state(level,$level)

  set w [wjoin $state(top) level] 
  $w configure -label "Skill: $skill"

  return
}
#####################################################
#
# RedrawBoard -- redraws all the pips and obstacles on the board
#
proc ::ataxx::RedrawBoard {{brd ""}} {
  variable state 
  variable bb 
  variable index
  
  if {$brd != ""} {set bb $brd}
  
  set canvas [wjoin $state(top) c]

  ShowGrid
  $canvas delete blob
  set state(sc,0) 0                           ;# Reset the scores
  set state(sc,1) 0                           ;# 0 is blanks, 1 is player 1
  set state(sc,2) 0                           ;# 2 is player 2
  set state(sc,3) 0                           ;# 3 is barriers
  
  for {set r 0} {$r < 7} {incr r} {
    for {set c 0} {$c < 7} {incr c} {
      set cell [lindex $bb $index($r,$c)] ;# What's in the cell
      incr state(sc,$cell)                ;# Update score info
      
      if {$cell == 3} {
	MakeObstacle $r $c
      } elseif {$cell > 0} {
	MakeBlob $cell $r $c
      }
    }
  }
  set bb [lreplace $bb 121 end $state(sc,0) $state(sc,1) $state(sc,2) \
	      $state(sc,3)]
}
#####################################################
#
# ShowGrid -- toggles the display of a grid on the board
#
proc ::ataxx::ShowGrid {} {
  variable state
  
  set canvas [wjoin $state(top) c]

  $canvas delete grid
  set wi [expr {$state(cs) * 7}]
  $canvas create rect 0 0 $wi $wi -width 5 -fill {} -tag grid
  
  for {set i 1} {$i < 7} {incr i} {
    set xy [expr {$i * $state(cs)}]
    $canvas create line 0 $xy $wi $xy -tag grid
    $canvas create line $xy $wi $xy 0 -tag grid
  }
}

proc ::ataxx::Resize {} {
  variable state

  set canvas [wjoin $state(top) c]

  set w [winfo width $canvas]
  set h [winfo height $canvas]

  set state(cs) [expr {(($w <= $h ? $w : $h) -10) / 7.0}]
  set state(bs) [expr {round($state(cs) * .9)}]

  RedrawBoard
}

#####################################################
#
# CellBBox -- returns the bounding box for a given row, col cell
#
proc ::ataxx::CellBBox {r c} {
  variable state
  
  set bs2 [expr {$state(bs) / 2.0}]
  set x [expr {round(($c+.5) * $state(cs) - $bs2)}]
  set y [expr {round(($r+.5) * $state(cs) - $bs2)}]
  set x2 [expr {$x + $state(bs)}]
  set y2 [expr {$y + $state(bs)}]
  
  return [list $x $y $x2 $y2]
}

#####################################################
#
# MakeBlob -- creates a new blob at location Row Col for WHO
#
proc ::ataxx::MakeBlob {who r {c -1}} {
  variable state 
  variable bb 
  variable index
  
  set canvas [wjoin $state(top) c]

  if {$c == -1} {
    set c [expr {($r % 11) - 2}]
    set r [expr {($r / 11) - 2}]
  }
  
  set col $state(c,$who)
  set xy [CellBBox $r $c]
  $canvas create oval $xy -fill ${col}3 -tag "blob blob${r}${c}"
  eval $canvas create arc $xy -start 45 -extent 180 -fill ${col}1 -outline {{}} \
      -tag \"blob blob${r}${c}\"
  $canvas create oval [Shrink $xy 5] -fill ${col}2 -outline {} \
      -tag "blob blob${r}${c}"
  
  set p $index($r,$c)                         ;# Update board info
  set bb [lreplace $bb $p $p $who]            ;# Put new piece there
}

#####################################################
#
# Shrink -- shrinks rectangle specified by x,y x2,y2
#
proc ::ataxx::Shrink {xy n} {
  foreach {x y x2 y2} $xy break
  set x [expr {$x + $n}]
  set y [expr {$y + $n}]
  set x2 [expr {$x2 - $n}]
  set y2 [expr {$y2 - $n}]
  
  return [list $x $y $x2 $y2]
}

#####################################################
#
# GrowBlob -- grows a blob at R,C
#
proc ::ataxx::GrowBlob {who r c} {
  variable state
  
  set canvas [wjoin $state(top) c]

  set xy [CellBBox $r $c]
  set step -1
  for {set i [expr {$state(bs) / 2}]} {$i >= 0} {incr i $step} {
    if {$i<0} {
      set i 0
    }

    set now [clock clicks -milliseconds]
    set bbox [Shrink $xy $i]
    $canvas create oval $bbox -tag grow -fill $state(c,$who)
    update idletasks
    set now [expr {[clock clicks -milliseconds] - $now}]
    set delay [expr {20 - $now}]
    if {$delay > 0} {
      after $delay
    } else {
      if {$step==-1} {
	set step -2
      } elseif {$step==-2} {
	set step -4
      }
    }
  }
  MakeBlob $who $r $c
  $canvas delete grow

  return
}

#####################################################
#
# Highlight -- highlights cell R, C
#
proc ::ataxx::highlight {r c} {
  variable state

  set canvas [wjoin $state(top) c]
  
  if {$r == -1} {
    $canvas delete high
    return
  }
  $canvas create rect [CellBBox $r $c] -fill {} -tag "blob high" -width 5
  $canvas lower high
}

#####################################################
#
# DeleteBlob -- deletes the blob from cell Row Col
#
proc ::ataxx::DeleteBlob {r {c -1}} {
  variable bb 
  variable index
  variable state

  set canvas [wjoin $state(top) c]

  if {$c == -1} {
    set c [expr {($r % 11) - 2}]
    set r [expr {($r / 11) - 2}]
  }
  $canvas delete blob${r}${c}
  
  set p $index($r,$c)                         ;# Update board info
  set bb [lreplace $bb $p $p 0]               ;# Cell now empty
}

#####################################################
#
# MakeObstacle -- creates an obstacle in cell Row Col
#
proc ::ataxx::MakeObstacle {r c} {
  variable bb 
  variable state
  
  set canvas [wjoin $state(top) c]

  set xy [CellBBox $r $c]
  foreach {x y x2 y2} $xy break
  
  $canvas create poly $x $y $x $y2 $x2 $y -fill white -tag blob
  $canvas create poly $x2 $y2 $x $y2 $x2 $y -fill gray45 -tag blob
  $canvas create rect [Shrink $xy 2] -fill gray -outline "" -tag blob
  
  set xy [Shrink $xy [expr {$state(cs) / 5}]]
  $canvas create rect $xy -fill $state(c,1) -outline "" -tag "blob center"

  return
}

#####################################################
#
# CleanBoard -- deletes everything off the board
#
proc ::ataxx::CleanBoard {} {
  variable bb
  variable state

  set canvas [wjoin $state(top) c]

  $canvas delete blob
  set    bb  "4 4 4 4 4 4 4 4 4 4 4"          ;# BB is the board info
  append bb " 4 4 4 4 4 4 4 4 4 4 4"          ;# ...w/ 2 row/col of sentinels
  
  append bb " 4 4 0 0 0 0 0 0 0 4 4"          ;# Actual board part
  append bb " 4 4 0 0 0 0 0 0 0 4 4"
  append bb " 4 4 0 0 0 0 0 0 0 4 4"
  append bb " 4 4 0 0 0 0 0 0 0 4 4"
  append bb " 4 4 0 0 0 0 0 0 0 4 4"
  append bb " 4 4 0 0 0 0 0 0 0 4 4"
  append bb " 4 4 0 0 0 0 0 0 0 4 4"
  
  append bb " 4 4 4 4 4 4 4 4 4 4 4"          ;# Bottom row sentinels
  append bb " 4 4 4 4 4 4 4 4 4 4 4"
  append bb " 45 2 2 0"                       ;# Cnt: empty, p1, p2, barriers
}

#####################################################
#
# FillBoard -- fills all blanks board positions with a blob. Called
# when the game is over.
#
proc ::ataxx::FillBoard {who} {
  variable state
  variable bb 
  variable index
  
  for {set r 0} {$r < 7} {incr r} {
    for {set c 0} {$c < 7} {incr c} {
      set p $index($r,$c)
      if {[lindex $bb $p] == 0} {
	MakeBlob $who $r $c
	incr state(sc,$who)
	update idletasks
      }
    }
  }
  
}

proc ::ataxx::Go {{restart 0}} {
  variable state

  set who -1
  if {$restart} { set who $state(brd)}
  NewBoard $who
  Start
}

#####################################################
#
# NewBoard -- creates a new board with obstacles of type N
#
proc ::ataxx::NewBoard {{who -1}} {
  variable newb 
  variable state
  variable bb 
  variable mm 
  variable index
  
  if {$who == -1} {
    set who [expr {int(rand() * $state(b))}]
    if {$who == $state(brd)} {
      set who [expr {int(rand() * $state(b))}]
    }
  }
  set state(brd) $who
  
  CleanBoard
  catch {unset mm}
  
  set xy $index(0,0) ; set bb [lreplace $bb $xy $xy 1]
  set xy $index(6,6) ; set bb [lreplace $bb $xy $xy 1]
  set xy $index(6,0) ; set bb [lreplace $bb $xy $xy 2]
  set xy $index(0,6) ; set bb [lreplace $bb $xy $xy 2]
  foreach p $newb($who) {                     ;# Add the obstacles
    set xy $index($p)
    set bb [lreplace $bb $xy $xy 3]
  }
  RedrawBoard
  set state(init) $bb
  set state(turn)  1
  set state(state) 0
  set state(n)     0
  set state(msg)   ""
  set state(tc) 0
  set state(c) 0
}

#####################################################
#
# Legal1 -- tests whether cell R,C is legal as a first move for
# player WHO. The cell must be in range, contain a WHO blob and can
# has a place to move.
#
proc ::ataxx::Legal1 {r c who} {
  variable bb 
  variable index
  
  set xy $index($r,$c)
  if {[lindex $bb $xy] != $who} { return 0 }
  
  foreach i {1 2 9 10 11 12 13 20 21 22 23 24} {;# Neighbors 1 & 2 cells away
    if {[lindex $bb [expr {$xy + $i}]] == 0} { return 1}
    if {[lindex $bb [expr {$xy - $i}]] == 0} { return 1}
  }
  
  return 0
}

#####################################################
#
# Legal2 -- Tests whether cell R,C is legal as a second move.
# Already we know the cell is empty, so we must check that
# its within 2 of the from cell.
#
proc ::ataxx::Legal2 {to from} {
  foreach {r c} $to break
  foreach {fr fc} $from break
  
  set dr [expr {abs($r - $fr)}]
  if {$dr > 2} { return 0 }
  set dc [expr {abs($c - $fc)}]
  if {$dc > 2} { return 0 }
  
  if {$dr == 2 || $dc == 2} { return 2}
  return 1
}

#####################################################
#
# MouseDown -- Called on a mouse down event. Handles moving pieces
# and checking legality.
#
proc ::ataxx::MouseDown {x y} {
  variable state 
  variable bb
  variable index
  
  set r [expr {int($y / $state(cs))}]
  set c [expr {int($x / $state(cs))}]
  if {$r < 0 || $r > 6 || $c < 0 || $c > 6} return
  set where [list $r $c]
  
  set xy $index($r,$c)
  set cell [lindex $bb $xy]
  
  if {$cell == $state(turn)} {
    highlight -1 -1
    if {$state(state) == 1 && $state(from) == $where} {
      set state(state) 0
      return
    }
    if [Legal1 $r $c $state(turn)] {
      highlight $r $c
      set state(state) 1
      set state(from) $where
      return
    }
  }
  if {$state(state) != 1} return
  if {$cell != 0} return
  
  set n [Legal2 $where $state(from)]
  if $n {
    DoMove $where $state(from) $n
  } else {
    highlight -1 -1
  }
  set state(state) 0
  
}

#####################################################
#
# DoMove -- does the move from FR,FC to R,C. Updates the blobs, toggles any
# neighbors of the new cell and checks for end-of-game, and can move?
#
proc ::ataxx::DoMove {to from type} {
  variable state
  variable bb
  variable mm
  
  set canvas [wjoin $state(top) c]

  foreach {r c} $to break
  foreach {fr fc} $from break
  set mm($state(n)) [list $state(turn) $r $c $fr $fc $type];# Undo info
  incr state(n)
  
  set who $state(turn)
  set opp [expr {3 - $who}]
  
  highlight -1 -1
  if {$type != -1} {
    GrowBlob $state(turn) $r $c
    set cnt [ToggleCells $r $c $state(turn)]
    incr state(sc,$who) $cnt
    incr state(sc,$opp) [expr {-1 * $cnt}]
    
    if {$type > 1} {                        ;# Long jump???
      DeleteBlob $fr $fc                  ;# ...then delete old blob
    } else {
      incr state(sc,$who)
      incr state(sc,0) -1
    }
    set bb [lreplace $bb 121 123 $state(sc,0) $state(sc,1) $state(sc,2)]
    update
  }
  
  if {$state(sc,0) == 0 || $state(sc,1) == 0 || $state(sc,2) == 0} {
    EndGame
    return
  }
  
  set mv [CanMove $opp]                       ;# Can opponent move?
  if {$mv == 0} {
    set state(msg) "$state(c,$opp) can't move. "
    set state(msg) "$state(msg) $state(c,$who)'s turn"
  } else {
    set state(turn) $opp
    $canvas itemconfig center -fill $state(c,$state(turn))
  }
  update
  if {$state($state(turn))} robot             ;# Do the computer move
}

#####################################################
#
# ToggleCells -- turns all neighbors of R,C of into WHO blobs
#
proc ::ataxx::ToggleCells {r c who} {
  variable bb
  variable index
  
  set opp [expr {3 - $who}]
  set cnt 0
  
  set xy $index($r,$c)
  foreach i {1 -1 10 -10 11 -11 12 -12} {     ;# Immediate neighbors
    set p [expr {$xy + $i}]
    if {[lindex $bb $p] == $opp} {
      DeleteBlob $p
      MakeBlob $who $p
      incr cnt
    }
  }
  
  return $cnt
}

#####################################################
#
# CanMove -- determines if WHO has a legal move
#
proc ::ataxx::CanMove {who} {
  variable state
  variable bb
  variable index
  
  for {set r 0} {$r < 7} {incr r} {
    for {set c 0} {$c < 7} {incr c} {
      set xy $index($r,$c)
      if {[lindex $bb $xy] != $who} continue
      
      if [Legal1 $r $c $who] {
	return 1
      }
    }
  }
  return 0
}

#####################################################
#
# EndGame -- handles end-of-game stuff
#
proc ::ataxx::EndGame {} {
  variable state
  
  if {$state(sc,0) != 0} {
    FillBoard [expr {($state(sc,1) > $state(sc,2)) ? 1 : 2}]
  }
  
  if {$state(sc,1) > $state(sc,2)} {          ;# Player 1 won
    set state(msg) "Game over: $state(c,1) won"
  } elseif {$state(sc,2) > $state(sc,1)} {    ;# Player 2 own
    set state(msg) "Game over: $state(c,2) won"
  } else {
    set state(msg) "Game over: it's a tie"
  }
}

#####################################################
#
# Index -- given row, col returns the corresponding index into the board
#
proc ::ataxx::rindex {i} {
  return [list [expr {($i / 11) - 2}] [expr {($i % 11) - 2}]]
}

#####################################################
#
# Undo -- undo last move. Works by replaying all but the last moves.
#
proc ::ataxx::undo {} {
  variable state
  variable mm
  variable bb
  
  set canvas [wjoin $state(top) c]

  if {$state(n) == 0} {
    set state(msg) "Nothing to undo"
    return
  }
  set state(msg) "Undoing last move"
  set brd $state(init)                        ;# Starting position
  set n [expr {$state(n) - 1}]                ;# Number of moves to undo
  set w [lindex $mm($n) 0]                    ;# Who made last turn
  if {$state($w)} {                           ;# Last move by computer
    incr n -1                               ;# So undo both moves
    set w [expr {3 - $w}]                   ;# Whose turn it is
  }
  
  for {set i 0} {$i < $n} {incr i} {          ;# Re-do each move
    set brd [move2 $brd $mm($i)]
  }
  
  set state(n) $n
  set bb $brd
  RedrawBoard
  
  set state(state) 0
  highlight -1 -1
  set state(turn) $w

  $canvas itemconfig center -fill $state(c,$state(turn))
}

#####################################################
#
# Robot -- moves the pieces for the robot player.
# Does a game-tree search for the best move.
#
proc ::ataxx::robot {{level -1}} {
  variable state
  variable bb
  
  set who $state(turn)
  if {$level == -1} { set level $state(level) }
  
  if {$level == 0} {                          ;# Random skill level
    set m [lindex [AllMoves $who $bb] 0]
  } else {
    set state(c) 0
    set state(msg) "Thinking ($state(level,$level))"
    busy 1
    set t [time {set mv [veb $who $bb $level 10000]}];# Get best move
    set state(msg) ""
    set tt [expr {[lindex $t 0] / 1000000.0}]
    set state(msg) "Rating: [lindex $mv 0] ($state(c) calls in $tt seconds)"
    incr state(tc) $state(c)
    busy 0
    
    set m [lindex $mv 1]
  }
  foreach {from to type} $m break
  DoMove [rindex $to] [rindex $from] $type
}

proc ::ataxx::busy {onoff} {
  variable state

  if {$onoff} {set how watch} {set how {}}

  foreach w [winfo children $state(top)] {
    $w configure -cursor $how
  }
  update idletasks
}
#####################################################
#
# Hint -- suggest a move
#
proc ::ataxx::hint {{level -1}} {
  variable state 
  variable bb
  
  if {$level == -1} {                         ;# Was level specified?
    set level $state(level)
    if {$level == 0} {                      ;# Level 0 is not a hint
      set level 1
    }
  }
  if {$level == -2} {                         ;# -2 is smart as possible
    set level $state(level,max)
  }
  if {$level < 0} {
    set level [expr {abs($level)}]
  }
  
  highlight -1 -1
  set state(c) 0
  set state(msg) "Thinking ($state(level,$level))"
  busy 1
  set t [time {set mv [veb $state(turn) $bb $level 10000]}];# Find best move
  set state(msg) ""
  set tt [expr {[lindex $t 0] / 1000000.0}]
  set state(msg) "Rating: [lindex $mv 0] ($state(c) calls in $tt seconds)"
  busy 0
  
  set m [lindex $mv 1]
  set from [lindex $m 0]
  set to [lindex $m 1]
  
  foreach {from to} [lindex $mv 1] break
  
  eval highlight [rindex $from]
  eval highlight [rindex $to]
}

#####################################################
#
# AllMoves -- returns a list of all legal moves for WHO on board BRD.
# Format is (from to type).
#
proc ::ataxx::AllMoves {who brd} {
  set m ""
  for {set i 24} {$i < 97} {incr i} {
    set c [lindex $brd $i]
    if {$c == 4} {                          ;# Is it a border cell?
      incr i 3
      continue
    }
    if {$c != $who} continue
    
    foreach j {1 10 11 12 -1 -10 -11 -12} { ;# Immediate neighbors
      set xy [expr {$i + $j}]
      if {[lindex $brd $xy] == 0} {
	lappend m [list $i $xy 1]
	set brd [lreplace $brd $xy $xy -1];# So we don't go here twice
      }
    }
    foreach j {2 9 13 20 21 22 23 24} {     ;# Neighbors 2 away
      if {[lindex $brd [expr {$i + $j}]] <= 0} {
	lappend m [list $i [expr {$i + $j}] 2]
      }
      if {[lindex $brd [expr {$i - $j}]] <= 0} {
	lappend m [list $i [expr {$i - $j}] 2]
      }
    }
  }
  
  set n [llength $m]
  if {$n == 0} {
    return {{0 0 -1}}
  }
  set n [expr {int(rand() * $n)}]             ;# Randomize the order
  set m [concat [lrange $m $n end] [lrange $m 0 [expr {$n - 1}]]]
  
  return $m
}

#####################################################
#
# Move -- returns new board with WHO moving FROM to TO on board BRD.
# Does no screen updates.
#
proc ::ataxx::move {who brd M} {
  foreach {frm to type} $M break
  
  if {$type == -1} { return $brd }
  set opp [expr {3 - $who}]
  set sw [lindex $brd [expr {121 + $who}]]
  set so [lindex $brd [expr {121 + $opp}]]
  
  set brd [lreplace $brd $to $to $who]
  if {$type == 2} {
    set brd [lreplace $brd $frm $frm 0]
  } else {
    incr sw
    set e [lindex $brd 121]
    set brd [lreplace $brd 121 121 [expr {$e - 1}]]
  }
  
  foreach i {1 10 11 12 -1 -10 -11 -12} {     ;# Immediate neighbors
    set xy [expr {$to + $i}]
    if {[lindex $brd $xy] == $opp} {
      set brd [lreplace $brd $xy $xy $who]
      incr sw
      incr so -1
    }
  }
  
  if {$who == 1} {
    set brd [lreplace $brd 122 123 $sw $so]
  } else {
    set brd [lreplace $brd 122 123 $so $sw]
  }
  return $brd
}

proc ::ataxx::move2 {brd MM} {
  variable index

  foreach {who r c fr fc type} $MM break
  set b [move $who $brd [list $index($fr,$fc) $index($r,$c) $type]]

  return $b
}

#####################################################
#
# E -- evaluates a position for WHO. Simply the difference in number of men.
#
proc ::ataxx::e {who brd} {
  set me  [lindex $brd [expr {121 + $who}]]
  set you [lindex $brd [expr {124 - $who}]]
  
  if {$you == 0} { return  10000 }
  if {$me == 0}  { return -10000 }
  return [expr {$me - $you}]
}

#####################################################
#
# Veb -- game-tree search with alpha-beta pruning. See _Fundamentals of Data
# Structures_, Horowitz, page 268.
#
# Initial call: veb (who board level infinity)
#
proc ::ataxx::veb {who brd l d} {
  variable state
  
  incr state(c)                               ;# Stats
  if {$l == 0 || [lindex $brd 121] == 0} {    ;# Terminal position?
    return [e $who $brd]                    ;# ...just evaluate position
  }
  
  set ans -10000                              ;# Lower bound on value
  set best ""                                 ;# Current best move
  
  incr l -1
  set moves [AllMoves $who $brd]
  foreach m $moves {
    set b [move $who $brd $m]
    set e [veb [expr {3 - $who}] $b $l [expr {-1 * $ans}]]
    set a [expr {-1 * [lindex $e 0]}]
    
    if {$a > $ans} {                        ;# Is it a better move?
      set ans $a                          ;# Yep, so use it
      set best [list $m]
    }
    if {$ans >= $d} break                   ;# BETA rule
  }
  return [concat $ans $best]
}

#####################################################
#
# Start -- starts/continues the game if it's the computer's turn
#
proc ::ataxx::Start {} {
  variable state

  if {$state(sc,0) == 0 || $state(sc,1) == 0} return
  if {$state($state(turn)) == 1} robot
}

proc ::ataxx::About {} {
  set msg "TkAtaxx\n\nby Keith Vetter\nFebruary, 2003"
  tk_messageBox -title About -message $msg
}

#####################################################
#
# Help -- displays a help screen
#
proc ::ataxx::Help {} {
  variable state

  set w [wjoin $state(top) help]
  set toplevel [winfo toplevel $state(top)]

  destroy $w
  toplevel $w
  wm title $w "TkAtaxx Help"
  wm geom $w "+[expr {[winfo x $toplevel] + [winfo width $toplevel] + 10}]+[winfo y $toplevel]"
  
  text $w.t -relief raised -wrap word -width 70 -height 32
  $w.t configure -padx 10 -pady 10
  button $w.dismiss -text Dismiss -command [list destroy $w]
  
  pack $w.dismiss -side bottom -pady 10
  pack $w.t -side top -expand 1 -fill both
  
  set bold "[font actual [$w.t cget -font]] -weight bold"
  $w.t tag configure title -justify center -foreground red \
      -font "Times 20 bold"
  $w.t tag configure title2 -justify center -font "Times 12 bold"
  $w.t tag configure bullet -font $bold
  $w.t tag configure n -lmargin1 15 -lmargin2 15
  
  $w.t insert end "TkAtaxx\n" title "by Keith Vetter\n\n" title2
  set msg "TkAtaxx is a tcl/tk implementation of the popular "
  append msg "arcade video Ataxx. The goal of the game is end up "
  append msg "with more pieces of your color than your "
  append msg "opponent. The game ends when there are no more "
  append msg "places to move. "
  $w.t insert end "DESCRIPTION\n" bullet $msg n \n\n
  
  set msg "You can move a piece in two different ways, either "
  append msg "sliding or jumping. To slide a piece, click on it "
  append msg "with the mouse, then click on an immediately "
  append msg "adjacent empty cell. The piece will split and "
  append msg "occupy both cells. To jump a piece, click on it "
  append msg "with the mouse, then click on an empty cell which "
  append msg "is exactly two positions away from the starting piece. The "
  append msg "piece will jump to the new position over any "
  append msg "intervening obstacles vacating the original "
  append msg "position. If there are no possible moves for a "
  append msg "player then the move if forfeited. "
  append msg "\n\nWhen a piece moves to a new cells, all surrounding "
  append msg "cells of the opponent's color will be captured and "
  append msg "turn into your color."
  $w.t insert end "MOVING\n" bullet $msg n \n\n
  
  set msg "You can adjust how smart the computer opponent "
  append msg "is. Random skill picks any move at "
  append msg "random. Greedy picks the move which maximizes how "
  append msg "many pieces he has at the end of the turn. Brainy "
  append msg "searches two moves ahead of the best move. Genius "
  append msg "searches three moves ahead for the best move.\n\n"
  append msg "More technically, TkAtaxx uses a Min-Max search "
  append msg "algorithm with alpha-beta pruning to find the best move. "
  append msg "The skill level corresponds to the depth of the search."
  $w.t insert end "SKILL LEVEL\n" bullet $msg n
  
  $w.t configure -state disabled
}

proc ataxx::ataxx {toplevel args} {
  ataxx::Init

  catch {::etcl::automanage $toplevel}

  ataxx::Display $toplevel
  ataxx::NewBoard

  return
}

# Init path to find Evotcl extension
proc ::ataxx::init {} {
  if {![catch {package require evolane::parseopts}]} {
    return
  }

  set thisfile [file normalize [info script]]
  set thisdir  [file dirname $thisfile]

  set path [list]
  lappend path [file join $thisdir .. .. .. .. evotcl sources]
  lappend path [file join $thisdir .. evotcl]
  lappend path [file join [info library] .. evotcl]

  global auto_path

  set found 0
  foreach d $path {
    set d [file normalize $d]

    if {![file isdirectory $d]} {
      continue
    }
    if {![file exists [file join $d pkgIndex.tcl]]} {
      continue
    }

    if {![info exists auto_path]} {
      set auto_path [list]
    } else {
      if {[lsearch -exact $::auto_path $d]>=0} {
	continue
      }
    }

    set auto_path [linsert $auto_path 0 $d]
    set found 1
    break
  }

  # Test path
  if {$found} {
    if {[catch {package require evolane::parseopts}]} {
      set found 0
    }
  }

  if {!$found} {
    # error "EvoTcl not found"
  }

  return
}

::ataxx::init
::ataxx::ataxx .
