#!/bin/sh
# \
# exec wish8.0 $0 ${1+"$@"} || exec wish $0 ${1+"$@"} || exit 1


# Originally written by Donald K. Fellows (fellows@cs.man.ac.uk)
# who deserves the full credit for this nice work.
# Little changes made by Samy Zafrany (samy@netanya.ac.il).
# These include font color selection button, more font size radiobuttons
# and other cosmetic fixups.
# I needed those changes for my tkpaint program in which this module is used.

namespace eval szdkfFontSel {
    # First some library stuff that is normally in another namespace
    proc parseopts {arglist optlist optarray} {
	upvar $optarray options
	set options(foo) {}
	unset options(foo)
	set callername [lindex [info level -1] 0]
	if {[llength $arglist]&1} {
	    return -code error \
		    "Must be an even number of arguments to $callername"
	}
	array set options $arglist
	foreach key [array names options] {
	    if {![string match -?* $key]} {
		return -code error "All parameter keys must start\
			with \"-\", but \"$key\" doesn't"
	    }
	    if {[lsearch -exact $optlist $key] < 0} {
		return -code error "Bad parameter \"$key\""
	    }
	}
    }

    proc capitalise {word} {
	set cUpper [string toupper [string index $word 0]]
	set cLower [string tolower [string range $word 1 end]]
	return ${cUpper}${cLower}
    }

    proc map {script list} {
	set newlist {}
	foreach item $list {
	    lappend newlist [uplevel 1 $script [list $item]]
	}
	return $newlist
    }

    # ----------------------------------------------------------------------
    # Now we start in earnest
    namespace export dkf_chooseFont

    global tcl_platform
    if {$tcl_platform(platform)=="windows"} {
         variable Family Arial
    } else {
         variable Family Helvetica
    }
    variable Size   12
    variable Color  black
    variable colorFrame {}
    variable Done   0
    variable Win    {}

    array set Style {
	bold 0
	italic 0
	underline 0
	overstrike 0
    }

    proc make_UI {w} {
        variable Color
        variable colorFrame
	label $w._testing
	set gap [expr {[font metrics [$w._testing cget -font] -linespace]/2+1}]
	destroy $w._testing
	#set gap [winfo pixels $w 2m]

	frame $w.border1 -class DKFChooseFontFrame
	frame $w.border2 -class DKFChooseFontFrame
	frame $w.border3 -class DKFChooseFontFrame
	frame $w.border4 -class DKFChooseFontFrame
	frame $w.border5 -class DKFChooseFontFrame
	grid $w.border1 -row 0 -column 0 -rowspan 6 -columnspan 4 \
		-padx $gap -pady $gap -sticky nsew
	grid $w.border2 -row 0 -column 4 -rowspan 6 -columnspan 3 \
		-padx $gap -pady $gap -sticky nsew
	grid $w.border3 -row 0 -column 7 -rowspan 6 -columnspan 3 \
		-padx $gap -pady $gap -sticky nsew
	grid $w.border4 -row 6 -column 0 -rowspan 3 -columnspan 12 \
		-padx $gap -pady $gap -sticky nsew
	grid $w.border5 -row 9 -column 0 -rowspan 4 -columnspan 12 \
		-padx $gap -pady $gap -sticky nsew
	incr gap $gap
	foreach col {0 3 4 6 7 9 10} {
	    grid columnconfig $w $col -minsize $gap
	}
	foreach row {0 5 6 8 9 11} {
	    grid rowconfig   $w $row -minsize $gap
	}
	foreach col {1 5 8 11} {
	    grid columnconfig  $w $col -weight 1
	}
	grid row $w 10 -weight 1

	label $w.lblFamily
        label $w.lblStyle
        label $w.lblColor
	label $w.lblSize
        label $w.lblSample
	foreach {subname row col} {
	    Family  0 1
	    Style   0 5
	    Color   0 8
	    Size    6 1
	    Sample  9 1
	} {
	    grid $w.lbl$subname -row $row -column $col -sticky w
	}

	frame $w.familyBox
	listbox $w.family -exportsel 0 -selectmode single \
		-xscrollcommand [list $w.familyX set] \
		-yscrollcommand [list $w.familyY set]
	scrollbar $w.familyX -command [list $w.family xview]
	scrollbar $w.familyY -command [list $w.family yview]
	foreach family [listFamilies] {
	    $w.family insert end [map capitalise $family]
	}
	grid $w.familyBox -row 1 -column 1 -rowspan 4 -columnspan 2 \
		-sticky nsew
	grid columnconfig $w.familyBox 0 -weight 1
	grid rowconfig    $w.familyBox 0 -weight 1
	grid $w.family  $w.familyY -sticky nsew -in $w.familyBox
	grid $w.familyX            -sticky nsew -in $w.familyBox
	bind $w.family <1> [namespace code {
	    set Family [%W get [%W nearest %y]]
	    setfont
	}]

	foreach {fontstyle lcstyle row} {
	    Bold bold 1
	    Italic italic 2
	    Underline underline 3
	    Strikeout overstrike 4
	} {
	    set b $w.style$fontstyle
	    checkbutton $b -variable [namespace current]::Style($lcstyle) \
		    -command [namespace code setfont]
	    grid $b -row $row -column 5 -sticky nsew
	}

### Added by Samy:
   frame $w.color
   grid $w.color -row 1 -column 8 -rowspan 4 -columnspan 1 \
		-sticky nsew
   button $w.color.but -text Choose \
         -command [namespace code chooseFontColor]
   frame  $w.color.sample -height 50 -bg $Color
   set colorFrame $w.color.sample
   pack $w.color.but $w.color.sample -side bottom -fill x


	frame $w.size
	grid $w.size -row 7 -column 1 -rowspan 1 -columnspan 10 -sticky nsew
	foreach {size row col} {
	    8  0 0
	    10 1 0
	    12 0 1
	    14 1 1
	    16 0 2
	    18 1 2
	    21 0 3
	    24 1 3
	    27 0 4
	    30 1 4
	    36 0 5
	    40 1 5
	} {
	    set b $w.size.b$size
	    radiobutton $b -variable [namespace current]::Size -value $size \
		    -command [namespace code setfont]
	    grid $b -row $row -column $col -sticky ew
	    #grid column $w.size $col -weight 1
	}
	entry $w.size.entry -textvariable [namespace current]::Size -width 6
	grid $w.size.entry -row 0 -column 6 -rowspan 2 -sticky ew
	set colwidth [expr 1.25*[winfo reqwidth $w.size.b40]]
        foreach c {0 1 2 3 4 5} {
           grid columnconfig $w.size $c -minsize $colwidth
        }
	grid column $w.size 6 -weight 1
	bind $w.size.entry <Return> \
		[namespace code {setfont;break}]

	frame $w.sample
	grid $w.sample -row 10 -rowspan 1 -column 1 -columnspan 10 -sticky nsew
	grid propagate $w.sample 0
	label $w.sample.text
	grid $w.sample.text

	frame $w.butnframe
	grid $w.butnframe -row 0 -column 10 -rowspan 6 -columnspan 2 \
		-sticky nsew -pady $gap
	foreach {but code} {
	    ok  0
	    can 1
	} {
	    button $w.butnframe.$but -command \
		    [namespace code [list set Done $code]]
	    pack $w.butnframe.$but -side top -fill x -padx [expr {$gap/2}]
	}
	grid rowconfig $w 1 -weight 1
    }

    proc setfont {} {
	variable Family
	variable Style
	variable Size
	variable Color
	variable Win
 
	set styles {}
	foreach style {italic bold underline overstrike} {
	    if {$Style($style)} {
		lappend styles $style
	    }
	}
	if {[catch {
	    expr {$Size+0}
	    if {[llength $styles]} {
		$Win configure -font [list $Family $Size $styles] -fg $Color
	    } else {
		$Win configure -font [list $Family $Size] -fg $Color
	    }
	} s]} {
	    bgerror $s
	    return 1
	}
	return 0
    }

    proc listFamilies {} {
	return [lsort [string tolower [font families]]]
    }

    # ----------------------------------------------------------------------

    proc dkf_chooseFont {args} {
	variable Family
	variable Style
	variable Size
	variable Color
	variable Done
	variable Win
        variable dkfpath

	array set options {
	    -parent {}
	    -title {Select a font}
	    -initialfont {$Family 12 {}}
	    -initialColor black
	}
	parseopts $args {-parent -title -initialfont -initialColor} options
	switch -exact -- $options(-parent) {
	    . -
            {} {
		set parent .
		set dkfpath .__dkf_chooseFont
		set w $dkfpath
	    }
	    default {
		set parent $options(-parent)
		set dkfpath $options(-parent).__dkf_chooseFont
		set w $dkfpath
	    }
	}
        set Color $options(-initialColor)
	catch {destroy $w}

	toplevel $w -class DKFChooseFont
	wm title $w $options(-title)
 	#wm transient $w $parent
	wm iconname $w ChooseFont
	wm group $w $parent
	#wm protocol $w WM_DELETE_WINDOW {#}
        wm protocol $w WM_DELETE_WINDOW [list destroy $w \; return \"\"]
        #bind $w <FocusOut> "raise $w; focus -force $w"
        #bind $w <Visibility> "raise $w; focus -force $w"
        grab set $w

	set Win $w.sample.text
	make_UI $w
	bind $w <Return>  [namespace code {set Done 0}]
	bind $w <Escape>  [namespace code {set Done 1}]
	bind $w <Destroy> [namespace code {set Done 1}]
	focus $w.butnframe.ok

	foreach style {italic bold underline overstrike} {
	    set Style($style) 0
	}
	foreach {family size styles} $options(-initialfont) {break}
	set Family $family
	set familyIndex [lsearch -exact [listFamilies] \
		[string tolower $family]]
	if {$familyIndex<0} {
            bind $w <FocusOut> {}
	    set Family [lindex [listFamilies] 0]
	    set familyIndex 0
	    tk_messageBox -title Error -message \
	       "Cannot find font family \"$family\", substituting \"$Family\""\
	       -type ok 
            raise $w
            bind $w <FocusOut> "raise $w; focus -force $w"
	}
	$w.family selection set $familyIndex
	$w.family see $familyIndex
	set Size $size
	foreach style $styles {set Style($style) 1}

	setfont

	wm withdraw $w
	update idletasks
	if {$options(-parent)==""} {
	    set x [expr {([winfo screenwidth $w]-[winfo reqwidth $w])/2}]
	    set y [expr {([winfo screenheigh $w]-[winfo reqheigh $w])/2}]
	} else {
	    set pw $options(-parent)
	    set x [expr {[winfo x $pw]+
                         ([winfo width $pw]-[winfo reqwidth $w])/2}]
	    set y [expr {[winfo y $pw]+
                         ([winfo heigh $pw]-[winfo reqheigh $w])/2}]
	}
#	wm geometry $w +$x+$y
	wm geometry $w +0+0
	update idletasks
	wm deiconify $w
	tkwait visibility $w
#        grab set $w
#        raise $w
	vwait [namespace current]::Done
	if {$Done} {
	    destroy $w
	    return ""
	}
	if {[setfont]} {
	    destroy $w
	    return ""
	}
	set font [$Win cget -font]
	set Color [$Win cget -fg]
	destroy $w
	return [list $font $Color]
    }

    proc chooseFontColor {} {
       variable Color 
       variable colorFrame
       variable Win
       variable dkfpath

       set save [bind $dkfpath <FocusOut>]
       bind $dkfpath <FocusOut> {}
       set oldColor $Color
       set Color [tk_chooseColor -initialcolor $Color \
                              -title "Choose Font Color"]
       if {[string length $Color]==0} {set Color $oldColor}
       $colorFrame config -bg $Color
       $Win config -fg $Color
       raise $dkfpath
       bind $dkfpath <FocusOut> $save
       focus $dkfpath.butnframe.ok
       return $Color
    }

    # ----------------------------------------------------------------------
    # I normally load these from a file, but I inline them here for portability
    foreach {pattern value} {
	*DKFChooseFont*Button.BorderWidth      1
	*DKFChooseFont*Checkbutton.BorderWidth 1
	*DKFChooseFont*Entry.BorderWidth       1
	*DKFChooseFont*Label.BorderWidth       1
	*DKFChooseFont*Listbox.BorderWidth     1
	*DKFChooseFont*Menu.BorderWidth        1
	*DKFChooseFont*Menubutton.BorderWidth  1
	*DKFChooseFont*Message.BorderWidth     1
	*DKFChooseFont*Radiobutton.BorderWidth 1
	*DKFChooseFont*Scale.BorderWidth       1
	*DKFChooseFont*Scrollbar.BorderWidth   1
	*DKFChooseFont*Text.BorderWidth        1
	*DKFChooseFont.DKFChooseFontFrame.borderWidth 2
	*DKFChooseFont.DKFChooseFontFrame.relief      ridge
	*DKFChooseFont.lblFamily.text 	       Family
	*DKFChooseFont.lblStyle.text  	       Style
	*DKFChooseFont.lblColor.text  	       Color
	*DKFChooseFont.lblSize.text   	       Size
	*DKFChooseFont.lblSample.text 	       Sample
	*DKFChooseFont.Label.padX              1m
	*DKFChooseFont.Label.padY              1
	*DKFChooseFont.Radiobutton.anchor      w
	*DKFChooseFont.Checkbutton.anchor      w
	*DKFChooseFont.family.height           1
	*DKFChooseFont.family.width            20
	*DKFChooseFont.familyX.orient 	       horizontal
	*DKFChooseFont.familyX.width  	       16
	*DKFChooseFont.familyY.width  	       16
	*DKFChooseFont.styleBold.text 	       Bold
	*DKFChooseFont.styleItalic.text        Italic
	*DKFChooseFont.styleUnderline.text     Underline
	*DKFChooseFont.styleStrikeout.text     Overstrike
	*DKFChooseFont.size.b8.text            8
	*DKFChooseFont.size.b10.text           10
	*DKFChooseFont.size.b12.text           12
	*DKFChooseFont.size.b14.text           14
	*DKFChooseFont.size.b16.text           16
	*DKFChooseFont.size.b18.text           18
	*DKFChooseFont.size.b21.text           21
	*DKFChooseFont.size.b24.text           24
	*DKFChooseFont.size.b27.text           27
	*DKFChooseFont.size.b30.text           30
	*DKFChooseFont.size.b36.text           36
	*DKFChooseFont.size.b40.text           40
	*DKFChooseFont.size.Radiobutton.anchor w
	*DKFChooseFont.size.Entry.background   white
	*DKFChooseFont.sample.text.text	       ABCabcXYZxyz12345
	*DKFChooseFont.sample.height           60
	*DKFChooseFont.sample.width            40
	*DKFChooseFont.butnframe.ok.default    active
	*DKFChooseFont.butnframe.ok.text       OK
	*DKFChooseFont.butnframe.can.text      Cancel
    } {
	option add $pattern $value startupFile
    }
}
namespace import szdkfFontSel::dkf_chooseFont

# ----------------------------------------------------------------------
# Stuff for testing the font selector
# wm deiconify .; update
# use after idle here to put errors into a dialog for testing...
# after idle {puts [dkf_chooseFont]}
