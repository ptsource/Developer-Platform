#
# test/demo script for dialog.tcl
#

package require tile

array set DLG {
    icon	question
    title	"Quit..."
    message	"Are you sure you want to quit?"
    detail	"Quitting the application will cause it to stop running. \
    		 You will lose any unsaved data, and make the application \
		 feel unloved.  Please consider leaving it open."
}

proc displayDialog {} {
    variable DLG

    if {[winfo exists .dlg]} { ttk::dialog::dismiss .dlg }

    ttk::dialog .dlg \
	-icon $DLG(icon) \
	-title $DLG(title) \
	-message $DLG(message) \
	-detail $DLG(detail) \
    	-type yesnocancel \
	-default yes \
	-cancel cancel \
	;

    if {0} {
	set f [ttk::dialog::clientframe .dlg]
	pack [ttk::progressbar $f.progress -value 50] -expand false -fill x
	tile::progressbar::start $f.progress
    }
}

# displayMessageBox --
#	Display standard Tk mesageDialog, for comparison.
#
proc displayMessageBox {} {
    variable DLG
    tk_messageBox -parent . \
	-type yesnocancel \
	-icon $DLG(icon) \
	-title $DLG(title) \
	-message $DLG(message) \
	-detail $DLG(detail) \
	-default yes \
	;
}


proc dialogDemo {t} {
    variable DLG

    ttk::frame $t
    set f [ttk::frame $t.f]
    foreach field {title message detail} { 
	grid \
	    [ttk::label $f.l$field -text "[string totitle $field]:" -anchor e] \
	    [ttk::entry $f.$field -textvariable ::DLG($field) -width 60] \
	-sticky new -padx 3
    }

    grid \
    	[ttk::label $f.licon -text "Icon:" -anchor e] \
        [ttk::combobox $f.icon -state readonly -textvariable DLG(icon) \
		-values [list info question warning error]] \
    -sticky new -padx 3

    grid columnconfigure $f 0 -weight 1
    grid columnconfigure $f 1 -weight 5
    grid rowconfigure $f 99 -weight 1

    set cmd [ttk::frame $t.cmd]
    grid x \
    	[ttk::button $cmd.go -text "Display" -command displayDialog] \
    	[ttk::button $cmd.alt -text "Message" -command displayMessageBox] \
	[ttk::button $cmd.quit -text "Close" \
		-command [list destroy [winfo toplevel $t]]] \
	-padx [list 6 0] -pady 6 -sticky ew;
    grid columnconfigure $cmd 0 -weight 1
    bind . <KeyPress-Escape> [list event generate $cmd.quit <<Invoke>>]
    keynav::defaultButton $cmd.go

    pack $t.cmd -side bottom -expand false -fill x -padx 6 -pady 6
    pack $t.f -side top -expand true -fill both -padx 12 -pady 12

    return $t
}

proc dlgtest-main {} {
    pack [dialogDemo .t] -expand true -fill both
}

if {[info exists argv0] && $argv0 eq [info script]} { dlgtest-main }
