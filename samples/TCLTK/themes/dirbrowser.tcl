#
# $Id: dirbrowser.tcl,v 1.2 2004/10/05 23:42:07 jenglish Exp $
#
# treeview widget demonstration.
#
#

lappend auto_path ../generic ..
package require tile

# Create a treeview widget:
#
set f [ttk::frame .f]
ttk::scrollbar $f.vsb -orient vertical -command [list $f.tv yview]

set tv [ttk::treeview $f.tv -columns {size mtime} \
	-yscrollcommand [list $f.vsb set] ]

grid $f.tv $f.vsb -sticky news
grid columnconfigure $f 0 -weight 1
grid rowconfigure $f 0 -weight 1

#
# Set column headings:
#
# Column #0 is the tree colum.
#
$tv heading #0 -text "Name" -command [list sortBy $tv #0]
$tv heading size -text "Size" -command [list sortBy $tv size]
$tv heading mtime -text "Modified" -command [list sortBy $tv mtime]

$tv column size -anchor e
$tv column mtime -anchor e

#
# Create some images to use as tree icons:
# (images taken from tkfbox.tcl)
#

foreach {icon data} {
    folder {R0lGODlhEAAMAKEAAAD//wAAAPD/gAAAACH5\
	    BAEAAAAALAAAAAAQAAwAAAIghINhyycvVFsB\
	    QtmS3rjaH1Hg141WaT5ouprt2HHcUgAAOw==}
    file   {R0lGODlhDAAMAKEAALLA3AAAAP//8wAAACH5\
    	    BAEAAAAALAAAAAAMAAwAAAIgRI4Ha+IfWHsO\
	    rSASvJTGhnhcV3EJlo3kh53ltF5nAhQAOw==}
} {
    set Icons($icon) [image create photo -data $data]
}

# scanDirectory -- 
#	Scan a directory and add items to the treeview widget.
#
#	To prevent a long initial delay, subdirectories are
#	scanned "on demand" in the <<TreeviewOpen>> binding.
#	The "Pending" array holds a script to be evaluated
#	when an item is first opened.
#
proc scanDirectory {tv parent dir} {
    variable Icons
    variable Pending

    foreach subdir [glob -nocomplain -type d -directory $dir *] {
        set item [$tv insert $parent end \
		-text [file tail $subdir] -image $Icons(folder) \
		-values [list {} [datestamp [file mtime $subdir]] ] ]
	set Pending($item) [list scanDirectory $tv $item $subdir]
    }
    foreach file [glob -nocomplain -type f -directory $dir *] {

	set item [$tv insert $parent end \
		-text [file tail $file] -image $Icons(file)]

    	$tv set $item size [file size $file]
    	$tv set $item mtime [datestamp [file mtime $file]]
    }
}

bind $tv <<TreeviewOpen>> { itemOpened %W }

proc itemOpened {w} {
    variable Pending
    set item [$w focus]
    if {[info exists Pending($item)]} {
    	uplevel #0 $Pending($item)
	unset Pending($item)
    }
}

# scanAll --
#	Force the tree to be fully populated, by repeatedly
#	evaluating the contents of the Pending array.
#
proc scanAll {} {
    variable Pending
    . configure -cursor watch
    while {[llength [set pending [array get Pending]]]} {
    	array unset Pending
	foreach {_ script} $pending { uplevel #0 $script }
    }
    . configure -cursor {}
}

# openAll --
#	Recursively open all nodes in the tree.
#
proc openAll {tv {item {}}} {
    foreach child [$tv children $item] {
	$tv item $child -open true
	openAll $tv $child
    }
}

# datestamp --
#	Convert clock values to a human-readable format
#
proc datestamp {clockValue} {
    variable clockfmt "%Y-%m-%d %H:%M"
    clock format $clockValue -format $clockfmt
}

# sortBy --
#	Sort the children of each item by the specified column,
#	or by the -text label if $column is {}.
#
proc sortBy {tv column {parent {}}} {
    foreach child [$tv children $parent] {
	sortBy $tv $column $child
    }
    set items [list]
    if {$column eq "#0"} {
	# Sort by -text label:
	foreach child [$tv children $parent] {
	    lappend items [list $child [$tv item $child -text]]
	}
    } else {
	foreach child [$tv children $parent] {
	    lappend items [list $child [$tv set $child $column]]
	}
    }

    set children [list]
    foreach item [lsort -dictionary -index 1 $items] {
	lappend children [lindex $item 0]
    }
    $tv children $parent $children
}

# Rest of GUI.
#
set cmd [ttk::frame .cmd]
grid x \
    [ttk::button $cmd.open -text "Open all" -command [list openAll $tv]] \
    [ttk::button $cmd.scan -text "Scan all" -command {scanAll} ] \
    [ttk::button $cmd.close -text "Close" -command [list destroy .]] \
    -padx 6 ;
grid columnconfigure $cmd 0 -weight 1

bind . <KeyPress-Escape> [list event generate $cmd.close <<Invoke>>]

pack $cmd -side bottom -expand false -fill x -padx 6 -pady 6
pack $f -side top -expand true -fill both

# Load the initial directory:
#
scanDirectory $tv {} ~

