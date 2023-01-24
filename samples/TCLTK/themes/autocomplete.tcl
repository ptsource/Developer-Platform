#
# $Id: autocomplete.tcl,v 1.1 2005/01/28 01:25:19 muonics Exp $
#
# Demonstration of inline auto-completion for Tile combobox widgets.
#
# Usage:
#
#	enableAutoComplete path ?presorted?
#
#	path may be an individual window to enable auto-completion for only
#	that window, or TCombobox to enable it for all comboboxes.
#
#	By default, the values list is assumed to be pre-sorted to optimize
#	the search.  If it is not presorted, pass 0 in for the second arg,
#	and the list will be sorted before the search at the cost of some
#	overhead.
#

namespace eval tile::combobox {
	namespace export enableAutocomplete
}

## enableAutocomplete
#
#	Enable inline auto-completion for the specified combobox widget.
#
proc tile::combobox::enableAutocomplete { w {presorted 1} } {
	bind $w <KeyPress> [namespace code [list DoAutoComplete %W %A $presorted]]
}

## DoAutoComplete
#
#	Perform inline auto-completion of typed text in the combobox.
#
proc tile::combobox::DoAutoComplete { w s presorted } {
    set old [$w get]
    tile::entry::Insert $w $s
    set new [$w get]

    # Only auto-complete if the string length has changed due to insertion.

    if {[string length $old] != [string length $new]} {
       	set values [$w cget -values]

		if {!$presorted} {
			set values [lsort -dictionary $values]
		}

        set match [lsearch -inline $values $new*]

        if {[string length $match]} {
            $w delete 0 end
            $w insert end $match
            $w selection range [string length $new] end
            $w icursor [string length $new]
        }
    }
}

