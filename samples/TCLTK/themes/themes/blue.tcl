# blue.tcl - Copyright (C) 2004 Pat Thoyts <patthoyts@users.sourceforge.net>
#
# $Id: blue.tcl,v 1.35 2007/05/19 21:55:41 patthoyts Exp $
#
#

namespace eval ttk::theme::blue {

    package provide ttk::theme::blue 0.8

    variable I
    variable imgdir [file join [file dirname [info script]] blue]
    foreach file [glob $imgdir/*.gif] {
	set I([file root [file tail $file]]) [image create photo -file $file]
    }

    variable colors
    array set colors {
	-frame  	"#6699cc"
	-lighter	"#bcd2e8"
	-window	 	"#e6f3ff"
	-selectbg	"#ffff33"
	-selectfg	"#000000"
	-disabledfg	"#666666"
    }

    ttk::style theme create blue -settings {

	ttk::style configure . \
	    -borderwidth 	1 \
	    -background 	$colors(-frame) \
	    -fieldbackground	$colors(-window) \
	    -troughcolor	$colors(-lighter) \
	    -selectbackground	$colors(-selectbg) \
	    -selectforeground	$colors(-selectfg) \
	    ;
	ttk::style map . -foreground [list disabled $colors(-disabledfg)]

	## Buttons.
	#
	ttk::style configure TButton -padding "10 0"
	ttk::style layout TButton {
	    Button.button -children {
		Button.focus -children {
		    Button.padding -children {
			Button.label
		    }
		}
	    }
	}

	ttk::style element create button image \
            [list $I(button-n) \
                 pressed $I(button-p)  active $I(button-h)] \
	    -border 4 -sticky ew

	ttk::style element create Checkbutton.indicator image \
            [list $I(check-nu) \
                 {!disabled active selected} $I(check-hc) \
                 {!disabled active} $I(check-hu) \
                 {!disabled selected} $I(check-nc) ] \
            -width 24 -sticky w

	ttk::style element create Radiobutton.indicator image \
            [list $I(radio-nu) \
                 {!disabled active selected} $I(radio-hc) \
                 {!disabled active} $I(radio-hu) \
                 selected $I(radio-nc) ] \
	    -width 24 -sticky w


	ttk::style configure TMenubutton -relief raised -padding {10 2}
	ttk::style configure TRadiobutton -padding 1
	ttk::style configure TCheckbutton -padding 1

	## Toolbar buttons.
	#
	ttk::style configure Toolbutton \
	    -width 0 -relief flat -borderwidth 2 -padding 4 \
	    -background $colors(-frame) -foreground #000000 ;
	ttk::style map Toolbutton -background [list active $colors(-selectbg)] 
	ttk::style map Toolbutton -foreground [list active $colors(-selectfg)] 
	ttk::style map Toolbutton -relief {
	    disabled 	flat
	    selected	sunken  
	    pressed 	sunken  
	    active  	raised
	}

	## Entry widgets.
	#
	ttk::style configure TEntry \
	    -selectborderwidth 1 -padding 2 -insertwidth 2 -font TkTextFont
	ttk::style configure TCombobox \
	    -selectborderwidth 1 -padding 2 -insertwidth 2 -font TkTextFont
        ttk::style configure TSpinbox \
            -selectborderwidth 1 -padding {2 2 2 12} -insertwidth 2 \
            -font TkTextFont -arrowsize 10
        
	## Notebooks.
	#
        ttk::style element create tab image \
            [list $I(tab-n) selected $I(tab-h) active $I(tab-h)] \
            -border {2 2 2 0}
        ttk::style configure TNotebook -padding 2 -tabmargins {2 2 2 0}
        ttk::style map TNotebook.Tab -expand [list active {2 0 2 0} selected {2 0 2 0}]

	## Labelframes.
	#
	ttk::style configure TLabelframe -borderwidth 2 -relief groove

	## Scrollbars.
	#
	ttk::style layout Vertical.TScrollbar {
	    Scrollbar.trough -children {
		Scrollbar.uparrow -side top
		Scrollbar.downarrow -side bottom
		Scrollbar.uparrow -side bottom
		Vertical.Scrollbar.thumb -side top -expand true -sticky ns
	    }
	}

	ttk::style layout Horizontal.TScrollbar {
	    Scrollbar.trough -children {
		Scrollbar.leftarrow -side left
		Scrollbar.rightarrow -side right
		Scrollbar.leftarrow -side right
		Horizontal.Scrollbar.thumb -side left -expand true -sticky we
	    }
	}

	ttk::style element create Horizontal.Scrollbar.thumb image \
            [list $I(sb-thumb) {pressed !disabled} $I(sb-thumb-p)] \
            -border 3

	ttk::style element create Vertical.Scrollbar.thumb image \
            [list $I(sb-vthumb) {pressed !disabled} $I(sb-vthumb-p)] \
            -border 3

	foreach dir {up down left right} {
	    ttk::style element create ${dir}arrow image \
                [list $I(arrow${dir}) \
                     disabled $I(arrow${dir}) \
                     pressed $I(arrow${dir}-p) \
                     active $I(arrow${dir}-h)] \
	        -border 1 -sticky {}
	}

	## Scales.
	#
	ttk::style element create Scale.slider image \
            [list $I(slider) {pressed !disabled} $I(slider-p)]

	ttk::style element create Vertical.Scale.slider image \
            [list $I(vslider) {pressed !disabled} $I(vslider-p)]

        ## Progressbar
        #
        ttk::style element create Horizontal.Progressbar.pbar image \
            [list $I(sb-thumb) {pressed !disabled} $I(sb-thumb-p)] \
            -border 2
        ttk::style element create Vertical.Progressbar.pbar image \
            [list $I(sb-vthumb) {pressed !disabled} $I(sb-vthumb-p)] \
            -border 2

        ## Statusbar parts
        #
        ttk::style element create sizegrip image $I(sizegrip)

        ## Panedwindow parts.
        #
        ttk::style element create hsash image \
            [list $I(hseparator-n) {active !disabled} $I(hseparator-a)] \
            -border {2 0}
        ttk::style element create vsash image \
            [list $I(vseparator-n) {active !disabled} $I(vseparator-a)] \
            -border {0 2}

    	## Treeview.
	#
	ttk::style configure Heading -font TkHeadingFont -relief raised
	ttk::style configure Row -background $colors(-window)
	ttk::style configure Cell -background $colors(-window)
	ttk::style map Row \
	    -background [list selected $colors(-selectbg)] \
	    -foreground [list selected $colors(-selectfg)] ;
	ttk::style map Cell \
	    -background [list selected $colors(-selectbg)] \
	    -foreground [list selected $colors(-selectfg)] ;
	ttk::style map Item \
	    -background [list selected $colors(-selectbg)] \
	    -foreground [list selected $colors(-selectfg)] ;
    }
}

