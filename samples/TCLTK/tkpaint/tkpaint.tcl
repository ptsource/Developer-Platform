set tkpaint_ver 1.6

set v [split [info tclversion] .]
set major [lindex $v 0]
set minor [lindex $v 1]

if {$major<8 || ($major==8 && $minor<3)} {
  tk_messageBox -type ok \
      -message "You need tcl/tk version 8.3 or higher\n\
to use tkpaint 1.6.\n\
Tcl/Tk version $major.$minor does not support dashes." \
           -icon info \
           -title "TkPaint: must have Tcl/Tk 8.3 or higher to run!" \
           -default ok
exit
}

set ImgAvaliable [expr {![catch {package require Img}]}]

#
# Trying to guess LIBDIR if not explicitely set
#
#set LIBDIR e:/netanya00/tkpaint
if ![info exist LIBDIR] {
   set LIBDIR [file dirname $argv0]
}

if {![info exists CONFIGDIR]} {
   set CONFIGDIR $LIBDIR
}   

lappend auto_path $LIBDIR

proc Platform {a b} {
   global tcl_platform
   if {$tcl_platform(platform)=="windows"} {
     return $a
   }
   return $b
}

proc bgerror {e} {
  set e [string trim $e]
  if {$e==""} {return}
  puts $e
}

option add *Menubutton.Font [Platform {Arial 11 bold} {Helvetica 11 bold}]
set Font(button) [Platform {Arial 11 bold} {Helvetica 11 bold}]
set Font(lineWidthDemo) [Platform {"MS Sans Serif" 8} {Courier 8}]
set Font(rotateTextBox) [Platform {Arial 12 bold} {Helvetica 12 bold}]
set Font(groupLineWidthDemo) [Platform {Arial 12 bold} {Helvetica 12 bold}]
set Font(gridTicks) [Platform {Arial 7} {Courier 8}]
set Font(about) [Platform {"Times New Roman" 12 bold} {Helvetica 12 bold}]
set Font(zoomEntry) [Platform {Arial 10} {Helvetica 10}]
set Font(dash) [Platform {Arial 12 bold} {Helvetica 12 bold}]

wm title . "Tkpaint $tkpaint_ver - new file"
wm iconname . "tkpaint"
wm minsize . 450 150
wm protocol . WM_DELETE_WINDOW {File exit}

###### DEFAULT VALUES OF GLOBAL VARIABLES

proc setDefaultGlobals {} {
   global Graphics Canv utagCounter Image
   global undoStack undoMode History histPtr
   global Message Zoom

   array set Graphics {
     line,width      1
     line,color      black
     line,style      {}
     line,joinstyle  miter
     line,capstyle   butt
     line,arrow      none
     line,dash       {}
     arrowshape      {8 10 4}
     splinesteps     20
     shape           none
     fill,color      {}
     fill,style      {}
     mode            NULL
     font,size       10
     font,color      black
     font,normal     0
     font,bold       0
     font,italic     0
     font,roman      0
     font,underline  0
     font,overstrike 0
     font,style      {}
     font,stipple    {}
     text,anchor     c
     grid,on         0
     ticks,on        0
     snap,on         0
     grid,size       10m
     grid,snap       1
     snap,size       1
   }
   set Graphics(font,type) [Platform Arial Helvetica]

   set Zoom(factor) 1
   set Zoom(button,text) 100%
   set Zoom(selected,button) 1
   set Zoom(caller) ""
   set Zoom(font,size) $Graphics(font,size)

#### CANVAS DEFAULTS
   array set Canv {
      W   540
      H   360
      SW  1500
      SH  1500
      coords   0,0
      bg  white
   }
   set undoStack   {}
   set undoMode    0
   set History     {}
   set histPtr     0
   set utagCounter 0
   set Image(ctr)  0
   set Image(hist) {}
   set Image(wd) [pwd]
   set Message(1) "TKPaint"
   set Message(last) 1
   set Message(ctr) 1
   set Message(text) $Message(1)
}

#### DEFAULT BINDINGS

proc Bindings {mode} {
 switch $mode {
   enable {
      bind Canvas <Motion> {
         set Canv(pointerxy) \
             [expr round([.c canvasx %x])],[expr round([.c canvasy %y])]
      }
      bind Canvas <Control-Left>  {%W xview scroll -1 units}
      bind Canvas <Control-Right> {%W xview scroll  1 units}
      bind Canvas <Control-Up>    {%W yview scroll -1 units}
      bind Canvas <Control-Down>  {%W yview scroll  1 units}
      bind Canvas <Alt-Left>      {%W xview scroll -1 pages}
      bind Canvas <Alt-Right>     {%W xview scroll  1 pages}
      bind Canvas <Alt-Up>        {%W yview scroll -1 pages}
      bind Canvas <Alt-Down>      {%W yview scroll  1 pages}
      bind Canvas <Prior>         {%W yview scroll -1 pages}
      bind Canvas <Next>          {%W yview scroll  1 pages}
      bind Canvas <Home>          {%W xview moveto 0
                                   %W yview moveto 0}
      bind Canvas <End>  {
        set f [expr ($Canv(SH)-$Canv(H)+0.0)/$Canv(SH)]
         %W xview moveto 0
         %W yview moveto $f
      }

      bind Canvas <Control-Prior>    {
         set Canv(SW) [expr $Canv(SW)+30]
         %W configure -scrollregion "0 0 $Canv(SW) $Canv(SH)"
      }

      bind Canvas <Control-Next>     {
         set Canv(SH) [expr $Canv(SH)+30]
         %W configure -scrollregion "0 0 $Canv(SW) $Canv(SH)"
      }

      bind .c <Leave> {
         set Canv(pointerxy) ""
      }

      bind .c <Enter> {focus %W}

      bind .c <Configure> {
         set Canv(W)  %w
         set Canv(H)  %h
      }
   }

   disable {
      foreach e [bind .c] {
          bind .c $e {}
      }
   }
 }
}

## UNDO AND HISTORY PROCS
# A VERY IMPORTANT NOTE ABOUT THESE PROCS!!!!
# WHEN USING THEM, THEY ALWAYS GO TOGETHER,
# THE HISTORY COMMAND MUST ALWAYS COME BEFORE
# THE UNDO PROC!!!! OR ELESE YOU ARE INTO REAL TROUBLE!

proc Undo {mode {cmd ""}} {
  global undoStack undoMode histPtr File

  switch -exact -- $mode {
     exec {
        set undoMode 1
        if {[llength $undoStack]==0 || $histPtr==0} {
             Message "Reached bottom of undo stack"
             return
        }
        incr histPtr -1
        set cmd [lindex $undoStack $histPtr]
        eval $cmd
        if {$File(progress)!="dead"} {
          incr File(progress) -1
        }
        if {$File(progress)<0} {
          set File(progress) dead
          set File(saved) 0
        }
        if {$File(progress)==0} {
          set File(saved) 1
        }
        Message "History counter=$histPtr"
     }
     add {
        lappend undoStack $cmd
     }
  }
}

proc History {mode {cmd ""}} {
  global History histPtr undoStack File
  switch -exact -- $mode {
     add {
        if {$File(progress)!="dead"} {
          incr File(progress)
        }
        set File(saved) 0
        set File(new) 0

        if {$histPtr < [llength $History]} {
             set History [lrange $History 0 [expr $histPtr-1]]
             set undoStack [lrange $undoStack 0 [expr $histPtr-1]]
        } elseif {[llength $History]==50} {
             set History [lreplace $History 0 0]
             set undoStack [lreplace $undoStack 0 0]
        }
        lappend History $cmd
        set histPtr [llength $History]
     }
     repeat {
        if {$histPtr==[llength $History]} {
             Message "Reached History end ($histPtr)"
             return
        }
        set cmd [lindex $History $histPtr]
        incr histPtr
        if {$File(progress)!="dead"} {
          incr File(progress)
        }
        set File(saved) 0
        set File(new) 0
        eval $cmd
        Message "History counter = $histPtr"
     }
  }
}

proc Message {msg} {
   global Message
   if [info exists Message(jobid)] {
        after cancel $Message(jobid)
   }
   set Message(text) $msg
   set Message(jobid) [after 5000 {
       if {$Message(ctr)==$Message(last)} {
            set Message(ctr) 1
       } else {
            incr Message(ctr)
       }
       set i $Message(ctr)
       set Message(text) $Message($i)
       unset Message(jobid)
   }]
}

############# PREFERENCES SECTION
# HERE WE DEFINE PROCEDURES FOR LOADING AND SAVING USER PREFERENCES IN
# FILES. THE DEFAULT EXTENSION IS .INI, BUT THE USER MAY CHOOSE ANY FILE
# NAMES FOR SAVING HIS PREFERENCES.
# THE DEFAULT INI FILE IS:   tkpaint.ini
# WHICH MUST BE AT THE SAME DIRECTORY AS tkpaint.tcl.
# HENCE NO HARM WILL HAPPEN IF THIS FILE IS REMOVED.
# TKPAINT WILL LOAD THIS FILE WHEN IT STARTS IF IT EXISTS.
# THE PARAMETERS IN THIS FILES ARE IDENTICAL TO DEFAULT ONES OF TKPAINT.
# SO THIS FILE, AS IT IS NOW, MAKES NO DIFFERENCE FOR TKPAINT.
# HOWEVER, USERS MAY WANT TO SAVE THEIR PREFERENCES THERE IN THE FUTURE,
# OR EVEN EDIT IT (CAREFULLY!) AND PICK THEIR PREFERED PARAMETERS.
# OF COURSE, IT IS POSSIBLE TO CREATE AN UNLIMITED NUMBER OF PREFERECES FILES
# AND LOAD THEM AT ANY TIME (THIS IS THE ADVISED METHOD), WHILE KEEPING
# TKPAINT.INI ONLY FOR THE MOST STANDARD PARAMETERS.
set File(pref,name) [Platform tkpaint.ini [file join $env(HOME) .tkpaintrc]]
if {[info exist $env(HOME)]} {
    set File(pref,name) [file join $env(HOME) $File(pref,name)]
}     
set File(pref,types) {
   {{INI file} {.ini} }
   {{RC file}  {.rc} }
   {{All files} * }
}

proc cleanupCanvas {} {
  global Graphics Polygon Line Text undoMode Arc Reshape

  Bindings disable
  set Graphics(mode) NULL

  .c delete arrowHandle arcMark reshapeHandle graybox
  catch {unselectGroup}

  if [info exists Arc] {unset Arc}

  if {[info exists Polygon(coords)] && [llength $Polygon(coords)]>=6} {
    makePolygon
  }

  if [info exists Polygon] {
     catch {.c delete $Polygon(tempLine)}
     unset Polygon
  }

  if [info exists Line] {
    makeLine
  }

  .c raise gridObject

  if [info exists Text] {
    foreach event [.c bind text] {
       .c bind text $event {}
    }
    .c focus {}
    .c select clear
    TextHist
  }

  if [info exists Reshape] {
    unset Reshape
  }

  .c configure -cursor ""
  Bindings enable
}

proc Zoom {z} {
  global Graphics Canv Zoom

  cleanupCanvas

  set Zoom(button,text) "[expr int($z*100)]%"
  if {$Zoom(factor)==$z} {
    Message "Current zoom factor is $Zoom(button,text)."
    return
  }

  set ratio [expr ($z+0.0)/$Zoom(factor)]
  set Zoom(font,size) [expr $ratio*$Zoom(font,size)]
  set Graphics(font,size) [expr round($Zoom(font,size))]
  set Graphics(line,width) [expr $Graphics(line,width)*$ratio]
  set tmp $Graphics(arrowshape)
  set Graphics(arrowshape) {}
  foreach e $tmp {
    lappend Graphics(arrowshape) [expr $e*$ratio]
  }
  unset tmp
  #? set Graphics(grid,snap) [expr round($Graphics(grid,snap)*$ratio)]

  set Canv(SW) [expr $Canv(SW)*$ratio]
  set Canv(SH) [expr $Canv(SH)*$ratio]
  .c configure -scrollregion "0 0 $Canv(SW) $Canv(SH)"
  set xv [lindex [.c xview] 0]
  set yv [lindex [.c yview] 0]
  .c xview moveto $xv
  .c yview moveto $yv

  foreach id [.c find withtag obj] {
      .c scale $id 0 0  $ratio $ratio

      if {[catch {.c itemcget $id -width} result]==0} {
        set u [Utag find $id]
        if ![info exists Zoom($u,line,width)] {
          set Zoom($u,line,width) $result
        }
        set Zoom($u,line,width) [expr $Zoom($u,line,width)*$ratio]
        set w [expr round($Zoom($u,line,width))]
        .c itemconfig $id -width $w
      }

      if {[catch {.c itemcget $id -arrowshape} result]==0} {
        set a [list [expr [lindex $result 0]*$ratio] \
                    [expr [lindex $result 1]*$ratio] \
                    [expr [lindex $result 2]*$ratio] ]
        .c itemconfig $id -arrowshape $a
      }

      if {[catch {.c itemcget $id -font} result]==0} {
        set u [Utag find $id]
        if ![info exists Zoom($u,font,size)] {
          set Zoom($u,font,size) [lindex $result 1]
        }
        set Zoom($u,font,size) [expr $Zoom($u,font,size)*$ratio]
        set fsize [expr round($Zoom($u,font,size))]
        .c itemconfig $id -font [lreplace $result 1 1 $fsize]
      }
  }

  # grid/snap sizes are sometimes in i/c/m units, so first we need to seperate
  # the number from the unit:
  foreach par {
       Graphics(grid,size)
       Graphics(snap,size)
       Graphics(grid,snap)
  } {
       regexp {^([0-9.\+-]+)(i|m|c)?$} [set $par] dummy num unit
       set newval [expr $ratio*$num]
       if {int($newval)==$newval} {
         set newval [expr int($newval)]
       } else {
         set newval [format "%.2f" $newval]
       }
       set $par $newval$unit
  }
  if {$Graphics(snap,on)==0} {set Graphics(grid,snap) 1}

  set old_factor $Zoom(factor)
  set Zoom(factor) $z
  set Zoom(selected,button) $z
  if {$Zoom(caller) == ""} {
    History add "uplevel #0 set Zoom(caller) History \; Zoom $z"
    Undo add "uplevel #0 set Zoom(caller) Undo \; Zoom $old_factor"
  }
  set Zoom(caller) ""
}

proc loadPreferences {file} {
   global File
   Zoom 1
   Bindings disable
   if {[catch {uplevel #0 [list source $file]} result] !=0} {
     set answer [tk_messageBox -type yesno \
           -message "Prefernces file $file has an error: $result\n\
It is advised that you exit tkpaint and fix the error.\n\
Would you like to exit tkpaint?" \
           -icon warning \
           -title "TkPaint: Prefernces file $file has error" \
           -default yes]
      if {$answer=="yes"} {exit}
   }
   Bindings enable
}

proc savePreferences {file} {
  global Graphics Canv
  set fd [open $file w]
  puts $fd "# You may edit this file, but you must be careful!"
  puts $fd "# One tiny error can turn tkpaint into a time bomb!"
  puts $fd "\n"
  foreach name [lsort [array names Graphics]] {
     puts $fd [list set Graphics($name) $Graphics($name)]
  }
  puts $fd {set Graphics(mode) NULL}
  puts $fd "### End of Graphics parameters\n\n"
  puts $fd "# Now we save the canvas width, height, bg color,"
  puts $fd "# scroll region width and height:"
  puts $fd "set Canv(H) $Canv(H)"
  puts $fd "set Canv(W) $Canv(W)"
  puts $fd "set Canv(SH) $Canv(SH)"
  puts $fd "set Canv(SW) $Canv(SW)"
  puts $fd "set Canv(bg) $Canv(bg)"
  puts $fd "# Some explanations:"
  puts $fd "# H = height"
  puts $fd "# W = width"
  puts $fd "# SH = Scroll region height"
  puts $fd "# SW = Scroll region width"
  puts $fd "# Now we issue some tcl/tk commands to set the canvas view:"
  puts $fd {.c config -width $Canv(W) -height $Canv(H) \
    -bg $Canv(bg) \
    -scrollregion "0 0 $Canv(SW) $Canv(SH)"}
  puts $fd {wm geometry . ""}
  puts $fd ".c xview moveto 0"
  puts $fd ".c yview moveto 0"

  close $fd
  return 1
}

proc Preferences {mode} {
  global File
  switch $mode {
     load {
        set filename [tk_getOpenFile \
                 -title "Select preferences file" \
                 -filetypes $File(pref,types) \
                 -initialfile $File(pref,name) \
                 -defaultextension ".ini" ]
        if {$filename==""} {
           Message "Did not pick a file? why?"
           return
        }
        set File(pref,name) $filename
        loadPreferences $File(pref,name)
        Message "Preferences loaded from $File(pref,name)"
     }
     save {
        set filename [tk_getSaveFile \
                 -title "Save preferences to file" \
                 -filetypes $File(pref,types) \
                 -initialfile $File(pref,name) \
                 -defaultextension ".ini" ]
        if {$filename==""} {
           Message "Did not save!?"
           return
        }
        set File(pref,name) $filename
        savePreferences $File(pref,name)
        Message "Preferences saved to $File(pref,name)"
     }
  }
}

proc resetCanvas {} {
   global Canv File TextInfo Zoom CONFIGDIR
   Bindings disable
   catch {unset TextInfo}
   catch {unset Zoom}
   setDefaultGlobals

   if [file readable $File(pref,name)] {
       loadPreferences $File(pref,name)
   } elseif [file readable [file join $CONFIGDIR tkpaintrc]] {
         loadPreferences [file join $CONFIGDIR tkpaintrc]
   } else {
       .c configure -width $Canv(W) \
	       -height $Canv(H) -bg $Canv(bg) \
	       -scrollregion "0 0 $Canv(SW) $Canv(SH)"
       wm geometry . ""
       .c xview moveto 0
       .c yview moveto 0
   }
   set Canv(W) [winfo width .c]
   set Canv(H) [winfo height .c]
   .c delete obj graybox bkg
   set File(progress) 0
   Bindings enable
}


#### FINALLY, HERE WE CREATE THE CANVAS .c
frame .main
canvas .c -xscrollcommand ".main.hscroll set" \
          -yscrollcommand ".main.vscroll set"
scrollbar .main.vscroll -command ".c yview"
scrollbar .main.hscroll -orient horiz -command ".c xview"

# Check for DASH patch bug.
proc dashbug {} {
set id [.c create rectangle 10 10 20 20 -tags bugtest]
set below [.c find below bugtest]
if {$below==$id} {
  tk_messageBox -title Warning -icon warning -message "You are using\
  buggy version of dash patch, which can break group operation in\
  tkpaint." -type ok
}

.c delete bugtest
}
grid .c -in .main \
    -row 0 -column 0 -rowspan 1 -columnspan 1 -sticky news
grid .main.vscroll \
    -row 0 -column 1 -rowspan 1 -columnspan 1 -sticky news
grid .main.hscroll \
    -row 1 -column 0 -rowspan 1 -columnspan 1 -sticky news
grid rowconfig    .main 0 -weight 1 -minsize 0
grid columnconfig .main 0 -weight 1 -minsize 0

resetCanvas


##### USER INTERFACE: BUTTONS, TOOL BARS, STATUS BARS, FRAMES, ETC ...

frame .mbar -bd 1 -relief raised

foreach {menub text menu under} {
   .mbar.file    File   .mbar.file.menu    0
   .mbar.shape   Shape  .mbar.shape.menu   0
   .mbar.line    Line   .mbar.line.menu    0
   .mbar.image   Image  .mbar.image.menu   0
   .mbar.fill    Fill   .mbar.fill.menu    2
   .mbar.edit    Edit   .mbar.edit.menu    0
   .mbar.group   Group  .mbar.group.menu   0
   .mbar.text    Text   .mbar.text.menu    0
} {
    menubutton $menub -text $text -underline $under -menu $menu
    pack $menub -side left
}

button .mbar.grid -text Grid -font $Font(button) \
       -relief flat \
       -command {gridSelector .gridsel}
pack .mbar.grid -side left
menubutton .mbar.zoom -text Zoom -underline 0 -menu .mbar.zoom.menu
pack .mbar.zoom -side left
menubutton .mbar.help -text Help -underline 1 -menu .mbar.help.menu
pack .mbar.help -side right

entry .mbar.zoomentry \
      -state disabled \
      -textvariable Zoom(button,text) \
      -bd 2 \
      -bg #00ff40 \
      -fg #000040 \
      -font $Font(zoomEntry) \
      -width 5 \
      -relief sunken
pack .mbar.zoomentry -side left

# IN THE FOLLOWING LIST, THE ITEMS ARE GROUPED AS FOLLOWS:
# BUTTON TYPE; ROW; COLUMN; GIF; COMMAND
# R IS A RADIOBUTTON
# B IS A REGULAR BUTTON
# C IS A CHECKBUTTON
# THE ROW AND COLUMN NUMBERS ARE FOR THE GRID GEOMETRY MANAGER
# THE GIF IS DISPLAYED ON THE BUTTON
# THE COMMAND IS INVOKED WHEN THE BUTTON IS PRESSED

set Buttons { 
R  mode  0  0  rectangle.gif   {.mbar.shape.menu invoke Rectangle}
R  mode  0  1  roundrect.gif   {.mbar.shape.menu invoke "Round rectangle"}
R  mode  0  2  circle.gif      {.mbar.shape.menu invoke Circle}
R  mode  0  3  ellipse.gif     {.mbar.shape.menu invoke Ellipse}
R  mode  0  4  polygon.gif     {.mbar.shape.menu invoke Polygon}
R  mode  0  5  polyline.gif    {.mbar.shape.menu invoke Line}
R  mode  0  6  spline.gif      {.mbar.shape.menu invoke Spline}
R  mode  0  7  cspline.gif     {.mbar.shape.menu invoke "Closed Spline"}
R  mode  0  8  arc.gif         {.mbar.shape.menu invoke Arc}
R  mode  0  9  pieslice.gif    {.mbar.shape.menu invoke PieSlice}
R  mode  0 10  chord.gif       {.mbar.shape.menu invoke Chord}
R  mode  0 11  freehand.gif    {.mbar.shape.menu invoke "Free Hand"}
R  mode  1  0  text.gif        {.mbar.text.menu invoke "Draw text"}
R  mode  1  1  move.gif        {.mbar.edit.menu invoke "Move object"}
R  mode  1  2  copy.gif        {.mbar.edit.menu invoke "Copy object"}
R  mode  1  3  erase.gif       {.mbar.edit.menu invoke "Delete object"}
R  mode  1  4  raise.gif       {.mbar.edit.menu invoke "Raise object"}
R  mode  1  5  lower.gif       {.mbar.edit.menu invoke "Lower object"}
R  mode  1  6  arrows.gif      {.mbar.line.menu invoke Arrows}
C  grid,size 1  7  grid.gif    {set Graphics(grid,on) 1}
R  mode  1 8  reconf.gif       {.mbar.group.menu invoke 0}
B  dumm  1 9 undo.gif          {.mbar.edit.menu invoke "Undo last change"}
B  dumm  1 10 unundo.gif       {.mbar.edit.menu invoke "Undo last undo"}
B  dumm  1 11  savefile.gif    {.mbar.file.menu invoke "Save"}
}

######## Text Tool buttons

set textButtons {
   C   0  12  bold.gif         {resetFontStyle}                 dummy
   C   0  13  underline.gif    {resetFontStyle}                 dummy
   C   0  14  italic.gif       {resetFontStyle}                 dummy
   R   1  12  lefta.gif        {.mbar.text.menu.anchor invoke West}    w
   R   1  13  centera.gif      {.mbar.text.menu.anchor invoke Center}  c
   R   1  14  righta.gif       {.mbar.text.menu.anchor invoke East}    e
}

frame .tools

foreach {btype var row col gif command} $Buttons {
    regexp {([^.]+)\.} $gif dummy b
    set im [image create photo -file [file join $LIBDIR gifs $gif]]
    set butt .tools.button${row}_${col}
    if {$btype=="R"} {
       set value [lindex $command end]
       radiobutton $butt -image $im -bd 1 \
             -indicatoron false \
             -selectcolor "" \
             -variable Graphics($var) \
             -value $value \
             -command $command
    }
    if {$btype=="B"} {
       button $butt -image $im -bd 1 \
             -command $command
    }
    if {$b=="grid"} {
       checkbutton $butt -image $im -bd 1 \
             -indicatoron false \
             -selectcolor "" \
             -variable Graphics(grid,on)
    }
    grid config $butt -row $row -column $col\
                -columnspan 1 -rowspan 1 -sticky "snew"
}

foreach {btype row col gif command value} $textButtons {
   regexp {([^.]+)\.} $gif dummy b
   set im [image create photo -file [file join $LIBDIR gifs $gif]]
   set butt .tools.button${row}_${col}
   if {$btype=="C"} {
      checkbutton $butt -image $im -bd 1 \
             -indicatoron false \
             -selectcolor "" \
             -variable Graphics(font,$b) \
             -command $command
   }
   if {$btype=="R"} {
      radiobutton $butt -image $im -bd 1 \
             -indicatoron false \
             -selectcolor "" \
             -variable Graphics(text,anchor) \
             -value $value \
             -command $command
   }
   grid config $butt -row $row -column $col\
         -columnspan 1 -rowspan 1 -sticky "snew"
}

####### LINE WIDTH DEMO SCALE
frame .tools.width -relief raised -bd 1
canvas .tools.widthcanvas -relief flat -height 5m -width 4c
.tools.widthcanvas create text 1 1 \
       -anchor nw \
       -text "Line Width" \
       -font $Font(lineWidthDemo)
       
.tools.widthcanvas create line 1.8c .3c 4c .3c \
       -tags demoLine \
       -fill "$Graphics(line,color)" \
       -stipple "$Graphics(line,style)" \
       -arrow "$Graphics(line,arrow)" \
       -joinstyle "$Graphics(line,joinstyle)" \
       -width "$Graphics(line,width)"

scale .tools.widthscale -orient horiz \
       -resolution 1 -from 0 -to 60 \
       -length 2.5c \
       -variable Graphics(line,width) \
       -bd 1 \
       -relief flat \
       -highlightthickness 0 \
       -width 8 \
       -showvalue true \
       -font $Font(lineWidthDemo)

pack .tools.widthcanvas .tools.widthscale -in .tools.width \
     -side top  -fill both -expand true

grid config .tools.width -row 0 -column 15\
        -columnspan 1 -rowspan 2 -sticky "snew"

####### HERE WE BUILD THE FILL AND OUTLINE COLORS BUTTONS AND SAMPLES
button .tools.but_outline -text Outline: -anchor e \
      -command {chooseOutlineColor}
button .tools.but_fill -text Fill: -anchor e \
      -command {chooseFillColor}
frame  .tools.fr_outline -bg $Graphics(line,color)
frame  .tools.fr_fill
#frame  .tools.fr_fill -bg $Graphics(fill,color)

grid config .tools.but_outline -row 0 -column 16\
        -columnspan 1 -rowspan 1 -sticky "snew"
grid config .tools.but_fill -row 1 -column 16\
        -columnspan 1 -rowspan 1 -sticky "snew"

grid config .tools.fr_outline -row 0 -column 17\
        -columnspan 1 -rowspan 1 -sticky "snew"
grid config .tools.fr_fill -row 1 -column 17\
        -columnspan 1 -rowspan 1 -sticky "snew"

######### HERE WE START PACKING WITH THE GRID GEOMETRY MANAGER

grid config .mbar -column 0 -row 0 \
        -columnspan 1 -rowspan 1 -sticky "snew"
grid config .tools -column 0 -row 1 \
        -columnspan 1 -rowspan 1 -sticky "snew" 
grid config .main -column 0 -row 2 \
        -columnspan 1 -rowspan 1 -sticky "snew" 

#
# SET UP GRID FOR RESIZING.
# COLUMN 0 (THE ONLY ONE) GETS THE EXTRA SPACE.
grid columnconfigure . 0 -weight 1
# COL 17 (COLOR SAMPLES) GETS EXTRA SPACE IN RESIZING
grid columnconfigure .tools 17 -minsize 30
#grid columnconfigure .tools 17 -weight 1
# COL 15 (LINE DEMO SAMPLES) GETS EXTRA SPACE IN RESIZING
grid columnconfigure .tools 15 -minsize 40
grid columnconfigure .tools 15 -weight 1
# Row 2 (the main area) gets the extra space.
grid rowconfigure . 2 -weight 1

for {set i 0} {$i<=14} {incr i} {
      grid columnconfigure .tools $i -minsize 25
}

######### MENUS ####################################

### FILE MENU:

menu .mbar.file.menu -tearoff 0

.mbar.file.menu add command \
         -label New \
         -accelerator "Ctrl+n" \
         -command {File new}

.mbar.file.menu add command \
         -label Open \
         -accelerator "Ctrl+o" \
         -command {File open}

.mbar.file.menu add command \
         -label Close  \
         -command {File close}

.mbar.file.menu add command \
         -label Save \
         -command {File save auto}

.mbar.file.menu add cascade -label "Save as" -menu .mbar.file.menu.save_as

menu .mbar.file.menu.save_as -tearoff 0

.mbar.file.menu.save_as add command \
         -label "Save as Encapsulated PostScript" \
         -command {File save eps}

.mbar.file.menu.save_as add command \
         -label "Save as Tcl script" \
         -command {File save pic}

.mbar.file.menu add command \
         -label Print \
         -command {File print}
.mbar.file.menu add command \
         -label Exit \
         -accelerator "Ctrl+x" \
         -command {File exit}

.mbar.file.menu add cascade -label "Preferences" -menu .mbar.file.menu.pref

menu .mbar.file.menu.pref -tearoff 0

.mbar.file.menu.pref add command \
         -label "Load" \
         -command {Preferences load}

.mbar.file.menu.pref add command \
         -label "Save" \
         -command {Preferences save}



####### SHAPE MENU:

menu .mbar.shape.menu -tearoff 0

.mbar.shape.menu add radiobutton \
     -label Rectangle \
     -variable Graphics(mode) \
     -value Rectangle \
     -command {startRectagle}

.mbar.shape.menu add radiobutton \
     -label "Round rectangle" \
     -variable Graphics(mode) \
     -value "Round rectangle" \
     -command {startRoundRect}

.mbar.shape.menu add radiobutton \
     -label Circle \
     -variable Graphics(mode) \
     -value Circle \
     -command {startCircle}

.mbar.shape.menu add radiobutton \
     -label Ellipse \
     -variable Graphics(mode) \
     -value Ellipse \
     -command {startEllipse}

.mbar.shape.menu add radiobutton \
     -label Polygon \
     -variable Graphics(mode) \
     -value Polygon \
     -command {startPolygon 0}

.mbar.shape.menu add radiobutton \
     -label "Closed Spline"  \
     -variable Graphics(mode) \
     -value "Closed Spline" \
     -command {startPolygon 1}

.mbar.shape.menu add radiobutton \
     -label Line \
     -variable Graphics(mode) \
     -value Line \
     -command {startLine 0}

.mbar.shape.menu add radiobutton \
     -label Spline \
     -variable Graphics(mode) \
     -value Spline \
     -command {startLine 1}

.mbar.shape.menu add radiobutton \
      -label Arc \
      -variable Graphics(mode) \
      -value Arc \
      -command {
         set Graphics(shape) arc
         arcMode
}

.mbar.shape.menu add radiobutton \
      -label PieSlice \
      -variable Graphics(mode) \
      -value PieSlice \
      -command {
         set Graphics(shape) pieslice
         arcMode
}

.mbar.shape.menu add radiobutton \
         -label Chord \
         -variable Graphics(mode) \
         -value Chord \
         -command {
             set Graphics(shape) chord
             arcMode
}

.mbar.shape.menu add radiobutton \
     -label "Free Hand" \
     -variable Graphics(mode) \
     -value "Free Hand" \
     -command {freeHand}

#### LINE MENU:

menu .mbar.line.menu

.mbar.line.menu add cascade -label Width -menu .mbar.line.menu.width

menu .mbar.line.menu.width -tearoff 0
foreach s {0 0.5 1 1.5 2 3 4 5 6 7 8 9 10 11 12 15 18 21 24 27 30 33 
           36 42 48 54 60} {
  .mbar.line.menu.width add radiobutton -label "${s} points" \
              -variable Graphics(line,width) \
              -value $s
}

.mbar.line.menu add cascade -label Style -menu .mbar.line.menu.style

menu .mbar.line.menu.style -tearoff 0

foreach s {solid gray12 gray25 gray50 gray75} {
   .mbar.line.menu.style add radiobutton -label $s \
         -variable Graphics(line,style) \
         -value $s
}

.mbar.line.menu add cascade -label "Join style" -menu .mbar.line.menu.join

menu .mbar.line.menu.join -tearoff 0
foreach s {bevel miter round} {
   .mbar.line.menu.join add radiobutton -label $s \
   -variable Graphics(line,joinstyle) \
   -value $s
}

.mbar.line.menu add cascade -label "Cap style" -menu .mbar.line.menu.cap

menu .mbar.line.menu.cap -tearoff 0
foreach s {butt projecting round} {
   .mbar.line.menu.cap add radiobutton -label $s \
   -variable Graphics(line,capstyle) \
   -value $s
}

.mbar.line.menu add cascade -label "Dash style" -menu .mbar.line.menu.dash

menu .mbar.line.menu.dash -tearoff 0
foreach s {. - -. -.. -- --. --.. , -, -,, NONE} {
   .mbar.line.menu.dash add radiobutton -label $s -font $Font(dash) \
   -variable Graphics(line,dash) \
   -value $s
}

.mbar.line.menu add command -label Color \
                -command {chooseOutlineColor}
.mbar.line.menu add command -label Arrows -command {arrowsMode}

.mbar.line.menu add command -label "Arrow shape" -command {arrowShapeTool}

####### IMAGE MENU:

menu .mbar.image.menu -tearoff 0
if {$ImgAvaliable} {
set imageInfo {
  GIF      {Image gif}
  JPEG     {Image jpg}
  BMP      {Image bmp}
  PPM      {Image ppm}
  PGM      {Image pgm}
  XPM      {Image xpm}
  PNG      {Image png}
  TIFF     {Image tif}
  POSTSCRIPT   {Image ps}
  BITMAP   {Image bitmap}
}
} else {
set imageInfo {
  GIF      {Image gif}
  PPM      {Image ppm}
  BITMAP   {Image bitmap}
}
}
foreach {lab cmd} $imageInfo {
   .mbar.image.menu add radiobutton \
        -label $lab \
        -variable Graphics(mode) \
        -value $lab \
        -command $cmd
}


#### FILL MENU:

menu .mbar.fill.menu -tearoff 0

.mbar.fill.menu add cascade -label Style -menu .mbar.fill.menu.style

menu .mbar.fill.menu.style -tearoff 0
foreach s {gray12 gray25 gray50 gray75} {
   .mbar.fill.menu.style add radiobutton -label $s \
         -variable Graphics(fill,style) \
         -value $s
}

.mbar.fill.menu.style add command -label "Solid" -command {
          .mbar.fill.menu.style activate none
          set Graphics(fill,style) {}
}

.mbar.fill.menu add command -label Color -command {chooseFillColor}

.mbar.fill.menu add command -label "No Color" -command {
          set Graphics(fill,color) {}
}

#### EDIT MENU:

menu .mbar.edit.menu

.mbar.edit.menu add command \
        -label "Undo last change" \
        -accelerator "Ctrl+u" \
        -command {Undo exec}

.mbar.edit.menu add command \
        -label "Undo last undo" \
        -accelerator "Ctrl+l" \
        -command {History repeat}

.mbar.edit.menu add radiobutton \
        -label "Move object" \
        -variable Graphics(mode) \
        -value "Move object" \
        -command {moveMode}

.mbar.edit.menu add radiobutton \
        -label "Copy object" \
        -variable Graphics(mode) \
        -value "Copy object" \
        -command {copyMode}

.mbar.edit.menu add radiobutton \
        -label "Raise object" \
        -variable Graphics(mode) \
        -value "Raise object" \
        -command {raiseMode}

.mbar.edit.menu add radiobutton \
        -label "Lower object"\
        -variable Graphics(mode) \
        -value "Lower object" \
        -command {lowerMode}

.mbar.edit.menu add radiobutton \
        -label "Delete object" \
        -variable Graphics(mode) \
        -value "Delete object" \
        -command {deleteMode}

.mbar.edit.menu add radiobutton \
        -label "Reshape polygon/line" \
        -variable Graphics(mode) \
        -value "Reshape mode" \
        -command {reshapeMode}

.mbar.edit.menu add command \
        -label "Delete All" \
        -command {deleteAll}

.mbar.edit.menu add command \
        -label "Canvas background color" \
        -command {chooseBackgroudColor}

.mbar.edit.menu add radiobutton \
        -label "Bitmap foreground color" \
        -variable Graphics(mode) \
        -value "Bitmap foreground" \
        -command {bitmapFgColor}

.mbar.edit.menu add radiobutton \
        -label "Bitmap background color" \
        -variable Graphics(mode) \
        -value "Bitmap background" \
        -command {bitmapBgColor}


#### GROUP MENU:

menu .mbar.group.menu

.mbar.group.menu add radiobutton \
        -label "Select group" \
        -variable Graphics(mode) \
        -value "Group Mode" \
        -accelerator "Ctrl+s" \
        -command {selectGroupMode}

.mbar.group.menu add command \
        -label "Select all" \
        -accelerator "Ctrl+a" \
        -command {selectAll}

.mbar.group.menu add command \
        -label "Select 1 object" \
        -command {select1object}

.mbar.group.menu add command \
        -label "Unselect"\
        -command {unselectGroup}

.mbar.group.menu add command \
        -label "Copy group" \
        -accelerator "Ctrl+c" \
        -command {createGroupCopy}

.mbar.group.menu add command \
        -label "Rotate group" \
        -accelerator "Ctrl+r" \
        -command {rotateGroupMode}

.mbar.group.menu add command \
        -label "Deform group" \
        -accelerator "Ctrl+e" \
        -command {deformGroupMode}

.mbar.group.menu add command \
        -label "Horizontal reflection" \
        -accelerator "Ctrl+h" \
        -command {reflect x}

.mbar.group.menu add command \
        -label "Vertical reflection"\
        -accelerator "Ctrl+v" \
        -command {reflect y}

.mbar.group.menu add command \
        -label "Raise group"\
        -command {raiseGroup}

.mbar.group.menu add command \
        -label "Lower group"\
        -command {lowerGroup}

.mbar.group.menu add command \
        -label "Delete group"\
        -accelerator "Ctrl+d" \
        -command {deleteGroup}

.mbar.group.menu add command \
        -label "Edit line width"\
        -command {editGroupLineWidth}

.mbar.group.menu add command \
        -label "Edit line color"\
        -command {editGroupLineColor}

.mbar.group.menu add command \
        -label "Edit fill color"\
        -command {editGroupFillColor}

.mbar.group.menu add command \
        -label "Edit font"\
        -command {editGroupFont}


#### TEXT MENU:

menu .mbar.text.menu -tearoff 0

.mbar.text.menu add radiobutton -label "Draw text" \
            -variable Graphics(mode) \
            -value "Draw text" \
            -command {TextMode}

.mbar.text.menu add command \
           -label "Choose font" \
           -accelerator "Ctrl+f" \
           -command {chooseFont}

.mbar.text.menu add cascade -label "Font stipple" \
                            -menu .mbar.text.menu.stipple
menu .mbar.text.menu.stipple -tearoff 0
foreach {lbl val} {
    Gray12 gray12
    Gray25 gray25
    Gray50 gray50
    Gray75 gray75
    Solid  solid
} {
   .mbar.text.menu.stipple add radiobutton -label $lbl \
         -variable fontStipple \
         -value $val \
         -command {
             if {$fontStipple == "solid"} {
               set Graphics(font,stipple) {}
             } else {
               set Graphics(font,stipple) $fontStipple
             }
         }
}

set fontStipple solid

.mbar.text.menu add cascade -label "Text anchor" -menu .mbar.text.menu.anchor

menu .mbar.text.menu.anchor -tearoff 0
foreach {anchor label} {
   w   West
   e   East
   c   Center
   n   North
   s   South
   nw  NW
   ne  NE
   sw  SW
   se  SE
} {
   .mbar.text.menu.anchor add radiobutton -label $label \
             -variable Graphics(text,anchor) \
             -value $anchor
}

# HELP MENU

menu .mbar.help.menu -tearoff 0

.mbar.help.menu add command -label "Help" -command  Help

.mbar.help.menu add command -label "About" -command {About}

#### ZOOM MENU:

menu .mbar.zoom.menu -tearoff 0

foreach x {0.5 0.75 1 1.5 2 2.5 3 3.5 4 4.5 5} {
  set percents "[expr int(100*$x)]%"
  .mbar.zoom.menu add radiobutton -label $percents \
            -value $x \
            -variable Zoom(selected,button) \
            -command "Zoom $x"
}


############## END OF GUI  .....   %>|(~



############################# PROCEDURES ###############################

# WE START WITH A PROCEDURE THAT ASSIGNS A UNIQUE TAG TO EACH
# OBJECT THAT WE CREATE ON THE CANVAS. THIS KIND OF TAG IS USEFUL,
# FOR EXAMPLE, FOR THE UNDO ACTION, WHERE AN OBJECT MAY BE CREATED AND DELETED
# SEVERAL TIMES (HENCE ITS NORMAL ID MAY CHANGE) RETAINING ITS UTAG.
# THE PROCEDURE ALSO FINDS THE UTAG OF A GIVEN ID.

proc Utag {mode id} {
  global utagCounter
  if ![regexp {^[1-9][0-9]*$} $id] {
    return ""
  }
  switch $mode {
     assign {
        incr utagCounter
        set utag utag$utagCounter
        .c addtag $utag withtag $id
        return $utag
     }
     find {
        set tags [.c gettags $id]
        set n [lsearch -regexp $tags {utag[0-9]+}]
        if {-1==$n} {error "utag trouble! Report bug!!"}
        return [lindex $tags $n]
     }
  }
}

###### RECTANGLE SECTION
proc startRectagle {} {
  global Rectangle Graphics

  set Graphics(shape) Rectangle

  bind .c <Button-1> {
       set x [.c canvasx %x $Graphics(grid,snap)]
       set y [.c canvasy %y $Graphics(grid,snap)]
       set Rectangle(coords) "$x $y $x $y"
       set Rectangle(options)  [list \
           -width   $Graphics(line,width) \
           -outline $Graphics(line,color) \
           -fill    $Graphics(fill,color) \
           -dash    $Graphics(line,dash)  \
           -stipple $Graphics(fill,style) \
           -tags    {Rectangle obj}       \
       ]
  }
  bind .c <B1-Motion> {
       set x [.c canvasx %x $Graphics(grid,snap)]
       set y [.c canvasy %y $Graphics(grid,snap)]
       makeRectagle $x $y
  }
  bind .c <B1-ButtonRelease> {
      if ![info exists Rectangle(id)] {return}
      set utag [Utag assign $Rectangle(id)]
      History add [getObjectCommand $utag 1]
      Undo add ".c delete $utag"
      unset Rectangle
      set z [expr round(rand()*5)]
      switch -exact $z {
          0 {Message "No more bad jokes!!"}
          1 {Message "And now we are out of chives"}
          2 {Message "OK folks!... It's a wrap!"}
          3 {Message "AMD K6 - great CPU!"}
          4 {Message "Amazone.com: good books store!"}
          5 {Message {If you haven't, try "Deform" from "Group"!}}
      }
  }
  Message "Found any bugs?"
}

proc makeRectagle {x y} {
  global Rectangle
  set Rectangle(coords) [lreplace $Rectangle(coords) 2 3 $x $y]
  catch {.c delete $Rectangle(id)}
  set Rectangle(id) \
      [eval .c create rectangle $Rectangle(coords) $Rectangle(options)]
}

###### ROUND RECTANGLE SECTION
proc startRoundRect {} {
  global RoundRect Graphics

  set Graphics(shape) "Round rectangle"

  bind .c <Button-1> {
       set x [.c canvasx %x $Graphics(grid,snap)]
       set y [.c canvasy %y $Graphics(grid,snap)]
       set RoundRect(tmp,coords) "$x $y $x $y"
       set RoundRect(tmp,options)  [list  \
           -width   $Graphics(line,width) \
           -outline $Graphics(line,color) \
           -fill    $Graphics(fill,color) \
           -dash    $Graphics(line,dash)  \
           -stipple $Graphics(fill,style) \
           -tags    {tmpRoundRect obj}    \
       ]

       set RoundRect(options)  [list \
           -width   $Graphics(line,width) \
           -outline $Graphics(line,color) \
           -fill    $Graphics(fill,color) \
           -dash    $Graphics(line,dash)  \
           -stipple $Graphics(fill,style) \
           -smooth  1                     \
           -tags    {RoundRect obj}       \
       ]

  }
  bind .c <B1-Motion> {
       set x [.c canvasx %x $Graphics(grid,snap)]
       set y [.c canvasy %y $Graphics(grid,snap)]
       makeRoundRect $x $y
  }
  bind .c <B1-ButtonRelease> {finishRoundRect}
}

proc makeRoundRect {x y} {
  global RoundRect
  set RoundRect(tmp,coords) [lreplace $RoundRect(tmp,coords) 2 3 $x $y]
  catch {.c delete $RoundRect(tmp,id)}
  set RoundRect(tmp,id) \
      [eval .c create rectangle $RoundRect(tmp,coords) $RoundRect(tmp,options)]
}

proc finishRoundRect {} {
  global RoundRect
  if ![info exists RoundRect(tmp,id)] {return}

  set x1 [lindex $RoundRect(tmp,coords) 0]
  set y1 [lindex $RoundRect(tmp,coords) 1]
  set x2 [lindex $RoundRect(tmp,coords) 2]
  set y2 [lindex $RoundRect(tmp,coords) 3]

  if {abs($x2-$x1)<=2 || abs($y2-$y1)<=2} {
      .c delete $RoundRect(tmp,id)
      catch {unset RoundRect}
      return
  }
  if {$x2<$x1} {
       set tmp $x1
       set x1 $x2
       set x2 $tmp
  }
  if {$y2<$y1} {
       set tmp $y1
       set y1 $y2
       set y2 $tmp
  }
  set a [expr $x2-$x1]
  set b [expr $y2-$y1]
  if {$a<=$b} {set min $a} else {set min $b}
  if {$min>=100} {set r 25} else {set r [expr int(0.4*$min)+1]}

  set points {
      $x1+$r   $y1
      $x1+$r   $y1
      $x2-$r   $y1
      $x2-$r   $y1
      $x2      $y1
      $x2      $y1+$r
      $x2      $y1+$r
      $x2      $y2-$r
      $x2      $y2-$r
      $x2      $y2
      $x2-$r   $y2
      $x2-$r   $y2
      $x1+$r   $y2
      $x1+$r   $y2
      $x1      $y2
      $x1      $y2-$r
      $x1      $y2-$r
      $x1      $y1+$r
      $x1      $y1+$r
      $x1      $y1
  }

  foreach {a b} $points {
    lappend coords [eval expr $a] [eval expr $b]
  }
  
  .c delete $RoundRect(tmp,id)
  set id [eval .c create polygon $coords $RoundRect(options)]
  set utag [Utag assign $id]
  History add [getObjectCommand $utag 1]
  Undo add ".c delete $utag"
  catch {unset RoundRect}
}

######## CIRCLE SECTION

proc startCircle {} {
  global Circle Graphics
  set Graphics(shape) circle
  bind .c <Button-1> {
       set x [.c canvasx %x $Graphics(grid,snap)]
       set y [.c canvasy %y $Graphics(grid,snap)]
       set Circle(center) "$x $y"
       set Circle(options)  [list \
            -width    $Graphics(line,width) \
            -outline  $Graphics(line,color) \
            -dash    $Graphics(line,dash)  \
            -stipple  $Graphics(fill,style) \
            -fill     $Graphics(fill,color) \
            -tags     {Circle obj}        \
       ]
       Message "Now hold and drag the mouse!"
  }
  bind .c <B1-Motion> {
       set x [.c canvasx %x $Graphics(grid,snap)]
       set y [.c canvasy %y $Graphics(grid,snap)]
       makeCircle $x $y
  }
  bind .c <B1-ButtonRelease> {
      if ![info exists Circle(id)] {return}
      set utag [Utag assign $Circle(id)]
      History add [getObjectCommand $utag 1]
      Undo add ".c delete $utag"
      catch {unset Circle}
      Message "Your circle is done!"
  }
  Message "Click for circle's center"
}

proc makeCircle {x y} {
  global Circle Graphics
  set x0 [lindex $Circle(center) 0]
  set y0 [lindex $Circle(center) 1]
  set tmp  [expr sqrt(pow($x-$x0,2)+pow($y-$y0,2))]
  set gsnap [winfo fpixels .c $Graphics(grid,snap)]
  set r  [expr (int($tmp)/$gsnap)*$gsnap]

  set coords [list [expr $x0-$r] [expr $y0-$r] [expr $x0+$r] [expr $y0+$r] ]

  catch {.c delete $Circle(id)}
  set Circle(id) [eval .c create oval $coords $Circle(options)]
}

######### ELLIPSE SECTION

proc startEllipse {} {
  global Ellipse Graphics
  set Graphics(shape) ellipse
  bind .c <Button-1> {
       set x [.c canvasx %x $Graphics(grid,snap)]
       set y [.c canvasy %y $Graphics(grid,snap)]
       set Ellipse(center) "$x $y"
       set Ellipse(options)  [list \
          -width   $Graphics(line,width) \
          -outline $Graphics(line,color) \
          -fill    $Graphics(fill,color) \
          -dash    $Graphics(line,dash)  \
          -stipple $Graphics(fill,style) \
          -tags    {Ellipse obj}         \
       ]
       Message "Now hold and drag the mouse!"
  }
  bind .c <B1-Motion> {
      set x [.c canvasx %x $Graphics(grid,snap)]
      set y [.c canvasy %y $Graphics(grid,snap)]
      makeEllipse $x $y
  }
  bind .c <B1-ButtonRelease> {
      if ![info exists Ellipse(id)] {return}
      set utag [Utag assign $Ellipse(id)]
      History add [getObjectCommand $utag 1]
      Undo add ".c delete $utag"
      catch {unset Ellipse}
      Message "Your ellipse is done!"
  }
  Message "Click to get ellipse center"
}

proc makeEllipse {x y} {
  global Graphics Ellipse
  set x0 [lindex $Ellipse(center) 0]
  set y0 [lindex $Ellipse(center) 1]
  set a [expr abs($x-$x0)]
  set b [expr abs($y-$y0)]
  set coords [list [expr $x0-$a] [expr $y0-$b] [expr $x0+$a] [expr $y0+$b] ]
  catch {.c delete $Ellipse(id)}
  set Ellipse(id) [eval .c create oval $coords $Ellipse(options)]
}

################ LINE SECTION

proc startLine {type} {
  catch {unset Line}
  global Line Graphics

  if {$type==0} {
    set Graphics(shape) line
  } else {
    set Graphics(shape) spline
  }
  set Graphics(line,smooth) $type

  bind .c <Button-1> {
       Message "When you finish your line - Right click!"
       set x [.c canvasx %x $Graphics(grid,snap)]
       set y [.c canvasy %y $Graphics(grid,snap)]
       if [info exists Line(coords)] {
         newLinePoint create $x $y
         continue
       }
       set Line(options)  [list     \
           -width     $Graphics(line,width)     \
           -capstyle  $Graphics(line,capstyle)  \
           -joinstyle $Graphics(line,joinstyle) \
           -fill      $Graphics(line,color)     \
           -dash    $Graphics(line,dash)        \
           -stipple   $Graphics(line,style)     \
           -smooth    $Graphics(line,smooth)    \
           -tags      {Line obj}             \
       ]
       set Line(coords) "$x $y"
       newLinePoint create $x $y
  }

  bind .c <B1-Motion> {
      set x [.c canvasx %x $Graphics(grid,snap)]
      set y [.c canvasy %y $Graphics(grid,snap)]
      newLinePoint drag $x $y
  }
  bind .c <Button-3> {makeLine}
}

proc newLinePoint {mode x y} {
  global Line Graphics

  set n [llength $Line(coords)]

  if {$mode=="create"} {
    lappend Line(coords) $x $y
  } else {
    set Line(coords) [lreplace $Line(coords) [expr $n-2] end $x $y]
  }

  catch {.c delete $Line(tempLine)}
  set Line(tempLine) [eval .c create line $Line(coords) $Line(options)]
}

proc distance {x1 y1 x2 y2} {
  return [expr abs($x1-$x2) + abs($y1-$y2)]
}

proc groomLine {coords} {
  if {[llength $coords]<=3} {
     error "groomLine trouble! report bug!!"
     return
  }

  set x1 [lindex $coords 0]
  set y1 [lindex $coords 1]
  set x2 [lindex $coords 2]
  set y2 [lindex $coords 3]
  
  if {[distance $x1 $y1 $x2 $y2]<=3} {
    set coords [lreplace $coords 2 3]
  }

  set n [llength $coords]

  set x1 [lindex $coords [expr $n-4]]
  set y1 [lindex $coords [expr $n-3]]
  set x2 [lindex $coords [expr $n-2]]
  set y2 [lindex $coords [expr $n-1]]
  
  if {[distance $x1 $y1 $x2 $y2]<=3} {
    set coords [lreplace $coords [expr $n-4] [expr $n-3]]
  }

  lappend new_coords [lindex $coords 0] [lindex $coords 1]

  foreach {x y} [lrange $coords 2 end] {
     set m [llength $new_coords]
     set x_top [lindex $new_coords [expr $m-2]]
     set y_top [lindex $new_coords [expr $m-1]]
     set d [distance $x $x_top $y $y_top]
     if {$d==0 || $d>3} {
       lappend new_coords $x $y
     }
  }
  return $new_coords
}

proc makeLine {} {
  global Line Graphics
  catch {.c delete $Line(tempLine)}
 
  if {![info exists Line] || [llength $Line(coords)]<4} {
    catch {unset Line}
    return
  }

   set Line(coords) [groomLine $Line(coords)]

  set id [eval .c create line $Line(coords) $Line(options)]
  set utag [Utag assign $id]
  History add [getObjectCommand $utag 1]
  Undo add ".c delete $utag"
  unset Line
  Message "Line done!"
}

################ POLYGON SECTION

proc startPolygon {type} {
  catch {unset Polygon}
  global Polygon Graphics
  if {$type==0} {
    set Graphics(shape) polygon
  } else {
    set Graphics(shape) "closed spline"
  }
  set Graphics(line,smooth) $type

  bind .c <Button-1> {
       Message "When you finish your polygon - Right click!"
       set x [.c canvasx %x $Graphics(grid,snap)]
       set y [.c canvasy %y $Graphics(grid,snap)]
       if [info exists Polygon(coords)] {
         newPolygonPoint create $x $y
         continue
       }
       set Polygon(tempLine,options)  [list     \
           -width     $Graphics(line,width)     \
           -capstyle  $Graphics(line,capstyle)  \
           -joinstyle $Graphics(line,joinstyle) \
           -fill      $Graphics(line,color)     \
           -dash      $Graphics(line,dash)      \
           -stipple   $Graphics(line,style)     \
           -smooth    $Graphics(line,smooth)    \
           -tags      {Polygon obj}             \
       ]
       set Polygon(options)  [list \
           -width   $Graphics(line,width) \
           -outline $Graphics(line,color) \
           -fill    $Graphics(fill,color) \
           -dash    $Graphics(line,dash)  \
           -stipple $Graphics(fill,style) \
           -smooth  $Graphics(line,smooth)\
           -tags    {Polygon obj}         \
       ]
       set Polygon(coords) "$x $y"
       newPolygonPoint create $x $y
  }

  bind .c <B1-Motion> {
      set x [.c canvasx %x $Graphics(grid,snap)]
      set y [.c canvasy %y $Graphics(grid,snap)]
      newPolygonPoint drag $x $y
  }
#  bind .c <B1-ButtonRelease> {catch {unset Polygon(tempLine)}}
  bind .c <Button-3> {makePolygon}
#  bind .c <Double-Button-1> {makePolygon}
}

proc newPolygonPoint {mode x y} {
  global Polygon Graphics

  set n [llength $Polygon(coords)]

  if {$mode=="create"} {
    lappend Polygon(coords) $x $y
  } else {
    set Polygon(coords) [lreplace $Polygon(coords) [expr $n-2] end $x $y]
  }

  catch {.c delete $Polygon(tempLine)}
  set Polygon(tempLine) [eval .c create line $Polygon(coords) \
                               $Polygon(tempLine,options) ]
}

proc makePolygon {} {
  global Polygon Graphics
  catch {.c delete $Polygon(tempLine)}
 
  if {![info exists Polygon] || [llength $Polygon(coords)]<6} {
    catch {unset Polygon}
    return
  }

#  if {$Graphics(line,smooth)==0} {
#    set Polygon(coords) [removeDuplicates $Polygon(coords)]
#  }

  set id [eval .c create polygon $Polygon(coords) $Polygon(options)]
  set utag [Utag assign $id]
  History add [getObjectCommand $utag 1]
  Undo add ".c delete $utag"
  unset Polygon
  Message "Polygon done!"
}

################ SECTION:  ARC
proc arcMode {} {
  global Arc Graphics
  bind .c <Button-1> {
      set x [.c canvasx %x $Graphics(grid,snap)]
      set y [.c canvasy %y $Graphics(grid,snap)]
      startArc $x $y
  }
  bind .c <B1-Motion> {
      set x [.c canvasx %x $Graphics(grid,snap)]
      set y [.c canvasy %y $Graphics(grid,snap)]
      makeArc $x $y
  }
  bind .c <B1-ButtonRelease> {finishArc}
  Message "Click arc's start point"
}

proc finishArc {} {
  global Arc
  if {![info exists Arc(p3)]} {return}
  .c delete arcMark
  set Arc(id) [shape2spline $Arc(id)]
  set utag [Utag assign $Arc(id)]
  History add [getObjectCommand $utag 1]
  Undo add ".c delete $utag"
  unset Arc
  set z [expr round(rand()*7)]
  switch -exact $z {
      0 {Message "Not easy huh!? look at the source!"}
      1 {Message "Arc is done"}
      2 {Message "Wow! wow! wow! you're sitting on my favorite chair!"}
      3 {Message "There are two kinds of dirt"}
      4 {Message "Light dirt: attracted to dark objects"}
      5 {Message "Dark dirt: attracted to light objects"}
      6 {Message "You can edit lines and polygons! Try Edit/Reshape."}
      7 {Message "Use Zoom to fine tune your drawing!"}
  }
}

proc startArc {x y} {
  global Arc
  if {![info exists Arc(p1)]}  {
    set Arc(p1) "$x $y"
    .c create oval [expr $x-3] [expr $y-3] [expr $x+3] [expr $y+3] \
                   -fill red -tags {arcMark obj}
    Message "Click arc's last point"
  } elseif {![info exists Arc(p2)]} {
    set Arc(p2) "$x $y"
    if {"$Arc(p2)"=="$Arc(p1)"} {
      unset Arc(p2)
      Message "End points must differ!"
      return
    }
    .c create oval [expr $x-3] [expr $y-3] [expr $x+3] [expr $y+3] \
                   -fill red -tags {arcMark obj}
    Message "Click arc's middle point"
  } else {
    set Arc(p3) "$x $y"
    if {"$Arc(p3)"=="$Arc(p1)" || "$Arc(p3)"=="$Arc(p2)"} {
      unset Arc(p3)
      Message "Midpoint must be dif from endpoint"
      return
    }
    makeArc $x $y
  }
}

proc getArcConfig {} {
   global Arc Graphics
   set PI 3.14159265359
   
   set x1 [lindex $Arc(p1) 0]
   set y1 [lindex $Arc(p1) 1]
   set x2 [lindex $Arc(p2) 0]
   set y2 [lindex $Arc(p2) 1]
   set x3 [lindex $Arc(p3) 0]
   set y3 [lindex $Arc(p3) 1]
   
     if {$x1*($y2-$y3) + $x2*($y3-$y1) + $x3*($y1-$y2) == 0} {
         set Arc(radius) infinity
         return
     }
   # (u1,v1) is the midpoint of (x1,y1) (x2,y2)
   # (u2,v2) is the midpoint of (x2,y2) (x3,y3)
   set u1 [expr ($x1+$x2)/2.0]
   set u2 [expr ($x2+$x3)/2.0]
   set v1 [expr ($y1+$y2)/2.0]
   set v2 [expr ($y2+$y3)/2.0]
   set b1 [expr ($y2-$y1)*$v1 + ($x2-$x1)*$u1]
   set b2 [expr ($y3-$y2)*$v2 + ($x3-$x2)*$u2]
   
   set delta [expr ($x2-$x1)*($y3-$y2) - ($x3-$x2)*($y2-$y1)]
   set x0 [expr ($b1*($y3-$y2) - $b2*($y2-$y1))/$delta]
   set y0 [expr (($x2-$x1)*$b2 - ($x3-$x2)*$b1)/$delta]
   #set Arc(center) "$x0 $y0"
   
#   set tmp    [expr sqrt(pow($x1-$x0,2)+pow($y1-$y0,2))]
#   set radius  [expr (int($tmp)/$Graphics(grid,snap))*$Graphics(grid,snap)]
   set radius [expr sqrt(pow($x1-$x0,2)+pow($y1-$y0,2))]
   set Arc(box) [list [expr $x0-$radius] [expr $y0-$radius] \
                      [expr $x0+$radius] [expr $y0+$radius]]
   
   set ang1 [expr -atan2($y1-$y0,$x1-$x0)*(180/$PI)]
   set ang2 [expr -atan2($y2-$y0,$x2-$x0)*(180/$PI)]
   set ang3 [expr -atan2($y3-$y0,$x3-$x0)*(180/$PI)]
   # we add minus to atan2 to convert to the strange coordinate system
   # of X!!!!
   # Now we compute the start and the extent of the arc
   foreach a {ang1 ang2 ang3} {
     if {[subst $$a]<0} {set $a [expr 360+[subst $$a]]}
   }
   
   if {$ang1<$ang2} {
     set Arc(start) $ang1
     set Arc(end) $ang2
   } else {
     set Arc(start) $ang2
     set Arc(end) $ang1
   }
   
   if {$Arc(start) < $ang3 && $ang3 < $Arc(end)} {
     set Arc(extent) [expr $Arc(end)-$Arc(start)]
   } else {
     set Arc(extent) [expr $Arc(end) - $Arc(start) - 360]
   }
}

proc makeArc {x y} {
  global Graphics
  global Arc

  if ![info exists Arc(p3)] {
    return
  }

  set Arc(p3) "$x $y"
  
  getArcConfig

  catch {.c delete $Arc(id)}
  set Arc(id) [eval .c create arc $Arc(box) \
                  { -start   $Arc(start) \
                    -extent  $Arc(extent) \
                    -style   $Graphics(shape) \
                    -width   $Graphics(line,width) \
                    -outline $Graphics(line,color) \
                    -outlinestipple $Graphics(line,style) \
                    -fill    $Graphics(fill,color) \
                    -dash    $Graphics(line,dash)  \
                    -stipple $Graphics(fill,style) \
                    -tags "arc $Graphics(shape) obj"\
                   }
     ]
}

###### FREE HAND SECTION
proc freeHand {} {
  global freeHand Graphics
  set Graphics(shape) "Free Hand"
  bind .c <Button-1> {
      lappend freeHand(coords) [.c canvasx %x] [.c canvasy %y]
      set freeHand(tmp_options)  [list \
             -width $Graphics(line,width) \
             -fill  $Graphics(line,color) \
             -stipple $Graphics(line,style) \
             -joinstyle $Graphics(line,joinstyle) \
             -capstyle $Graphics(line,capstyle) \
             -tags {freeHandTemp}\
      ]
      set freeHand(options)  [list \
             -width $Graphics(line,width) \
             -fill  $Graphics(line,color) \
             -dash  $Graphics(line,dash)  \
             -stipple $Graphics(line,style) \
             -joinstyle $Graphics(line,joinstyle) \
             -capstyle $Graphics(line,capstyle) \
             -tags {freeHand obj}\
      ]
  }

  bind .c <B1-Motion> {
        set x [.c canvasx %x]
        set y [.c canvasy %y]
        set n [llength $freeHand(coords)]
        set lastPoint [lrange $freeHand(coords) [expr $n-2] end]
        eval .c create line $lastPoint $x $y $freeHand(tmp_options)
        lappend freeHand(coords) $x $y
  }

  bind .c <B1-ButtonRelease> {
     .c delete freeHandTemp
      set id [eval .c create line $freeHand(coords) $freeHand(options)]
      set utag [Utag assign $id]
      History add [getObjectCommand $utag 1]
      Undo add ".c delete $utag"
      catch {unset freeHand}
  }
  Message "Never scare your users!"
}

###### IMAGE SECTION
proc Image {type} {
  global Image Graphics
  set Graphics(shape) image
#  catch {unset Image}
  set Image(type) $type

  switch $Image(type) {
      gif {
           set Image(types) {
              {{GIF file} {.gif} }
              {{All files} * }
           }
           set default_ext ".gif"
      }
      jpg {
           set Image(types) {
              {{JPEG file} {.jpg} }
              {{All files} * }
           }
           set default_ext ".jpg"
      }
      bmp {
           set Image(types) {
              {{BMP file} {.bmp} }
              {{All files} * }
           }
           set default_ext ".bmp"
      }
      ppm {
           set Image(types) {
              {{PPM file} {.ppm} }
              {{All files} * }
           }
           set default_ext ".ppm"
      }
      pgm {
           set Image(types) {
              {{PGM file} {.pgm} }
              {{All files} * }
           }
           set default_ext ".pgm"
      }
      png {
           set Image(types) {
              {{PNG file} {.png} }
              {{All files} * }
           }
           set default_ext ".png"
      }
      xpm {
           set Image(types) {
              {{XPM file} {.xpm} }
              {{All files} * }
           }
           set default_ext ".xpm"
      }
      tif {
           set Image(types) {
              {{TIFF file} {.tif} }
              {{All files} * }
           }
           set default_ext ".tif"
      }
      ps {
           set Image(types) {
              {{PS file} {.ps} }
              {{EPS file} {.eps} }
              {{All files} * }
           }
           set default_ext ".ps"
      }
      bitmap {
           set Image(types) {
              {{XBM file} {.bmp} }
              {{XBM file} {.xbm} }
              {{All files} * }
           }
           set default_ext ".bmp"
      }
      default {
         error "Unsupported image type"
      }
  }

  cd $Image(wd)
  set Image(file) [tk_getOpenFile -title "Image file" \
                -filetypes $Image(types) \
                -defaultextension $default_ext ]
  if {$Image(file)==""} {return}

  set Image(wd) [file dirname $Image(file)]

  Message "Click to insert image in canvas"

  bind .c <Button-1> {
      set x [.c canvasx %x $Graphics(grid,snap)]
      set y [.c canvasy %y $Graphics(grid,snap)]
      incr Image(ctr)
      set Image(name) Tkpaint_image$Image(ctr)

      switch $Image(type) {
         ppm -
         pgm -
         ps  -
         jpg -
         bmp -
         xpm -
         png -
         tif -
         gif {
             set imcmd \
                 [list image create photo $Image(name) -file $Image(file)]
             set v [catch {
                eval $imcmd
                set id [.c create image $x $y \
                     -image $Image(name) -anchor nw -tags {image photo obj}]
                     } err]
         }
         bitmap {
             set imcmd \
                 [list image create bitmap $Image(name) -file $Image(file)]
             set v [catch {
                eval $imcmd
                set id [.c create bitmap $x $y \
                     -bitmap @$Image(file) -anchor nw -tags {image bitmap obj}]
                     } err]
         }
      }
      if {$v!=0} {
         incr Image(ctr) -1
         tk_messageBox -type ok \
                -message "Problem with image file or the Img package \
                          not installed:\n $err\n \
                          look at the readme file for details" \
                -icon warning \
                -title "TkPaint: $err" \
                -default ok
         return
       }
      lappend Image(hist) $imcmd
      set Image(utag) [Utag assign $id]
      .c addtag spline withtag $Image(utag)
      History add [getObjectCommand $Image(utag) 1]
      Undo add ".c delete $Image(utag)"
      bind .c <Button-1> {}
  }
}


########## FILL COLOR AND OUTLINE COLOR

proc chooseFillColor {} {
   global Graphics
   if {$Graphics(fill,color)==""} {
     set initColor gray75
   } else {
     set initColor $Graphics(fill,color)
   }
   set color [tk_chooseColor -initialcolor $initColor \
                             -title "Choose Fill Color"]
   if {$color==""} {return}
   set Graphics(fill,color) $color
}

proc chooseOutlineColor {} {
   global Graphics
   if {$Graphics(line,color)==""} {
     set initColor white
   } else {
     set initColor $Graphics(line,color)
   }
   set color [tk_chooseColor -initialcolor $initColor \
                             -title "Choose Outline Color"]
   if {$color==""} {return}
   set Graphics(line,color) $color
}

############## EDIT SECTION:  DELETE, MOVE, COPY, RAISE, LOWER, 

# UTILITY PROCEDURES TO HELP US DO MOVE, DELETE, RAISE, LOWER, AND COPY
# OPERATIONS MORE NEAT.
#
# THE FOLLOWING PROCEDURE RETURNS THE UTAG of THE CLOSEST ITEM WITH TAG "tag"
# THAT OVERLAP WITH THE AREA (x-r,y-r) (x+r,y+r) IN THE CANVAS .c.
# (CLOSEST ALSO MEANS AS HIGH AS POSSIBLE IN THE DISPLAY LIST)
# THE PROCEDURE RETURNS AN EMPTY STRING IF IT FINDS NO ITEM WITH THE
# SPECIFIED REQUIREMNETS.

proc getNearestUtag {x y r tag} {
  set nearObjects [.c find overlapping [expr $x-$r] [expr $y-$r] \
                                       [expr $x+$r] [expr $y+$r]]
  if {[llength $nearObjects]==0} {
    return ""
  }
  set n [expr [llength $nearObjects]-1]
  for {set i $n} {$i>=0} {incr i -1} {
     set id [lindex $nearObjects $i]
     if {[lsearch [.c gettags $id] $tag]>=0} {
       return [Utag find $id]
     }
  }
}

# THE NEXT PROC ACCEPTS AN OBJECT UTAG AND RETURNS A COMMAND TO CREATE AN
# IDENTICAL COPY OF THIS OBJECT.
# THE "flag" ARGUMENT IS AN INTEGER VALUE THAT INDICATES IF WE WANT TO KEEP
# THE ORIGINAL UTAG (1), DELETE IT (0), KEEP THE "Selected" tag (2).
# NEW: if flag==2 then keep the "Selected" tag

proc getObjectOptions {utagORid flag} {
  foreach conf [.c itemconfigure $utagORid] {
    set opt [lindex $conf 0]
    if {$opt=="-tags"} {continue}
    set default [lindex $conf 3]
    set value [lindex $conf 4]
    # This is probably a bug work around (bezier? should be boolean!)
    if {$opt=="-smooth" && $value=="bezier"} {
       set value 1
    }
    if {[string compare $default $value] != 0} {
      lappend options [lindex $conf 0] $value
    }
  }
  set tags [.c gettags $utagORid]
  if {[lsearch $tags current]>=0} {
    regsub current $tags "" tags
  }
  if {[lsearch $tags Selected]>=0 && $flag!=2} {
    regsub Selected $tags "" tags
  }
  # next, we strip out the utag (if exists) if flag=0
  if {$flag==0} {
    regsub {utag[0-9]+} $tags "" tags
  }
  lappend options -tags $tags
  return $options
}

#LOOK AT THE "getObjectOptions" proc for an explanation about the "flag" arg.
proc getObjectCommand {utagORid flag} {
  lappend command .c create
  lappend command [.c type $utagORid]
  eval lappend command [.c coords $utagORid]
  eval lappend command [getObjectOptions $utagORid $flag]
  return $command
}

proc getObjectAbove {utag} {
   set i $utag
   set previ ""
   while { $i != "" } {
     set i [.c find above $i]
     if {$i==""||$i=="$previ"} {return ""}
     set previ $i
     set tags [.c gettags $i]
     if {[lsearch $tags obj] >= 0} {
       return [Utag find $i]
     }
   }
   return ""
}

proc getObjectBelow {utag} {
   set i $utag
   set previ ""
   while { $i != "" } {
     set i [.c find below $i]
     if {$i==""||$i=="$previ"} {return ""}
     set previ $i
     set tags [.c gettags $i]
     if {[lsearch $tags obj] >= 0} {
       return [Utag find $i]
     }
   }
   return ""
}

proc deleteMode {} {
  bind .c <Button-1>  "itemDelete %x %y"
  bind .c <B1-Motion> "itemDelete %x %y"
  Message "Click on the object you want to delete"
}

proc itemDelete {x y} {
  set x [.c canvasx $x]
  set y [.c canvasy $y]
  set utag [getNearestUtag $x $y 2 obj]
  if {$utag==""} {
      Message "No object under cursor!"
      return
  }
  set below [getObjectBelow $utag]
  set above [getObjectAbove $utag]
  set undo [getObjectCommand $utag 1]\;
  if { $below != "" } {
    append undo ".c raise $utag $below\;"
  } elseif { $above != "" } {
    append undo ".c lower $utag $above\;"
  }
  set cmd ".c delete $utag"
  History add $cmd
  Undo add $undo
  eval $cmd
  Message "Object $utag deleted"
}

proc raiseMode {} {
  bind .c <Button-1> {itemRaise [.c canvasx %x] [.c canvasy %y]}
  Message "Click on the object you want to raise"
}

proc itemRaise {x y} {
  set utag [getNearestUtag $x $y 2 obj]
  if {$utag==""} {
       Message "No object under the cursor!"
       return
  }
  set above [getObjectAbove $utag]
  if {$above != ""} {
    History add ".c raise $utag"
    Undo add ".c lower $utag $above"
  }
  .c raise $utag
  Message "Object $utag raised"
}

proc lowerMode {} {
  bind .c <Button-1> {itemLower [.c canvasx %x] [.c canvasy %y]}
  Message "Click on the object you want to lower"
}

proc itemLower {x y} {
  set utag [getNearestUtag $x $y 2 obj]
  if {$utag==""} {
       Message "No object under the cursor!"
       return
  }
  set below [getObjectBelow $utag]
  if {$below != ""} {
    History add ".c lower $utag"
    Undo add ".c raise $utag $below"
  }
  .c lower $utag
  Message "Object $utag lowered"
}

proc moveMode {} {
  bind .c <Button-1> {
      set x [.c canvasx %x $Graphics(grid,snap)]
      set y [.c canvasy %y $Graphics(grid,snap)]
      Move begin $x $y
  }
  bind .c <B1-Motion> {
      set x [.c canvasx %x $Graphics(grid,snap)]
      set y [.c canvasy %y $Graphics(grid,snap)]
      Move drag $x $y
  }
  bind .c <B1-ButtonRelease> {
      if {$Move(utag) != ""} {
        set a [expr $Move(lastX)-$Move(firstX)]
        set b [expr $Move(lastY)-$Move(firstY)]
        set cmd  "[list .c move $Move(utag) $a $b]\;"
        set undo "[list .c move $Move(utag) [expr -$a] [expr -$b]]\;"
        History add $cmd
        Undo add $undo
      }
      unset Move
      Message "Bug reports: samy@netanya.ac.il"
  }
  Message "Click on the object and hold mouse"
}

proc Move {mode x y} {
    global Move
    switch -exact -- $mode {
       begin {
          set Move(utag) [getNearestUtag $x $y 2 obj]
          if {$Move(utag)==""} {
               Message "There is no object to move under the cursor!"
               return
          }
          set Move(firstX) $x
          set Move(firstY) $y
          set Move(lastX) $x
          set Move(lastY) $y
          Message "Now drag the object to new location"
       }
       drag  {
          if {$Move(utag)==""} {return}
          .c move $Move(utag) [expr $x-$Move(lastX)] [expr $y-$Move(lastY)]
          set Move(lastX) $x
          set Move(lastY) $y
        }
    }
}

# copying of items.

proc copyMode {} {
  bind .c <Button-1> {
      set x [.c canvasx %x $Graphics(grid,snap)]
      set y [.c canvasy %y $Graphics(grid,snap)]
      itemStartCopy $x $y
  }
  bind .c <B1-Motion> {
      set x [.c canvasx %x $Graphics(grid,snap)]
      set y [.c canvasy %y $Graphics(grid,snap)]
      itemCopy $x $y
  }
  bind .c <B1-ButtonRelease> {
      if {$Copy(utag) == ""} {
        catch {unset Copy}
        return
      }
      set cmd "[getObjectCommand $Copy(utag) 1] \;"
      append cmd ".c raise $Copy(utag) $Copy(origUtag) \;"
      History add $cmd
      Undo add ".c delete $Copy(utag)"
      if {[lsearch [.c gettags $Copy(utag)] text]>=0} {
        set TextInfo($Copy(utag)) [.c itemcget $Copy(utag) -text]
      }
      unset Copy
  }
  Message "Click on the object and hold"
}

proc itemStartCopy {x y} {
  global Copy

  set utag [getNearestUtag $x $y 2 obj]
  if {$utag==""} {
       set Copy(utag) ""
       Message "No object to copy under the cursor!"
       return
  }
  set Copy(lastX) $x
  set Copy(lastY) $y
  set Copy(origUtag) $utag

  set Copy(utag) [Utag assign [eval [getObjectCommand $utag 0]]]
  .c raise $Copy(utag) $utag
  Message "Now drag the copied object to a new location"
}

proc itemCopy {x y} {
    global Copy
    if {$Copy(utag)==""} {return}
    .c move $Copy(utag) [expr $x-$Copy(lastX)] [expr $y-$Copy(lastY)]
    set Copy(lastX) $x
    set Copy(lastY) $y
}

proc deleteAll {} {
  .c delete graybox
  set objects [.c find withtag obj]
  if {[llength $objects]==0} {return}
  foreach id $objects {
     append undo [getObjectCommand [Utag find $id] 1]\;
  }
  set cmd ".c delete graybox obj"
  History add $cmd
  Undo add $undo
  .c delete obj
  Message "If you are sorry you did it click undo!"
}

# RESHAPING POLYGONS AND LINES:

proc reshapeMode {} {
  global Reshape

  catch {unset Reshape}

  bind .c <Button-1> {
      set x [.c canvasx %x]
      set y [.c canvasy %y]
      set Reshape(utag) [getNearestUtag $x $y 2 obj]
  }

  bind .c <B1-ButtonRelease> {
      if {$Reshape(utag)==""} {
          Message "No object under cursor!"
          return
      }
      set tags [.c gettags $Reshape(utag)]
      set isPoly [lsearch $tags Polygon]
      set isLine [lsearch $tags Line]
      if {$isPoly==-1 && $isLine==-1} {
           Message "Object under cursor is not a polygon/line!"
           unset Reshape(utag)
           return
      }

      set Reshape(state) dragVertex
      setReshapeHandles

      bind .c <Any-B1-ButtonRelease> {reshapeButtonRelease}

      bind .c <Button-1> {}
  }

  bind .c <Button-3> {
     .c delete reshapeHandle
     catch {unset Reshape}
     bind .c <Any-Button-1> {}
     bind .c <Any-B1-ButtonRelease> {}
     .mbar.edit.menu invoke "Reshape polygon/line"
  }

  Message "Now click on a line or a polygon object"
}

proc setReshapeHandles {} {
  global Reshape
  Message "You may drag or Ctrl-click to add vertex"
  .c delete reshapeHandle

  set Reshape(type) [.c type $Reshape(utag)]
  set Reshape(options) [getObjectOptions $Reshape(utag) 1]
  set r [expr [.c itemcget $Reshape(utag) -width]+4]
  set i 1
  foreach {x y} [.c coords $Reshape(utag)] {
     set Reshape($i,x) $x
     set Reshape($i,y) $y
     set id [.c create rectangle \
                 [expr $x-$r] [expr $y-$r] [expr $x+$r] [expr $y+$r] \
                 -outline {} \
                 -fill black \
                 -stipple gray25 \
                 -tags reshapeHandle]
     set Reshape($i,id) $id
     .c bind $id <B1-Motion> "reshapeMotion $i %x %y"
     .c bind $id <Control-Button-1> "addVertex $i"
     .c bind $id <Alt-Button-1> "deleteVertex $i"
     .c bind $id <Alt-B1-Motion> {break}
     incr i
  }

  .c bind reshapeHandle <Button-1> {
     if {$Reshape(state)=="addVertex" || $Reshape(state)=="deleteVertex"} {
       return
     }
     set Reshape(undo) ".c delete $Reshape(utag) \; "
     append Reshape(undo) [getObjectCommand $Reshape(utag) 1]\;
     set above [getObjectAbove $Reshape(utag)]
     if {$above != ""} {
         append Reshape(undo) "\; .c lower $Reshape(utag) $above"
     }
  }

  set Reshape(n) [expr $i-1]
  .c raise reshapeHandle
}

proc reshapeButtonRelease {} {
  global Reshape

  if ![info exists Reshape(undo)] {
       return
  }

  set cmd ".c delete $Reshape(utag) \; "
  append cmd [getObjectCommand $Reshape(utag) 1]\;
  set above [getObjectAbove $Reshape(utag)]
  if {$above != ""} {
      append cmd "\; .c lower $Reshape(utag) $above"
  }
  History add $cmd
  Undo add $Reshape(undo)
  unset Reshape(undo)
  set Reshape(state) dragVertex
  set z [expr round(rand()*7)]
  switch -exact $z {
      0 {Message "The cursor has to be on the gray boxes!"}
      1 {Message "To stop reshaping current object: Right click"}
      2 {Message "After a right click you may select a new object!"}
      3 {Message "To add vertex: control-click on a gray box!"}
      4 {Message "To delete vertex: Alt-click on a gray box!"}
      5 {Message "You can add as many vertices as you wish!"}
      6 {Message "You can also delete vertices! Alt-click!"}
      7 {Message "A little humor here and there never hurts"}
  }
}

proc reshapeMotion {i x y} {
   global Reshape Graphics
   set x [.c canvasx $x $Graphics(grid,snap)]
   set y [.c canvasy $y $Graphics(grid,snap)]
   set dx [expr $x-$Reshape($i,x)]
   set dy [expr $y-$Reshape($i,y)]
   .c move $Reshape($i,id) $dx $dy
   set Reshape($i,x) $x
   set Reshape($i,y) $y
   set coords {}
   for {set j 1} {$j<=$Reshape(n)} {incr j} {
        lappend coords $Reshape($j,x) $Reshape($j,y)
   }
   set above [getObjectAbove $Reshape(utag)]
   .c delete $Reshape(utag)
   eval .c create $Reshape(type) $coords $Reshape(options)
   if {$above != ""} {
       .c lower $Reshape(utag) $above
   }
   .c raise reshapeHandle
}

proc addVertex {i} {
   global Reshape

   set Reshape(state) addVertex
   set Reshape(undo) ".c delete $Reshape(utag) \; "
   append Reshape(undo) [getObjectCommand $Reshape(utag) 1]\;
   set above [getObjectAbove $Reshape(utag)]
   if {$above != ""} {
       append Reshape(undo) "\; .c lower $Reshape(utag) $above"
   }
 
   incr Reshape(n)
   for {set j $Reshape(n)} {$j>=[expr $i+2]} {incr j -1} {
      set k [expr $j-1]
      set Reshape($j,x) $Reshape($k,x)
      set Reshape($j,y) $Reshape($k,y)
   }
   set x $Reshape($i,x)
   set y $Reshape($i,y)
   set k [expr $i+1]
   set Reshape($k,x) [expr $x+10]
   set Reshape($k,y) [expr $y+10]
   set coords {}
   for {set j 1} {$j<=$Reshape(n)} {incr j} {
        lappend coords $Reshape($j,x) $Reshape($j,y)
   }
   set above [getObjectAbove $Reshape(utag)]
   .c delete $Reshape(utag)
   eval .c create $Reshape(type) $coords $Reshape(options)
   if {$above != ""} {
       .c lower $Reshape(utag) $above
   }
   setReshapeHandles
}

proc deleteVertex {i} {
   global Reshape

   set Reshape(state) deleteVertex

   if {$Reshape(type)=="line" && $Reshape(n)==2} {
     Message "Cannot delete a vertex from a Line with 2 vertices!"
     catch {unset Reshape(undo)}
     return
   }

   if {$Reshape(type)=="polygon" && $Reshape(n)==3} {
     Message "Cannot delete a vertex from a polygon with 3 vertices!"
     catch {unset Reshape(undo)}
     return
   }

   set Reshape(undo) ".c delete $Reshape(utag) \; "
   append Reshape(undo) [getObjectCommand $Reshape(utag) 1]\;
   set above [getObjectAbove $Reshape(utag)]
   if {$above != ""} {
       append Reshape(undo) "\; .c lower $Reshape(utag) $above"
   }

   set n $Reshape(n)
   incr Reshape(n) -1
   for {set j $i} {$j<=$Reshape(n)} {incr j} {
      set k [expr $j+1]
      set Reshape($j,x) $Reshape($k,x)
      set Reshape($j,y) $Reshape($k,y)
   }
   unset Reshape($n,x) Reshape($n,y)
   set coords {}
   for {set j 1} {$j<=$Reshape(n)} {incr j} {
        lappend coords $Reshape($j,x) $Reshape($j,y)
   }
   set above [getObjectAbove $Reshape(utag)]
   .c delete $Reshape(utag)
   eval .c create $Reshape(type) $coords $Reshape(options)
   if {$above != ""} {
       .c lower $Reshape(utag) $above
   }
   setReshapeHandles
}

# BITMAPS BACKGROUND AND FOREGROUND COLORS

proc bitmapFgColor {} {
  Message "Click on a bitmap to change fg color"
  bind .c <Button-1> { 
        set id [.c find withtag current]
        if {$id==""} {
          Message "No object under cursor!"
          return
        }
        if {[lsearch [.c gettags $id] bitmap]==-1} {
          Message "Object under cursor is not a bitmap"
          return
        }
        set old_fg [.c itemcget $id -foreground]
        set fg [tk_chooseColor -title "Choose bitmap foreground color"]
        if {$fg==""} {return}
        set utag [Utag find $id]
        set cmd [list .c itemconfigure $utag -foreground $fg]
        set undo [list .c itemconfigure $utag -foreground $old_fg]
        History add $cmd
        Undo add $undo
        eval $cmd
  }
}

proc bitmapBgColor {} {
  Message "Click on a bitmap to change bg color"
  bind .c <Button-1> {
        set id [.c find withtag current]
        if {$id==""} {
          Message "No object under cursor!"
          return
        }
        if {[lsearch [.c gettags $id] bitmap]==-1} {
          Message "Object under cursor is not a bitmap"
          return
        }
        set old_bg [.c itemcget $id -background]
        set bg [tk_chooseColor -title "Choose bitmap background color"]
        if {$bg==""} {return}
        set utag [Utag find $id]
        set cmd [list .c itemconfigure $utag -background $bg]
        set undo [list .c itemconfigure $utag -background $old_bg]
        History add $cmd
        Undo add $undo
        eval $cmd
  }
}


# TAKING CARE OF CANVAS BACKGROUND COLOR AND STIPPLE:

proc chooseBackgroudColor {} {
   global Canv
   set undo ".c config -bg $Canv(bg)"
   set color [tk_chooseColor -initialcolor $Canv(bg) \
                             -title "Choose Canvas Background Color"]
   if {$color==""} {return}
   set Canv(bg) $color
   .c config -bg $Canv(bg)
   set cmd [list .c config -bg $Canv(bg)]
   History add $cmd
   Undo add $undo
}


############## GROUP SECTION:
# DELETE, MOVE, COPY, RAISE, LOWER, ...
# OPERATIONS ON GROUPS OF OBJECTS
# HERE WE DEFINE PROCEDURES FOR SELECTING A GROUP OF OBJECTS,
# DELETING, COPYING, RESIZING, ... A GROUP OF OBJECTS


proc selectGroupMode {} {
  global selectBox
  .c delete graybox
  .c dtag obj Selected
  .c configure -cursor ""
  bind .c <Button-1> {
        catch {unset selectBox}
        .c delete graybox
        .c dtag obj Selected
        set selectBox(x1) [.c canvasx %x]
        set selectBox(y1) [.c canvasy %y]
        set selectBox(x2) [.c canvasx %x]
        set selectBox(y2) [.c canvasy %y]
  }
  bind .c <B1-Motion> {drawSelectionBox [.c canvasx %x] [.c canvasy %y]}
  bind .c <B1-ButtonRelease> {
      setBoundingBox
      setEditGroupMode
  }
  Message "Draw a rectangle arround the objects you want to edit"
}

proc selectAll {} {
  global Graphics selectBox
  set Graphics(mode) "Group Mode"
  selectGroupMode

  .c addtag Selected withtag obj
  set bbox [.c bbox Selected]
  set selectBox(x1) [lindex $bbox 0]
  set selectBox(y1) [lindex $bbox 1]
  set selectBox(x2) [lindex $bbox 2]
  set selectBox(y2) [lindex $bbox 3]

  if {[llength [.c find withtag Selected]]==0} {
    .c delete selectBox
    unset selectBox
    return
  }
  .c delete selectBox
  unset selectBox
  drawBoundingBox
  setEditGroupMode
  Message "Use the mouse to drag or resize the group"
}

proc select1object {} {
  global Graphics
  set Graphics(mode) "Group Mode"

  bind .c <Button-1> {
     unselectGroup
     set x [.c canvasx %x]
     set y [.c canvasy %y]
     set utag [getNearestUtag $x $y 2 obj]
     if {$utag==""} {
       Message "No object under cursor. Try again."
       return
     }
     .c addtag Selected withtag $utag
     set bbox [.c bbox Selected]
  }
  bind .c <B1-ButtonRelease> {
     if {[llength [.c find withtag Selected]]==0} {return}
     drawBoundingBox
     setEditGroupMode
  }
  Message "Use mouse and \"Group\"(!) menu to act on the object"
}

proc unselectGroup {} {
  global selectBox
  catch {unset selectBox}
  .c delete graybox
  .c dtag obj Selected
  .c configure -cursor ""
}

proc drawSelectionBox {x y} {
  global selectBox
  set selectBox(x2) $x
  set selectBox(y2) $y
  catch {.c delete $selectBox(id)}
  set selectBox(id) [.c create rectangle $selectBox(x1) $selectBox(y1) \
                                        $selectBox(x2) $selectBox(y2) \
                -width 1 \
                -tags selectBox ]
}

proc drawGrayBox {x1 y1 x2 y2 col stip tag} {
  return [.c create rectangle $x1 $y1 $x2 $y2 \
                -outline {} \
                -fill $col \
                -stipple $stip \
                -tags "graybox $tag"]
#  .c raise gridObject
}

proc setBoundingBox {} {
  global selectBox

  set enclosed [.c find enclosed $selectBox(x1) $selectBox(y1) \
                              $selectBox(x2) $selectBox(y2)]

  set group {}
  foreach id $enclosed {
     if {[lsearch [.c itemcget $id -tags] obj]<0} {continue}
     lappend group $id
  }
  .c delete selectBox
  unset selectBox

  if {[llength $group]==0} {
    Message "No objects selected. Try again."
    return
  }

  foreach id $group {
     .c addtag Selected withtag $id
  }
  drawBoundingBox
}

proc drawBoundingBox {} {
  global BBox

  .c delete graybox
  set bbox [.c bbox Selected]
  set BBox(x1) [lindex $bbox 0]
  set BBox(y1) [lindex $bbox 1]
  set BBox(x2) [lindex $bbox 2]
  set BBox(y2) [lindex $bbox 3]

  set x1 $BBox(x1)
  set y1 $BBox(y1)
  set x2 $BBox(x2)
  set y2 $BBox(y2)
  drawGrayBox $x1 $y1 $x2 $y2 gray60 gray12 mainBBox
  
# Now we create the 8 small rectangles (handles) around the main BBox.
# Naming the boxes is based on:
#    NW   North NE
#           *
#    West * * * East
#           *
#    SW   South SE
  set a 14
  set midx [expr ($x1+$x2-$a)/2]
  set midy [expr ($y1+$y2-$a)/2]
  foreach {X1 Y1 X2 Y2 tag} "
      [expr $x1-$a] [expr $y1-$a] $x1 $y1       nwHandle
      $x2 $y2 [expr $x2+$a] [expr $y2+$a]       seHandle
      $x2 $y1 [expr $x2+$a] [expr $y1-$a]       neHandle
      [expr $x1-$a] [expr $y2+$a] $x1 $y2       swHandle
      $midx $y1 [expr $midx+$a] [expr $y1-$a]   nHandle
      $midx [expr $y2+$a] [expr $midx+$a] $y2   sHandle
      [expr $x1-$a] $midy $x1 [expr $midy+$a]   wHandle
      $x2 $midy [expr $x2+$a] [expr $midy+$a]   eHandle
  " {
     drawGrayBox $X1 $Y1 $X2 $Y2 black gray50 $tag
  }
  .c raise graybox
  .c raise mainBBox
#  .c raise gridObject
  Message "Use mouse to drag, resize. More acts click \"Group\"."
}

# LOOK AT THE getObjectOptions proc for an explanation about the "flag" arg.
# FIXME
proc getGroupCommand {flag} {
   set group [.c find withtag Selected]
   if {[llength $group]==0} {
       Message "BUG! getGroupCommand: group is empty!! report"
       return
   }
   foreach id $group {
      set utag [Utag find $id]
      append cmd ".c delete $utag\;"
      append cmd [getObjectCommand $utag $flag]\;
   }
   set below [getObjectBelow Selected]
   set above [getObjectAbove Selected]
   set n [llength $group]
   if { $below != "" } {
     set first [Utag find [lindex $group 0]]
     append cmd ".c raise $first $below\;"
     
     for {set i 0} {$i<[expr $n-1]} {incr i} {
        set current [Utag find [lindex $group $i]]
        set next [Utag find [lindex $group [expr $i+1]]]
        append cmd ".c raise $next $current\;"
     }
   } 

   if { $above != "" } {
     set last [Utag find [lindex $group [expr $n-1]]]
     append cmd ".c lower $last $above\;"
     for {set i [expr $n-1]} {$i>0} {incr i -1} {
        set current [Utag find [lindex $group $i]]
        set previous [Utag find [lindex $group [expr $i-1]]]
        append cmd ".c lower $previous $current\;"
     }
   }

   append cmd ".c delete graybox\;"
   append cmd ".c delete rotateLine rotateBox rotateText rotateTextBox\;"
   return $cmd
}

proc setEditGroupMode {} {
   set group [.c find withtag Selected]
   if {0==[llength $group]} {return}
   global BBox Graphics lastX lastY
   set BBox(action) none

   foreach {tag curs side} {
      nHandle   top_side             n
      sHandle   bottom_side          s
      wHandle   left_side            w
      eHandle   right_side           e
      nwHandle  top_left_corner      nw
      neHandle  top_right_corner     ne
      swHandle  bottom_left_corner   sw
      seHandle  bottom_right_corner  se
   } {
       .c bind $tag <Enter> "%W configure -cursor $curs"

       .c bind $tag <Leave> {
            %W configure -cursor ""
        }

       .c bind $tag <Button-1> "HandlesButton1-bind $side $curs"
   }

   .c bind mainBBox <Enter> {%W configure -cursor fleur}
   .c bind mainBBox <Leave> {%W configure -cursor ""}
   .c bind mainBBox <Button-1> {
           set BBox(action) move
           %W configure -cursor fleur
           set BBox(undo) [getGroupCommand 1]
   }
   .c bind mainBBox <B1-ButtonRelease> {catch {unset lastX lastY}}

   bind .c <Button-1> {
      set lastX [.c canvasx %x $Graphics(grid,snap)]
      set lastY [.c canvasy %y $Graphics(grid,snap)]
   }

   bind .c <B1-Motion> {
      switch -exact -- $BBox(action) {
           move {
             set x [.c canvasx %x $Graphics(grid,snap)]
             set y [.c canvasy %y $Graphics(grid,snap)]
             moveGroup $x $y
           }
           none {
             set selectBox(x1) [.c canvasx %x]
             set selectBox(y1) [.c canvasy %y]
             set selectBox(x2) [.c canvasx %x]
             set selectBox(y2) [.c canvasy %y]
             selectGroupMode
           }
           default {
             scaleGroup [.c canvasx %x] [.c canvasy %y]
           }
      }
   }

   bind .c <B1-ButtonRelease> {
       set BBox(action) none
       catch {unset lastX lastY}
       %W configure -cursor ""
       set cmd [getGroupCommand 1]
       global History
       if {$cmd!="[lindex $History end]"} {
            History add [getGroupCommand 1]
            Undo add $BBox(undo)
       }
   }
}

proc HandlesButton1-bind {side cursor} {
  global BBox
  set BBox(action) $side
  .c configure -cursor $cursor
  set BBox(undo) [getGroupCommand 1]
  set BBox(xscale) 1
  foreach id [.c find withtag Selected] {
      if {[catch {.c itemcget $id -font} result]==0} {
            set u [Utag find $id]
            set BBox($u,fontsize) [lindex $result 1]
      }
  }
}

proc scaleGroup {x y} {
   global BBox lastX1 lastY1 lastX2 lastY2
   switch -exact -- $BBox(action) {
      none  { return }
      n    { if {abs($y-$BBox(y1))<2} {return} }
      s    { if {abs($y-$BBox(y2))<2} {return} }
      w    { if {abs($x-$BBox(x1))<2} {return} }
      e    { if {abs($x-$BBox(x2))<2} {return} }
      ne   { if {abs($x-$BBox(x2))<2 || abs($y-$BBox(y1))<2} {return} }
      nw   { if {abs($x-$BBox(x1))<2 || abs($y-$BBox(y1))<2} {return} }
      se   { if {abs($x-$BBox(x2))<2 || abs($y-$BBox(y2))<2} {return} }
      sw   { if {abs($x-$BBox(x1))<2 || abs($y-$BBox(y2))<2} {return} }
   }

   set lastX1 $BBox(x1)
   set lastY1 $BBox(y1)
   set lastX2 $BBox(x2)
   set lastY2 $BBox(y2)

   switch -exact -- $BBox(action) {
      none  { return }
      n    { set BBox(y1) $y
             set xOrigin $BBox(x1)
             set yOrigin $BBox(y2)
             set xScale  1.0
             set yScale  [getRatio $lastY2 $lastY1 $BBox(y2) $BBox(y1)]
      }

      s    { set BBox(y2) $y
             set xOrigin $BBox(x1)
             set yOrigin $BBox(y1)
             set xScale  1.0
             set yScale  [getRatio $lastY2 $lastY1 $BBox(y2) $BBox(y1)]
      }

      w    { set BBox(x1) $x
             set xOrigin $BBox(x2)
             set yOrigin $BBox(y1)
             set xScale  [getRatio $lastX2 $lastX1 $BBox(x2) $BBox(x1)]
             set yScale  1.0
      }

      e    { set BBox(x2) $x
             set xOrigin $BBox(x1)
             set yOrigin $BBox(y1)
             set xScale  [getRatio $lastX2 $lastX1 $BBox(x2) $BBox(x1)]
             set yScale  1.0
      }

      ne   { set BBox(y1) $y
             set xOrigin $BBox(x1)
             set yOrigin $BBox(y2)
             set xScale  [getRatio $lastY2 $lastY1 $BBox(y2) $BBox(y1)]
             set yScale  $xScale
             set BBox(x2) [expr $lastX1+($lastX2-$lastX1)*$xScale]
      }

      nw   { set BBox(y1) $y
             set xOrigin $BBox(x2)
             set yOrigin $BBox(y2)
             set xScale  [getRatio $lastY2 $lastY1 $BBox(y2) $BBox(y1)]
             set yScale  $xScale
             set BBox(x1) [expr $lastX2-($lastX2-$lastX1)*$xScale]
      }

      se   { set BBox(y2) $y
             set xOrigin $BBox(x1)
             set yOrigin $BBox(y1)
             set xScale  [getRatio $lastY2 $lastY1 $BBox(y2) $BBox(y1)]
             set yScale  $xScale
             set BBox(x2) [expr $lastX1+($lastX2-$lastX1)*$xScale]
      }

      sw   { set BBox(y2) $y
             set xOrigin $BBox(x2)
             set yOrigin $BBox(y1)
             set xScale  [getRatio $lastY2 $lastY1 $BBox(y2) $BBox(y1)]
             set yScale  $xScale
             set BBox(x1) [expr $lastX2-($lastX2-$lastX1)*$xScale]
      }
   }

   .c scale Selected $xOrigin $yOrigin $xScale $yScale
   set BBox(xscale) [expr $xScale*$BBox(xscale)]

   foreach id [.c find withtag Selected] {
      if {[catch {.c itemcget $id -font} result]==0} {
        set u [Utag find $id]
        set fsize [expr round($BBox($u,fontsize)*$BBox(xscale))]
        if {$fsize != [lindex $result 1]} {
            .c itemconfig $id -font [lreplace $result 1 1 $fsize]
        }
      }
   }
   drawBoundingBox
}

proc getRatio {a b c d} {
  set ratio [expr ($c-$d+0.0)/($a-$b+0.0)]
  if {$ratio==0} {
    return 0.01
  }
  return $ratio
}


proc deleteGroup {} {
   set group [.c find withtag Selected]
   if {[llength $group]==0} {
     Message "First you need to select a group of objects!"
     return
   }
   set undo [getGroupCommand 1]
   foreach id $group {
       set utag [Utag find $id]
       append cmd ".c delete $utag \; "
   }
   .c delete Selected graybox
   History add $cmd
   Undo add $undo
   selectGroupMode
}

proc raiseGroup {} {
   set group [.c find withtag Selected]
   if {[llength $group]==0} {
     Message "First you need to select a group of objects!"
     return
   }
   set undo [getGroupCommand 1]
   set cmd ""
   foreach id $group {
       set utag [Utag find $id]
       append cmd ".c raise $utag \; "
   }
   .c raise Selected
   .c raise graybox
#   .c raise gridObject
   History add $cmd
   Undo add $undo
}

proc lowerGroup {} {
   set group [.c find withtag Selected]
   if {[llength $group]==0} {
     Message "First you need to select a group of objects!"
     return
   }
   set n [expr [llength $group]-1]
   set cmd ""
   for {set i $n} {$i>=0} {incr i -1} {
       set id [lindex $group $i]
       set utag [Utag find $id]
       append cmd ".c lower $utag \; "
   }
   History add $cmd
   Undo add [getGroupCommand 1]
   .c lower Selected
}

proc moveGroup {x y} {
    global lastX lastY BBox
    set dx [expr $x-$lastX]
    set dy [expr $y-$lastY]
    .c move Selected $dx $dy
    drawBoundingBox
    set lastX $x
    set lastY $y
}

# COPY A GROUP:

proc createGroupCopy {} {
  global TextInfo Graphics
  set group [.c find withtag Selected]
  if {[llength $group]==0} {
    Message "First you need to select a group of objects!"
    return
  }
  puts "group $group"
  foreach id $group {
      set id_utag [Utag find $id]
      set cp_utag [Utag assign [eval [getObjectCommand $id_utag 0]]]
      if {[lsearch [.c gettags $cp_utag] text]>=0} {
        set TextInfo($cp_utag) [.c itemcget $cp_utag -text]
      }
      .c addtag tmpSelected withtag $cp_utag
      append undo ".c delete $cp_utag \; "
   }
   .c dtag Selected
   .c addtag Selected withtag tmpSelected
   .c dtag tmpSelected
   set gsnap [winfo fpixels .c $Graphics(grid,snap)]
   if {$gsnap<6} {
     set trans [expr $gsnap*6]
   } else {
     set trans [expr $gsnap*2]
   }
   .c move Selected $trans $trans
   drawBoundingBox
   History add [getGroupCommand 1]
   puts "Adding undo info"
   Undo add $undo
#   .c raise gridObject
   puts "Message"
   Message "hmmmm... do I remember this one!?"
}

##### ROTATE A GROUP

proc rotateObj {xo yo ang id} {
   set type [.c type $id]
   set coords  [.c coords $id]
   foreach conf [.c itemconfigure $id] {
      set opt [lindex $conf 0]
      set val [lindex $conf 4]
      # This is probably a bug work around (bezier? should be boolean!)
      if {$opt=="-smooth" && $val=="bezier"} {
        set val 1
      }
      set Options($opt) $val
   }
   set new_coords {}
   set sin [expr sin($ang)]
   set cos [expr cos($ang)]
   foreach {x y} $coords {
      lappend new_coords [expr ($x-$xo)*$cos + ($y-$yo)*$sin + $xo] \
                         [expr -($x-$xo)*$sin + ($y-$yo)*$cos + $yo]
   }
   .c delete $id
   eval .c create $type $new_coords [array get Options]
}

proc shape2spline {id} {
   if {[lsearch [.c gettags $id] spline] >= 0} {return $id}
   set pi [expr 2*asin(1)]
   set Options(-width)    [.c itemcget $id -width]
   set Options(-stipple)  [.c itemcget $id -stipple]
   set Options(-dash)     [.c itemcget $id -dash]
   set Options(-tags)     [.c itemcget $id -tags]
   lappend Options(-tags) spline
   set coords  [.c coords $id]
   set type [.c type $id]

   switch -exact -- $type {
      text      -
      line      -
      image     -
      bitmap    -
      polygon   { .c addtag spline withtag $id
         return $id
      }
      oval {
         set Options(-outline) [.c itemcget $id -outline]
         set Options(-fill)    [.c itemcget $id -fill]
         set Options(-smooth) 1
         set type polygon
         set x1 [lindex $coords 0]
         set y1 [lindex $coords 1]
         set x2 [lindex $coords 2]
         set y2 [lindex $coords 3]
         set a [expr ($x2-$x1)/2.0]
         set b [expr ($y2-$y1)/2.0]
         set coords {}
         for {set i 0} {$i<36} {incr i} {
           set t [expr $i*(2*$pi/36)]
           lappend coords [expr $x1+$a+$a*cos($t)]
           lappend coords [expr $y1+$b-$b*sin($t)]
         }
      }
      rectangle {
         set Options(-outline)  [.c itemcget $id -outline]
         set Options(-fill)     [.c itemcget $id -fill]
         set Options(-tags)     [.c itemcget $id -tags]
         lappend Options(-tags) Polygon
         set Options(-smooth) 0
         set type polygon
         set x1 [lindex $coords 0]
         set y1 [lindex $coords 1]
         set x2 [lindex $coords 2]
         set y2 [lindex $coords 3]
         set coords [list $x1 $y1 $x2 $y1 $x2 $y2 $x1 $y2]
      }
      arc {
         set Options(-smooth) 1
         set start  [expr ($pi*[.c itemcget $id -start])/180]
         set extent [expr ($pi*[.c itemcget $id -extent])/180]
         set style  [.c itemcget $id -style]
         set x1 [lindex $coords 0]
         set y1 [lindex $coords 1]
         set x2 [lindex $coords 2]
         set y2 [lindex $coords 3]
         set a [expr ($x2-$x1)/2.0]
         set b [expr ($y2-$y1)/2.0]
         set coords {}
         set divnum 24.0
         for {set i 0} {$i<=$divnum} {incr i} {
           set t [expr $start+$i*($extent/$divnum)]
           lappend coords [expr $x1+$a+$a*cos($t)]
           lappend coords [expr $y1+$b-$b*sin($t)]
         }
         switch -exact -- $style {
             arc  {
                set type line
                set Options(-fill) [.c itemcget $id -outline]
             }
             chord {
                set type polygon
                set Options(-outline) [.c itemcget $id -outline]
                set Options(-fill)    [.c itemcget $id -fill]
                set n [expr [llength $coords]-2]
                set x0 [lindex $coords 0]
                set y0 [lindex $coords 1]
                set xn [lindex $coords $n]
                set yn [lindex $coords [expr $n+1]]
                set coords [lreplace $coords 0 1]
                lappend coords $xn $yn $x0 $y0 $x0 $y0
             }
             pieslice {
                set type polygon
                set Options(-outline) [.c itemcget $id -outline]
                set Options(-fill)    [.c itemcget $id -fill]
                set n [expr [llength $coords]-2]
                set x0 [lindex $coords 0]
                set y0 [lindex $coords 1]
                set xn [lindex $coords $n]
                set yn [lindex $coords [expr $n+1]]
                set xc [expr ($x1+$x2)/2]
                set yc [expr ($y1+$y2)/2]
                set coords [lreplace $coords 0 1]
                lappend coords $xn $yn $xc $yc $xc $yc $x0 $y0 $x0 $y0
            }
          }
             
      }
   }
   .c addtag aboutToDie withtag $id
   set new_id [eval .c create $type $coords [array get Options]]
   .c lower $new_id aboutToDie
   .c delete aboutToDie
   return $new_id
}


proc rotateGroupMode {} {
   global Rotate pi Font
   set pi [expr 2*asin(1)]
   
   .c delete graybox

   set group [.c find withtag Selected]
   if {[llength $group]==0} {
     Message "First you need to select a group of objects!"
     return
   }
   Message "Choose rotation center (click)"
   set bbox [.c bbox Selected]
   set x1 [lindex $bbox 0]
   set y1 [lindex $bbox 1]
   set x2 [lindex $bbox 2]
   set y2 [lindex $bbox 3]
   .c create polygon $x1 $y1 $x2 $y1 $x2 $y2 $x1 $y2\
                -outline {} \
                -fill gray50 \
                -stipple gray12 \
                -tags {graybox rotateBox}

   set Rotate(x1) $x1
   set Rotate(x2) $x2
   set Rotate(y1) $y1
   set Rotate(y2) $y2
   set Rotate(xc) [expr ($x1+$x2)/2]
   set Rotate(yc) [expr ($y1+$y2)/2]

   .c bind rotateBox <Enter> {%W configure -cursor dot}
   .c bind rotateBox <Leave> {
        %W configure -cursor ""
        %W delete rotateText
   }

   .c bind rotateBox <Motion> {
        set x [.c canvasx %x $Graphics(grid,snap)]
        set y [.c canvasy %y $Graphics(grid,snap)]
        .c delete rotateText
        .c create text $Rotate(xc) [expr $Rotate(y1)-3] \
              -anchor s \
              -text [format "%%.1f" [expr $Rotate(yc)-$y]] \
              -tags rotateText
        .c create text [expr $Rotate(x2)+3]  $Rotate(yc) \
              -anchor w \
              -text [format "%%.1f" [expr $x-$Rotate(xc)]] \
              -tags rotateText
   }

   bind .c <Button-1> {
      set Rotate(x_orig) [.c canvasx %x]
      set Rotate(y_orig) [.c canvasy %y]
      set Rotate(last) 0
      set Rotate(ang) 0
      set Rotate(delta) 0
      set Rotate(undo) [getGroupCommand 1]
      foreach id [.c find withtag Selected] {
         shape2spline $id
      }
      Message "Now hold and drag the mouse to the desired angle"
   }

   bind .c <B1-Motion> {
     set x [.c canvasx %x]
     set y [.c canvasy %y]
     .c delete rotateLine rotateText rotateTextBox
     .c create line $Rotate(x_orig) $Rotate(y_orig) $x $y \
           -width 2 \
           -arrow last \
           -tags rotateLine
     if {abs($Rotate(x_orig) - $x) < 15 && abs($Rotate(y_orig) - $y) < 15} {
       return
     }
     .c create rectangle [expr $x+5] [expr $y-32] [expr $x+55] [expr $y-8] \
                -width 2 \
                -fill cyan \
                -tags rotateTextBox
     set Rotate(ang) [expr -atan2($y-$Rotate(y_orig),$x-$Rotate(x_orig))]
     .c create text [expr $x+30] [expr $y-20] \
           -anchor c \
           -fill red \
           -text [format "%%.1f" [expr $Rotate(ang)*180.0/$pi]] \
           -font $Font(rotateTextBox) \
           -tags rotateText
     set Rotate(delta) [expr $Rotate(ang) - $Rotate(last)]
     set Rotate(last) $Rotate(ang)
     rotateGroup
   }

   bind .c <B1-ButtonRelease> {
       .c delete rotateLine rotateBox rotateText rotateTextBox
       %W configure -cursor ""
       foreach id [.c find withtag Selected] {
          set utag [Utag find $id]
          append Rotate(cmd) "shape2spline $utag \; "
          append Rotate(cmd) "rotateObj $Rotate(x_orig) $Rotate(y_orig) \
                      $Rotate(last) $utag \; "
       }
       History add $Rotate(cmd)
       Undo add $Rotate(undo)
#       Message "Rotate action completed successfully (angle=$Rotate(ang))"
       catch {unset Rotate}
       selectGroupMode
   }
}

proc rotateGroup {} {
  global Rotate

  rotateObj $Rotate(x_orig) $Rotate(y_orig) $Rotate(delta) graybox

  foreach id [.c find withtag Selected] {
     rotateObj $Rotate(x_orig) $Rotate(y_orig) $Rotate(delta) $id
  }
  .c raise rotateLine
  .c raise rotateTextBox
  .c raise rotateText
}

##### DEFORM A GROUP

proc deformObj {side utag} {
   global deformInfo

   set xFloat $deformInfo($side,float,x)
   set yFloat $deformInfo($side,float,y)
   set x1 $deformInfo(bbox,x1)
   set x2 $deformInfo(bbox,x2)
   set y1 $deformInfo(bbox,y1)
   set y2 $deformInfo(bbox,y2)
   set h  $deformInfo(bbox,height)
   set w  $deformInfo(bbox,width)
   set new_coords {}

   switch $side {
      s  {
        if {abs($yFloat-$y1)<2} {return}
        foreach {x y} $deformInfo($utag,coords) {
           set y [expr $y1+($yFloat-$y1)*($y-$y1)/$h]
           set x [expr $x+($y-$y1)*($xFloat-$x2)/($yFloat-$y1)]
           lappend new_coords $x $y
        }
      }
      n  {
        if {abs($yFloat-$y2)<2} {return}
        foreach {x y} $deformInfo($utag,coords) {
           set y [expr $y2-($yFloat-$y2)*($y-$y2)/$h]
           set x [expr $x+($y-$y2)*($xFloat-$x1)/($yFloat-$y2)]
           lappend new_coords $x $y
        }
      }
      e  {
        if {abs($xFloat-$x1)<2} {return}
        foreach {x y} $deformInfo($utag,coords) {
           set x [expr $x1+($xFloat-$x1)*($x-$x1)/$w]
           set y [expr $y+($x-$x1)*($yFloat-$y1)/($xFloat-$x1)]
           lappend new_coords $x $y
        }
      }
      w  {
        if {abs($xFloat-$x2)<2} {return}
        foreach {x y} $deformInfo($utag,coords) {
           set x [expr $x2-($xFloat-$x2)*($x-$x2)/$w]
           set y [expr $y+($x-$x2)*($yFloat-$y2)/($xFloat-$x2)]
           lappend new_coords $x $y
        }
      }
   }

   .c delete $utag
   eval .c create $deformInfo($utag,type) $new_coords $deformInfo($utag,options)
}

proc deformGroup {side} {
  global deformInfo

  deformObj $side deformBox

  foreach id [.c find withtag Selected] {
     deformObj $side [Utag find $id]
  }
}

proc deformHandlePress {side} {
  global deformInfo
  switch $side {
      s {.c delete n-deformHandle e-deformHandle w-deformHandle}
      n {.c delete s-deformHandle e-deformHandle w-deformHandle}
      e {.c delete n-deformHandle s-deformHandle w-deformHandle}
      w {.c delete n-deformHandle s-deformHandle e-deformHandle}
  }
  set deformInfo(undo) [getGroupCommand 1]
  foreach id [.c find withtag Selected] {
     set u [Utag find [shape2spline $id]]
     set deformInfo($u,type) [.c type $u]
     set deformInfo($u,coords) [.c coords $u]
     set deformInfo($u,options) [getObjectOptions $u 2]
  }
}

proc deformHandleMotion {side x y} {
   global Graphics deformInfo
   set x [.c canvasx $x $Graphics(grid,snap)]
   set y [.c canvasy $y $Graphics(grid,snap)]
   set dx [expr $x-$deformInfo($side-handle,x)]
   set dy [expr $y-$deformInfo($side-handle,y)]
   .c move $side-deformHandle $dx $dy
   set deformInfo($side-handle,x) $x
   set deformInfo($side-handle,y) $y
   set deformInfo($side,float,x) [expr $deformInfo($side,float,x)+$dx]
   set deformInfo($side,float,y) [expr $deformInfo($side,float,y)+$dy]
   deformGroup $side
}

proc deformGroupMode {} {
   global deformInfo
   
   .c delete graybox
   .c configure -cursor ""

   set tmp [.c find withtag Selected]
   if {[llength $tmp]==0} {
     Message "First you need to select a group of objects!"
     return
   }
   unset tmp
   set bbox [.c bbox Selected]
   set x1 [lindex $bbox 0]
   set y1 [lindex $bbox 1]
   set x2 [lindex $bbox 2]
   set y2 [lindex $bbox 3]
   .c create polygon $x1 $y1 $x2 $y1 $x2 $y2 $x1 $y2\
                -outline {} \
                -fill gray50 \
                -stipple gray12 \
                -tags {graybox deformBox}
# deformHandle box width and height:
   set handWidth 16
   set Coords(s) [list \
         [expr ($x1+$x2-$handWidth)/2]  $y2 \
         [expr ($x1+$x2+$handWidth)/2]  [expr $y2+$handWidth] \
   ]
   set Coords(n) [list \
         [expr ($x1+$x2-$handWidth)/2]  [expr $y1-$handWidth] \
         [expr ($x1+$x2+$handWidth)/2]  $y1 \
   ]
   set Coords(e) [list \
         $x2  [expr ($y1+$y2-$handWidth)/2] \
         [expr $x2+$handWidth]  [expr ($y1+$y2+$handWidth)/2] \
   ]
   set Coords(w) [list \
         [expr $x1-$handWidth]  [expr ($y1+$y2-$handWidth)/2] \
         $x1   [expr ($y1+$y2+$handWidth)/2] \
   ]

   foreach a {s n e w} {
       set coords $Coords($a)
       set options [list -outline {} -fill black -stipple gray75 \
                -tags [list graybox deformHandle $a-deformHandle]]
       eval .c create rectangle $coords $options
   }
   unset Coords

   Message "Drag one of the deform handles"

   set deformInfo(bbox,x1) $x1
   set deformInfo(bbox,y1) $y1
   set deformInfo(bbox,x2) $x2
   set deformInfo(bbox,y2) $y2
   set deformInfo(bbox,height) [expr $y2-$y1]
   set deformInfo(bbox,width) [expr $x2-$x1]

   set deformInfo(s,float,x) $x2
   set deformInfo(s,float,y) $y2
   set deformInfo(s-handle,x) [expr ($x1+$x2)/2]
   set deformInfo(s-handle,y) [expr $y2+$handWidth/2]
   set deformInfo(n,float,x) $x1
   set deformInfo(n,float,y) $y1
   set deformInfo(n-handle,x) [expr ($x1+$x2)/2]
   set deformInfo(n-handle,y) [expr $y1-$handWidth/2]
   set deformInfo(e,float,x) $x2
   set deformInfo(e,float,y) $y1
   set deformInfo(e-handle,x) [expr $x2+$handWidth/2]
   set deformInfo(e-handle,y) [expr ($y1+$y2)/2]
   set deformInfo(w,float,x) $x1
   set deformInfo(w,float,y) $y2
   set deformInfo(w-handle,x) [expr $x1-$handWidth/2]
   set deformInfo(w-handle,y) [expr ($y1+$y2)/2]

   set deformInfo(deformBox,type) [.c type deformBox]
   set deformInfo(deformBox,coords) [.c coords deformBox]
   set deformInfo(deformBox,options) [getObjectOptions deformBox 0]

   .c bind deformHandle <Enter> {%W configure -cursor trek}

   .c bind deformHandle <Leave> {%W configure -cursor ""}

   bind .c <Button-1> {}
   .c bind s-deformHandle <Button-1> {deformHandlePress s}
   .c bind n-deformHandle <Button-1> {deformHandlePress n}
   .c bind e-deformHandle <Button-1> {deformHandlePress e}
   .c bind w-deformHandle <Button-1> {deformHandlePress w}

   bind .c <B1-Motion> {}
   .c bind s-deformHandle <B1-Motion> {deformHandleMotion s %x %y}
   .c bind n-deformHandle <B1-Motion> {deformHandleMotion n %x %y}
   .c bind e-deformHandle <B1-Motion> {deformHandleMotion e %x %y}
   .c bind w-deformHandle <B1-Motion> {deformHandleMotion w %x %y}

   bind .c <B1-ButtonRelease> {}
   .c bind deformHandle <B1-ButtonRelease> {
         .c delete graybox
         %W configure -cursor ""
         append deformInfo(cmd) [getGroupCommand 1]
         History add $deformInfo(cmd)
         Undo add $deformInfo(undo)
         # Message "Deform action completed successfully"
         catch {unset deformInfo}
         set selectBox(x1) [.c canvasx %x]
         set selectBox(y1) [.c canvasy %y]
         set selectBox(x2) [.c canvasx %x]
         set selectBox(y2) [.c canvasy %y]
         selectGroupMode
   }
}


######## GROUP LINE COLOR:
proc editGroupLineColor {} {
   set undo [getGroupCommand 1]
   set group [.c find withtag Selected]
   if {[llength $group]==0} {
     Message "First you need to select a group of objects!"
     return
   }
   set color [tk_chooseColor -title "Choose Group Outline Color"]
   if {$color==""} {return}
   set cmd ""
   foreach id $group {
       set type [.c type $id]
       set utag [Utag find $id]
       switch -exact -- $type {
          text      -
          image     -
          bitmap    { set step "" }
          line      { set step [list .c itemconfigure $utag -fill $color]\; }
          default   {
               if {[.c itemcget $id -outline]==""} {
                    set step ""
               } else {
                   set step [list .c itemconfigure $utag -outline $color]\;
               }
          }
       }
       if {$step==""} {continue}
       eval $step
       append cmd $step
   }
   History add $cmd
   Undo add $undo
}

# GROUP FILL COLOR:
proc editGroupFillColor {} {
   set have_fill 0
   set filledTypes [list Rectangle Ellipse RoundRect Circle Polygon \
             pieslice chord]

   set group [.c find withtag Selected]
   foreach id $group {
      foreach t [.c gettags $id] {
         if {[lsearch $filledTypes $t]>=0} {
              set have_fill 1
         }
      }
      if {$have_fill==1} {break}
   }

   if {$have_fill==0} {
     Message "There are no selected objects with fill color!"
     return
   }

   set undo [getGroupCommand 1]
   set cmd ""

   set color [tk_chooseColor -title "Choose Group Fill Color"]
   if {$color==""} {return}
   foreach id $group {
       set type [.c type $id]
       switch -exact -- $type {
          line      -
          text      -
          image     -
          bitmap    {set step ""}
          default   {
             set utag [Utag find $id]
             set step [list .c itemconfigure $utag -fill $color]\;
          }
       }
       if {$step==""} {continue}
       eval $step
       append cmd $step
   }
   History add $cmd
   Undo add $undo
}


# GROUP LINE WIDTH:
proc editGroupLineWidth {} {
   global glwidth glw_undo Font
   set have_line 0

   set glw_undo [getGroupCommand 1]

   foreach id [.c find withtag Selected] {
      set type [.c type $id]
      switch -exact -- $type {
         text     -
         image    -
         bitmap   {continue}
         default  {set glwidth [.c itemcget $id -width]
                   set have_line 1
                   break
                  }
      }
   }

   if {$have_line==0} {
     Message "There are no lines in selection box"
     return
   }

   catch {destroy .grouplw}
   toplevel .grouplw
#   wm transient .grouplw .
   wm resizable .grouplw 0 0
#   wm geometry .grouplw +250+150
   focus -force .grouplw
   wm title .grouplw "Pick line width"
   frame .grouplw.width ;# -relief raised -bd 1
   canvas .grouplw.widthcanvas -relief flat -height 2c -width 7.5c
   .grouplw.widthcanvas create text 5 5 \
          -anchor nw \
          -text "Group Line Width" \
          -font $Font(groupLineWidthDemo)
       
   .grouplw.widthcanvas create line 1.2c 1.5c 6.3c 1.5c \
          -tags demoGroupLine \
          -width $glwidth

   scale .grouplw.widthscale -orient horiz \
          -resolution 1 -from 0 -to 60 \
          -length 4c \
          -variable glwidth \
          -command updateGroupLineWidth \
          -bd 2 \
          -relief flat \
          -highlightthickness 0 \
          -width 10 \
          -showvalue true \
          -font $Font(groupLineWidthDemo)
   pack .grouplw.widthcanvas .grouplw.widthscale -in .grouplw.width \
           -side top  -fill both -expand true
   pack .grouplw.width
   frame .grouplw.butts
   pack .grouplw.butts -side top -fill both -expand true -pady 2m

   button .grouplw.butts.ok -text OK -command {
        set cmd ""
        foreach id [.c find withtag Selected] {
            set type [.c type $id]
            if {$type=="text" || $type=="image" || $type=="bitmap"} {
              continue
            }
            set utag [Utag find $id]
            set lw [.c itemcget $id -width]
            append cmd [list .c itemconfigure $utag -width $lw]\;
        }
        History add $cmd
        Undo add $glw_undo
        unset glwidth glw_undo cmd
        destroy .grouplw
   }

   button .grouplw.butts.cancel -text Cancel -command {
      eval $glw_undo
      unset glw_undo
      destroy .grouplw
   }

   pack .grouplw.butts.ok .grouplw.butts.cancel -side left -fill x -expand 1

   wm protocol .grouplw WM_DELETE_WINDOW {.grouplw.butts.ok invoke}
   #tkwait window .grouplw
   grab set .grouplw
}

proc updateGroupLineWidth {glw} {
   global Graphics
   .grouplw.widthcanvas itemconfigure demoGroupLine -width $glw
   foreach id [.c find withtag Selected] {
       set type [.c type $id]
       switch -exact -- $type {
          text   -
          image  -
          bitmap {continue}
          line   {
             .c itemconfigure $id -width $glw
          }
          default   {
             set outline [.c itemcget $id -outline]
             if {$outline==""} {
                 if [info exists Graphics(line,color,save)] {
                     set outline $Graphics(line,color,save)
                 } else {
                     set outline $Graphics(line,color)
                 }
             }
             if {$glw>0} {
                 .c itemconfigure $id -width $glw -outline $outline
             } else {
                 .c itemconfigure $id -outline {}
             }
          }
       }
   }
}

proc editGroupFont {} {
   set have_text 0

   set undo [getGroupCommand 1]

   foreach id [.c find withtag Selected] {
       set type [.c type $id]
       if {$type=="text"} {
         set initfont  [.c itemcget $id -font]
         set initcolor [.c itemcget $id -fill]
         set have_text 1
         break
       }
   }

   if {$have_text==0} {
     Message "There is no text in selected area"
     return
   }

   set newData [dkf_chooseFont -initialfont  $initfont \
                               -initialColor $initcolor]
   if {$newData==""} {return}

   set newFont [lindex $newData 0]
   set newColor [lindex $newData 1]

   set cmd ""
   foreach id [.c find withtag Selected] {
       set type [.c type $id]
       set utag [Utag find $id]
       if {$type=="text"} {
         .c itemconfigure $id -font $newFont -fill $newColor
         append cmd [list .c itemconfigure $utag -font $newFont \
                          -fill $newColor] \;
       }
   }
   History add $cmd
   Undo add $undo
}

# X-REFLECT GROUP:
proc reflect {mode} {
   global BBox
   set group [.c find withtag Selected]
   if {[llength $group]==0} {
     Message "First you need to select a group of objects!"
     return
   }
   set undo [getGroupCommand 1]
   set x0 [expr ($BBox(x1)+$BBox(x2))/2.0]
   set y0 [expr ($BBox(y1)+$BBox(y2))/2.0]
   set cmd ""
   foreach id $group {
       set id [shape2spline $id]
       set utag [Utag find $id]
       lappend utags $utag
       append cmd ".c delete $utag \;"
       set type [.c type $id]
       append cmd ".c create $type "
       set coords [.c coords $id]
       set new_coords {}
       if {$mode=="x"} {
           foreach {x y} $coords {
              lappend new_coords $x [expr (2*$y0)-$y]
           }
       } else {
           foreach {x y} $coords {
              lappend new_coords [expr (2*$x0)-$x] $y
           }
       }
       append cmd $new_coords " "
       set options [getObjectOptions $utag 1]
       if {$type=="text" || $type=="image" || $type=="bitmap"} {
            set a [.c itemcget $id -anchor]
            if {$mode=="x"} {
                if {[string first "n" $a]>=0} {
                     regsub n $a s b
                } else {
                     regsub s $a n b
                }
            } else {
                if {[string first "w" $a]>=0} {
                     regsub w $a e b
                } else {
                     regsub e $a w b
                }
            }
            regsub -- "-anchor $a" $options "-anchor $b" options
       }
       append cmd "$options \; "
   }
   eval $cmd
   foreach u $utags {
       .c addtag Selected withtag $u
   }
   drawBoundingBox
   History add $cmd
   Undo add $undo
}

###################### SECTION:  ARROWS

proc drawArrowHandle {x y w} {
  set r [expr $w+3]
  set coords [list [expr $x-$r] [expr $y-$r] \
                   [expr $x-$r] [expr $y+$r] \
                   [expr $x+$r] [expr $y+$r] \
                   [expr $x+$r] [expr $y-$r] ]
  set options [list -outline black -width 1 -fill {} -smooth 1 \
                    -tags arrowHandle]
  return [eval .c create polygon $coords $options]
}

proc arrowsMode {} {
  global arrowsInfo Graphics
  set Graphics(mode) Arrows

  catch {unset arrowsInfo}
  set arrowsInfo(lines) {}

  foreach id [.c find withtag obj] {
      set type [.c type $id]
      if {$type=="line"} {
        lappend arrowsInfo(lines) $id
      }
  }

  if {[llength $arrowsInfo(lines)]==0} {
    set Graphics(mode) "NULL"
    Message "No lines on canvas!"
    return
  }

  foreach line $arrowsInfo(lines) {
     set line [Utag find $line]
     set coords [.c coords $line]
     set n [llength $coords]
     set x1 [lindex $coords 0]
     set y1 [lindex $coords 1]
     set x2 [lindex $coords [expr $n-2]]
     set y2 [lindex $coords [expr $n-1]]
     
     set arrowsConfig [.c itemcget $line -arrow]
     set width [.c itemcget $line -width]

     set id1 [drawArrowHandle $x1 $y1 $width]
     set arrowsInfo($id1,point) first
     set arrowsInfo($id1,line) $line
     set arrowsInfo($id1,option) $arrowsConfig
     .c bind $id1 <Button-1> "toggleArrow $id1"

     set id2 [drawArrowHandle $x2 $y2 $width]
     set arrowsInfo($id2,point) last
     set arrowsInfo($id2,line) $line
     set arrowsInfo($id2,option) $arrowsConfig
     .c bind $id2 <Button-1> "toggleArrow $id2"

     set arrowsInfo($id1,friend) $id2
     set arrowsInfo($id2,friend) $id1
   }
   set arrowsInfo(map) {
      first  none    first
      first  first   none
      first  last    both
      first  both    last
      last   none    last
      last   first   both
      last   last    none
      last   both    first
   }
   Message "Click in circles to toggle arrow/no-arrow"
}

proc toggleArrow {id} {
   global arrowsInfo Graphics

   Message {if you hate the arrow goto "Line"/"Arrow shape"}
  
   foreach {a b c} $arrowsInfo(map) {
     if {$arrowsInfo($id,point)==$a && $arrowsInfo($id,option)==$b} {
       set cmd [list .c itemconfigure $arrowsInfo($id,line) \
                     -arrow $c -arrowshape $Graphics(arrowshape)]
       set undo [list .c itemconfigure $arrowsInfo($id,line) \
                 -arrow $arrowsInfo($id,option) \
                 -arrowshape $Graphics(arrowshape)]
       eval $cmd
       set arrowsInfo($id,option) $c
       set friend $arrowsInfo($id,friend)
       set arrowsInfo($friend,option) $c
       History add $cmd
       Undo add $undo
       return
     }
   }
}

### SECTION: TEXT IN CANVAS

#
# Based on Welch's textbook code:
# Example 31-12 of Welch's great book "Practical Programming in Tcl/Tk".
# Simple edit bindings for canvas text items.
#

proc TextMode {} {
   global Graphics

   bind .c <Button-1> {
      set x [.c canvasx %x $Graphics(grid,snap)]
      set y [.c canvasy %y $Graphics(grid,snap)]
      TextFocus $x $y
   }
   bind .c <Button-3> {
      set x [.c canvasx %x $Graphics(grid,snap)]
      set y [.c canvasy %y $Graphics(grid,snap)]
      TextPaste $x $y
   }
   bind .c <<Cut>> {TextCopy ; TextDelete}
   bind .c <<Copy>> {TextCopy}
   bind .c <<Paste>> {TextPaste}
   .c bind text <B1-Motion> {
      TextDrag [%W canvasx %x] [%W canvasy %y]
   }
   .c bind text <Delete> {TextDelete}
   .c bind text <Control-h> {TextBackSpace}
   .c bind text <BackSpace> {TextBackSpace}
   .c bind text <Control-Delete> {TextErase}
   .c bind text <Return> {TextNewline}
   .c bind text <Any-Key> {TextInsert %A}
   .c bind text <Key-Right> {TextMoveRight}
   .c bind text <Control-f> {TextMoveRight}
   .c bind text <Key-Left> {TextMoveLeft}
   .c bind text <Control-b> {TextMoveLeft}
}

proc TextFocus {x y} {
   global Text Graphics TextInfo
   focus .c
   if [info exists Text] {TextHist}

   set Text(utag) [getNearestUtag $x $y 2 text]

   if {$Text(utag) != ""} {
        foreach opt {text font fill stipple anchor tags} {
            set Text($opt)  [.c itemcget $Text(utag) -$opt]
        }
        .c focus $Text(utag)
        .c icursor $Text(utag) @$x,$y
        .c select clear
        .c select from $Text(utag) @$x,$y
   } else {
         set Text(font)    [list $Graphics(font,type) $Graphics(font,size)\
                                 $Graphics(font,style)]
         set Text(color)   $Graphics(font,color)
         set Text(stipple) $Graphics(font,stipple)
         set Text(anchor)  $Graphics(text,anchor)
         set id [.c create text $x $y -text "" \
                         -font    $Text(font) \
                         -fill    $Text(color) \
                         -stipple $Text(stipple) \
                         -anchor  $Text(anchor) \
                         -tags {text obj} \
                         -anchor $Graphics(text,anchor)]
         set Text(utag) [Utag assign $id]
         set TextInfo($Text(utag)) {}
         .c focus $Text(utag)
         .c select clear
         .c icursor $Text(utag) 0
   }
}

proc TextHist {} {
     global TextInfo Text
     set u $Text(utag)
     if [info exists TextInfo(TextBackSpace)] {
       unset TextInfo(TextBackSpace) TextInfo(TextBackSpaceCmd)
     }
     if [info exists TextInfo(TextDelete)] {
       unset TextInfo(TextDelete) TextInfo(TextDeleteCmd)
     }
     set t [.c itemcget $u -text]
     if {$t==""} {
          .c delete $u
          unset Text
          return
     } elseif {$TextInfo($u)==""} {
          set TextInfo($u) $t
          set cmd "[getObjectCommand $u 1] \;"
          append cmd "[list set TextInfo($u) $t] \;"
          set undo ".c delete $u \;"
          append undo "set TextInfo($u) {}"
     } elseif {$t==$TextInfo($u)} {
          unset Text
          return
     } else {
          set cmd  "[list .c itemconfig $u -text $t] \;"
          append cmd "[list set TextInfo($u) $t] \;"
          set undo "[list .c itemconfig $u -text $TextInfo($u)] \; "
          append undo "[list set TextInfo($u) $TextInfo($u)] \;"
          set TextInfo($u) $t
     }

     History add $cmd
     Undo add $undo
     unset Text
}

proc TextDrag {x y} {
   .c select to current @$x,$y
}

proc TextDelete {} {
   global TextInfo Text
   set id [.c select item]
   if {$id != {}} {
      set u [Utag find $id]
      if ![info exists TextInfo(TextDelete)] {
        set TextInfo(TextDeleteCmd) [getObjectCommand $u 1]
        set TextInfo(TextDelete) 1
        if [info exists Text(text)] {
            set TextInfo($u) $Text(text)
        }
      }
      .c dchars $u sel.first sel.last
      set t [.c itemcget $u -text]
   } elseif {[.c focus] != {}} {
      set u [Utag find [.c focus]]
      if ![info exists TextInfo(TextDelete)] {
        set TextInfo(TextDeleteCmd) [getObjectCommand $u 1]
        set TextInfo(TextDelete) 1
        if [info exists Text(text)] {
            set TextInfo($u) $Text(text)
        }
      }
      .c dchars $u insert
      set t [.c itemcget $u -text]
   }
   if {$t==""} {
        .c delete $u
        #unset TextInfo($u)
        History add ".c delete $u"
        Undo add $TextInfo(TextDeleteCmd)
        catch {unset TextInfo(TextDelete) TextInfo(TextDeleteCmd)}
   }
}

proc TextBackSpace {} {
   global TextInfo Text
   set id [.c select item]
   if {$id != {}} {
      set u [Utag find $id]
      if ![info exists TextInfo(TextBackSpace)] {
        set TextInfo(TextBackSpaceCmd) [getObjectCommand $u 1]
        set TextInfo(TextBackSpace) 1
        if [info exists Text(text)] {
            set TextInfo($u) $Text(text)
        }
      }
      .c dchars $u sel.first sel.last
      set t [.c itemcget $u -text]
   } elseif {[.c focus] != {}} {
      set u [Utag find [.c focus]]
      if ![info exists TextInfo(TextBackSpace)] {
        set TextInfo(TextBackSpaceCmd) [getObjectCommand $u 1]
        set TextInfo(TextBackSpace) 1
        if [info exists Text(text)] {
            set TextInfo($u) $Text(text)
        }
      }
      .c icursor $u [expr [.c index $u insert]-1]
      .c dchars $u insert
      set t [.c itemcget $u -text]
   }
   if {$t==""} {
        .c delete $u
        #unset TextInfo($u)
        History add ".c delete $u"
        Undo add $TextInfo(TextBackSpaceCmd)
        catch {unset TextInfo(TextBackSpace) TextInfo(TextBackSpaceCmd)}
   }
}

proc TextCopy {} {
   if {[.c select item] != {}} {
      clipboard clear
      set t [.c select item]
      set text [.c itemcget $t -text]
      set start [.c index $t sel.first]
      set end [.c index $t sel.last]
      clipboard append [string range $text $start $end]
   } elseif {[.c focus] != {}} {
      clipboard clear
      set t [.c focus]
      set text [.c itemcget $t -text]
      clipboard append $text
   }
}

proc TextErase {} {
   global Text TextInfo

   if ![info exists Text] {return}

   .c focus {}
   .c select clear

   set u $Text(utag)

   set text [.c itemcget $u -text]

   set cmd ".c delete $u"
   set undo "[getObjectCommand $u 1]\;"

   if {$text==""} {
       if {$TextInfo($u) != ""} {
         append undo "[list .c itemconfig $u -text $TextInfo($u)] \;"
       } else {
        .c delete $u
        catch {unset Text}
        return
       }
   } elseif {$TextInfo($u)!="" && $text!=$TextInfo($u)} {
#        History add [getObjectCommand $u 1]
        History add [list .c itemconfig $u -text $text]
        Undo add [list .c itemconfig $u -text $TextInfo($u)]
        set TextInfo($u) $text
   }

   History add $cmd
   Undo add $undo
   catch {unset Text}
   .c delete $u
}

proc TextNewline {} {
   .c insert [.c focus] insert \n
}

proc TextInsert {char} {
   if {$char=="" || $char=="" || $char==""} {return}
   .c insert [.c focus] insert $char
}

proc TextPaste {{x {}} {y {}}} {
   if {[catch {selection get} _s] &&
       [catch {selection get -selection CLIPBOARD} _s]} {
      return      ;# No selection
   }
   set id [.c focus]
   if {[string length $id] == 0 } {
      set id [.c find withtag current]
   }
   if {[string length $id] == 0 } {
      # No object under the mouse
      if {[string length $x] == 0} {
         # Keyboard paste
         set x [expr [winfo pointerx .c] - [winfo rootx .c]]
         set y [expr [winfo pointery .c] - [winfo rooty .c]]
      }
      TextFocus $x $y
   } else {
      .c focus $id
   }
   .c insert [.c focus] insert $_s
}

proc TextMoveRight {} {
   .c icursor [.c focus] [expr [.c index current insert]+1]
}

proc TextMoveLeft {} {
   .c icursor [.c focus] [expr [.c index current insert]-1]
}



#### FONT CHOOSING
proc chooseFont {} {
   global Graphics Zoom
   set initFont [list $Graphics(font,type) \
                      $Graphics(font,size) \
                      $Graphics(font,style)]
   set initColor $Graphics(font,color)
   set newData [dkf_chooseFont -initialfont $initFont\
                               -initialColor $initColor]
   if {$newData==""} {return}
   set newFont [lindex $newData 0]
   set newFontColor [lindex $newData 1]
   set Graphics(font,type)  [lindex $newFont 0]
   set Graphics(font,size)  [lindex $newFont 1]
   set Graphics(font,style) [lindex $newFont 2]
   set Graphics(font,color) $newFontColor
   set Zoom(font,size) $Graphics(font,size)
}

proc resetFontStyle {} {
   global Graphics
   foreach s {bold italic underline overstrike} {
      if {$Graphics(font,$s)==1 && [lsearch $Graphics(font,style) $s]<0} {
        lappend Graphics(font,style) $s
      }
      if {$Graphics(font,$s)==0 && [lsearch $Graphics(font,style) $s]>=0} {
        set i [lsearch $Graphics(font,style) $s]
        set Graphics(font,style) [lreplace $Graphics(font,style) $i $i]
      }
   }
}

###### GRID SECTION

proc gridSelector {w} {
   catch {destroy $w}
   global Graphics gridInfo
   set gridInfo(gridon)   $Graphics(grid,on)
   set gridInfo(snapon)   $Graphics(snap,on)
   set gridInfo(tickson)  $Graphics(ticks,on)
   set gridInfo(snapsize) $Graphics(snap,size)
   set gridInfo(gridsize) $Graphics(grid,size)
   set gridInfo(win)      $w

   toplevel $w
   wm title $w "Grid selector"
   #wm transient $w .
   wm iconname $w Gridsel
   wm group $w .
   #wm protocol $w WM_DELETE_WINDOW [list destroy $w \; return \"\"]
   focus $w
   grab set $w

   label $w._testing
   set gap [expr {[font metrics [$w._testing cget -font] -linespace]/2+1}]
   destroy $w._testing
   #set gap [winfo pixels $w 2m]

   frame $w.border1 -bd 2 -relief ridge
   frame $w.border2 -bd 2 -relief ridge
   grid $w.border1 -row 2 -column 0 -rowspan 3 -columnspan 12 \
        -padx $gap -pady $gap -sticky nsew
   grid $w.border2 -row 5 -column 0 -rowspan 3 -columnspan 12 \
        -padx $gap -pady $gap -sticky nsew
   foreach col {0 11} {
       grid columnconfig  $w $col -minsize $gap
   }
   incr gap $gap
   foreach row {0 2 4 5 7} {
       grid rowconfig  $w $row -minsize $gap
   }
   #foreach col {1 11} {
   #     grid columnconfig  $w $col -weight 1
   #}

   label $w.grid_label -text GRID -padx 1m -pady 1
   label $w.snap_label -text SNAP -padx 1m -pady 1
   grid $w.grid_label -row 2 -column 2 -sticky w
   grid $w.snap_label -row 5 -column 2 -sticky w

   frame $w.gridsize
   frame $w.snapsize
   grid $w.gridsize -row 3 -column 1 -rowspan 1 -columnspan 10 -sticky nsew \
         -padx $gap
   grid $w.snapsize -row 6 -column 1 -rowspan 1 -columnspan 10 -sticky nsew \
         -padx $gap
   foreach {size row col} {
       5    0 0
       10   1 0
       15   2 0
       20   0 1
       25   1 1
       30   2 1
       35   0 2
       40   1 2
       45   2 2
       50   0 3
       55   1 3
       60   2 3
       5m   0 4
       10m  1 4
       15m  2 4
       20m  0 5
       0.5i 1 5
       1i   2 5
   } {
       set b $w.gridsize.but_${row}_${col}
       radiobutton $b -variable gridInfo(gridsize) -value $size \
                      -text $size -anchor w
       grid $b -row $row -column $col -sticky ew
       set b $w.snapsize.but_${row}_${col}
       radiobutton $b -variable gridInfo(snapsize) -value $size \
                      -text $size -anchor w
       grid $b -row $row -column $col -sticky ew
       #grid column $w.gridsize $col -weight 1
       #grid column $w.snapsize $col -weight 1
   }

   entry $w.gridsize.entry -textvariable gridInfo(gridsize) -width 6 -bg white
   grid $w.gridsize.entry -row 0 -column 6 -rowspan 3 -sticky ew
   entry $w.snapsize.entry -textvariable gridInfo(snapsize) -width 6 -bg white
   grid $w.snapsize.entry -row 0 -column 6 -rowspan 3 -sticky ew
   set colwidth [expr 1.25*[winfo reqwidth $w.gridsize.but_1_5]]
   foreach c {0 1 2 3 4 5} {
       grid columnconfig $w.gridsize $c -minsize $colwidth
       grid columnconfig $w.snapsize $c -minsize $colwidth
   }
   grid column $w.gridsize 6 -weight 1
   grid column $w.snapsize 6 -weight 1
   bind $w.gridsize.entry <Return> {Grid}
   
   frame $w.butnframe1
   grid $w.butnframe1 -row 0 -column 3 -rowspan 2 -columnspan 2 \
   	-sticky nsew -pady $gap
   checkbutton $w.butnframe1.gridon -text "Grid on" \
        -variable gridInfo(gridon) -anchor w
   pack $w.butnframe1.gridon -side top -fill x -padx [expr {$gap/2}]
   checkbutton $w.butnframe1.snapon -text "Snap on" \
        -variable gridInfo(snapon) -anchor w
   pack $w.butnframe1.snapon -side top -fill x -padx [expr {$gap/2}]
   checkbutton $w.butnframe1.tickson -text "Ticks on" \
        -variable gridInfo(tickson) -anchor w
   pack $w.butnframe1.tickson -side top -fill x -padx [expr {$gap/2}]
   
   frame $w.butnframe2
   grid $w.butnframe2 -row 0 -column 5 -rowspan 2 -columnspan 2 \
   	-sticky ew -pady $gap
   button $w.butnframe2.ok -text OK -command {
        set Graphics(grid,on)   $gridInfo(gridon)
        set Graphics(snap,on)   $gridInfo(snapon)
        set Graphics(ticks,on)  $gridInfo(tickson)
        set Graphics(grid,size) $gridInfo(gridsize)
        set Graphics(snap,size) $gridInfo(snapsize)
        if {$gridInfo(snapon)==1} {
              set Graphics(grid,snap) $gridInfo(snapsize)
        } else {
              set Graphics(grid,snap) 1
        } 
        destroy $gridInfo(win)
   }
   pack $w.butnframe2.ok -side top -fill x -padx [expr {$gap/2}]
   button $w.butnframe2.cancel -text Cancel -command {
        destroy $gridInfo(win)
   }
   pack $w.butnframe2.cancel -side top -fill x -padx [expr {$gap/2}]
   bind $w <FocusOut> "raise $w; focus -force $w"
}

proc Grid {} {
  global Graphics Canv
  if {$Graphics(grid,on)==0} {
    .c delete gridObject
    return
  }
  .c delete gridLine
  set size [winfo fpixels .c $Graphics(grid,size)]
  if {$size<2} {
    return
  }
  set m [expr int($Canv(SW)/$size)]
  set n [expr int($Canv(SH)/$size)]
  
  for {set i 1} {$i<=$m} {incr i} {
    set Xi [expr $i*$size]
    .c create line $Xi 0 $Xi $Canv(SH) \
        -width 1.5 \
        -stipple gray12 \
        -tags {gridLine gridObject}
  }
  
  for {set i 1} {$i<=$n} {incr i} {
    set Yi [expr $i*$size]
    .c create line 0 $Yi $Canv(SW) $Yi \
        -stipple gray12 \
        -width 1.5 \
        -tags {gridLine gridObject}
  }
  Ticks
}

proc Ticks {} {
  global Graphics Canv Font

  if {$Graphics(ticks,on)==0} {
    .c delete gridText gridTick
    return
  }

  .c delete gridText gridTick
  set size [winfo fpixels .c $Graphics(grid,size)]

  if {$size<2} {
    return
  }

  set m [expr int($Canv(SW)/$size)]
  set n [expr int($Canv(SH)/$size)]
  
  for {set i 1} {$i<=$m} {incr i} {
    set Xnum [expr $i*$size+3]
    set Xtick [expr $i*$size]
    .c create text $Xnum 3 \
        -font $Font(gridTicks) \
        -text $i \
        -fill red \
        -anchor nw \
        -tags {gridText gridObject}
    .c create line $Xtick 0 $Xtick 4 \
        -width 2 \
        -fill red \
        -tags {gridTick gridObject}
  }
  
  for {set i 1} {$i<=$n} {incr i} {
    set Ynum [expr $i*$size+3]
    set Ytick [expr $i*$size]
    .c create text 3 $Ynum\
        -font $Font(gridTicks) \
        -text $i \
        -fill red \
        -anchor nw \
        -tags {gridText gridObject}
    .c create line 0 $Ytick 4 $Ytick \
        -width 2 \
        -fill red \
        -tags {gridTick gridObject}
  }
}


####### FILE SECTION: NEW, OPEN, SAVE, EXIT, ...
set File(pic,name) ""
set File(eps,name) ""
set File(new) 1
set File(saved) 1
#set File(progress) 0

set File(pic,types) {
   {{tcl pic} {.pic} }
   {{All files} * }
}

set File(eps,types) {
   {{EPS file} {.eps} }
   {{All files} * }
}

set File(wd) [pwd]


proc File {cmnd args} {
global File Graphics Canv utagCounter TextInfo Image Zoom

cleanupCanvas
cd $File(wd)

switch -exact -- $cmnd {
   getname {
       set mode        [lindex $args 0]
       set type        [lindex $args 1]
       set title       [lindex $args 2]
       set defaultName [lindex $args 3]
       if {$mode=="save"} { set command tk_getSaveFile }
       if {$mode=="open"} { set command tk_getOpenFile }
       set filename [$command \
                -title "$title" \
                -filetypes $File($type,types) \
                -initialfile $defaultName \
                -defaultextension ".$type" ]
       if {$filename==""} {return 0}
       set File($type,name) $filename
       set File(wd) [file dirname $File(pic,name)]
       return 1
   }

   new {
       if {$File(saved)==0} {
         File close
         return
       }
       resetCanvas
       set File(pic,name) ""
       set File(eps,name) ""
       set File(new) 1
       set File(saved) 1
       set Graphics(mode) NULL
   }

   open {
       if {$File(saved)==0  &&  [File close]==0} {
         return
       }
       if ![File getname open pic "Open a Tcl pic file" ""] {
         return
       }
       resetCanvas
       if {[catch {uplevel #0 [list source $File(pic,name)]} result] !=0} {
       set answer [tk_messageBox -type yesno \
             -message "Pic file $File(pic,name) has an error: $result\n\
It is advised that you restart tkpaint.\n\
Would you like to exit tkpaint?" \
           -icon warning \
           -title "TkPaint: File \"$File(pic,name)\" has error" \
           -default yes]
      if {$answer=="yes"} {exit}
   }
       set File(eps,name) ""
       set File(saved) 1
       set File(new) 0
   }

   close {
       if {$File(new)==1} {
         return
       }
       if {$File(saved)==1} {
         File new
         return 1
       }

       switch [tk_messageBox -type yesnocancel \
                -message "Current work was not saved !\nSave now ?" \
                -icon question \
                -title "TkPaint: save file?" \
                -default yes] {
          yes {
                if {$File(pic,name)==""
                       && ![File getname save pic "Save as a Tcl pic file" \
                       untitled.pic] } {
                   return 0
                }
                File write pic
                set File(saved) 1
                File new
                return 1
          }

          no {
                set File(saved) 1
                File new
                return 1
          }

          cancel {
            return 0
          }
       }
   }

   save {
       set type [lindex $args 0]

       switch -exact -- $type {

            pic {
              if ![File getname save pic "Save a Tcl pic file" $File(pic,name)] {
                 return
              }
              File write pic
              set File(progress) 0
              set File(saved) 1
              Message "File was saved to disk"
            }

            eps {
              if {$File(pic,name)==""} {
                set File(eps,name) "untitled.eps"
              } else {
                set File(eps,name) [file rootname $File(pic,name)].eps
              }
              if ![File getname save eps "Save as Encapsulated PostScript File" $File(eps,name)] {
                return
              }
              File write eps
            }

            auto {
              if {$File(pic,name)=="" &&
                  ![File getname save pic "Save a Tcl pic file" untitled.pic]} {
                return
              }
              File write pic
              set File(progress) 0
              set File(saved) 1
              Message "File was saved to disk"
            }
       }
   }

   write {
       set type [lindex $args 0]

       if {$type=="eps"} {
         set dimens [eval .c bbox [.c find withtag obj]]
         set x1 [lindex $dimens 0]
         set x2 [lindex $dimens 2]
         set y1 [lindex $dimens 1]
         set y2 [lindex $dimens 3]
         set h [expr $y2-$y1]
         set w [expr $x2-$x1]
         .c postscript -file $File(eps,name) \
                       -x $x1 \
                       -y $y1 \
                       -width $w \
                       -height $h \
                       -pagewidth 19c
         #return
       }

       if {$type=="pic"} {
         set fd [open $File(pic,name) w]
         foreach name [lsort [array names Graphics]] {
            puts $fd [list set Graphics($name) $Graphics($name)]
         }
         puts $fd {set Graphics(mode) NULL}
         puts $fd "### End of Graphics parameters\n\n"
         foreach name [lsort [array names Zoom]] {
            puts $fd [list set Zoom($name) $Zoom($name)]
         }
         puts $fd "set utagCounter $utagCounter\n\n"
         puts $fd "set Image(ctr) $Image(ctr)\n\n"
         puts $fd "set Canv(H) $Canv(H)"
         puts $fd "set Canv(W) $Canv(W)"
         puts $fd "set Canv(SH) $Canv(SH)"
         puts $fd "set Canv(SW) $Canv(SW)"
         puts $fd "set Canv(bg) $Canv(bg)"
         puts $fd {.c config -width $Canv(W) \
              -height $Canv(H) \
              -bg $Canv(bg) \
              -scrollregion "0 0 $Canv(SW) $Canv(SH)"}
         puts $fd {wm geometry . ""}
         puts $fd ".c xview moveto 0"
         puts $fd ".c yview moveto 0"

         foreach name [array names TextInfo] {
            puts $fd [list set TextInfo($name) $TextInfo($name)]
         }

         if {[llength $Image(hist)]>0} {
             puts $fd "set Image(hist) \{"
             foreach cmd $Image(hist) {
                puts $fd "    \"$cmd\""
             }
             puts $fd "\}\n"
             foreach cmd $Image(hist) {
                puts $fd $cmd
             }
         }

         foreach id [.c find withtag obj] {
            puts $fd [getObjectCommand $id 1]
         }
         close $fd
         #return
      }
   }

   exit  {
       if {$File(saved)==1} {exit}
       if [File close] {exit}
   }

   print  {
       global tcl_platform PS_VIEWER
       if {$File(new)==1} {return}
       if {$File(pic,name) != ""} {
         set File(eps,name) [file rootname $File(pic,name)].eps
       } else {
         set File(eps,name) printout.eps
       }
       File write eps
       if {$tcl_platform(platform)=="windows"} {
         if {$tcl_platform(os)=="Windows 95" ||
             $tcl_platform(os)=="Windows 98"} {
            set cmnd [list exec start $File(eps,name)]
         } else {
            set cmnd [list exec cmd.exe /c start $File(eps,name)]
         }
       } else {
         set cmnd [list exec $PS_VIEWER $File(eps,name)]
       }
       if [catch $cmnd err] {
         tk_messageBox -type ok \
                -message "$err\n You need gsview program to print!\
                          It looks like you don't have it. Sorry." \
                -icon warning \
                -title "TkPaint: can't print" \
                -default ok
       }
   }
}
} ;# end of File proc

###### HELP SECTION

proc About {} {
   global Font tkpaint_ver LIBDIR
   toplevel .about
   wm protocol .about WM_DELETE_WINDOW {.about.dismiss invoke}
   wm transient .about .
   wm resizable .about 0 0
   #wm iconify .
   wm geometry .about +250+150
   focus .about
   wm title .about "About tkpaint"
   label .about.l \
         -image [image create photo -file [file join $LIBDIR gifs TclTk.gif]] \
         -relief raised \
         -bd 2 \
         -bg white
   pack .about.l -padx 10 -pady 5

   set text "TKPaint\n"

   label .about.msg -width 45 -justify center \
               -font $Font(about) \
               -text $text
   pack .about.msg -pady 5
   button .about.dismiss -text Dismiss \
               -bd 2 \
               -command {grab release .about ; destroy .about}
   pack .about.dismiss -ipadx 3
   grab set .about
   #tkwait window .about.dismiss
}

proc balloon { w text } {
   global Balloon
   set x [expr [winfo rootx $w] + int(0.8*[winfo width $w])]
   set y [expr [winfo rooty $w] + int(0.8*[winfo height $w])]
   regsub -all {\.} $w _ temp 
   set Balloon($w,name) .balloon$temp
   set b $Balloon($w,name)
   set job1  "toplevel $b -bg black
        wm geometry $b +$x+$y 
        wm overrideredirect $b 1
        label $b.label -text \"$text\" \
                   -relief flat \
                   -bg #ffffaa \
                   -fg black \
                   -padx 2 \
                   -pady 0 \
                   -anchor w
         pack $b.label  -side left \
                   -padx 1 \
                   -pady 1
         set Balloon($w,job2) [after 5000 [list catch [list destroy $b]]]
   "
   set Balloon($w,job1) [after 1500 "$job1"]
}

set ButtonsHelp { 
  0  0  rectangle.gif   "Draw a rectangle"
  0  1  roundrect.gif   "Draw a rounded rectangle"
  0  2  circle.gif      "Draw a circle"
  0  3  ellipse.gif     "Draw an ellipse"
  0  4  polygon.gif     "Draw a polygon"
  0  5  polyline.gif    "Draw lines"
  0  6  spline.gif      "Draw a spline"
  0  7  cspline.gif     "Draw a closed spline"
  0  8  arc.gif         "Draw an arc (of a circle)"
  0  9  pieslice.gif    "Draw a pie slice (of a circle)"
  0 10  chord.gif       "Draw a chord (of a circle)"
  0 11  freehand.gif    "Draw a free hand line"
  1  0  text.gif        "Insert text"
  1  1  move.gif        "Move an object"
  1  2  copy.gif        "Copy an object"
  1  3  erase.gif       "Erase an object"
  1  4  raise.gif       "Raise an object"
  1  5  lower.gif       "Lower an object"
  1  6  arrows.gif      "Put arrows on lines"
  1  7  grid.gif        "Toggle a 1cm grid"
  1  8  reconf.gif      "Edit a group of objects"
  1  9  undo.gif        "Undo last change"
  1 10  unundo.gif      "Undo last undo"
  1 11  savefile.gif    "Save file to disk"
  0 12  bold.gif        "Bold style text"
  0 13  underline.gif   "Undeline style text"
  0 14  italic.gif      "Italic style text"
  1 12  lefta.gif       "Left justified text"
  1 13  centera.gif     "Center text"
  1 14  righta.gif      "Right justified text"
}

foreach {row col dummy text} $ButtonsHelp {
   set w .tools.button${row}_$col
   bind $w <Enter> [list balloon %W $text]
   bind $w  <Leave>  {catch {
       after cancel $Balloon(%W,job1)
       after cancel $Balloon(%W,job2)
       destroy $Balloon(%W,name)
      }
   }
}

bind  .tools.but_outline  <Enter> {
     balloon %W  "Choose line color"
}

bind  .tools.but_outline  <Leave> {catch {
       after cancel $Balloon(%W,job1)
       after cancel $Balloon(%W,job2)
       destroy $Balloon(%W,name)
   }
}

bind  .tools.but_fill  <Enter> {
     balloon %W  "Choose fill color"
}

bind  .tools.but_fill  <Leave> {catch {
       after cancel $Balloon(%W,job1)
       after cancel $Balloon(%W,job2)
       destroy $Balloon(%W,name)
   }
}

########### Status Bar:
frame .statbar
grid config .statbar -column 0 -row 3 \
        -columnspan 1 -rowspan 1 -sticky "snew" -ipadx 1 -ipady 1

label .statbar.coords -textvariable Canv(pointerxy) \
      -bd 1 \
      -width 9 \
      -anchor w \
      -relief sunken
pack .statbar.coords -side left -padx 1 -pady 1

label .statbar.mode -textvariable Graphics(mode) \
      -bd 1 \
      -width 13 \
      -anchor w \
      -relief sunken
pack .statbar.mode -side left -padx 1 -pady 0.5

label .statbar.font -textvariable Graphics(font,type) \
      -bd 1 \
      -width 15 \
      -anchor w \
      -relief sunken
pack .statbar.font -side left -padx 1 -pady 0.5

label .statbar.fontsize -textvariable Graphics(font,size) \
      -bd 1 \
      -width 3 \
      -anchor e \
      -relief sunken
pack .statbar.fontsize -side left -padx 1 -pady 0.5

label .statbar.fontstyle -textvariable Graphics(font,style) \
      -bd 1 \
      -width 18 \
      -anchor w \
      -relief sunken
pack .statbar.fontstyle -side left -padx 1 -pady 0.5

entry .statbar.message -textvariable Message(text) \
      -bd 1 \
      -width 40 \
      -state disabled \
      -relief sunken
pack .statbar.message -side left -fill x -expand 1
#pack .statbar.message -side left -padx 1 -pady 0.5 -fill x -expand 1

################ End of Status bar


#########  VARIABLE TRACING

proc Traces {mode} {
   global Graphics undoMode File
   set traceList {
     Graphics(line,width)    w   traceProc1
     Graphics(line,width)    w   traceProc1.1
     Graphics(line,capstyle) w   traceProc1.1
     Graphics(line,color)    w   traceProc1.1
     Graphics(line,style)    w   traceProc1.2
     Graphics(line,dash)     w   traceProc1.3
     Graphics(fill,color)    w   traceProc2
     Graphics(line,color)    w   traceProc3
     Graphics(mode)          w   traceProc4
     Graphics(font,style)    w   traceProc5
     Graphics(grid,on)       w   traceProc6
     Graphics(grid,size)     w   traceProc6
     Graphics(ticks,on)      w   traceProc6
     Graphics(font,color)    w   traceProc7
     undoMode                w   traceProc9
     File(pic,name)          w   traceProc10
   }

   switch $mode {
      enable {
         foreach {var op proc} $traceList {
            trace variable $var $op $proc
         }
      }
      disable {
         foreach {var op proc} $traceList {
            trace vdelete $var $op $proc
         }
      }
   }
}

Traces enable

proc traceProc1 {v index op} {
  global Graphics
  if {$Graphics(line,width)==0} {
    set Graphics(line,color,save) $Graphics(line,color)
    set Graphics(line,color) {}
  }
  if {$Graphics(line,width)!=0 && [info exists Graphics(line,color,save)]} {
    set Graphics(line,color) $Graphics(line,color,save)
    unset Graphics(line,color,save)
  }
}

proc traceProc1.1 {v index op} {
  global Graphics
  .tools.widthcanvas itemconfig demoLine -width $Graphics(line,width) \
               -fill $Graphics(line,color) \
               -stipple $Graphics(line,style) \
               -capstyle $Graphics(line,capstyle)
}

proc traceProc1.2 {v index op} {
  global Graphics
  if {$Graphics(line,style)=="solid"} {
    set Graphics(line,style) {}
  }
}

proc traceProc1.3 {v index op} {
  global Graphics
  if {$Graphics(line,dash)=="NONE"} {
    set Graphics(line,dash) {}
  }
}

proc traceProc2 {v index op} {
  global Graphics
  if {$Graphics(fill,color)==""} {
    set color gray75
  } else {
    set color $Graphics(fill,color)
  }
  .tools.fr_fill configure -bg $color
  update
}

proc traceProc3 {v index op} {
  global Graphics
  .tools.fr_outline configure -bg $Graphics(line,color)
  update
}

proc traceProc4 {v index op} {
  global Graphics Polygon Line Arc Text TextInfo Reshape

  .c delete arrowHandle reshapeHandle arcMark

  if {[info exists Polygon(coords)] && [llength $Polygon(coords)]>=6} {
    makePolygon
    Message "Next time remember to close polygon! (right click)"
  }

  if [info exists Polygon] {
     catch {.c delete $Polygon(tempLine)}
     unset Polygon
  }

  if [info exists Line] {
    makeLine
    Message "Next time remember to finish line! (right click)"
  }

  if [info exists Arc] {
    unset Arc
    Message "You have started an ARC object but did not finish with it!"
  }

  if [info exists Reshape] {
    if [info exists Reshape(undo)] {
         Undo add $Reshape(undo)
    }
    unset Reshape
  }

  .c raise gridObject

  if [info exists Text] {
    foreach event [.c bind text] {
       .c bind text $event {}
    }
    TextHist
    .c focus {}
    .c select clear
  }
  catch {unset TextInfo(TextBackSpace) TextInfo(TextBackSpaceCmd)}
  if [info exists TextInfo(TextBackSpace)] {
      unset TextInfo(TextBackSpace) TextInfo(TextBackSpaceCmd)
      foreach event [.c bind text] {
         .c bind text $event {}
      }
      .c focus {}
      .c select clear
  }
  if [info exists TextInfo(TextDelete)] {
      unset TextInfo(TextDelete) TextInfo(TextDeleteCmd)
      foreach event [.c bind text] {
         .c bind text $event {}
      }
      .c focus {}
      .c select clear
  }

  .c delete graybox
  .c configure -cursor ""
  unselectGroup
  
  foreach b [bind .c] {
     bind .c $b {}
  }
  Bindings enable
}

proc traceProc5 {v index op} {
  global Graphics
  foreach s {normal bold italic underline overstrike roman} {
     if {[lsearch $Graphics(font,style) $s] >= 0} {
       set Graphics(font,$s) 1
     } else {
       set Graphics(font,$s) 0
     }
  }
}

proc traceProc6 {v index op} {
  Grid
  Ticks
}

proc traceProc7 {v index op} {
  global Graphics
  .statbar.font config -fg $Graphics(font,color)
}

proc traceProc9 {v index op} {
  global Polygon Line Text undoMode Graphics Reshape

  if {$Graphics(mode)=="Arrows"} {
    set Graphics(mode) NULL
   .c delete arrowHandle
    catch {unset arrowsInfo}
  }

  .c delete arcMark reshapeHandle graybox

  if {[info exists Polygon(coords)] && [llength $Polygon(coords)]>=6} {
    makePolygon
  }

  if [info exists Polygon] {
     catch {.c delete $Polygon(tempLine)}
     unset Polygon
  }

  if [info exists Line] {
    makeLine
  }

  if [info exists Reshape] {
    unset Reshape
  }

  .c raise gridObject

  if [info exists Text] {
    .c focus {}
    .c select clear
    TextHist
  }

  #.c configure -cursor ""
  unselectGroup

  set undoMode 0
}

proc traceProc10 {v index op} {
  global File tkpaint_ver
  if {$File(pic,name)==""} {
    wm title . "Tkpaint $tkpaint_ver - new file"
  } else {
    wm title . "Tkpaint $tkpaint_ver - $File(pic,name)"
  }
}


########## MENU BAR KEY BINDINGS:
bind all <Alt-Key-f> { tkMbPost .mbar.file }
bind all <Alt-Key-s> { tkMbPost .mbar.shape }
bind all <Alt-Key-e> { tkMbPost .mbar.edit }
bind all <Alt-Key-l> { tkMbPost .mbar.line }
bind all <Alt-Key-i> { tkMbPost .mbar.image }
bind all <Alt-Key-i> { tkMbPost .mbar.fill }
bind all <Alt-Key-e> { tkMbPost .mbar.edit}
bind all <Alt-Key-g> { tkMbPost .mbar.group}
bind all <Alt-Key-r> { tkMbPost .mbar.grid}
bind all <Alt-Key-t> { tkMbPost .mbar.text}
bind all <Alt-Key-h> { tkMbPost .mbar.help}
########## ACCELERATORS:
bind all <Control-Key-u> {.mbar.edit.menu invoke "Undo last change"}
bind all <Control-Key-l> {.mbar.edit.menu invoke "Undo last undo"}
bind all <Control-Key-s> {.mbar.group.menu invoke "Select group"}
bind all <Control-Key-a> {.mbar.group.menu invoke "Select all"}
bind all <Control-Key-c> {.mbar.group.menu invoke "Copy group"}
bind all <Control-Key-r> {.mbar.group.menu invoke "Rotate group"}
bind all <Control-Key-e> {.mbar.group.menu invoke "Deform group"}
bind all <Control-Key-h> {.mbar.group.menu invoke "Horizontal reflection"}
bind all <Control-Key-v> {.mbar.group.menu invoke "Vertical reflection"}
bind all <Control-Key-d> {.mbar.group.menu invoke "Delete group"}
bind all <Control-Key-n> {.mbar.file.menu invoke "New"}
bind all <Control-Key-o> {.mbar.file.menu invoke "Open"}
bind all <Control-Key-x> {.mbar.file.menu invoke "Exit"}
bind all <Control-Key-f> {.mbar.text.menu invoke "Choose font"}
bind all <Control-Key-z> {
    if {$Zoom(factor)<5} {
         set z [expr $Zoom(factor)+0.5]
    } else {
         set z 0.5
    }
    Zoom $z
}

###### HANDLING COMMAND LINE ARGUMENT:
# If the user supplied a command line argument (file name) we check
# and source this file. Only the 1st arg (if any) is handled.

update
dashbug

rename dashbug {}
puts "Processing command line args"
if {$argc>=1} {
  set fileName [lindex $argv 0]
  if ![file exists $fileName] {
       tk_messageBox -type ok \
             -message "$fileName: File does not exist." \
             -parent . \
             -icon warning \
             -title "TkPaint: error" \
             -default ok
#    Message "$fileName: File does not exist."
  } else {
      source $fileName
      set File(pic,name) $fileName
      set File(new) 0
      Message "loaded $fileName"
  }
  unset fileName
}
