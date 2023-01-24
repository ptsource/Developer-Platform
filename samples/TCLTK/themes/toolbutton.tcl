#
# $Id: toolbutton.tcl,v 1.6 2006/11/06 02:30:49 jenglish Exp $
#
# Demonstration of custom widget styles.
#

#
# ~ BACKGROUND
#
# Checkbuttons in toolbars have a very different appearance 
# than regular checkbuttons: there's no indicator, they
# "pop up" when the mouse is over them, and they appear sunken
# when selected.
# 
# Tk added partial support for toolbar-style buttons in 8.4 
# with the "-overrelief" option, and TIP #82 added further
# support with the "-offrelief" option.  So to get a toolbar-style 
# checkbutton, you can configure it with:
#
# checkbutton .cb \
#     -indicatoron false -selectcolor {} -relief flat -overrelief raised -offrelief flat
#
# Behind the scenes, Tk has a lot of rather complicated logic
# to implement this checkbutton style; see library/button.tcl,
# generic/tkButton.c, and the platform-specific files unix/tkUnixButton.c
# et al. for the full details.
#
# The tile widget set has a better way: custom styles.
# Since the appearance is completely controlled by the theme engine,
# we can define a new "Toolbutton" style and just use:
#
# checkbutton .cb -style Toolbutton
#
#
# ~ DEMONSTRATION
#
# The tile built-in themes (default, "alt", windows, and XP) 
# already include Toolbutton styles.  This script will add
# them to the "step" theme as a demonstration.
#
# (Note: Pushbuttons and radiobuttons can also use the "Toolbutton" 
# style; see demo.tcl.)
#

ttk::style theme settings "step" {

#
# First, we use [ttk::style layout] to define what elements to
# use and how they're arranged.  Toolbuttons are pretty
# simple, consisting of a border, some internal padding,
# and a label.  (See also the TScrollbar layout definition 
# in demos/blue.tcl for a more complicated layout spec.)
#
    ttk::style layout Toolbutton {
        Toolbutton.border -children {
            Toolbutton.padding -children {
                Toolbutton.label
            }
        }
    }

# (Actually the above isn't strictly necessary, since the same layout 
# is defined in the default theme; we could have inherited it 
# instead.)
#
# Next, specify default values for element options.
# For many options (like -background), the defaults
# inherited from the parent style are sufficient.
#
    ttk::style configure Toolbutton \
    	-width 0 -padding 1 -relief flat -borderwidth 2

#
# Finally, use [ttk::style map] to specify state-specific 
# resource values.  We want a flat relief if the widget is
# disabled, sunken if it's selected (on) or pressed, 
# and raised when it's active (the mouse pointer is
# over the widget).  Each state-value pair is checked
# in order, and the first matching state takes precedence.
#
    ttk::style map Toolbutton -relief {
	disabled 	flat
    	selected	sunken  
	pressed 	sunken  
	active		raised
    }
}

#
# ~ A final note:  
#
# TIP #82 also says: "When -indicatoron is off and the button itself
# is on, the relief continues to be hard-coded to sunken. For symmetry,
# we might consider adding another -onrelief option to cover this
# case. But it is difficult to imagine ever wanting to change the
# value of -onrelief so it has been omitted from this TIP.
# If there as strong desire to have -onrelief, it can be added later."
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
#
# The Tile project aims to make sure that this never needs to happen.
#
