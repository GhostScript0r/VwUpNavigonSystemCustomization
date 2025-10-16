# Evolane add ons:
#  - Get rid of regular expressions. Really not useful.

package require Tk

namespace eval calc {
}

proc ::calc::wjoin {w child} {
  if {![string compare $w "."]} {
    set result ""
  } else {
    set result $w
  }
  append result "." [string trimleft $child "."]

  return $result
}

# -----------------------------------------------------------------------------
#  DoAppend
# -----------------------------------------------------------------------------
proc ::calc::DoAppend {what} {
  variable state
  
  if {$state(started) == 0} {
    set state(ent) 0.
    set state(started) 1
  }
  if {$state(op) == ""} {
    set state(result) 0.
  }
  if {[string length $state(ent)] > 12} return
  if {!($what == 0 && [string compare $state(ent) 0.] == 0)} {
    if {$state(dot) == 1} {
      set state(ent) [format "%s%s" $state(ent) $what]
      return
    } else {
      # regexp {([-0-9]+).} $state(ent) foo integer
      set p [string first "." $state(ent)]
      set integer [string range $state(ent) 0 [expr {$p-1}]]

      if {$integer == 0} {
	set state(ent) [format "%s." $what]
	return
      } else {
	set state(ent) [format "%s%s." $integer $what]
	return
      }
    }
  } else {
    if {$state(dot) == 1} {
      set state(ent) 0.0
      return
    }
    return
  }
}

# -----------------------------------------------------------------------------
#  DoClear
# -----------------------------------------------------------------------------
proc ::calc::DoClear {} {
  variable state
  set state(ent) 0.
  set state(dot) 0
  if {$state(started) == 0} {
    set state(result) 0.
    set state(op) ""
  }
  set state(started) 0
  return
}

# -----------------------------------------------------------------------------
#  DoDot
# -----------------------------------------------------------------------------
proc ::calc::DoDot {} {
  variable state
  set state(dot) 1
  return
}

# -----------------------------------------------------------------------------
#  DoEqual
# -----------------------------------------------------------------------------
proc ::calc::DoEqual {} {
  variable state

  # Compute new result
  if {$state(op) != ""} {
    set exp "$state(result) $state(op) $state(ent)"
    set state(result) [expr $exp]
  } else {
    set state(result) $state(ent)
  }

  # Format result for displaying on 12-digits display
  set pos [expr {abs($state(result))}]
  if {$pos<1e-8} {
    # Display as 1.23456e-20
    set fmt [format {%.7g} $pos]
  } elseif {$pos>=1e13} {
    set fmt [format {%7g} $pos]
  } else {
    set fmt [format {%.12g} $pos]
  }

  # Trim 0 after .
  set p [string first "." $fmt]
  if {$p>=0} {
    set t [string range $fmt [expr {$p+1}] end]
    if {[string length [string trimright $t "0"]]==0} {
      set zero [expr [string length $fmt] - 2]
      set fmt [string range $fmt 0 [expr {$p}]]
    }
  }

  if {$state(result)<0.0} {
    set fmt "-${fmt}"
  }

  set state(ent) $fmt

  # Reset state
  set state(started) 0
  set state(op) ""
  set state(dot) 0

  return
}

# -----------------------------------------------------------------------------
#  DoFunc
# -----------------------------------------------------------------------------
proc ::calc::DoFunc {func} {
  variable state
  set L "("
  set R ")"
  set state(ent) [eval expr "$func$L$state(ent)$R"]
  DoEqual
  return
}

# -----------------------------------------------------------------------------
#  DoPercent
# -----------------------------------------------------------------------------
proc ::calc::DoPercent {} {
  variable state
  set state(ent) [expr $state(ent)/100.]
  DoEqual
  return
}

# -----------------------------------------------------------------------------
#  DoOpe
# -----------------------------------------------------------------------------
proc ::calc::DoOpe {what} {
  variable state
  if {$state(op) != ""} {
    DoEqual
  }
  set state(op) $what
  set state(result) $state(ent)
  set state(started) 0
  set state(dot) 0
  return
}

# -----------------------------------------------------------------------------
#  DoSign
# -----------------------------------------------------------------------------
proc ::calc::DoSign {} {
  variable state
  set state(ent) [expr -$state(ent)]
  set state(started) 0
  return
}

# -----------------------------------------------------------------------------
# Handle keypress events
# -----------------------------------------------------------------------------
proc ::calc::KeyPressed {top key} {
  switch -exact -- $key {
    0 -
    1 -
    2 -
    3 -
    4 -
    5 -
    6 -
    7 -
    8 -
    9 {
      DoAppend $key
    }
    plus {
      DoOpe +
    }
    minus {
      DoOpe -
    }
    asterisk {
      DoOpe *
    }
    slash {
      DoOpe /
    }
    + -
    - -
    * -
    / {
      DoOpe $key
    }
    = -
    equal -
    Return -
    Enter {
      DoEqual
    }
    Delete -
    Escape {
      DoClear
    }
    period -
    . {
      DoDot
    }
    Tab {
      DoSign
    }
  }

  # puts "KEY ON $top AS $key"
}

proc ::calc::Quit {top} {
  catch {destroy $top}
  exit
}

# -----------------------------------------------------------------------------
#  Main
# -----------------------------------------------------------------------------
proc ::calc::GuessFontSize {maxwidth maxheight} {
  if {$maxheight<$maxwidth} {
    set maxsize $maxheight
  } else {
    set maxsize $maxwidth
  }

  if {$maxsize<0} {
    set maxsize 4
  }

  if {0} {
    set fsize 1
    while {1} {
      set ftry [expr {$fsize+1}]
      set fontname "$family $ftry"
      
      set ascent [font metrics $fontname -displayof $toplevel -ascent]
      set descent [font metrics $fontname -displayof $toplevel -descent]
      if {$ascent+$descent>=$maxsize} {
	# Too large
	break
      }
      
      set fsize $ftry
    }
  } else {
    set fsize [expr {($maxsize*8)/10}]
  }


  return $fsize
}

proc ::calc::AutoFont {toplevel wlist1 wlist2} {
  # Widget height
  set width [winfo width $toplevel]
  set height [winfo height $toplevel]

  if {[catch {set os [set ::tcl_platform(os)]}]} {
    set os "unknown"
  }
  if {[string match "Windows CE" $os]} {
    set family "Tahoma"
  } else {
    set family "Arial"
  }

  set fsize1 [GuessFontSize [expr {$height/4}] [expr {$width/8}]]
  set font1 "$family $fsize1 bold"
  foreach w $wlist1 {
    $w configure -font $font1
  }

  set fsize2 [GuessFontSize [expr {$height/8}] [expr {$width/11}]]
  set font2 "$family $fsize2"
  foreach w $wlist2 {
    $w configure -font $font2
  }

  return	      
}

proc ::calc::calc {toplevel args} {
  variable state

  set state(result)  0.
  set state(ent)     0.
  set state(op)      {}
  set state(dot)     0
  set state(started) 0

  if {0} {
    set keytop {
      {\uff17 {DoAppend 7} }
      {\uff18 {DoAppend 8} }
      {\uff19 {DoAppend 9} }
      {\u00f7 {DoOpe /}    }
      {\uff23  DoClear     }
      {\uff14 {DoAppend 4} }
      {\uff15 {DoAppend 5} }
      {\uff16 {DoAppend 6} }
      {\u00d7 {DoOpe *}    }
      {\u221a {DoFunc sqrt}}
      {\uff11 {DoAppend 1} }
      {\uff12 {DoAppend 2} }
      {\uff13 {DoAppend 3} }
      {\uff0d {DoOpe -}    }
      {\uff05  DoPercent   }
      {\uff10 {DoAppend 0} }
      {\u00b1  DoSign      }
      {\u30fb  DoDot       }
      {\uff0b {DoOpe +}    }
      {\uff1d  DoEqual     }
    }
  } else {
    set keytop {
      {7 {DoAppend 7}}
      {8 {DoAppend 8} }
      {9 {DoAppend 9} }
      {/ {DoOpe /}    }
      {CE  DoClear     }
      {4 {DoAppend 4} }
      {5 {DoAppend 5} }
      {6 {DoAppend 6} }
      {* {DoOpe *}    }
      {\u221a {DoFunc sqrt}}
      {1 {DoAppend 1} }
      {2 {DoAppend 2} }
      {3 {DoAppend 3} }
      {- {DoOpe -}    }
      {%  DoPercent   }
      {0 {DoAppend 0} }
      {\u00b1  DoSign      }
      {.  DoDot       }
      {+ {DoOpe +}    }
      {=  DoEqual     }
    }
  }
  
  set bodycolor "#0050a0"
  $toplevel configure \
      -bg     $bodycolor \
      -bd     2 \
      -relief ridge
    
  grid propagate $toplevel false
  set autofont1 [list]
  set autofont2 [list]

  set w [label [wjoin $toplevel disp] \
	     -textvariable [namespace current]::state(ent) \
	     -anchor       e \
	     -fg           "#004020" \
	     -bg           "#d0e0d0" \
	     -bd           1 \
	     -relief       ridge \
	     -padx         2 \
	     -pady         2]
  grid $w -row 0 -column 0 -columnspan 5 -sticky "news"

  lappend autofont1 $w

  set w [frame [wjoin $toplevel pad] \
	     -bg     $bodycolor \
	     -width  2 \
	     -height 3 \
	     -bd     3 \
	     -relief raised]
  grid $w -row 1 -column 0 -columnspan 5 -sticky "news"
  
  set fgcolor1 "#0060f0"
  set fgcolor2 "#806000"
  set fgcolor3 "#f03000"

  set bgcolor1 "#90c0ff"
  set bgcolor2 "#ffc0c0"

  for {set y 2} {$y < 6} {incr y} {
    for {set x 0} {$x < 5} {incr x} {
      set idx [expr $x + ($y - 2) * 5]
      set key [lindex [lindex $keytop $idx] 0]
      set cmd [lindex [lindex $keytop $idx] 1]
      if {$x < 3} {
	set fgcolor $fgcolor1
	set bgcolor $bgcolor1
      } elseif {($x == 4) && ($y == 2)} {
	set fgcolor $fgcolor3
	set bgcolor $bgcolor2
      } else {
	set fgcolor $fgcolor2
	set bgcolor $bgcolor2
      }

      if {0} {
	set activefgcolor $bgcolor
	set activebgcolor $fgcolor
      } else {
	set activefgcolor $fgcolor
	set activebgcolor $bgcolor
      }

      set w [button [wjoin $toplevel b$idx] \
		 -text                $key \
		 -fg                  $fgcolor \
		 -bg                  $bgcolor \
		 -activeforeground    $activefgcolor \
		 -activebackground    $activebgcolor \
		 -bd                  1 \
		 -highlightthickness  0 \
		 -padx                5 \
		 -pady                5 \
		 -cursor              hand2 \
		 -command [namespace code $cmd]]
      grid $w -row $y -column $x -sticky news
      lappend autofont2 $w
    }
  }
  
  bind $toplevel <KeyPress> [list [namespace code KeyPressed] $toplevel %K]
  bind $toplevel <Configure> [list ::calc::AutoFont $toplevel $autofont1 $autofont2]

  grid rowconfigure $toplevel {0} -weight 3 -uniform 1
  grid rowconfigure $toplevel {1} -weight 1 -uniform 1
  grid rowconfigure $toplevel {2 3 4 5} -weight 2 -uniform 1

  grid columnconfigure $toplevel {0 1 2 3} -weight 2 -uniform 1
  grid columnconfigure $toplevel {4} -weight 2 -uniform 1

  # Add menu
  if {[catch {set os [set ::tcl_platform(os)]}]} {
    set os "unknown"
  }

  set addmenu 1
  if {[string match "Windows CE" $os]} {
    set addmenu 1
  }

  set menuargs [list]
  lappend menuargs -tearoff 0

  if {$addmenu} {
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
      # lappend menuargs -font $S(font)
    }
    
    set mb [eval [list menu $toplevel.mb] $menuargs]
    
    set m [eval [list menu $mb.file] $menuargs]  
    
    $m add command -label "Exit" \
	-command [namespace code [list Quit $toplevel]]
    
    $mb add cascade -label "File" \
	-menu $m -underline 0
    
    $toplevel configure -menu $mb
  }

  # Adjust geometry dynamically
  if {[catch {::etcl::automanage $toplevel}]} {
    catch {wm geometry $toplevel "240x320"}
  }

  return
}

::calc::calc .
