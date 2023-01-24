#===================================
#               HELP.TCL FOR TKPAINT.TCL
#===================================

proc Help { } {
   catch {destroy .msg .help}
   global help
   toplevel .help
   #wm transient .help .
   wm resizable .help 0 0
   wm geometry .help +0+0
   focus .help
   wm title .help "Tkpaint Help"
   wm protocol .help WM_DELETE_WINDOW {destroy .msg .help}
   set font {Helvetica 12}
   #set font {"Times New Roman" 12}

## Help Widget

   frame .help.textFrame
   scrollbar .help.s -orient vertical \
           -command {.help.t yview} \
           -highlightthickness 0 \
           -takefocus 1
   pack .help.s -in .help.textFrame \
           -side right \
           -fill y
   text .help.t -yscrollcommand {.help.s set} \
           -wrap word \
           -width 60 \
           -height 19 \
           -font $font \
           -setgrid 1 \
           -highlightthickness 0 \
           -padx 4 \
           -pady 2 \
           -takefocus 0
   pack .help.t -in .help.textFrame \
           -expand y \
           -fill both \
           -padx 1
   pack .help.textFrame -expand yes \
              -fill both

#### Help Tags

   .help.t tag configure title -font {Helvetica 18 bold}
   .help.t tag configure helpspace -lmargin1 1c -lmargin2 1c
   .help.t tag configure help -lmargin1 1c \
            -lmargin2 1c \
            -foreground blue \
            -underline 1
   .help.t tag configure visited -lmargin1 1c \
            -lmargin2 1c \
            -foreground #303080 \
            -underline 1
   .help.t tag configure hot -foreground red -underline 1

#..................... Help Binds

   .help.t tag bind help <ButtonRelease-1> {
         invoke [.help.t index {@%x,%y}]
   }
   set lastLine ""

   .help.t tag bind help <Enter> {
      set lastLine [.help.t index {@%x,%y linestart}]
      .help.t tag add hot "$lastLine +1 chars" "$lastLine lineend -1 chars"
      .help.t config -cursor hand2
   }

   .help.t tag bind help <Leave> {
      .help.t tag remove hot 1.0 end
      .help.t config -cursor xterm
   }

   .help.t tag bind help <Motion> {
      set newLine [.help.t index {@%x,%y linestart}]
      if {[string compare $newLine $lastLine]} {
        .help.t tag remove hot 1.0 end
        set lastLine $newLine
        set tags [.help.t tag names {@%x,%y}]
        set i [lsearch -glob $tags help-*]
        if {$i >= 0} {
          .help.t tag add hot "$lastLine +1 chars" "$lastLine lineend -1 chars"
         }
      }
   }

#   bind .help <Destroy> {.buttons.buttons1.help config -relief raised}

#..................... Help Text

.help.t insert end "Tkpaint overview\n" title
.help.t insert end "Tkpaint is a graphics utility based on the canvas\
widget of the tool command language Tcl/Tk.\
You can draw a variety of two dimensional geometrical objects with it:\
polygon, rectangle, circle, ellipse, spline, arc, chord, pie slice, and\
free hand curves.\
You can select fill and outline colors.\
It is possible to draw text in any font, size, color, and stipple.\
The canvas environment of Tcl/Tk is based on objects,\
which means that every shape, line, text item, or image\
are treated as an undivisible units.\
All actions are performed on these objects:\
you can create, move, copy, raise, lower, and delete\
each object as a graphical unit.\n
However, in this application it is also possible to select a group of objects
and perform various actions on all the objects in the group: edit their outline
width and color, edit their interiour color, scale, reflect with respect\
to the x or y-axis and even rotate the group\
to any desired angle.\n"

#----------- Topics

set topics {
"Rectangle"                 {help help-rectangle}
"Circle"                    {help help-circle}
"Ellipse"                   {help help-ellipse}
"Line"                      {help help-line}
"Polygon"                   {help help-polygon}
"Spline"                    {help help-spline}
"Closed spline"             {help help-cspline}
"Arc"                       {help help-arc}
"Chord"                     {help help-chord}
"Pieslice"                 {help help-pieslice}
"Text"                     {help help-text}
"Image"                    {help help-image}
"Fill color"               {help help-fill}
"Raise object"             {help help-raise}
"Lower object"             {help help-lower}
"Delete object"            {help help-erase}
"Reshape polygone/line"    {help help-reshape}
"Move object"              {help help-move}
"Copy object"              {help help-copy}
"Undo last change"         {help help-undo}
"Undo last undo"           {help help-undo-undo}
"Arrows"                   {help help-arrows}
"Arrow shape"              {help help-arrowshape}
"Grid"                     {help help-grid}
"Group"                    {help help-group}
"Move a group of objects"     {help help-move-group}
"Scale a group of objects"    {help help-scale-group}
"Copy a group of objects"     {help help-copy-group}
"Raise a group of objects"    {help help-raise-group}
"Lower a group of objects"    {help help-lower-group}
"Rotate a group of objects"   {help help-rotate-group}
"Deform a group of objects"   {help help-deform-group}
"Horizontal reflection"       {help help-hreflection}
"Vertical reflection"         {help help-vreflection}
"Delete a group of objects"   {help help-delete-group}
"Edit line width"             {help help-group-line-width}
"Edit line color"             {help help-group-line-color}
"Edit fill color"             {help help-group-fill-color}
"Scrolling the canvas"        {help help-canvas-scroll}
"preferences"                 {help help-preferences}
}

set i 0

foreach {feature script} $topics {
   incr i
   .help.t insert end [format "%-6s%s" "$i." "$feature"] $script
   .help.t insert end " \n "   {helpspace}
}

.help.t configure -state disabled
}

proc invoke {index} {
   global HelpMsg 
   set tags [.help.t tag names $index]
   set i [lsearch -glob $tags help-*]
   if {$i < 0} {
     return
   }
   set cursor [.help.t cget -cursor]
   .help.t configure -cursor watch
   update
   set help [string range [lindex $tags $i] 5 end]
   catch {msg $HelpMsg($help) $help}
   update
   .help.t configure -cursor $cursor
   .help.t tag add visited "$index linestart +1 chars" \
                           "$index lineend -1 chars"
}

proc msg {message title} {
   catch {destroy .msg}
   toplevel .msg
   focus -force .msg
#   wm transient .msg .
   wm resizable .msg 0 0
   wm group .msg .help
   wm title .msg "$title Help"
   wm geometry .msg -0+0
   message .msg.m -width 10c \
            -text $message \
            -font {Courier 12} \
            -bg #ffffaa \
            -relief sunken \
            -bd 1
   pack .msg.m
}
   

#..................... Help Messages

set helpmessages {
rectangle
{Select rectangle button or choose from the shape
menu. Click the mouse left button for the first corner and drag until
you get the desired rectangle shape. Release mouse left button to.}

circle
{Press circle button (or choose "Circle" from the "Shape" menu). \
Click left mouse button for the circle's center. \
Drag the mouse to extend the circle. \
Right mouse button release terminates a segment. \
Release left mouse button to finish.}

ellipse
{Press ellipse button. (or choose "Ellipse" from the "Shape" menu). \
Look at the "circle" help.}

line
{Press line button. (or choose "Line" from the "Shape" menu). \
Click left mouse button to start each line segment. \
Drag the mouse to get the desired line segment. \
Left mouse button release terminates a segment. \
To finish: click right mouse button.}

polygon
{Press polygon button. (or choose "Polygon" from the "Shape" menu). \
The routine is identical to that of "line", \
except that a right mouse button click is need to close the polygon.}

spline
{Press spline button (or choose "Spline" from the shape menu). \
The routine is identical to that of "line", \
execpt that you get curved lines instead of straight lines.}

cspline
{Press closed spline button (or choose "Close spline" from the shape menu). \
The routine is identical to that of "Spline", \
except that a right mouse button click is need to close the shape.}

arc
{Press arc button (or choose "Arc" from the shape menu). \
Click left mouse button to get the first end point P1. \
Second left mouse button click to get the second end point P2. \
Press and hold left mouse button to get an intermediate point P3. \
Assuming that P1, P2, and P3 do no lie on the same line, there is \
exactly one arc that passes through the points P1, P2, and P3. \
This arc will be drawn. Drag the mouse until you get the desired arc, \
and then release.}

chord
{Press chord button (or choose "Chord" from the shape menu). \
The routine is identical to that of "arc", \
except that whene you are done you end up with a chord.}

pieslice
{Press pieslice button (or choose "Pieslice" from the shape menu). \
The routine is identical to that of "arc", \
except that whene you are done you end up with a pieslice.}

text
{Press T button (or choose "Draw text" from the text menu). \
Click left mouse button at the point that you want to insert text. \
Use the "B", "U", or "I" buttons for Bold, Underlined, or Italic
style text. Below this buttons are the left, center, \
and right justify buttons. \
Use the "Font" menu button for selecting font with all its attributes \
(size, style, color, and stipple).
In text mode you may use the following bindings:
<Button-3>  paste (Ctrl-V)
<<Cut>>     cut   (Ctrl-X)
<<Copy>>    copy  (Ctrl-C)
<<Paste>>   paste (Ctrl-V)
<Delete>    delete selected text
<Control-h> backspace
<Control-Delete> erase text
<Return>    newline
<Key-Right> move cursor right
<Control-f> move cursor right
<Key-Left>  move cursor left
<Control-b> move cursor left}

image
{From the "Image" menu choose "GIF", "Bitmap", "PPM", or "PGM" \
(the other formats are available only if the Img package was installed). \
A file dialog window will pop up. Select the graphic image file. \
Click left mouse button on the canvas to insert the image. \
The click point corresponds to the upper left corner of the image. \
Foreground and background colors of bitmap images can be edited via \
the "Edit" menu.\
Note that images cannot be resized or zoomed.\
If you need them in different size or colors, you will have to do it\
via some other program before you load them. \
There are no plans to add to tkpaint raster operations on images!}

fill
{Press "Fill" menu button.
Any closed shape can be filled with color and in addition may filling \
can be stippled with one of Tk's existing gray stipples. \
Choose "Style" for stipple style, "Color" for fill color, and \
"No color" for a transparent fill.}

raise
{Press "raise" button (or choose "Raise object" from the "Edit" menu). \
A left mouse button click on an object will put it at the top of the display \
list. That means that it will cover any object that intersects it.}

lower
{Press "lower" button (or choose "Lower object" from the "Edit" menu). \
A left mouse button click on an object will put it at the bottom of the \
display list. That means that it will be covered by any object that \
intersects it. \
Note that for unfilled circle, rectangle, and ellipse objects, you need \
to click their borders.}

erase
{Press "Eraser" button \
(or choose "Delete object" from the "Edit" menu). \
A left mouse button click on an object will delete it from the canvas. \
Note that for unfilled circle, rectangle, and ellipse objects, you need \
to click their borders. \
If you made a mistake, you can always bring back the object with the \
undo command.}

move
{Press "Mover" button \
(or choose "Move object" from the "Edit" menu). \
Hold mouse left button on the object \
you want to move. As you drag the mouse, the object \
moves. Releasing mouse button will place the object.
Note that for unfilled circle, rectangle, and ellipse objects, you need \
to click their borders.}

copy
{Press the "Copy" button \
(or choose "Copy object" from the "Edit" menu). \
Hold mouse left button on the object \
you want to copy. As you drag the mouse, the original \
object is not touched, but an exact copy of it is \
being draged by the mouse. releasing mouse button \
will place the new copy on the canvas. \
Note that for unfilled circle, rectangle, and ellipse objects, you need \
to click their borders.}

reshape
{With this feature you can edit lines and polygons. \
From the "edit" menu click "Reshape polygon/line". \
This puts you in "Reshape mode". \
Now choose a polygon or a line by clicking on it. \
Black squares will be drawn on each vertex of the line/polygon. \
You can drag with the mouse each of this black squares and thus \
changing the vertex position. \
You can add new vertices by control-click on an existing vertex. \
The new vertex will come to life nearby. \
To delete a vertex: Alt-click on the vertex.
Remember that smooth lines and polygons can be edited too!}

undo
{Press the "Undo" button \
(or choose "Undo last change" from the "Edit" menu). \
The effect is to cancel the last operation.}

undo-undo
{Press the "Cancel undo" button \
(or choose "Undo last undo" from the "Edit" menu). \
The effect is to cancel the last undo operation.}

arrows
{Press the "Arrows" button \
(or choose "Arrows" from the "Line" menu). \
A small circle will be drawn at each endpoint of each open line \
on the canvas. \
Click left mouse button on a circle to get an arrow \
at the corresponding endpoint if it does not exists or to cancel \
an existing arrow.}

arrowshape
{Choose "Arrow shape" from the "Line" menu. \
An arrowhead editor window should pop up. \
Design your favourite arrow head shape with this tool, and then \
click the "Apply" button.}

grid
{Press the "Grid" button to toggle a 1cm grid.
For a larger variety of grids, press the "Grid" menu button. \
This menu also has a cascade menu for grid-spacing sizes.
Picking one of those, each canvas coordinate will be rounded to the \
nearest multiple of the chosen unit. \
This is useful for accurate drawing, where you want to make sure that lines
or shape meet at certain points.}

group
{The group menu allows one to perform more complex actions on a selected \
group of objects, rather than do one simple action on a single object \
as the "Edit" menu provides. \
Before attempting any action on a group of objects \
(or on all the objects of the canvas) you must select the objects first \
by clicking on the "Select group", "Select all", or \
"Select 1 object". \
It should be stressed that the "Group" menu is equally useful for \
manipulating single objects. Some of the actions provided by the "Group" \
menu are not available via the "Edit" menu. \
A single object can be selected in the normal way (surrounding it by a \
selection box) or by clicking on "Select 1 object" and then clicking \
on the object to select it. Sometimes this is necessary since it can \
be impossible \
to surround the object without including other objects that we do not \
want to edit.}

move-group
{From the "Group" menu, first press "Select group" to enter group mode. \
Select a group of objects by drawing a rectangle around the group. \
This rectangle must contain each object completely. \
A gray box will be drawn, covering all the selected objects. \
Click and hold left mouse button inside the gray box, and drag the group \
to the new location.}

scale-group
{From the "Group" menu, first press "Select group" to enter group mode. \
Select a group of objects by drawing a rectangle around the group. \
This rectangle must contain each object completely. \
A gray box will be drawn, covering all the selected objects. \
This gray box has eight small handles. \
Click and hold left mouse button inside one of those handles, \
and scale the group by dragging the mouse.}

copy-group
{From the "Group" menu, first press "Select group" to enter group mode. \
Select a group of objects by drawing a rectangle around the group. \
This rectangle must contain each object completely. \
A gray box will be drawn, covering all the selected objects. \
Go back to the "Group" menu and select "Copy group". \
Click left mouse button to get an identical copy of your group of \
objects. The new group will be selected (covered with the gray box), and
can be further manipulated via the "Group" menu.}

raise-group
{From the "Group" menu, first press "Select group" to enter group mode. \
Select a group of objects by drawing a rectangle around the group. \
This rectangle must contain each object completely. \
A gray box will be drawn, covering all the selected objects. \
Go back to the "Group" menu and select "Raise group". \
Click left mouse button to raise all the selected objects to the top of \
the display list.}

lower-group
{From the "Group" menu, first press "Select group" to enter group mode. \
Select a group of objects by drawing a rectangle around the group. \
This rectangle must contain each object completely. \
A gray box will be drawn, covering all the selected objects. \
Go back to the "Group" menu and select "Lower group". \
Click left mouse button to lower all the selected objects to the bottom of \
the display list.}

rotate-group
{From the "Group" menu, first press "Select group" to enter group mode. \
Select a group of objects by drawing a rectangle around the group. \
This rectangle must surround each object completely. \
A gray box will be drawn, covering all the selected objects. \
Go back to the "Group" menu and choose "Rotate group". \
Choose the rotation center by clicking and holding \
the left mouse button. Drag the mouse \
to get the rotation angle (relative to the positive x-axis).}

deform-group
{From the "Group" menu, first press "Select group" to enter group mode. \
Select a group of objects by drawing a rectangle around the group. \
This rectangle must contain each object completely. \
A gray box will be drawn, covering all the selected objects. \
Go back to the "Group" menu and choose "Deform group". \
Drag one of the 4 handles (the small gray boxes on the sides of the \
big gray box) \
to change the inclination of the group of objects. Hard to describe, try it! \
You can always press undo.}

hreflection
{From the "Group" menu, first press "Select group" to enter group mode. \
Select a group of objects by drawing a rectangle around the group. \
This rectangle must contain each object completely. \
A gray box will be drawn, covering all the selected objects. \
Go back to the "Group" menu and click "Horizontal reflection".}

vreflection
{From the "Group" menu, first press "Select group" to enter group mode. \
Select a group of objects by drawing a rectangle around the group. \
This rectangle must contain each object completely. \
A gray box will be drawn, covering all the selected objects. \
Go back to the "Group" menu and click "Vertical reflection".}

delete-group
{From the "Group" menu, first press "Select group" to enter group mode. \
Select a group of objects by drawing a rectangle around the group. \
This rectangle must contain each object completely. \
A gray box will be drawn, covering all the selected objects. \
Go back to the "Group" menu and select "Delete group". \
Click left mouse button inside the gray box to \
delete all the selected objects.}

group-line-width
{From the "Group" menu, first press "Select group" to enter group mode. \
Select a group of objects by drawing a rectangle around the group. \
This rectangle must contain each object completely. \
A gray box will be drawn, covering all the selected objects. \
Go back to the "Group" menu and select "Edit line width". \
A line width scale will pop-up. Use the scale to determine the desired \
line width. All the selected objects will be affected.}

group-line-color
{From the "Group" menu, first press "Select group" to enter group mode. \
Select a group of objects by drawing a rectangle around the group. \
This rectangle must contain each object completely. \
A gray box will be drawn, covering all the selected objects. \
Go back to the "Group" menu and select "Edit line color". \
A color box dialog will pop-up. Choose the desired line color.\
All the selected objects will be affected.}

group-fill-color
{From the "Group" menu, first press "Select group" to enter group mode. \
Select a group of objects by drawing a rectangle around the group. \
This rectangle must contain each object completely. \
A gray box will be drawn, covering all the selected objects. \
Go back to the "Group" menu and select "Edit fill color". \
A color box dialog will pop-up. Choose the desired fill color.\
All the selected objects will be affected.}

canvas-scroll
{The canvas maximum size is 1500 pixels wide and 1500 high. Only part of it is \
viewable at any time. To move to other regions of the canvas:
Control-RightArrow   Move right
Control-LeftArrow    Move left
Control-UpArrow      Move up
Control-DownArrow    Move down
Alt-RightArrow       Move right 1 page
Alt-LeftArrow        Move left 1 page
Alt-UpArrow          Move up 1 page
Alt-DownArrow        Move down 1 page
Page-down            Move down 1 page
Page-up              Move up 1 page
Home                 Move to home
End                  Move to bottom of canvas.
Control-Page-down    Stretch the canvas height by 30 pixels
Control-Page-up      Stretch the canvas width by 30 pixels}

preferences
{It is possible to save your current graphics parameters into files \
or load saved prefernces from files.  The default preferences file is \
"tkpaint.ini". Tkpaint will load this file when it starts if it exists. \
You may delete this file without any risk if you like. In this case, \
tkpaint will always start with the most basic graphics parameters. \
To load a preferences file go to the "File" menu and choose "Preferences". \
You may load any existing preferences file or save the current configuration \
to any file you wish. \
The user may choose multiple files for saving different sets of preferences, \
and load them whenever he wants to (even at the midst of work). \
It is also easy to edit them by hand and thus making it possible to choose \
special parameters that are hard to get via the menus of tkpaint (like a \
huge arrow shape, precise color numbers, grid parameters, etc).}
}

foreach {topic message} $helpmessages {
    set HelpMsg($topic)  $message
}
