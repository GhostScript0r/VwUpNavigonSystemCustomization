# A modified (improved?) version, running fine on PocketPC
# Initial authors: see header below

#  - bricks are generated dynamically, so game support any resolution
#  - better time handling for "slower" CPU.
#  - improved performance (especially for Windows Mobile platform)
#  - add menu
#  - cells remains clickable during UpRow
#  - no popup (tk_messageBox) for running as Tclet as well

# TODO:
#  - SlideCells: re-assign bindings instead of re-creating images, which 
#    is more expensive, particulary since Tk port on Windows Mobile is
#    not yet fully optimized (slow GDI emulation)

##################
#
# Collapse
# http://www.gamehouse.com/affiliates/template.jsp?AID=1406
# by Keith Vetter -- October 2003
#
# KPV  Oct 30, 2003 - Initial revision starting with gemgame code
# KPV  Nov 04, 2003 - EOR bonus, new row count down display, new levels
# male Nov 21, 2003 - Game Over canvas items with tags, delete
#                     in NewGame
# suchenwi Jan 22, 2003 - adapted for iPaq
# TODO:
#   bombs

package require Tk 8.4

namespace eval collapse {
  variable S
}

proc collapse::Init {} {
  variable S

  array set S {
    title "Collapse" 
    version 1.1
    mute 0
    level 1
    maxtile 7
  }

  # Background color
  set S(bgcolor) "\#304040"
  set S(bgcolor) "\#101030"

  # Unique Id for new cells
  set S(cellid) 0

  # Number of columns and rows
  set S(cols) 10
  set S(rows) 15

  # Delay for next level banner
  set S(nextdelay)  1500

  # Number of steps for slides
  set S(slidesteps) 4
  set S(slidedelay) 100

  # Number of steps for explode
  set S(explodesteps) 3
  set S(explodedelay) 100

  # Size of each cell
  if {[winfo screenwidth .]>=480} {
    set S(cell) 32
  } else {
    set S(cell) 16
  }

  # Total delay for bonus screen
  set S(bonusdelay) 2000
  set S(bonuswait)   700

  # Maximal row id (i.e. baseline)
  set S(rowsX) [expr {$S(rows) - 1}]

  set S(ticks) [expr {$S(cols)+1}]
  set S(tickfactor) [expr "1.0"]

  if {[catch {set os [set ::tcl_platform(os)]}]} {
    set os "unknown"
  }

  if {[string match "Windows CE" $os]} {
    set S(font) "Tahoma 8"
  } else {
    # set S(font) "Tahoma 8"
    set S(font) "Helvetica 8"
  }

  variable LEVEL

  array set LEVEL {
    1 {srows  4 tiles 3 newRow 5000 lines 25}
    2 {srows  5 tiles 3 newRow 4000 lines 30}
    3 {srows  7 tiles 3 newRow 2000 lines 30}
    4 {srows  7 tiles 3 newRow 1000 lines 30}
    5 {srows  8 tiles 3 newRow 1000 lines 35}
    6 {srows  9 tiles 3 newRow 1000 lines 40}
    7 {srows 10 tiles 3 newRow 1000 lines 45}
    8 {srows  3 tiles 3 newRow  700 lines 20}
    9 {srows  4 tiles 3 newRow  700 lines 25}
    10 {srows  5 tiles 3 newRow  700 lines 25}
    11 {srows  4 tiles 4 newRow 4000 lines 25}
  }

  return
}

proc collapse::DoMenu {top} {
  variable S

  if {[string compare "." $top]} {
    set w "${top}.mb"
  } else {
    set w ".mb"
  }

  set ns [namespace current]

  set menuargs {}
  lappend menuargs -tearoff 0

  if {[catch {set os [set ::tcl_platform(os)]}]} {
    set os "unknown"
  }

  # Force menu theme on PocketPC
  if {[string match "Windows CE" $os]} {
    lappend menuargs -borderwidth 0
    lappend menuargs -background "white"
    lappend menuargs -foreground "black"
    lappend menuargs -activebackground "#000080"
    lappend menuargs -activeforeground "white"
    lappend menuargs -relief flat
  }

  # Default menu options on X11 are just ugly...
  if {![string compare "x11" [tk windowingsystem]]} {
    lappend menuargs -borderwidth 1
    lappend menuargs -relief raised
    lappend menuargs -activeborderwidth 1
    lappend menuargs -activeforeground "\#000000"
    lappend menuargs -activebackground "\#e0e0e0"
    lappend menuargs -font $S(font)
  }

  set mb [eval [list menu $w] $menuargs]

  # Menu "File"
  set m [eval [list menu $mb.file] $menuargs]  

  $m add command -label "New game" \
      -command [namespace code [list NewGame]]
  $m add checkbutton \
      -label Pause \
      -variable ${ns}::S(pause) \
      -onvalue 1 -offvalue 0
  $m add separator
  $m add command -label "Exit" \
      -command [namespace code [list Quit $top]]
  
  $mb add cascade -label "File" \
      -menu $m -underline 0

  # Menu "Help"
  set m [eval [list menu $mb.help] $menuargs]
  
  $m add command -label "About..." \
      -command "${ns}::About"
  
  $mb add cascade -label "Help" -menu $m -underline 0
  
  return $mb  
}

proc collapse::DoDisplay {} {
  variable S
  variable LEVEL

  package require Tk  

  # Optional
  if {[catch {wm withdraw .}]} {
    set hidden 0
  } else {
    set hidden 1

    catch {load {} wce}
    # catch {wce hotkey .toto}

    set mb [DoMenu .]
    . configure -menu $mb
  }

  # wm title . $S(title)
  set w [expr {$S(cell) * $S(cols) + 5}]
  set h [expr {$S(cell) * $S(rows) + 5}]

  set S(width) $w
  set S(height) $h

  set ns [namespace current]

  frame .ctrl -relief ridge -bd 2 -bg $S(bgcolor)
  canvas .c -relief ridge -bg $S(bgcolor) -height $h -width $w \
      -highlightthickness 0 -bd 1 -relief raised
  canvas .cc -relief ridge -bg $S(bgcolor) -height [expr {5 + $S(cell)}] -width $w \
      -highlightthickness 0 -bd 1 -relief raised
  
  # Generic bindings for main frame
  bind .c <Button-1> [list ${ns}::CellClick %x %y]

  label .score -text "Score" -fg white -bg $S(bgcolor)
  .score configure  -font "[font actual [.score cget -font]] -weight bold"
  
  label .vscore -textvariable "${ns}::S(score)" -fg yellow -bg $S(bgcolor)
  label .vscore2 -textvariable "${ns}::S(score2)" -fg orange -bg $S(bgcolor)

  label .level -text "Level" -fg white -bg $S(bgcolor)
  label .vlevel -textvariable ${ns}::S(level) -fg yellow -bg $S(bgcolor)

  label .lines -text "Left" -font $S(font) -fg white -bg $S(bgcolor)
  label .vlines -textvariable ${ns}::S(lines) -fg yellow -bg $S(bgcolor)

  button .new -text "New" -font $S(font) -command [list ${ns}::NewGame]
  
  set levels {}
  foreach a [lsort -integer [array names LEVEL]] {
    lappend levels "L. $a"
  }

  if {0} {
    eval tk_optionMenu .optlvl S(strlvl) $levels
    .optlvl config -highlightthickness 0
  } else {
    set S(strlvl) [lindex $levels 0]
    label .optlvl -textvariable ${ns}::S(strlvl)
  }

  checkbutton .pausebtn \
      -text Pause \
      -font $S(font) \
      -variable ${ns}::S(pause) \
      -relief raised -anchor w

  button .aboutbtn \
      -text About \
      -font $S(font) \
      -command [list ${ns}::About]

  button .quitbtn \
      -text Quit \
      -font $S(font) \
      -command [list ${ns}::Quit .]
  
  pack .ctrl -side right -fill y ;# -ipady 5 -ipadx 5
  pack .c -side top -fill both -expand 1
  pack .cc -side top -fill both -expand 1

  grid .score -in .ctrl -sticky ew -row 1
  grid .vscore -in .ctrl -sticky ew
  grid .vscore2 -in .ctrl -sticky ew

  grid .level -in .ctrl -sticky ew
  grid .vlevel -in .ctrl -sticky ew

  grid .lines -in .ctrl -sticky ew
  grid .vlines -in .ctrl -sticky ew

  grid rowconfigure .ctrl 20 -minsize 10

  grid .new -in .ctrl -sticky ew -row 25 -pady 1
  grid .new -in .ctrl -sticky ew -pady 1
  # grid .optlvl -in .ctrl -sticky ew -pady 1
  grid .pausebtn -in .ctrl -sticky ew -pady 1

  grid rowconfigure .ctrl 50 -weight 1
  
  # grid .aboutbtn -in .ctrl -row 100 -sticky ew -pady 5
  # grid .aboutbtn -in .ctrl -sticky ew -pady 5
  # grid .quitbtn -in .ctrl -sticky ew
  
  set ns [namespace current]
  
  trace variable "${ns}::S(strlvl)" w [list ${ns}::Tracer]
  trace variable "${ns}::S(pause)" w [list ${ns}::Tracer]
  
  # Display main window
  if {$hidden} {
    if {[llength [info commands ::etcl::automanage]]>0} {
      # pack propagate . false
      ::etcl::automanage .
      update
    }

    wm deiconify .
    tkwait visibility .
  }

  # Bug in current WCE implementation. 
  # Menu to be attached again once modified.
  if {[info exists mb]} {
    if {[catch {set os [set ::tcl_platform(os)]}]} {
      set os "unknown"
    }
    if {[string match "Windows CE" $os]} {
      . configure -menu ""
      . configure -menu $mb
    }
  }

  return
}

# Generic callback for "trace variable"
proc collapse::Tracer {var1 var2 op} {
  variable S

  switch -exact -- $var2 {
    "strlvl" {
      scan $S(strlvl) "L. %d" level
      if {$level == $S(level)} return
      set S(level) $level
      NewGame
    }
    "pause" {
      Pause 0
    }
  }
}

proc collapse::NewGame {} {
  variable S

  array set S {
    score 0 
    state 0 
    score2 "" 
    best 0
  }

  catch {eval .c delete gameOver}

  StartLevel
  Banner "CLICK TO START"
  WaitClick

  return
}

proc collapse::EmptyRow {} {
  variable S

  set result [list]
  for {set col 0} {$col < $S(cols)} {incr col} {
    lappend result 0
  }

  return $result
}

proc collapse::StartLevel {} {
  variable S 
  variable BB
  variable LEVEL

  StartStop 0
  array set S {
    busy 0 
    needRow 0 
    pause 0
    vscroll 0
  }

  if {! [info exists LEVEL($S(level))]} {     ;# Above set levels
    set lvl [expr {$S(level) % 10}]
    if {$lvl == 0} {set lvl 10}
    if ![info exi LEVEL($lvl)] {set lvl [expr 1+$lvl%7]}
    array set S $LEVEL($lvl)
    set S(tiles) $S(maxtile)
  } else {
    array set S $LEVEL($S(level))
    set S(strlvl) "L. $S(level)"
  }

  # Tick mark interval
  set S(newRowX) [expr {int(($S(newRow)*$S(tickfactor)) / $S(ticks))}]
  
  .c delete banner
  .c itemconfig cell -image {}

  # Initialize array
  CellInit

  set BB [EmptyRow]
  
  # Add rows
  set S(busy) 1
  for {set i 0} {$i < $S(srows)} {incr i} {
    UpRow
  }
  set S(busy) 0

  return
}

proc collapse::NewCell {row col value} {
  variable S

  set ns [namespace current]

  if {$row<0} {
    set w .cc
    set itag "c${col}"
    set row 0
  } else {
    set w .c
    set itag "c${row},${col}"
  }

  if {$value<=0} {
    $w delete $itag
  } else {
    set cellid [incr S(cellid)]

    set tags [list cell $itag]
    set id [$w create image [GetXY $row $col] -image ::img::img($value) -tags $tags]

    # To prevent future "raise banner", create cells below banner
    .c lower $id banner
  }

  return
}

proc collapse::IsEmpty {} {
  variable B

  foreach row $B {
    foreach value $row {
      if {$value>0} {
	return 0
      }      
    }
  }

  return 1
}

proc collapse::GetCell {row col} {
  variable B

  # Extract row
  set res [lindex $B $row $col]
  if {$res>0} {
    set res [expr {$res & 63}]
  }

  return $res
}

proc collapse::SetCell {row col color {special 0}} {
  variable B

  if {$row<0 || $col<0} {
    return
  }

  if {$color<=0} {
    set value -1
  } else {
    set value [expr {$color & 63}]
    if {$special} {
      set value [expr {$value | 64}]
    }
  }
  
  lset B $row $col $value

  return $value
}

proc collapse::CellInit {} {
  variable B
  variable S

  set B [list]
  set emptyrow [EmptyRow]
  while {[llength $B]<=$S(rows)} {
    lappend B $emptyrow
  }

  return
}


proc collapse::CellBoard {row col} {
  set v [GetCell $row $col]
  if {$v<=0} {
    .c delete "c${row},${col}"
  } else {
    NewCell $row $col $v
  }
}

# Display one cell in next row
proc collapse::CellNext {col} {
  variable BB

  return [NewCell -1 $col [lindex $BB $col]]
}

# Display next row
proc collapse::DrawNext {} {
  variable S 

  for {set col 0} {$col < $S(cols)} {incr col} {
    CellNext $col
  }
}

# Transform (row,column) to (x,y)
proc collapse::GetXY {r c} {
  variable S

  if {$r<0} {
    set r 0
    set scroll 0
  } else {
    set scroll $S(vscroll)
  }

  set x [expr {5 + $c * $S(cell) + $S(cell)/2}]
  set y [expr {5 - $scroll + $r * $S(cell) + $S(cell)/2}]

  return [list $x $y]
}

# Transform (x,y) to (row,column)
proc collapse::FindXY {x y} {
  variable S

  set row [expr {($y-(5-$S(vscroll)))/$S(cell)}]
  set col [expr {($x-5)/$S(cell)}]

  return [list $row $col]
}

proc collapse::CellClick {x y} {
  variable S

  if {$S(state)==0} {
    # Waiting for click
    set S(click) 1
    return
  }

  foreach {row col} [FindXY $x $y] {break}
  # puts "CLICK TRY $row $col"

  if {$row>=0 && $col>=0 && $row<=$S(rows) && $col<$S(cols)} {
    set v [GetCell $row $col]
    if {$v>0} {
      # puts "CLICK ON $row $col"
      DoClick $row $col
    } else {
      # puts "BAD CLICK $v"
    }
  }  
}

proc collapse::DoClick {args} {
  variable S

  if {[llength $args]==0} {
    set row -1
    set col -1
  } else {
    set row [lindex $args 0]
    set col [lindex $args 1]
  }

  if {$S(state) == 0} {
    Banner ""
    StartStop 1
    set S(state) 1
    if {$row == -1} return
  }
  
  if {$S(state) != 1} {
    # Not running
    return
  }

  if {$row<0} {
    return
  }

  if {$S(busy)} {
    set S(click) [list $row $col]
    return
  }

  # Explosion
  set S(busy) 1
  Explode $row $col
  set S(busy) 0

  if {$S(needRow)} {
    NewRow
  }
}

proc collapse::Explode {r c} {
  variable S

  # Find cells
  set cells [FindNeighbors $r $c]

  # Number of cells to explode
  set nbcells [expr {[llength $cells]/2}]
  if {$nbcells == 0} {
    return
  }
  
  # Update our score
  set n [expr {$nbcells * $nbcells}]
  incr S(score) $n

  if {$nbcells > 3} {
    # Special bonus if more than 3 cells detroyed
    set S(score2) "(${n})"
  } else {
    # No bonus
    set S(score2) ""
  }
  
  SetCell $r $c $S(maxtile)
  CellBoard $r $c
  update

  ExplodeCells $cells $r $c                   ;# Do the explosion affect
  CollapseCells                               ;# Move cells down
  CompactCells                                ;# Move cells inward

  if {[IsEmpty]} {
    # Special bonus if board is empty
    incr S(score) 1000
    Banner "1000 POINT BONUS"

    set ns [namespace current]
    after 500 [list ${ns}::Banner ""]
  }
}

proc collapse::FindNeighbors {row col} {                  ;# Find all triplets and up
  variable S 
  
  set type [GetCell $row $col]               ;# Type of our neighborhood
  if {$type<=0} {
    return {}
  }

  # We'll do a flood fill (bfs) to find connected components
  set q [list $row $col]                      ;# Our BFS queue
  set qhead 0                                 ;# Head of the queue
  
  array unset neighbors                       ;# Whose in our neighborhood
  set neighbors($row,$col) 1                  ;# We're in our own neighborhood
  set cnt 1

  set result [list]
  lappend result $row $col

  while {[llength $q] > $qhead} {             ;# While stuff in the queue
    foreach {r c} [lrange $q $qhead [incr qhead]] break
    incr qhead
    
    foreach {dr dc} {-1 0 1 0 0 -1 0 1} {   ;# Look n,s,e & w
      set r1 [expr {$r + $dr}]
      set c1 [expr {$c + $dc}]
      if {[info exists neighbors($r1,$c1)]} {
	# Already seen
	continue
      }

      if {[GetCell $r1 $c1] != $type} continue  ;# Wrong type
      
      set neighbors($r1,$c1) 1            ;# Another neighbor
      lappend result $r1 $c1

      lappend q $r1 $c1                   ;# Add to our BFS
      incr cnt
    }
  }

  if {$cnt < 3} {
    return {}
  }

  return $result
}

proc collapse::ExplodeCells {cells mrow mcol} {
  variable S

  set steps $S(explodesteps)
  set delay [expr {$S(explodedelay)/($steps-1)}]

  for {set stage 2} {$stage<=$steps} {incr stage} {
    set t [time {
      foreach {row col} $cells {
	if {$stage == $steps} {
	  SetCell $row $col 0
	  CellBoard $row $col
	} else {
	  if {$row!=$mrow || $col!=$mcol} {
	    set value [GetCell $row $col]
	    set img "::img::img($value,$stage)"
	    .c itemconfigure "c$row,$col" -image $img
	  }
	}
      }
      update
    }]

    if {$stage==$steps} {      
      break
    }

    set ms [expr {int([lindex $t 0]/1000)}]
    if {$ms>0 && $delay>$ms} {
      after [expr {$delay-$ms}]
    }
  }

  return
}

proc collapse::CollapseCells {} {
  variable S
  
  while {1} {
    set sliders {}
    for {set col 0} {$col < $S(cols)} {incr col} {
      set collapse 0
      for {set row $S(rowsX)} {$row >= 0} {incr row -1} {
	if {[GetCell $row $col] <= 0} {
	  set collapse 1
	} elseif {$collapse} {
	  lappend sliders $row $col y
	}
      }
    }

    # Nothing slides. Stop.
    if {[llength $sliders] == 0} {
      break
    }

    SlideCells $sliders
  }

  return
}

proc collapse::CompactCells {} {
  variable S
  variable BB

  set ROW $S(rowsX)
  set COL [expr {int($S(cols) / 2)}]

  while {1} {                                 ;# Stop when nothing slides
    set sliders {}
    
    # Check the slide to the right columns
    set cols {}
    for {set col 0} {$col < $COL} {incr col} {
      if {[GetCell $ROW $col] <= 0} {
	foreach c $cols {
	  for {set row $ROW} {$row >= 0} {incr row -1} {
	    if {[GetCell $row $c] <= 0} break
	    lappend sliders $row $c x
	  }
	}
	set cols {}
      } else {
	lappend cols $col
      }
    }

    # Check slide to the left columns
    set cols {}
    for {set col [expr {$S(cols) - 1}]} {$col >= $COL} {incr col -1} {
      if {[GetCell $ROW $col] <= 0} {
	foreach c $cols {
	  for {set row $ROW} {$row >= 0} {incr row -1} {
	    if {[GetCell $row $c] <= 0} break
	    lappend sliders $row $c xx
	  }
	}
	set cols {}
      } else {
	lappend cols $col
      }
    }

    if {[llength $sliders] == 0} {
      break
    }

    SlideCells $sliders
  }

  return
}

#############################################################################
#
# SlideCells -- move a set of cells one unit in a specified direction.
#
proc collapse::SlideCells {cells} {
  variable S

  # "cells" is {row1 col1 dir1 ... rown coln dirn}, with "dir" one of:
  # x, y, xx(=-x) or yy(=-y)
  set translate [list]
  foreach {r c dir} $cells {
    set newr $r
    set newc $c

    switch -exact -- $dir {
      "y" {
	incr newr
      }
      "yy" {
	incr newr -1
      }
      "x" {
	incr newc
      }
      "xx" {
	incr newc -1
      }
    }

    set ids [.c find withtag "c${r},${c}"]
    if {[llength $ids]>0} {
      foreach id $ids {
	.c addtag "slider$dir" withtag $id
	.c addtag "slider" withtag $id
      }
      
      lappend translate $r $c $newr $newc [GetCell $r $c] $ids
    }
  }

  # Move
  set steps $S(slidesteps)
  set delay [expr {$S(slidedelay)/$steps}]

  set dx [expr {double($S(cell)) / $steps}]
  set dy [expr {double($S(cell)) / $steps}]

  for {set step 0} {$step < $steps} {incr step} {
    set t [time {
      .c move slidery 0 $dy
      .c move slideryy 0 -$dy
      .c move sliderx $dx 0
      .c move sliderxx -$dx 0
      update
    }]

    set ms [expr {int([lindex $t 0]/1000)}]
    if {$ms>0 && $delay>$ms} {
      after [expr {$delay-$ms}]
    }
  }

  foreach {r c newr newc value ids} $translate {
    SetCell $r $c 0
  }

  # Update board
  foreach {r c newr newc value ids} $translate {
    set oldid "$r,$c"
    set newid "$newr,$newc"

    # New tags
    foreach id $ids {
      .c addtag "c${newid}" withtag $id
      .c dtag $id "c${oldid}"
    }
    SetCell $newr $newc $value
  }

  # Delete temporary tags
  .c dtag slidery
  .c dtag slideryy
  .c dtag sliderx
  .c dtag sliderxx

  return
}

proc collapse::NewRow {} {
  variable S 

  # Stop adding new cells
  StartStop 0

  if {$S(busy)} {
    # Busy handling mouse click, so set flag and leave
    set S(needRow) 1
    return
  }

  set S(busy) 1
  set S(click) [list]

  incr S(lines) -1
  if {$S(lines) == 0} {                       ;# Is the level over yet???
    return [LevelOver]
  }

  # Check for game over
  for {set col 0} {$col < $S(cols)} {incr col} {
    if {[GetCell 0 $col] > 0} {
      return [GameOver]
    }
  }

  UpRow

  StartStop 1

  set S(needRow) 0
  set S(busy) 0

  # If a click occured while new row was added, process it now
  if {[llength $S(click)]>0} {
    foreach {row col} $S(click) {break}
    incr row -2   ;# TO BE FIXED !!!!
    set S(click) [list]

    DoClick $row $col
  }

  return
}

#############################################################################
#
# UpRow -- Scrolls the screen up one row and adds in another row
#
proc collapse::UpRow {} {
  variable S
  variable BB

  # Fill next row
  set nextrow [list]
  for {set col 0} {$col < $S(cols)} {incr col} {
    set value [lindex $BB $col]
    if {$value <= 0} {
      set value [expr {1 + int(rand() * $S(tiles))}]
    }
    lappend nextrow $value
  }
  set BB [EmptyRow]

  # Scroll everything up (new version)
  if {0} {
    variable B

    # Drop top row (which is known to be empty)
    set B [lrange $B 1 end]

    # And add new row
    lappend B $nextrow

    # Update all tags
    for {set row 1} {$row < $S(rows)} {incr row} {
      set newr [expr {$row-1}]

      for {set col 0} {$col < $S(cols)} {incr col} {
	set oldid "$row,$col"	
	set newid "$newr,$col"
      
	# New tags
	foreach id [.c find withtag $oldid] {
	  .c addtag "c${newid}" withtag $id
	  .c dtag $id "c${oldid}"
	}
      }
    }

    # set S(vscroll) [expr {$S(cell)}]

    # Create items for new row
    for {set col 0} {$col < $S(cols)} {incr col} {
      CellBoard $S(rows) $col
    }
    update

    # Scroll up
    .c move cell 0 [expr {-$S(cell)}]
    set S(vscroll) 0

    return
  }
  ##########################################################
  # End of unstable version
  ##########################################################

  # Scroll everything up
  set sliders {}
  for {set row 1} {$row < $S(rows)} {incr row} {
    for {set col 0} {$col < $S(cols)} {incr col} {
      if {[GetCell $row $col] > 0} {
	lappend sliders $row $col yy
      }
    }
  }

  for {set col 0} {$col < $S(cols)} {incr col} {
    set n [lindex $nextrow $col]

    # Create new cell
    SetCell $S(rows) $col $n
    CellBoard $S(rows) $col

    # Add it to slide list
    lappend sliders $S(rows) $col yy
  }

  SlideCells $sliders

  return
}

proc collapse::Quit {top} {
  catch {destroy $top}
  exit
}

proc collapse::About {} {
  variable S

  set w [frame .about]

  set t [text $w.text \
	     -background "\#C0E0FF" -foreground black \
	     -font $S(font) -height 1 \
	     -wrap word]

  $t tag configure title -foreground "\#0000c0" -font "Arial 9 bold" -justify center
  $t tag configure body -foreground "\#000080" -justify center

  # Fill text
  $t insert end "$S(title) v$S(version)\n" title
  $t insert end "\n" body
  
  $t insert end "Created by Keith Vetter\n" body
  $t insert end "Ported to PDA by R. Suchenwirth\n" body
  $t insert end "Updated for eTcl by E. Hassold\n" body
  $t insert end "\n" body

  $t insert end "Collapse the rising blocks " body
  $t insert end "to get as many points as possible.\n" body
  $t insert end "\n" body

  $t insert end "Score points by clicking on a block that has " body
  $t insert end "two or more neighbors of same color. Blocks above " body
  $t insert end "the explosion will collapse on blocks " body
  $t insert end "below. The more blocks exploded the higher your score.\n" body
  $t insert end "\n" body
  
  #$t insert end "As you play, new lines of blocks will appear. When " body
  #$t insert end "\"Lines Left\" reaches 0, the next level will start." body
  $t configure -state disabled

  set b [button $w.done -text "Close" -font $S(font) -command [list destroy $w]]

  pack $t -side top -fill both -expand true
  pack $b -side top -fill x -expand false

  if {$S(state)==1 && !$S(pause)} {
    Pause
  }

  set oldstate $S(state)
  set S(state) 4
  place $w -in . -relheight 0.9 -relwidth 0.9 -relx 0.5 -rely 0.5 -anchor c
  tkwait window $w
  set S(state) $oldstate

  return
}

proc collapse::GameOver {{txt "Game Over"}} {
  variable S

  set S(state) 2
  StartStop 0

  # set w [winfo width .c]
  # set h [winfo height .c]
  set w $S(width)
  set h $S(height)

  set cx [expr {$w/2}]
  set cy [expr {$h/2}]

  .c create rect 0 0 $w $h \
      -fill white -stipple gray25 -tags gameOver
  .c create text $cx $cy \
      -anchor c \
      -text $txt -font {Helvetica 18 bold} \
      -fill white -tags gameOver
}

proc collapse::StartStop {onoff} {
  variable S

  # Cancel event loop
  catch {after cancel $S(tickerevent)}

  # Delete new row frame
  .cc delete all

  if {!$onoff} {    
    return
  }
  
  set S(tcnt) $S(ticks)

  set ns [namespace current]
  set S(tickerevent) [after $S(newRowX) [list ${ns}::ticker]]

  return
}

proc collapse::ticker {} {
  variable S 
  variable BB
  
  incr S(tcnt) -1
  set col [expr {$S(ticks) - 1 - $S(tcnt)}]

  if {$col<$S(cols)} {
    lset BB $col [expr {1 + int(rand() * $S(tiles))}]
    CellNext $col
  }
  
  if {$S(tcnt) <= 0} {
    NewRow
  } else {
    set ns [namespace current]
    set S(tickerevent) [after $S(newRowX) [list ${ns}::ticker]]
  }
}

proc collapse::LevelOver {} {
  variable S 
  
  # Set state
  set S(state) 3
  StartStop 0

  # Show banner
  Banner "LEVEL COMPLETE"
  update

  # Wait
  after $S(nextdelay)

  # Next level
  LevelOverAnimation
  incr S(level)
  StartLevel
  set S(state) 1

  # Restart
  StartStop 1

  return
}
proc collapse::LevelOverAnimation {} {
  variable S

  Banner "0 POINT BONUS"

  set delay [expr {$S(bonusdelay)/($S(cols)*$S(rows))}]

  for {set row 0} {$row < $S(rows)} {incr row} {
    set bonus [expr {100 + $row*10}]
    incr S(score) $bonus
    BannerUpdate "$bonus POINT BONUS"

    for {set col 0} {$col < $S(cols)} {incr col} {
      if {[GetCell $row $col] > 0} break

      set t [time {
	SetCell $row $col $S(maxtile)
	CellBoard $row $col
	update
      }]

      set ms [expr {int([lindex $t 0]/1000)}]
      if {$ms>0 && $delay>$ms} {
	after [expr {$delay-$ms}]
      }
    }

    if {[GetCell $row $col] > 0} {
      # Cell hit. No more bonus.
      break
    }
  }

  if {$S(bonuswait)>0} {
    after $S(bonuswait)
  }

  return
}

############################################################################
#
# WaitClick -- waits for a click to begin
#
proc collapse::WaitClick {} {
  variable S

  .c raise banner
  vwait "[namespace current]::S(click)"
  DoClick

  return
}

proc collapse::Banner {msg} {
  variable S

  # Delete banner
  .c delete banner

  if {[string length $msg] == 0} {
    return
  }

  set w $S(width)
  set h $S(height)

  set cx [expr {$w/2}]
  set cy [expr {$h/2}]

  set dx [expr {(($w/2)*4)/5}]
  set dy [expr {(($h/2)*4)/5}]

  .c create rect \
      [expr {$cx - $dx}] [expr {$cy - $dy}] \
      [expr {$cx + $dx}] [expr {$cy + $dy}] \
      -tags banner -fill $S(bgcolor) -outline gold \
      -stipple gray50
  
  for {set i 0} {$i < 6} {incr i} {
    set xx [expr {$cx - (2.5-$i)*$S(cell)}]
    set yy [expr {$cy + rand()*$S(cell)}]
    set who [expr {1 + int(rand() * $S(tiles))}]
    .c create image $xx $yy -image ::img::img($who) -tags [list banner "banneritem${i}"]
  }

  .c create text $cx $cy \
      -tags {banner bannertext} -font {Helvetica 12 bold} \
      -text $msg -anchor c -fill white

  return
}

proc collapse::BannerUpdate {msg} {
  variable S

  if {[string length $msg]==0} {
    return [Banner ""]
  }

  set h $S(height)
  set cy [expr {$h/2}]

  for {set i 0} {$i < 6} {incr i} {
    set tag "banneritem${i}"

    foreach {oldx oldy} [.c coords $tag] {break}
    set yy [expr {$cy + rand()*$S(cell)}]
    .c coords $tag $oldx $yy

    set who [expr {1 + int(rand() * $S(tiles))}]
    .c itemconfigure $tag -image ::img::img($who)
  }

  .c itemconfigure bannertext -text $msg

  return
}

proc collapse::Pause { {byBinding 1} } {
  variable S

  if {$byBinding} {
    # Manually toggle button state
    set S(pause) [expr {! $S(pause)}]
  }
  
  if {![info exists S(state)]} {
    return
  }

  if {$S(pause) == 1} {
    # Pause on
    if {$S(state) != 1} {
      # Not in play mode
      return
    }

    catch {after cancel $S(tickerevent)}
    
    set w $S(width)
    set h $S(height)

    set cx [expr {$w/2}]
    set cy [expr {$h/2}]

    .c create rect 0 0 $w $h \
	-fill $S(bgcolor) -outline $S(bgcolor) -tags pause
    .c create text $cx $cy -font {Helvetica 14 bold} \
	-fill white -tags pause -text "PAUSED" -justify center -anchor s

    .c create text $cx [expr {$cy+10}] \
	-font {Helvetica 10 bold} \
	-fill white -tags pause \
	-text "Click to continue" \
	-justify center -anchor n
  } else {
    if {$S(state) != 1} {
      # Not in play mode
      return
    }

    # Pause off
    .c delete pause
    
    set ns [namespace current]
    set S(tickerevent) [after $S(newRowX) [list ${ns}::ticker]]
  }

  return
}

proc collapse::MakeBrick {name w h color} {
  catch {image delete $name}

  set p [image create photo $name]
  $p configure -width $w -height $h
  $p blank

  foreach {r g b} [winfo rgb . $color] {break}
  set r [expr {$r>>8}]
  set g [expr {$g>>8}]
  set b [expr {$b>>8}]

  set alpha [expr {0x60}]
  foreach c [list $r $g $b] v [list lr lg lb] {
    set $v [expr {($alpha*0xff+(255-$alpha)*$c)/255}]
  }
  foreach c [list $r $g $b] v [list dr dg db] {
    set $v [expr {($alpha*0x00+(255-$alpha)*$c)/255}]
  }
  set light [format "\#%02x%02x%02x" $lr $lg $lb]
  set dark  [format "\#%02x%02x%02x" $dr $dg $db]

  # Fill image
  set metal 1
  if {$metal} {
    for {set ypos 0} {$ypos<$h} {incr ypos} {
      set section [expr {double($ypos)/$h}]

      if {$section<0.30} {
	# Dark to light in first third 1/3
	set vr [expr {int($dr+($section/0.3)*($lr-$dr))}]
	set vg [expr {int($dg+($section/0.3)*($lg-$dg))}]
	set vb [expr {int($db+($section/0.3)*($lb-$db))}]
      } else {
	# Light to dark in second and third 1/3
	set vr [expr {int($lr-(($section-0.3)/0.7)*($lr-$dr))}]
	set vg [expr {int($lg-(($section-0.3)/0.7)*($lg-$dg))}]
	set vb [expr {int($lb-(($section-0.3)/0.7)*($lb-$db))}]
      }
      
      set tkcolor [format "\#%02x%02x%02x" $vr $vg $vb]
      $p put [list [list $tkcolor]] -to 0 $ypos $w [expr {$ypos+1}]
    }
  } else {
    set tkcolor [format "\#%02x%02x%02x" $r $g $b]
    $p put [list [list $tkcolor]] -to 0 0 $w $h
  }

  # Draw border (relief)
  set borderwidth [expr {$w/20}]
  if {$borderwidth<1} {
    set borderwidth 1
  }

  $p put [list [list $light]] -to 0 0 $w $borderwidth
  $p put [list [list $light]] -to 0 0 $borderwidth $h
  $p put [list [list $dark]]  -to 0 [expr {$h-$borderwidth}] $w $h
  $p put [list [list $dark]]  -to [expr {$w-$borderwidth}] 0 $w $h
  
  return $p
}

proc collapse::MakeBall {name w h color} {
  catch {image delete $name}

  set p [image create photo $name]
  $p configure -width $w -height $h
  $p blank

  foreach {r g b} [winfo rgb . $color] {break}
  set r [expr {$r>>8}]
  set g [expr {$g>>8}]
  set b [expr {$b>>8}]

  set alpha [expr {0x60}]
  set alpha 0xa0

  foreach c [list $r $g $b] v [list lr lg lb] {
    set $v [expr {($alpha*0xff+(255-$alpha)*$c)/255}]
  }
  foreach c [list $r $g $b] v [list dr dg db] {
    set $v [expr {($alpha*0x00+(255-$alpha)*$c)/255}]
  }
  set light [format "\#%02x%02x%02x" $lr $lg $lb]
  set dark  [format "\#%02x%02x%02x" $dr $dg $db]

  # Fill image
  set rx [expr {$w/2}]
  set ry [expr {$h/2}]

  set cx $rx
  set cy $ry

  set lx [expr {$w/3}]
  set ly [expr {$h/3}]

  set rmax [expr {$rx*$rx*$ry*$ry}]

  for {set ypos 0} {$ypos<=$h} {incr ypos} {
    for {set xpos 0} {$xpos<$w} {incr xpos} {
      set r2 [expr {($xpos-$cx)*($xpos-$cx)*$ry*$ry+($ypos-$cy)*($ypos-$cy)*$rx*$rx}]
      if {$r2>$rmax} {
	continue
      }

      # Number in the range [0,1] (0=darkest, 1=brightest)
      set rl2 [expr {($xpos-$lx)*($xpos-$lx)*$ry*$ry+($ypos-$ly)*($ypos-$ly)*$rx*$rx}]
      # set rl $r2

      set lumin [expr {1.0-double($rl2)/($rmax)}]
      if {$lumin<0.0} {
	set lumin 0.0
      } elseif {$lumin>1.0} {
	set lumin 1.0
      }
    
      set vr [expr {int($dr+$lumin*($lr-$dr))}]
      set vg [expr {int($dg+$lumin*($lg-$dg))}]
      set vb [expr {int($db+$lumin*($lb-$db))}]
    
      set tkcolor [format "\#%02x%02x%02x" $vr $vg $vb]
      $p put [list [list $tkcolor]] -to $xpos $ypos [expr {$xpos+1}] [expr {$ypos+1}]
    }
  }

  return $p
}

proc collapse::MakeImages {} {
  variable S

  image create photo ::img::img(-1)
  image create photo ::img::img(0)

  set w $S(cell)
  set h $S(cell)
  
  # Tile colors (last one used for bonus)
  set colors [list]
  lappend colors "\#00FF00"  ;# green
  lappend colors "\#0000FF"  ;# blue
  lappend colors "\#FF0000"  ;# red
  lappend colors "\#FF8000"  ;# orange
  lappend colors "\#00FFFF"  ;# cyan
  lappend colors "\#C0C0C0"  ;# silver
  lappend colors "\#FFFF80"  ;# gold

  set imgid 0
  foreach color $colors {
    incr imgid
    MakeBrick "::img::img($imgid)" $w $h $color
    # MakeBall "::img::img($imgid)" $w $h $color
  }

  # Number of sub-samples to generate
  set steps $S(explodesteps)

  # Sub-samples
  for {set id 0} {$id<$imgid} {incr id} {
    for {set a 2} {$a<=$steps} {incr a} {
      image create photo ::img::img($id,$a)
      if {$a < $steps} {
	::img::img($id,$a) copy ::img::img($id) \
	    -subsample $a $a
      }
    }
  }

  if {$S(maxtile)>$imgid} {
    error "Not enough tile colors defined"
  }

  return
}

collapse::Init
collapse::MakeImages
collapse::DoDisplay

after 0 [list ::collapse::NewGame]
