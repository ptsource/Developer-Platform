#!/bin/sh
# --- plan4tcl a tcl/tk-GUI for netplan --- (c) 2005-2008 Joerg Schulenburg
#
# This is a day planner written in tcl and compatible to the plan and
# netplan program of Thomas Driemeyer (www.bitrot.de).
# It can handle local data files and remote connections to a netplan
# server.
#
# This is an alpha version, please send bug reports to (email, see about).
#
# Why a new plan? Plan4tcl runs where tcl/tk runs (linux, unix, windows).
#
# start:    wish plan4tcl.tcl -geometry 560x400  # large-month view
#           wish plan4tcl.tcl -geometry 324x280  # small-month view
#           wish plan4tcl.tcl -geometry 324x280 -- -l stderr  # log to stderr
# windows:  cp plan4tcl.tcl ~/.wine/drive_c/
#           wine freewrap.exe c:\\plan4tcl.tcl  # turn .tcl into .exe
#           wine plan4tcl.exe -- -l stderr      # test unter wine (no alarm)
#           OR use tclkit.exe plan4tcl.tcl
#           # http://sourceforge.net/projects/freewrap/
#           # freeWrap 6.4 is based on TCL/TK 8.5.0 
#
# dedication:
#   This program was dedicated to my wife and its breastfeed dementia :)
#   Its a dementia coming from the baby who wants to be feeded every
#   two hours during the night.
#
# license:
#   This program is free software; you can redistribute it and/or
#   modify it under the terms of the GNU General Public License
#   as published by the Free Software Foundation; either version 2
#   of the License, or (at your option) any later version.
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
# history:
#   v0.18 - correct TZ problem, alarm 1d to early 2013-11-21
#   v0.17 - correct TZ problem, some dates were shown on the wrong day 2013-11
#   v0.16 - correct TZ problem, some dates were shown on the wrong day 2013-10
#   v0.15 - warnlist wlist integrated to dlist for less complexity 
#           ToDo: remove warnings between tdate-wdays and tdate ???
#           fontsize set per option, remote X still slow (6M/64k:40s)
#   v0.14b - fix 24h to early warning on TZ=:CET, font-- (2012-11-30)
#   v0.14a - replace $time by nowHHMM (2012-11-26)
#   v0.14 - fix problems openSUSE-12.2 showing day+1 LANG=US TZ=CET 2012-11-23
#           clock scan fixed (clock scan ... -format not available until v8.4)
#   v0.13 - fix denied read only access (recv="otr")
#           .netplan-acl: : permit read netmask 255.255.0.0 host 141.44.0.0
#   v0.12 - fix yearly entries not shown in Jan if Dec 31 is shown 
#   v0.11 - display a message if adding empty Note, extend the help
#   v0.10 - Fix bug: next day marked as today if CEST (european sommer time)
#   v0.09 - WinXP timeout Bug? (no such variable $chan) fixed
#   v0.08 - Bug in CloseSockets fixed, Adaption to tclkit-8.4.2 + WinXP problem
#           Problem with Spaces in Config-Filenames under WinXP fixed
#   v0.07 - set repeat days, if only EndDate is set
#   v0.06 - bugs fixed (delete netplan entry flush missed, 1st..5th week)
#   v0.05 - warnday bug removed, day view on left side
#   v0.04 - bugs removed
#   v0.03 - bug fixed writing local file, multiple alarm windows, +timeouts
#   v0.02 - make it more robust against disconnects, colored entries
#   v0.01 - initial version, month layout (took me 3 weeks)
#
#
# ToDo:
#   - keine Alarme bei neuem Jahr! erst nach Neustart (2013-01-10)
#   - test: TZ=:Etc/GMT+12 wish plan4tcl.tcl -- -l stderr # date -14h..+12h
#   - slowness via remote X11 (ssh -X), Tk has lot of X traffic!
#     Tk asks for lot of X11 events, bad bind mechanism
#     its terrible slow because of communication?
#     RX=161kB,693(1M/s),TX=579kB,874(64k/s), tcl/text as fast remote version
#     test: using cstream -t 300k -b 1024
#     but needs another simple and practical UI 
#     simpler text-version? (or list of days -4 ... +14)
#   - reduce double calculations + speedup via remote-X11
#   - problems with firewall/windows
#   - support .holidays, include dayview
#   - support except-entries
#   - script and mails, popup message (include popup options)
#   - warn for unknown/unsupported data entries (not D, not N)
#   - time format for edit 00:00 instead of 0:0:0
#   - support entryD-flags
#   - choose better proc-names
#   - write fallback file for remote data 
#   - support stunnel ?
#   - support copy/move entry to other file
#   - support warning days  and todo-flag 
#   - security/availability of netplan
#      connect authorized via SSL (stunnel)
#      netplan hangs after unfinished "...\\" (and close) ?!
#      remote delete not correct handled by plan 1.8.7
#   - ...
#   - add graphical overview using starttime and length
#       (lines with short description, most compact)
#
# file format:
#   man 4 plan: ~/.dayplan - database file of plan
#
#3/5/1998  99:99:99  0:0:0  0:0:0  0:0:0  ---------- 0 0
##m/d/y  start_h:m:s len_h:m:s warn1 warn2 -P-MYWODt- 0 3  # color+1 warn days?
## P=private show_not_in_MYWOD_view 
#R       0 0 0 0 1                # every year
#R       86400 1125446400 0 0 0   # every 60*60*24s=1d stop_on_unixtime
#R       0 0 16 0 0               # every 2^4=Thu, 2^4+2^1=Mon+Thu (&127)
#R       0 0 544 0 0              # every 2nd Fry of the month (544=2^9+2^5)
#R       0 0 0 18 0               # every 1st+4rd od the months
#R       86400 0 0 0 0            # every day
#E       7/30/2005                # exeption day (one per exception day)
#N       test                     # note
#M       message                  # popup message
#S       echo script              # script
#
# - netplan has 2 leading strings and backslash at the end of line
#   if next line belongs to the same data set
# netplan:
#   debug with sudo /usr/sbin/netplan -vdf   # ToDo: -a ???
#   /usr/local/lib/netplan v2.1
#   telnet netplanserver 2983
#?Error on netplan server univis.urz.uni-magdeburg.de:\
#recognized server commands:\
#(S=success(t|f), V=version, F=file ID, R=row ID)\
#\
#-          -> !SV <msg>         version banner after connect\
#=string    ->                   save optional client self-description\
#t<type>    ->                   set client type: 0=plan, 1=grok\
#m<dname>   -> mS                make directory (not used)\
#o<fname>   -> oSwF              open file, is writable\
#           -> oSrF              open file, is read-only\
#nF         -> nF N              return number of rows in F\
#cF         ->                   close file\
#rF R       -> rSF R <row>       read all (R=0) or one row, multiple replies\
#-          -> RSF R <row>       unsolicited row msg: somebody changed it\
#wF R <row> -> wSR               write one row, R=0: create\
#dF R       ->                   delete a row\
#lF R       -> lS                lock row for editing\
#uF R       ->                   unlock row\
#q          ->                   close connection explicitly\
#L          -> LS<user> ... LS   list of users\
#-          -> ?<msg>            server wants client to put up error popup\
#.          -> .msg              debugging info
# Warning: netplan hangs when line ends with backspace
#          and no further line follows (Weakness?)
#  - numeration for data sets is changing after reopen (reread!)
#   
# this is a multiline comment in wish, but not in sh \
exec wish -f $0 $@

set ver 0.18
wm title . "plan4tcl v$ver"    ;# hier Kommentar nur mit Semikolon


set os  "unknown"
set pc  "localhost"
set cfg ".dayplan"
set user "user"
set home "."   ;# ToDo: what about spaces in file names (win/lx)? or [pwd]
# check for typical linux vars
if [info exists env(HOME)]     { set home "$env(HOME)" }   ;# +lx,-win
if [info exists env(OSTYPE)]   { set os   "$env(OSTYPE)" } ;# -RHlx,-win
if [info exists env(USER)]     { set user $env(USER) }     ;# +lx,-win
if [info exists env(HOSTNAME)] { set pc   $env(HOSTNAME) } ;# +lx
if [info exists env(USERNAME)]     { set user $env(USERNAME) }     ;# +XP
if [info exists env(COMPUTERNAME)] { set pc   $env(COMPUTERNAME) } ;# +XP
if [info exists env(OS) ]          { set os   $env(OS) } ;#  w98: Windows_NT
if { [info exists env(HOMEPATH) ] \
  && [info exists env(HOMEDRIVE)] } {
 set home "$env(HOMEDRIVE)$env(HOMEPATH)" }
# regsub / "[pwd]\\.plan.dir"
# set env(PATH)        "$env(PATH);$env(ORACLE_HOME)\\BIN"

# ToDo: better creating subdir by [file mkdir $home/.plan.dir]?
if {[file isfile      "$home/.dayplan"]} {            ;# SuSE plan-file
             set cfg  "$home/.dayplan" }
#  [file mkdir $home/.plan.dir]                       ;# problems with wine
if {[file isdirectory "$home/.plan.dir"]} {           ;# RedHat plan-file
             set home "$home/.plan.dir"}
if { [file isfile "$home/dayplan"]} { set cfg "$home/dayplan" }
if {![file isfile "$cfg"]} { set cfg  "$home/plan4tcl.cfg" } ;# default 
set fontsize 12    ;# change that per option -f ..., dflt=12
set num_entries 0  ;# number of stored appointment
set numL 0         ;# number of files/(open)sockets
set todolist ""    ;# empty list, todays dates set by ReadFiles

# on Windows output (puts) to stdout does not work, so we create a log-file
# ToDo: switchable by option (set log stderr) OR log to a text-canvas?
set log ""
set logfile "$home/plan4tcl.log"       ;# logfile for this TCL-program
proc Log { msg } {
  global log logfile
  if {"$logfile" == "stderr"} {set log stderr}
  if {"$logfile" == "null"}   {return}
  if {"$log" == ""} {
    if [catch {open "$logfile" w} log] {   ;# "" are important for spaces
      tk_messageBox -icon error -type ok -title "Error Plan4tcl/Log" -message\
        "could not open logfile $logfile for writing, set to stderr"
      set log stderr
    }
  }
  puts  $log "$msg"
  flush $log          ;# no cashing
  # if {"$log" != ""} { catch { close $log } }; set log "" ;# close logfile
}
# on Error open a dialogbox because Windows 
proc Error { msg } {
  tk_messageBox -icon error -type ok -title "Error Plan4tcl"\
    -message "$msg"
  Log "ERROR: $msg"
}

# tk_messageBox does block the application, no other action is possible
# my_messageBox we wont one non blocking window
# call: msgBox ".msg$no" "Help" "No help text available."
proc msgBox { tag title msg } {  
  # tag must be unique and has to be exact one dot int front
  set ww $tag
  catch {destroy $ww}  ;# destroy if called again
  toplevel $ww         ;# create new window
  wm title $ww $title
  label  $ww.txt  -text "$msg" -justify left -anchor nw ;# -width 40
  button $ww.ok   -text "close" -command "destroy $ww"
  pack   $ww.txt $ww.ok -side top
}

# debugging output to logfile (stderr does not work on Windows)
proc DEBUG { msg } {
  Log "DBG: $msg"
}

# encode filename having spaces in it "%" -> "%%" , " " -> "%20" 
proc encode_filename { name } {
  set result [string map {"%" "%%" " " "%20"} "$name"]
  return $result
}
# decode filename having spaces in it "%%" -> "%" , "%20" -> " " 
proc decode_filename { name } {
  set result [string map {"%%" "%" "%20" " "} "$name"]
  return $result
}
# test it:
# puts [decode_filename [encode_filename "C:\\Documents and Programs"]]

# entry out{n+1}.txt can automaticly generated!
if  { $argc } {
 # DEBUG "Plan4tcl num_arguments: $argc   arguments: $argv" ;# Log isnt open
 for {set x 0} {$x < $argc} {incr x} {
   if       { "[lindex $argv $x]" == "-c" && $x+1 < $argc} {
     set cfg  "[lindex $argv [expr $x + 1]]"
     # DEBUG "detect option -c $cfg"
     incr x
   } elseif { "[lindex $argv $x]" == "-l" && $x+1 < $argc} {
     set logfile  "[lindex $argv [expr $x + 1]]"
     if {"$log" != ""} { catch { close $log } }; set log "" ;# close logfile
     DEBUG "detect option -l $logfile"
     incr  x
   } elseif { "[lindex $argv $x]" == "-f" && $x+1 < $argc} {
     set fontsize  "[lindex $argv [expr $x + 1]]"
     DEBUG "detect option -f $fontsize"
     incr  x
   } else {
     # puts does not work on windows, do you now a workaround?
     puts "plan4tcl v$ver -- unsupported option [lindex $argv $x]"
     puts "use: \[wish\] plan4tcl.tcl \[wish-options\] \[-- \[options\]\]"
     puts "options:"
     puts "   -c plan4tcl.cfg  - use other config file (default: ~/.dayplan)"
     puts "   -l stderr        - log to stderr (default is plan4tcl.log)"
     puts "   -l null          - switch logging off"
     puts "   -f 12            - fontsize to 12 (max)"
     puts ""
     exit 0
   }
 }
}

DEBUG "Plan4tcl user=$user@$pc:$home cfg=$cfg OS=$tcl_platform(platform)/$os"
DEBUG "FONTSIZE=$fontsize"

# dont use $cfg instead of "$cfg" under XP with spaces in pathnames
if { [file exists "$cfg"] } { } else {
  # write initial config file
  if [catch {open "$cfg" w} in] { 
    Error "create configfile $cfg failed"
    exit  2
  }
  puts $in "plan V1.8"
  puts $in "p\tlpr"
  puts $in "m\tMail -s %s $user"
  puts $in "u\town             [format "%-20s" [encode_filename "$cfg"]] 0  0 0 1 0 0 localhost 0"
  catch { close $in }
}

#DEBUG "before get_line"

set ::timeout 0  ;# shared by all input events (ToDo: change)
# get a line and check for timeout (make it robust against network problems)
proc get_line { chan } {
  set ::result($chan) ""    ;# ToDo: check ...
  set ::timeout 0  ;# if more channels are observed, possible race condition
  # below line produces a error on tclkit-win32, no such variable chan
  # set id [after 5000 {set ::result($chan) "";set ::timeout 10}]
  # below produces an error under linux, no such variable chan
  # set id [after 5000 "set ::result($chan) \"\";set ::timeout 10"]
  set cmd "set ::result($chan) \"\";set ::timeout 10"
  # DEBUG "after 5000 \"$cmd\""
  set id [after 5000 "$cmd"]      ;# this seems to best for Linux + Windows
  fileevent $chan readable "gets $chan ::result($chan)"
  vwait ::result($chan)              ;# see vwait/tkwait
  after cancel $id
  if {$::timeout} {
    # msgBox .getl "TimeOut" "time-out get_line chan=$chan timeout=$::timeout"
    DEBUG "time-out get_line chan=$chan"
  }
  return $::result($chan)
}

# Testcode:
#  msgBox .getl "Test" "Timeout get_line timeout=$::timeout"
#puts "please enter your text:"
#set x [get_line stdin]
#puts "result=$x timeout=$::timeout"
#exit 5

#DEBUG "before .menu"

menu .menu -font -*-Helvetica-*-*-*-*-$fontsize-*-*-*-*-*-*-*
. configure -menu .menu
.menu add cascade -label File  -menu .menu.m -underline 0
.menu add cascade -label Help  -menu .menu.h -underline 0 

menu .menu.m -tearoff 0
.menu.m add command -label "FileList"     -underline 0 -command {EditFileList}  -accelerator "^L"
.menu.m add command -label "RereadFiles"  -underline 0 -command {ReadFiles}
.menu.m add separator
.menu.m add command -label "daywidth +1"  -command {daywidth  1} -accelerator "+"
.menu.m add command -label "daywidth -1"  -command {daywidth -1} -accelerator "-"
.menu.m add separator
.menu.m add command -label "Quit"         -underline 0 -command exit -accelerator "^Q"
bind . <Control-q>     exit
bind . <Control-l>     EditFileList
#bind . <Control-plus>  {myfont  1}
#bind . <Control-minus> {myfont -1}
bind . <plus>  {daywidth  1}
bind . <minus> {daywidth -1}

menu .menu.h -tearoff 0
.menu.h add command -label "About"   -underline 0 -command {Help}

#DEBUG "before Help"

# [clock format 0]                       Thu Jan 01 01:00:00 AM CET 1970
# [clock format [expr ( 1 << 31 ) - 1]]  Tue Jan 19 04:14:07 AM CET 2038
proc Help {} {
  global ver user pc home cfg os logfile log tcl_platform
# "" or [format ""]
#  tk_messageBox -icon info -type ok -title "About Plan4tcl" -message ...
#  tk_messageBox does block, but we wont that
  msgBox .msghelp "About Help" \
   "Plan4tcl v$ver.   (c) 2005-2012 Joerg Schulenburg (www.ovgu.de/jschulen/)\n\
    \nCompatible to the Day Planner of Thomas Driemeyer (www.bitrot.de).\n\
    \nWhy this day planer?\
    \n - It runs on all platforms tcl/tk runs (Linux and Windows).\
    \n - It is small and easy to extend.\n\
    \nIts alpha version, bug reports are welcome.\n\
    \nRange of proper work:\
    \n[clock format 0]\n[clock format [expr ( 1 << 31 ) - 1]]\n\
    \nDEBUG: user=$user@$pc:[encode_filename "$home"] cfg=$cfg\
    \nDEBUG: OS=$tcl_platform(platform)/$os\
    \nDEBUG: logfile=$logfile log=$log\
 "
 }

# -foundry-family-weight-slant-setwidth-addstyle-pixel-point-resx-resy-spacing-width-charset-encoding
# fam=courier,times,helvetica weight=normal,bold
# try: xfs; xfd -fn -*-...
# set font1 {-*-courier-*-*-*-*-$size-*-*-*-*-*-*-*}
#  size:   12, 14, 18
#proc myfont { add } {
# global fontsize
# if { $fontsize + $add < 4 } { Log "font to small!"; return }  ;#  to small
# if { $add != 0 } { set fontsize [expr $fontsize + $add] } else { set fontsize 14 }
## .menu   configure -font -*-Helvetica-*-*-*-*-$fontsize-*-*-*-*-*-*-*
## .head   configure -font -*-*-*-*-*-*-$fontsize-*-*-*-*-*-*-*
## ShowMonth 0
#}

# width of the left column containing the entries of the day
set daysize 15
proc daywidth { add } {
 global daysize
 set daysize [expr $daysize + $add]
 if {$daysize==15} {DEBUG "daywidth $add"}  ;# output only once
 .day.head.date configure -width $daysize
}

#DEBUG "before main window"

# main window

# what about option -timezone :UTC or TC=:UTC?
# actual time (in seconds since 01.01.1970 00:00 UTC)
set now   [clock seconds]
# output also as %a=weekday(Mon..Thu...) %V=week %u=1(Mon)-7(Sun=7or0@input) %w=1..7
DEBUG "now=     $now = [clock format $now -format "%V %u %w %a %d.%m.%Y %H:%M %z %Z"]"

DEBUG "scan 08:15      =  [clock format [clock scan "08:15"]]"
DEBUG "scan 2012-11-23 =  [clock format [clock scan "2012-11-23"]]"
DEBUG "scan 2012-11-01 =  [clock format [clock scan "2012-11-01"]]"
DEBUG "scan 2012-11-01/3600%24 =  [expr [clock scan "2012-11-01"] / 3600 % 24]"
DEBUG "scan 2012-11-01+2h/3600%24 =  [expr [clock scan "2012-11-01 02:00"] / 3600 % 24]"
DEBUG "scan 2012-11-01+1h/3600%24 =  [expr [clock scan "2012-11-01 01:00"] / 3600 % 24]"
#set nowHHMM  [clock format $now -format "%a, %d.%m.%y  %H:%M"]
#DEBUG "set now=$now == $nowHHMM"

set nowHHMM "[clock format $now -format "%H:%M"]"  ;# format small month hh:mm
#DEBUG "nowHHMM= $nowHHMM"

# search nowHHMM
set year       "[clock format $now -format "%Y"]"
#DEBUG "set year = $year"

set month      "[clock format $now -format "%m"]"
set mytz       "[clock format $now -format "%Z"]"
# get start of 5*7 display as seconds since 1.1.1970 0:00 UTC
#set s_month [clock scan "$year-$month-1 01:00 AM CET"]  ;# month_start old2012-11
#set s_month [clock scan "$year-$month-01 00:00 $mytz" -format "%Y-%m-%d %H:%M %Z"]  ;# month_start 2012-11
set s_month [clock scan "$year-$month-01"]  ;# month_start 2012-11
# %u == day of the week (1=Monday..7=Sunday)
set s_week  [clock scan "[expr 1 - [clock format $s_month -format "%u"]] days" -base $s_month]
DEBUG "s_month= $s_month = [clock format $s_month -format "%V.%u %w %a %d.%m.%Y %H:%M %z"]"
DEBUG "s_week=  $s_week = [clock format $s_week -format "%V.%u %w %a %d.%m.%Y %H:%M %z"]"

#DEBUG "before wm iconname"

wm iconname . "[clock format $now -format "%H:%M %a"]"


frame .day ;# day view
pack  .day -side left -fill y -expand false ;# -fill both
# pack  .day -side left -fill both -expand true  ;# -fill both

frame  .day.head
pack   .day.head -fill x 
label  .day.head.date -text "[clock format $now -format "%a %d.%m.%Y"]"\
     -width 15 -anchor w

pack   .day.head.date                  -side left  -pady 2 -padx 2

# 2pixel-frame around today-texts, bit lighter gray
frame  .day.cal -borderwidth 2 -bg "#eee"
pack   .day.cal -fill both -expand true

# today-textbox, in gray 2012-11-23
text  .day.cal.t -width 5 -height 1 -wrap none -bg "#ddd"
pack  .day.cal.t -anchor nw -fill both -expand true
.day.cal.t insert end "test-entry\n"
DEBUG "L449"


frame .mon  ;# month view
pack  .mon -side left -fill both -expand true

# today day month year week weekday ???
frame  .mon.head
pack   .mon.head -fill x 
label  .mon.head.date -text "$nowHHMM"

label  .mon.head.mon  -text "[clock format $now -format "%B"]" -width 9 -justify right
label  .mon.head.year -text "$year" -width 5 -justify right
set font -*-*-*-*-*-*-[expr $fontsize - 4]-*-*-*-*-*-*-*
# month +-
button .mon.head.md -text "-" -command { ShowMonth  -1 } -font $font
button .mon.head.mu -text "+" -command { ShowMonth  +1 } -font $font
# year +-
button .mon.head.yd -text "-" -command { ShowMonth -12 } -font $font
button .mon.head.yu -text "+" -command { ShowMonth +12 } -font $font

pack   .mon.head.date                  -side left  -pady 2 -padx 2
pack   .mon.head.yu .mon.head.yd .mon.head.year \
       .mon.head.mu .mon.head.md .mon.head.mon -side right 

frame  .mon.cal ;# -relief sunken -borderwidth 1 -bg "#333"
pack   .mon.cal -fill both -expand true
#bind .cal <Button>   { Log "Button1" }
#bind .    <Button>   { Log "Button2" }  ;# works
#bind . <Activate> { Log "ButtonRelease" }

# a bit lighter gray on top of 6*7 day-array
frame .mon.cal.w -bg "#eee"
pack  .mon.cal.w -side top -fill x -expand false
for {set wday 0} {$wday<7} {incr wday} {
    frame .mon.cal.w.d$wday -bg "#eee"
    pack  .mon.cal.w.d$wday -side left -pady 1 -padx 1 -fill x -expand true

    # start_week + 0..6 days = "Mon Tue Wed Thu Fri Sat Sun"
    set wd [clock format [clock scan "$wday days" -base $s_week] -format "%a"]
    label .mon.cal.w.d$wday.l -text "$wd" -bg "#eee" -anchor w \
             -font -*-*-*-*-*-*-[expr $fontsize - 2]-*-*-*-*-*-*-*
    pack  .mon.cal.w.d$wday.l -side left -fill x -anchor w ;# west
}
DEBUG "L493"

# canvas .mon.cal.c ???

# create 6 * 7 canvas squares (show 6weeks of the month)
set w .mon.cal
for {set week 0} {$week<6} {incr week} {
  frame $w.w$week -bg "#333"     ;# not a complete black
  pack  $w.w$week -side top -fill both -expand true
  for {set wday 0} {$wday<7} {incr wday} {
    frame $w.w$week.d$wday -borderwidth 2 ;# -bg "#ddd"
 
    set date [clock scan "[expr $week * 7 + $wday] days" -base $s_week]
    set mday [clock format $date -format "%d"] ;# day of the month 01..31
    if {$wday > 4} {set color "#b00"} else {set color "#000"}
    # 24h/d*60m/h*60s/m = 86400s/d, make today green (gray else)
    # JS 2012-11-23 results differ in different TZs, / 86400 is bad!
    #   test: TZ=:Etc/GMT+12 wish plan4tcl.tcl -- -l stderr # date -14h..+12h
    if {[expr $now  / 86400] == [expr $date / 86400] } \
      {DEBUG "setgreen0(BAD) $week.$wday [clock format $now -format "%Y-%m-%d.%Hh"] - [clock format $date -format "%Y-%m-%d.%Hh"] = [expr ($now - $date)/3600]h"}
    if {[expr ($now-$date)  / 86400] == 0 } \
      {DEBUG "setgreen1(OK?) $week.$wday [clock format $now -format "%Y-%m-%d.%Hh"] - [clock format $date -format "%Y-%m-%d.%Hh"] = [expr ($now - $date)/3600]h"}
    if {[clock format $now  -format "%Y-%m-%d"]\
     == [clock format $date -format "%Y-%m-%d"] } \
      {DEBUG "setgreen2(OK)  $week.$wday [clock format $now -format "%Y-%m-%d.%Hh"] - [clock format $date -format "%Y-%m-%d.%Hh"] = [expr ($now - $date)/3600]h"}
#    if {[expr $now  / 86400]\
#     == [expr $date / 86400] } \
#                   {set bg "#7f7"} else {set bg "#ddd"}
    if {[clock format $now  -format "%Y-%m-%d"]\
     == [clock format $date -format "%Y-%m-%d"] } \
                   {set bg "#7f7"} else {set bg "#ddd"}
    # ToDo: replace by button
    label $w.w$week.d$wday.l -text "$mday" -bg $bg -fg $color -width 2 -justify left\
      -font -*-*-bold-r-*--[expr $fontsize + 0]-*-*-*-m-*-utf-*
#    text  $w.w$week.d$wday.t -bg $bg -relief flat -borderwidth 0 -fg "#007"\
#      -width 7 -height 2 -wrap none -selectborderwidth 0\
#      -font -*-*-medium-r-*--[expr $fontsize - 1]-*-*-*-p-*-utf-* \
#      -state disabled
    # 2013-11-07
    text  $w.w$week.d$wday.t -bg $bg -relief flat -borderwidth 0 -fg "#007"\
      -width 2 -height 2 -wrap none -selectborderwidth 0\
      -font -*-*-medium-r-*--[expr $fontsize - 1]-*-*-*-p-*-utf-* \
      -state disabled
# 2012-11-30      -state normal
    pack  $w.w$week.d$wday -side left -pady 1 -padx 1 -fill both -expand true
    pack  $w.w$week.d$wday.l -anchor nw ;# north-west
    pack  $w.w$week.d$wday.t  -fill both -expand 1
## 2012-11-30 faster if seperated? no still 14s on 6M/64k-DSL
    bind  $w.w$week.d$wday.l <ButtonPress-1>   { ShowDay "%W"} ;# 2012-11-30
    bind  $w.w$week.d$wday.t <ButtonPress-1>   { ShowDay "%W"}
    bind  $w.w$week.d$wday   <ButtonPress-1>   { ShowDay "%W"} ;#2012-11-30
##    $w.w$week.d$wday.t configure -relief flat -borderwidth 0 \
##      -state normal
#    # $w.w$week.d$wday.t configure -state disabled
  }
#  update
}
DEBUG "L545"



# ToDo: subroutine get list: fg_color bg_color "[time:] [W:]entry [(duration)]"
#       from Number
proc ShowMonth { addmonth } {
  global month mytz year now entryN entryD entryR
  global entryF   ;# file or group number (-1,0..numL-1; -1 means deleted)
  global s_month s_week alist mlist fontsize
  # search nowHHMM
  scan $month %d month  ;# 01..09 -> 1..9
  set year  "[expr (12 * $year +   $month + $addmonth -  1) / 12 ]"
  set month "[expr           1 + (($month + $addmonth + 11) % 12)]"

  # was wrong for 27-31.4.06 in CEST
  # set s_month [clock scan "$year-$month-1 01:00 AM CET"]  ;# month_start
#  set s_month [clock scan "$year-$month-01 00:00 $mytz" -format "%Y-%m-%d %H:%M %Z"]  ;# month_start
  set s_month [clock scan "$year-$month-01"]  ;# month_start
  set s_week  [clock scan "[expr 1 - [clock format $s_month -format "%u"]] days" -base $s_month]
  DEBUG "ShowMonth month=$month year=$year"
  DEBUG "now=     $now = [clock format $now -format "%V.%a %w %d.%m.%Y %H:%M"] [expr $now / 86400]"
  DEBUG "s_month= $s_month = [clock format $s_month -format "%V.%a %w %d.%m.%Y %H:%M"] [expr $s_month / 86400]"
  # today day month year week weekday ???
  .mon.head.year configure -text "$year" -anchor e
  # %B = January,...
  .mon.head.mon  configure -text "[clock format [clock scan $year-$month-01] -format "%B"]" -anchor e

  # reduce data, extract list for the showed month (ToDo: use unix time)
  set mlist [GetList     $s_week [expr $s_week + (6*7-1)*24*3600] $alist]
  set w .mon.cal
  for {set week 0} {$week<6} {incr week} {
    for {set wday 0} {$wday<7} {incr wday} {
      set tc "#007"  ;# color of entry
      set dc "#000"  ;# color of day
      set date [clock scan "[expr $week * 7 + $wday] days" -base $s_week]
      set mday [clock format $date -format "%d"]  ;# day of month
      if {$wday > 4} {set dc "#b00"}   ;# set 5+6=Sat+Sun in red
      if {[clock format $date -format "%m"]\
             != [format "%02d" $month] } {set dc "#aaa"; set tc "#aac"}
      # mark today with green color
      # 86400s/d fails if now and date are of different TZ!?
#      if {[expr $now / 86400] == [expr $date / 86400]} \
#
      if {[clock format $now  -format "%Y-%m-%d"] ==\
          [clock format $date -format "%Y-%m-%d"]} \
       {DEBUG "setgreen3 [clock format $now -format "%Y-%m-%d"] now-date=[expr ($now - $date)/3600]h"}
      if {[clock format $now  -format "%Y-%m-%d"] ==\
          [clock format $date -format "%Y-%m-%d"]} \
                     {set bg    "#7f7"; ShowDay $w.w$week.d$wday }\
                else {set bg    "#ddd"}
      # 86400s/d Abbrev.Weekday=%a(Mon,Tue...) week=%V (ISO-8601 week1=4.Jan)
#      if {$wday == 0} {\
#        DEBUG "date= [clock format $date -format "%Y-%m-%d w%V.%a"] $week.$wday now= [clock format $now -format "%Y-%m-%d w%V.%a"]" \
#      }
      # ToDo: replace by button
      $w.w$week.d$wday   configure -bg $bg
      $w.w$week.d$wday.l configure -text "$mday" -bg $bg -fg $dc ;# \
#        -font -*-*-bold-r-*--[expr $fontsize + 0]-*-*-*-m-*-utf-*
#        -font -*-*-medium-r-*--[expr $fontsize - 1]-*-*-*-p-*-utf-* \
#
      $w.w$week.d$wday.t configure -bg $bg -relief flat -borderwidth 0 -fg $tc\
        -selectborderwidth 0 -state normal ;# need normal to modify
      $w.w$week.d$wday.t delete 1.0 end
      set nyy [clock format $date -format "%Y"]  ;# 1970..2038
      set nmm 0    ;# against scan error on tclkit + XP
      set ndd 0    ;# against scan error on tclkit + XP
      scan "[clock format $date -format "%m %d"]" "%d %d" nmm ndd
      #  01..12 -> 1..12,  01..31 -> 1..31
#      set xx [clock format \
#         [expr $s_week + ($week * 7 + $wday) * 24 * 3600]\
#             -format "%Y-%m-%d"]
      # 2013-10-29 detect TZ-shift and correct it, force output as H:M=00:00
      set tzshift [clock scan "1970-01-01"]   ;#  -3600 for CET, -7200 for CEST
      set xx [expr $s_week + ($week * 7 + $wday) * 24 * 3600 - $tzshift]
      # xx is in GMT, will result in day-1 23:00 on GMT+1 == bad
      # termine raussuchen mit aktuell darzustellenden Tag $date
      # ????? JS 2012-11-30
      # Probleme mit Umrechnung 00:00-Termine und Zeiten unter Zeitzonendiff?
      # 2013-11-07 still problems with [GetList  $xx $xx $mlist]
#     set dlist [GetList  $xx [clock format $xx -format "%Y-%m-%d"] $mlist] ;# day list
      set dlist [GetList [clock format $xx -format "%Y-%m-%d"]\
                         [clock format $xx -format "%Y-%m-%d"] $mlist]
#     set dlist [GetList  $xx $xx $mlist]   ;# generate day list
      set dlist [SortList $dlist] ;# -ascii -increasing

      # mark some text colored only via ".text tag configure"?
      set dlen [llength $dlist]
      for {set y 0} {$y<$dlen} {incr y} {
        set x [lindex $dlist $y]
        set emm 0    ;# against scan error on tclkit + XP
        set edd 0    ;# against scan error on tclkit + XP
        set eyy 0    ;# against scan error on tclkit + XP
        set eHH 0    ;# against scan error on tclkit + XP
        set eMM 0    ;# against scan error on tclkit + XP
        set e_col 0    ;# against scan error on tclkit + XP
        set wdays 0  ;# against scan error on tclkit + XP, 2012-11-30
        scan $entryD($x) "%d/%d/%d %d:%d:%*d %*s %*s %*s %*s %d %d" \
           emm edd eyy eHH eMM e_col wdays
        if {$e_col>7} {set e_col 7}
# 2012-11-30 minimize output on small squares
#        if { $eHH < 25 } {set tt "[format "%02d:%02d " $eHH $eMM]"}\
#                    else {set tt ""}
        if { $eHH < 25 } {set tt "[format "%d " $eHH]"}\
                    else {set tt ""}
        if {$wdays != 0 && $edd+31*$emm != $ndd+31*$nmm}  {set tt "${tt}w:"}
        # wday:0=Mo..6=So
        DEBUG "ShowMonth+ $edd.$emm.$eyy $tt$entryN($x) on $week.$wday" ;# hh:mm
        set e_bg [expr $entryF($x)%8]
        $w.w$week.d$wday.t insert end "$tt$entryN($x)\n"
        ;# set a tag x$y to line y+1 and color it
        $w.w$week.d$wday.t tag add x$y [expr $y+1].0 [expr $y+1].end
        $w.w$week.d$wday.t tag configure x$y -foreground "[string range\
          "#000#000#f00#0f0#ff0#00f#f0f#0ff#fff" \
           [expr $e_col*4] [expr $e_col*4+3]]"
# faster? 2012-11-30
        $w.w$week.d$wday.t tag configure x$y -background "[string range\
           "#ddd#dcc#cdc#ddc#ccd#dcd#bcc#ccc" \
           [expr ($e_bg%8)*4] [expr ($e_bg%8)*4+3]]"
      }
      $w.w$week.d$wday.t configure -state disabled
    }
  }
#  DEBUG "start update1"
  update
#  DEBUG "end   update1"
}


# input/output list of date indizees (slow, call only with daylist!)
proc SortList { ilist } {
  global entryD entryF
  set olist {}  ;# output list
  set slist {}  ;# temporary textlist
  for {set y 0} {$y<[llength $ilist]} {incr y} {
    set x [lindex $ilist $y]
    set emm 0    ;# against scan error on tclkit + XP
    set edd 0    ;# against scan error on tclkit + XP
    set eyy 0    ;# against scan error on tclkit + XP
    set eHH 0    ;# against scan error on tclkit + XP
    set eMM 0    ;# against scan error on tclkit + XP
    set e_col 0    ;# against scan error on tclkit + XP
    scan $entryD($x) "%d/%d/%d %d:%d:%*d %*s %*s %*s %*s %d %*d" \
         emm edd eyy eHH eMM e_col
    if { $eHH > 24 } {set eHH 0; set eMM 0}
    set tsort "[format "%02d:%02d %2d %d" $eHH $eMM $entryF($x) $x]"
    lappend slist "$tsort"
  }
  set slist [lsort $slist] ;# -ascii -increasing
  # mark some text colored only via ".text tag configure"?
  for {set y 0} {$y<[llength $slist]} {incr y} {
    set x 0    ;# against scan error on tclkit + XP
    scan "[lindex $slist $y]" "%*s %*d %d" x
    lappend  olist $x
  }
  return $olist
}

# Eastern = christian tradition (http://www.ptb.de/de/org/4/44/441/oste.htm)
# first Sunday after the first full moon (circlular moon orbit assumed)
#     after begin of spring (fixed to 21. march, but 19.-21.march real)
#     easter formula of Gauss (range: 22.march - 25.april (=56.march))
# earth-moon-cycle: 76 years = 940 moon months = 27759 days
#       + some corrections + special rules to avoid Pessach fest
#          year = 365.2422    days
# synodic month =    29.53059 days (full moon to full moon)
#  19 years = 6939.60 days = metonic cycle
# 235 s.ms  = 6939.69 days = metonic cycle
proc Easter { year } {                        ;# 1583 - 8202
  set k  [expr $year / 100]
  set m  [expr 15 + (3*$k+3)/4 - (8*$k+13)/25]
  set s  [expr  2 - (3*$k+3)/4]
  set a  [expr $year % 19]                    ;# metonic cycle
  set d  [expr (19*$a+$m) % 30]
  set r  [expr $d/29 + ($d/28 - $d/29)*($a/11)]
  set og [expr 21 + $d - $r]                  ;# easter full moon in march
  set sz [expr 7 - ($year + $year/4 + $s)%7]  ;# first sunday in march
  set oe [expr 7 - ($og - $sz)%7]
  set os [expr $og + $oe]                     ;# easter sunday in march
                                               # 32. march = 1. april etc.
  # os - 46: Aschermittwoch
  # os + 39: Christi Himmelfahrt
  # os + 49: Pfingstsonntag
  # os + 60: Fronleichnam

#  set os1 $os
#  # formula of de.wikipedia.org (same as above)
#  set a  [expr $year % 19]                ;# metonic cycle
#  set b  [expr $year %  4]
#  set c  [expr $year %  7]
#  set H1 [expr $year / 100]
#  set H2 [expr $year / 400]
#  set   N [expr   4 + $H1 - $H2]
#  set   M [expr  15 + $H1 - $H2 - ((8 * $H1 + 13) / 25)]
#  set   d [expr  (19 * $a + $M) % 30]
#  set   e [expr  (2 * $b + 4 * $c + 6 * $d + $N) % 7]
#  if {$d + $e == 35} {set os 50} \
#  elseif {$d == 28 && $e == 6 && $a > 10} {set os 49} \
#  else  {set os [expr 22 + $d + $e]}
#  set os2 $os
#  if {$os1 != $os2} {Error "Easter results differ: $year $os1 $os2"}
#  
  return $os
}

# ToDo: return a list of holiday strings (read from ~/.holiday file)
# format sday, eday is "yyyy-mm-dd" or clock in seconds since 1970
# 
proc GetHolidayList { day } {
  set olist {}
  return $olist
}

# return a index-list of entries between startday and endday
# faster if done once a month instead every day, see man 4 plan
# format sday, eday is "yyyy-mm-dd" or clock in seconds since 1970
#  should be in GMT so that sday / (24*3600), but is -$tz
proc GetList { sday eday ilist } { ;# startday - endday, yyyy-mm-dd
  global entryD entryR entryF mytz
  set olist {}        ;# output-list of selected entries
  if { $eday == "" } { set eday $sday }
  # if the input-format is %Y-%m-%d, convert to unix seconds, change 2012-11
  #  but this may not give multiple of 24*3600 for non-UTC-TZs mytz=CET
  if {[string first - $sday]<0} {set sclock $sday} \
                         else   {set sclock "[clock scan "$sday"]"}
  if {[string first - $eday]<0} {set eclock $eday} \
                         else   {set eclock "[clock scan "$eday"]"}
  # 2013-10-29 detect TZ-shift and correct it,  -1 for CET, -2 for CEST
  set tzshift [expr [clock scan "1970-01-01"] / 3600] ;#
#  if {[expr $sclock / 3600 % 24]} {
#    # should never happen!
#    DEBUG "GetList sclock has TZ-shift of ${tzshift}h TZ=$mytz"
#  }
#  if {[expr ($sclock/3600-$tzshift)%24] == 0} {   ;# positive shift
#    set sclock [expr $sclock - 3600*$tzshift] }
#  if {[expr ($sclock/3600+$tzshift)%24] == 0} {
#    set sclock [expr $sclock + 3600*$tzshift] }
#  if {[expr ($eclock/3600-$tzshift)%24] == 0} {
#    set eclock [expr $eclock - 3600*$tzshift] }
#  if {[expr ($eclock/3600+$tzshift)%24] == 0} {
#    set eclock [expr $eclock + 3600*$tzshift] }
#  if {[expr $sclock / 3600 % 24]} {
#    DEBUG "GetList correct2 TZ-shift of ${tzshift}h TZ=$mytz"
#  }

  if {$sday != $eday} {
   DEBUG "GetList $sday - $eday = [clock format $sclock -format "%Y-%m-%d %H:%M"] - [clock format $eclock -format "%Y-%m-%d %H:%M"]"
  }
  if {$sday == $eday} {
   DEBUG "GetList $sday = [clock format $sclock -format "%Y-%m-%d %H:%M"] TZ=$mytz ${tzshift}h"
  }
  # generate a bitmask of weekdays lying between sday and eday
  set mmask 0  ;# bitmask days of month + last day (bit0,1..31  of monthday)
  set wmask 0  ;# bitmask weekdays 0=Sun...6=Sat   (bit0..6     of weekday)
  set umask 0  ;# bitmask week of month + lastweek (bit8..12,13 of weekday)
  # clock format returns %02d string, but we need %d string
  set syy   "[clock format $sclock -format "%Y"]"    ;# 2005
  set swday "[clock format $sclock -format "%w"]"    ;# 0=Sun 6=Sat (inp7==0)
  set smm   "[clock format $sclock -format "%m"]"    ;# 01..12
  set sdd   "[clock format $sclock -format "%e"]"    ;#  1..31
  set eyy   "[clock format $eclock -format "%Y"]"    ;# 2005
  set emm   "[clock format $eclock -format "%m"]"    ;# 01..12
  set edd   "[clock format $eclock -format "%e"]"    ;#  1..31
  set smm   "[string trimleft $smm 0]" ;# 1..12
  set emm   "[string trimleft $emm 0]" ;# 1..12
  # we need the first day of the next month to calculate last day of the month
  set nextmon "[clock scan \
              "[expr $syy+($smm/12)]-[expr ($smm % 12)+1]-01"]" ;# Y-m-01

  # check for last day of the month
  if {$sclock <        $nextmon\
   && $eclock >= [expr $nextmon -   24*3600]} {
                                        set mmask [expr $mmask | 1] }

  # check for last 7 weekdays of the month
  if {$sclock <        $nextmon\
   && $eclock >= [expr $nextmon - 7*24*3600]} {
                                        set umask [expr $umask | (1<<13)]}

  # set BitMask (bits 01234567) for SunMonTueWedThuFriSat
  for {set x 0} {$x<7} {incr x} {
    set xx "[expr $sclock + ($x * 24 * 3600)]"
    if {$xx > $eclock} break   ;# only weekdays in range
    set wmask [expr $wmask | (1<<(($swday+$x)%7))]
  }
  #  DEBUG "sday eday $sday $eday"
  #  DEBUG "wmask [format "%0x" $wmask]"

  # set Bitmask for day last=bit0, 1..31=bit1..31 of every month
  for {set x 0} {$x<31} {incr x} {
    set xx "[expr $sclock + ($x * 24 * 3600)]"
    if {$xx > $eclock} break   ;# only days in range
    set mmask [expr $mmask | (1<<[clock format $xx -format "%e"])]
  }
  #  DEBUG "mmask [format "%0x" $mmask]"

  # set week of month number (4-5 weeks possible)
  #   first week goes from 01.-07., 2nd from 08.-14.
  #   last  week goes from 30./31. back to 24./25.
  #   if 31. is a Monday, there is no 5th Tue
  for {set x 0} {$x<6} {incr x} {
    # adjust startclock to 1. 8. 15. 22. 29. of the month
    set xx "[expr $sclock + ((7 * $x - ($sdd-1)%7) * 3600 * 24)]"
    if {$xx > $eclock} break   ;# only weeks in range
    set y [clock format $xx -format "%e"]  ;# 1,8,15,22,29
    set umask [expr $umask | (1<<(($y-1)/7+8))]
  }
  # handle the overlap correct: if 2 months involved, we have always 1st week
  # start month != end month
  if {$emm != $smm} {set umask [expr $umask | (1<<8)]}
  #  DEBUG "umask [format "%0x" $umask]"

  # check every entry if its in the given range
  for {set y 0} {$y<[llength $ilist]} {incr y} {
    set  trigger 0               ;# 0 = outside, 1..6 = inside range
    set  x [lindex $ilist $y]
    set rr 0
    if {$entryF($x)<0} { continue }  ;# deleted entry
    # D date time ...
    set xmm 0    ;# against scan error on tclkit + XP
    set xdd 0    ;# against scan error on tclkit + XP
    set xyy 0    ;# against scan error on tclkit + XP
    set xHH 0    ;# against scan error on tclkit + XP
    set xMM 0    ;# against scan error on tclkit + XP
    set wdays 0  ;# against scan error on tclkit + XP
    scan $entryD($x) "%d/%d/%d %d:%d:%*d %*s %*s %*s %*s %*d %d"\
        xmm xdd xyy xHH xMM wdays
    # R repeat enddate weekly monthly yearly
    set nR [scan "$entryR($x)" "%d%d%d%d%d" rr re rw rm ry]
    set rr [expr $rr / 86400]  ;# defined as unixtime but used as days
    # JS 2012-11 add -format
    set xx "[clock scan "$xyy-$xmm-$xdd"]"
# 01..12 01..31 yyyy -> 1..12 1..31 yyyy
#   scan "[clock format $xx -format "%m %d %Y"]" "%d %d %d" xmm xdd xyy
    # test if entry $xx is within range sclock-eclock (2012-11-30 add wdays)
    # ToDo: TZ-test DEBUG output + wdays=2++
    if {  $xx / 86400 - $wdays >   $eclock / 86400} continue ;# after range
    if { $nR != 5 } {   ;# no repetition
      if {$xx / 86400          >=  $sclock / 86400} {set trigger 1}
    }\
    elseif {$nR == 5} { ;# repetition
      if {$re>0 && $re / 86400 < $sclock / 86400} continue ;# before range
      #  yearly is wrong!? should also combined with weekdays etc.
      #  Jan 29 within Dec 31 .. Jan 10 for eyy>syy!
      if { ($ry > 0)\
        && ($xmm*31+$xdd >= $smm*31+$sdd)\
        && ($xmm*31+$xdd <= $emm*31+$edd+(12*31*($eyy-$syy)))} {set trigger 2}
      if { ($ry > 0)\
        && ($xmm*31+$xdd >= $smm*31+$sdd-(12*31*($eyy-$syy)))\
        && ($xmm*31+$xdd <= $emm*31+$edd)} {set trigger 2}
      #  monthly?
      if { ($rm > 0) && ($rm & $mmask)}    {set trigger 3}
      #  weekly?
      if { ($rw > 0) && ($rw & $wmask)\
        && ($rw<128 ||  ($rw & $umask)) }  {set trigger 4}
      #  repeat every rr/86400 days
      if { ($rr > 0) && (((($sclock - $xx) / 86400 - 1) / $rr + 1 ) * $rr\
                        <= ($eclock - $xx) / 86400 )} {set trigger 5}
      # if endday is given, but repeat day resetted, trigger on startday
      if {$rr==0 && $rw==0 && $rm==0 && $ry==0} { set trigger 6}
    }
    if {$trigger} { lappend olist $x }
    global entryN
    # if {$trigger} { DEBUG "GetList+ $x $entryD($x) $entryR($x) $entryN($x)"}
    if {$trigger} { DEBUG "GetList+ $trigger $x $entryN($x)"}
  }
  # output list if GetList called via option?
  # DEBUG "OutList= $olist"
#  global entryN
#  for {set y 0} {$y<[llength $olist]} {incr y} {
#    set  x [lindex $olist $y]
#    DEBUG "$entryD($x)\n$entryR($x)\n $entryN($x)"
#  }
  return $olist
}

# return a index-list of Warning entries between startday and endday
# this is a slow routine (better use clock values?)
#  2012-11-30 integrated to reduce complexity and 3-fold computation
#  obsolete! removed
#proc GetWarnList { sday eday ilist } { ... }

# ToDo: store a list of indizes of entries per day and get/show/edit it here
proc ShowDay { tag } {
  global s_week month year numL entryN entryD flistU entryI entryF group mlist
  global fontsize
  set week 0    ;# against scan error on tclkit + XP
  set wday 0    ;# against scan error on tclkit + XP
  set nmm  0    ;# against scan error on tclkit + XP
  set ndd  0    ;# against scan error on tclkit + XP
  scan "$tag" ".mon.cal.w%d.d%d" week wday
  set date [clock scan "[expr $week * 7 + $wday] days" -base $s_week]
  set nyy  [clock format $date -format "%Y"]  ;# 1970..2038
  scan    "[clock format $date -format "%m %d"]" "%d %d" nmm ndd
  DEBUG "ShowDay $tag $week.$wday $ndd.$nmm.$nyy date = [clock format $date -format "%a %V.%w %d.%m.%Y"]"
  set ww .day.cal
  # catch {destroy .day.cal}  ;# destroy if ShowDay is called again
  .day.head.date configure -text "[clock format $date -format "%a %d.%m.%Y"]"
  set dlist [GetList     "$nyy-$nmm-$ndd" "$nyy-$nmm-$ndd" $mlist]
  set dlist [SortList $dlist]
  # ToDo: sort dlist! (also for ShowMonth)
  set e_col 0
  set e_bg  0
  set fg "[string range "#000#000#f00#0f0#ff0#00f#f0f#0ff#fff" \
           [expr $e_col*4] [expr $e_col*4+3]]"
  set bg "[string range     "#ddd#dcc#cdc#ddc#ccd#dcd#bcc#ccc" \
           [expr ($e_bg%8)*4] [expr ($e_bg%8)*4+3]]"
  .day.cal.t configure -state normal ;#\
#    -font -*-*-bold-r-*--[expr $fontsize + 1]-*-*-*-m-*-utf-*
  .day.cal.t delete 1.0 end
  .day.cal.t insert end "- New Entry -\n"
  .day.cal.t tag add xn 1.0 1.end
  .day.cal.t tag configure xn -foreground "$fg"
  .day.cal.t tag configure xn -background "$bg"
  .day.cal.t tag bind xn  <Enter> ".day.cal.t tag configure xn -background \"#0d0\""
  .day.cal.t tag bind xn  <Leave> ".day.cal.t tag configure xn -background \"$bg\""
  .day.cal.t tag bind xn  <Button-1> "EditEntry $ndd.$nmm.$nyy -1"

  set dlen [llength $dlist]
  for {set y 0} {$y<$dlen} {incr y} {
    if {$y<$dlen} {set x [lindex $dlist $y]}
    set e_col 0
    set e_bg  [expr $entryF($x)%8]
    set eyy  0    ;# against scan error on tclkit + XP, entry.year
    set emm  0    ;# against scan error on tclkit + XP, entry.month
    set edd  0    ;# against scan error on tclkit + XP, entry.day
    set thh  0    ;# against scan error on tclkit + XP, start hour
    set tmm  0    ;# against scan error on tclkit + XP, start minute
    set lhh  0    ;# against scan error on tclkit + XP  unused length hour
    set lmm  0    ;# against scan error on tclkit + XP  unused length minute
    set e_col  0    ;# against scan error on tclkit + XP
    set wdays  0    ;# against scan error on tclkit + XP, 2012-11-30
    scan "$entryD($x)" "%d/%d/%d %d:%d:%*d %d:%d:%*s %*s %*s %*s %d %d" \
       emm edd eyy thh tmm lhh lmm e_col wdays
    if {$e_col>7} {set e_col 7}
    if {$thh > 24 } { set ttime "" }\
    else            { set ttime "[format "%02d:%02d " $thh $tmm]" }     
    if {$wdays != 0 && $edd+31*$emm != $ndd+31*$nmm}  {set ttime "${ttime}w:"}
    global  entry_ey$y
    set entry_ey$y "[lindex $entryD($x) 0] $entryN($x)" ;# ToDo: obsolete?
    set fg "[string range "#000#000#f00#0f0#ff0#00f#f0f#0ff#fff" \
             [expr $e_col*4] [expr $e_col*4+3]]"
    set bg "[string range     "#ddd#dcc#cdc#ddc#ccd#dcd#bcc#ccc" \
             [expr ($e_bg%8)*4] [expr ($e_bg%8)*4+3]]"
    .day.cal.t insert end "$ttime$entryN($x)\n"
    .day.cal.t tag add x$y [expr $y+2].0 [expr $y+2].end
    .day.cal.t tag configure x$y -foreground "$fg"
    .day.cal.t tag configure x$y -background "$bg"
    .day.cal.t tag bind x$y  <Enter> ".day.cal.t tag configure x$y -background \"#0d0\" "
    .day.cal.t tag bind x$y  <Leave> ".day.cal.t tag configure x$y -background \"$bg\" "
    .day.cal.t tag bind x$y  <Button-1> "EditEntry $ndd.$nmm.$nyy $x"
    # ToDo: 1st argument of EditEntry useless?
  }
  .day.cal.t configure -state disabled
}

# entry<0: create a new entry for datum
proc EditEntry { datum entry } {
  global s_week month year numL entryF entryN entryD flistU entryR group mlist
  global num_entries numN alist entryI old
  set ww .ee
  catch {destroy .ee}  ;# destroy if Edit is called again
  toplevel .ee
  wm title .ee "Edit Entry"
  DEBUG "EditEntry $datum (num_entry=$entry)"
  global ee_date ee_note ee_grp ee_num ee_time ee_len ee_end ee_warn ee_alarm
  global ee_flag ee_wday ee_color ee_year ee_week ee_mont ee_rep
  global ee_w0 ee_w8 ee_m0
  set ndd  0    ;# against scan error on tclkit + XP
  set nmm  0    ;# against scan error on tclkit + XP
  set nyy  0    ;# against scan error on tclkit + XP
  scan "$datum" "%d.%d.%d" ndd nmm nyy
  set ee_date "[format "%02d.%02d.%02d" $ndd $nmm $nyy]"    ;# dd.mm.[yy]yy
  set ee_note ""
  set ee_time  "99:99"
  set ee_len   "00:00"  ;# time len (format file: 0:0:0 edit: 00:00)
  set ee_warn  "00:00" 
  set ee_alarm "00:00" 
  set ee_flag  "----------"
  set ee_color 0
  set ee_wday  0       ;# warning-day (shown in the calendar, ToDo)
  set ee_end  ""       ;# repeat stops on this day
  set ee_rep  0        ;# repeat in days
  set ee_grp  0        ;# file
  set ee_year 0        ;# repeat yearly
  # ee_week bitmask 0..6,8..12,13 = Sun+Mon+Tue+Wed+Thu+Fri+Sat, 1+2+3+4+5+last
  # ee_mont bitmask 0,1..31       = last,1+2+3+..+31
  set ee_week 0        ;# weekly-bitmask
  set ee_mont 0        ;# monthly-bitmask
  set ee_w0   ""       ;# bitmask 0..7  converted to string, Sun..Sat
  set ee_w8   ""       ;# bitmask 8..13 converted to string, 1..5+last week
  set ee_m0   ""       ;# bitmask 0..31 converted to string, 1..31+last day
  set ee_num $entry    ;# we need global var, local var is not available
  if {$entry >= 0} {
    scan "$entryD($entry)"\
        "%d/%d/%d %d:%d:%*d %d:%d:%*d %d:%d:%*d %d:%d:%*d %s %d %d"\
        nmm ndd nyy nHH nMM lHH lMM wHH wMM aHH aMM ee_flag ee_color ee_wday
    set ee_date  "[format "%02d.%02d.%02d" $ndd $nmm $nyy]"
    set ee_time  "[format "%02d:%02d" $nHH $nMM]"
    set ee_len   "[format "%02d:%02d" $lHH $lMM]"
    set ee_warn  "[format "%02d:%02d" $wHH $wMM]"
    set ee_alarm "[format "%02d:%02d" $aHH $aMM]"
    set ee_grp   $entryF($entry)
    set ee_note "$entryN($entry)"
    if {"$entryR($entry)" != ""} {
      scan "$entryR($entry)" "%d%d%d%d%d" nr1 nr2 ee_week ee_mont ee_year
      if {$nr1 != 0} { set ee_rep [expr $nr1 / 86400]}
      if {$nr2 != 0} { set ee_end "[clock format $nr2 -format "%d.%m.%Y"]"}
      for {set x 0} {$x < 7} {incr x} {
        set y "[string range "SunMonTueWedThuFriSat" [expr $x*3] [expr $x*3+2]]"
        if {($ee_week>>$x)&1}     { set ee_w0 "$ee_w0 $y" }
      }
      for {set x 0} {$x < 5} {incr x} {
        if {($ee_week>>($x+8))&1} { set ee_w8 "$ee_w8 [expr $x+1]" }
      }
      if {($ee_week>>13)&1}       { set ee_w8 "$ee_w8 last" }
      set ee_w0 "[string trim "$ee_w0"]"
      set ee_w8 "[string trim "$ee_w8"]"
      for {set x 1} {$x < 32} {incr x} {
        if {($ee_mont>>$x)&1} { set ee_m0 "$ee_m0 $x" }
      }
      if {$ee_mont&1}         { set ee_m0 "$ee_m0 last" }
      set ee_m0 "[string trim "$ee_m0"]"
    }
  }

  global numL flistU
  scan "$flistU($ee_grp)" "%*s%s%s%*d%*d%*d%*d%*d%d%s%*d" name file server host
  frame .ee.grp
  pack .ee.grp -side top -fill x
  label      .ee.grp.l -text "File @ Host :"
  menubutton .ee.grp.m -text "$name @ $host" -menu .ee.grp.m.glist -relief sunken -width 30
  menu .ee.grp.m.glist
  if {$entry < 0 } { ;# only for insert, edit it can destroy data integrity
    for {set x 0} {$x<$numL} {incr x} {
      scan "$flistU($x)" "%*s%s%s%*d%*d%*d%*d%*d%d%s%*d" name file server host
      set color "[string range "#bbb#dbb#bdb#ddb#bbd#dbd#bdd#ddd" \
         [expr ($x%8)*4] [expr ($x%8)*4+3]]"
      .ee.grp.m.glist add radiobutton -label "$name @ $host" -variable ee_grp\
         -value $x -command ".ee.grp.m configure -text \"$name @ $host\" \
         -background \"$color\" " -background "$color"
    }
  }
  pack .ee.grp.l  -side left  -fill x
  pack .ee.grp.m  -side right -fill x

  set ww .ee.not
  frame $ww
  label $ww.l -text "Note   (empty means delete) :"
  entry $ww.e -textvariable ee_note -width 30
  pack  $ww -side top -fill x
  pack  $ww.l -side left  -fill x
  pack  $ww.e -side right -fill x

  set  ww .ee.dat
  frame $ww
  label $ww.l -text "Date   (dd.mm.yyyy) :"
  entry $ww.e -textvariable ee_date -width 12
  pack  $ww -side top -fill x
  pack  $ww.l -side left  -fill x
  pack  $ww.e -side right -fill x

  set  ww .ee.rep
  frame $ww
  label $ww.l -text "Repeat every .. day (days, 0 for none) :"
  entry $ww.e -textvariable ee_rep -width 12
  pack  $ww -side top -fill x
  pack  $ww.l -side left  -fill x
  pack  $ww.e -side right -fill x

  set  ww .ee.end
  frame $ww
  label $ww.l -text "EndDate (dd.mm.yyyy, empty for none) :"
  entry $ww.e -textvariable ee_end -width 12
  pack  $ww -side top -fill x
  pack  $ww.l -side left  -fill x
  pack  $ww.e -side right -fill x

  set  ww .ee.tim
  frame $ww
  label $ww.l -text "Time   (hh:mm, 99:99 for none) :"
  entry $ww.e -textvariable ee_time -width 12
  pack  $ww -side top -fill x
  pack  $ww.l -side left  -fill x
  pack  $ww.e -side right -fill x

  set ww .ee.len
  frame $ww
  label $ww.l -text "Length (hh:mm, 00:00 for none) :"
  entry $ww.e -textvariable ee_len -width 12
  pack  $ww -side top -fill x
  pack  $ww.l -side left  -fill x
  pack  $ww.e -side right -fill x

  set ww .ee.warn
  frame $ww
  label $ww.l -text "Early Warning (hh:mm, 00:00 for none, rel.) :"
  entry $ww.e -textvariable ee_warn -width 12
  pack  $ww -side top -fill x
  pack  $ww.l -side left  -fill x
  pack  $ww.e -side right -fill x

  set ww .ee.alarm
  frame $ww
  label $ww.l -text "Late  Warning  (hh:mm, 00:00 for none, rel.) :"
  entry $ww.e -textvariable ee_alarm -width 12
  pack  $ww -side top -fill x
  pack  $ww.l -side left  -fill x
  pack  $ww.e -side right -fill x

  set ww .ee.wday
  frame $ww
  label $ww.l -text "Warn   (days, 0 for none) :"
  entry $ww.e -textvariable ee_wday -width 12
  pack  $ww -side top -fill x
  pack  $ww.l -side left  -fill x
  pack  $ww.e -side right -fill x

  set ww .ee.color
  frame $ww
  label $ww.l -text "Color  (0, 1..8) :"
  entry $ww.e -textvariable ee_color -width 12
  pack  $ww -side top -fill x
  pack  $ww.l -side left  -fill x
  pack  $ww.e -side right -fill x

  # useless if ee_rep is set!
  set ww .ee.w0
  frame $ww
  label $ww.l -text "Repeat weekday (SunMonTueWedThuFriSat) :"
  entry $ww.e -textvariable ee_w0 -width 24
  pack  $ww -side top -fill x
  pack  $ww.l -side left  -fill x
  pack  $ww.e -side right -fill x

  set ww .ee.w8
  frame $ww
  label $ww.l -text "... only week per month (1 2 3 4 5 last) :"
  entry $ww.e -textvariable ee_w8 -width 24
  pack  $ww -side top -fill x
  pack  $ww.l -side left  -fill x
  pack  $ww.e -side right -fill x

  set ww .ee.month
  frame $ww
  label $ww.l -text "Repeat only monthly days (1 2 3 ... 30 31 last) :"
  entry $ww.e -textvariable ee_m0 -width 24
  pack  $ww -side top -fill x
  pack  $ww.l -side left  -fill x
  pack  $ww.e -side right -fill x

  set ww .ee.year
  frame $ww
  label $ww.l -text "Repeat yearly (0 for none, 1 for annual) :"
  entry $ww.e -textvariable ee_year -width 12
  pack  $ww -side top -fill x
  pack  $ww.l -side left  -fill x
  pack  $ww.e -side right -fill x


  frame .ee.cmds
  button .ee.cmds.ok   -text "ok" -command {
    if {$ee_rep==0 && $ee_end!="" && $ee_year==0 \
     && $ee_m0=="" && $ee_w8=="" && $ee_w0==""} {
      msgBox ".msg_ee_cmds" "EndDate" \
   "Warning: Setting EndDate without setting one of Repeat fields is useless."
      return
    }
    if {$ee_num < 0} { set ee_num $num_entries }  ;# append
#   scan "09:12" "%d:%d"    tHH tMM       ;# 09 -> 9
#   scan "09:12" "%\[0-9\]:%\[0-9\]"    tHH tMM ;# 09 -> 09
    DEBUG "EditEntry note=$ee_note file=$ee_grp entry=$ee_num num_entries=$num_entries llength(entryD)=[llength entryD]"
    scan "$ee_date"  "%d.%d.%d" ndd nmm nyy
    scan "$ee_time"  "%d:%d"    tHH tMM        ;#  09 -> 9
    scan "$ee_len"   "%d:%d"    lHH lMM
    scan "$ee_warn"  "%d:%d"    wHH wMM
    scan "$ee_alarm" "%d:%d"    aHH aMM
    set tSS 0; if {$tHH==99} {set tSS 99}
    set entryD($ee_num) "$nmm/$ndd/$nyy  $tHH:$tMM:$tSS  $lHH:$lMM:0  $wHH:$wMM:0  $aHH:$aMM:0  ---------- $ee_color $ee_wday"
    set entryR($ee_num) ""
    set entryN($ee_num) "$ee_note"
    set ee_week 0
    set ee_mont 0
    for {set x 0} {$x < 7} {incr x} {
      set y1 "[string range "SuMoTuWeThFrSa" [expr $x*2] [expr $x*2+1]]"
      set y2 [string first "$y1" "$ee_w0"]
      if {$y2>=0} {set ee_week [expr $ee_week | (1<<$x)]}
    }
    for {set x 0} {$x < 5} {incr x} {
      set y2 [string first "[expr $x+1]" "$ee_w8"]
      if {$y2>=0} {set ee_week [expr $ee_week | (1<<($x+8))]}
    }
    if {[string first "last" "$ee_w8"]>=0} { 
      set ee_week [expr $ee_week | (1<<13)] 
    }
    set y [split "$ee_m0" " ,+/-.:;|&"]
    for {set x 0} {$x < [llength $y]} {incr x} {
      set y2 [lindex $y $x]
      if {"$y2" == "last"} { set ee_mont [expr $ee_mont | 1] }\
      elseif { [string is integer $y2] && $y2>0 && $y2<32 } {
        set ee_mont [expr $ee_mont | (1<<$y2)]
      } else { Error "split ee_m0, unknown word $y2" }
    }
    if {"$ee_end"!="" || $ee_rep!=0\
      || $ee_week!=0  || $ee_mont!=0 || $ee_year!=0} {
      set nr1 [expr $ee_rep * 86400]
      set nr2 0
      if {"$ee_end"!=""} {
        set rc [scan "$ee_end" "%d.%d.%d" n1 n2 n3]
        # JS 2012-11-23 add -format, removed again for old versions
        if {$rc!=3} { DEBUG "EditEntry wrong format ee_end=$ee_end" } \
        else {set nr2 [clock scan "$n3-$n2-$n1"]}
      }
      set entryR($ee_num) "$nr1 $nr2 $ee_week $ee_mont $ee_year"
    }
    if {($ee_num<0 || $ee_num>=$num_entries)\
                         && "$ee_note" != ""} {  ;# append data-set
      DEBUG "EditEntry append data-set $ee_num"
      set entryF($ee_num) $ee_grp ;# file no.
      set entryI($ee_num) 0       ;# append index for netplan
      if {[EditFile $ee_grp $ee_num] == 0} {
        # abort on error!
        lappend alist $ee_num        ;# expand index-list
        incr num_entries             ;# expand data-table
        DEBUG "EditEntry data-set appended, num_entries=$num_entries"
      } else { Error "data could not be stored" } 
    } elseif { $ee_num>=0 && $ee_num<$num_entries \
                          && "$ee_note" == ""} {  ;# delete
      DEBUG "delete data-set $ee_num"
      set entryF($ee_num) -1   ;# mark as deleted
      if {[EditFile $ee_grp $ee_num] == 0} {
        # abort on error!
        # ToDo: remove index from alist and todolist
        set alen [llength $alist]
        for {set y 0} {$y < $alen} {incr y} {
          if {"[lindex $alist $y]"=="$ee_num"} {
            set alist [lreplace $alist $y $y]
            break 
          }
        }
        # incr num_entries -1                       ;# reduce data-table??
        # dont reduce data table, because it is indexed
      } else { Error "data could not be deleted" } 
    } elseif { $ee_num>=0 && $ee_num<$num_entries \
                          && "$ee_note" != ""} {  ;# modify
      DEBUG "EditEntry modify data-set $ee_num"
      if {[EditFile $ee_grp $ee_num] == 0} {
        DEBUG "EditEntry data set $ee_num of $ee_grp modified, do ReDraw"
      } else { Error "data could not be modified (ToDo?)" } 
    } elseif { $ee_num==$num_entries \
           && "$ee_note" == ""} {  ;# adding empty Note?
               Error "Warning: You tried to add an empty note. This will be ignored."
    } else   { Error "Warning: unknown status L855 ee_num=$ee_num $num_entries $ee_note" }
    # better ReadFiles?
    ShowMonth 0
    set old 0   ;# force recreation of todolist
    destroy .edit
    destroy .ee
  }
  # .ee tag bind .ee.cmds.ok  <Enter> ""  ??? ToDo
  button .ee.cmds.abort -text "abort" -command {
    destroy .ee
  }
  button .ee.cmds.delete -text "delete" -command {
    set ee_note ""
  }
  button .ee.cmds.help -text "help" -command {
    # local variables of Edit doe not exist here!?
    msgBox .helpEditEntry "Help EditEntry" \
     "For new entries the group (file@host) can be selected.\
      \nEarly and Late Warning must be given as time difference before the\
      \nTime. Length is given in houres and minutes relative to the Time.\
      \nException days, scripts and mails are not supported at the moment.\
      \nBe carful when editing the entries. Wrong syntax can cause\
      \ndestruction of data file (this will be changed in future versions).\
     "
  }
  pack  .ee.cmds -side top
  pack  .ee.cmds.ok .ee.cmds.abort .ee.cmds.delete .ee.cmds.help -side left
       
}

proc ReadFile { no name file server host } {  ;# if server let open
  global num_entries entryF entryD entryN entryR entryI flistU pc alist
  global flistO flistH  ;# used for sockets + handle which left open
  #  man 4 plan
  #  set entryD(0) "7/9/2005  14:15:0  0:0:0  0:0:0  0:0:0  ---------- 0 0"
  #  set entryR(0) ""
  #  set entryN(0) "N\tImpfung"
  #  set entryI(0) "dataindex_or_linenumer" ;# 0 = insert
  set numN 0     ;# index for data-sets (start with 1)
  set rows 0     ;# index for network file or line number for local file
  # set flistO($no) ""   ;# dummy socket (ToDo: call OpenSocket $no ?)
  # set flistH($no) -1   ;# dummy file no (open only if not open)
  DEBUG "ReadFile no= $no  name= $name  serv= $server  host= $host"
  if {$server == 0} {
    if [catch {open $file r} in] { 
      Error "ReadFile: open datafile $file failed (no data?)"
      return  
    }
    set rows -1
  } else {
    OpenSocket $no                ;# timeout ca. 5s
    set in     $flistO($no)
    set handle $flistH($no)
    if {"$in" == "" || $handle < 0} { return }
    DEBUG "ReadFile reset fileevent socket=$in"
    fileevent $in readable ""
    DEBUG "send: n$handle"
    puts $in    "n$handle" ;# read num rows
    flush $in
    set line [get_line $in]       ;# n31 rows
    if {$::timeout} { Error "ReadFile timeout"; return }
    DEBUG "recv: $line"
    scan "$line" "%*c%*d%d" rows
    # DEBUG "rows=$rows line=$line"
    DEBUG        "send: r$flistH($no) 0"
    puts  $flistO($no) "r$flistH($no) 0" ;# read all
    flush $flistO($no)
  }
  set subN 0   ;# line of data set $numN
  if { $rows != 0 } {
    while {![eof $in]} {   ;# can hang here if no input
      set line [get_line $in] 
      if {$::timeout} { Error "ReadFile timeout"; break }
      set idx [expr $numN+1]     ;# default index for files
      if { ([scan $line          "%d/%d/%d"     emm edd eyy] == 3) \
        || ([scan $line "rt%*d %d %d/%d/%d" idx emm edd eyy] == 4) } {
        # netplan-index does not start with 1, it counts every read
        #  dont close socket if you want to have valid index!
        set skip [string first "$emm/$edd/$eyy" "$line"]
        set entryD($num_entries) "[string range "$line" $skip 99]"
        set entryR($num_entries) ""
        set entryN($num_entries) ""
        set entryF($num_entries) $no    ;# file no.
        set entryI($num_entries) $idx
        lappend alist $num_entries      ;# expand index-list
        incr num_entries
        incr numN
        set  subN 0
      }
      if     { $numN <  9                } { DEBUG "$numN.$subN: $line" } \
      elseif { $numN == 9  && $subN == 0 } { DEBUG "..." } \
      elseif { $numN >= [expr $rows-1] &&\
                               $rows>8   } { DEBUG "$numN.$subN: $line" }
      if {$numN <= 0} { continue } ;# expect N for each data set
      # ToDo: nur eine Tabelle mit \n verketteten Zeilen!?
      if        { "[string index "$line" 0]" == "N" } {
          # scan "$line" "N\t%s" entryN([expr $num_entries - 1])
          set entryN([expr $num_entries - 1]) "[string range "$line" 2 99]"
      } elseif  { "[string index "$line" 0]" == "R" } {
          set entryR([expr $num_entries - 1]) "[string range "$line" 2 99]"
      }
      incr subN
      if { "[string index "$line" end]" == "\\" } { continue }
      if { $numN >= $rows && $rows>0 } { break }
    }
  }
  if {$server == 0} { catch {close $in} } else {
    DEBUG "ReadFile set fileevent socket=$in"
    fileevent $in readable "ListenToSocket $in"
  }
  DEBUG [format "ReadFile num_data= %4d sum= %4d name=$name" $numN $num_entries]
#  for {set x 0} {$x<$num_entries} {incr x} {
#    scan $entryD($x) "%d/%d/%d %d:%d" mm dd yy HH MM
#    DEBUG "$yy-$mm-$dd $HH:$MM $entryN($x)" 
#  }
}

# ( ToDo: add edit + delete)
# entry is modified in the list, now we update files (on server)
# - append if $nentry >= $num_entries
# - delete if $entryN($nentry) is ""
proc EditFile { nfile nentry } {
  global num_entries entryF entryD entryN entryR flistU entryI pc
  # entryI($nentry) contains the data-set number starting with 1 (0 means new)

  # set  name file server host num_entry 
  scan "$flistU($nfile)" "%*s%s%s%*d%*d%*d%*d%*d%d%s%*d" name file server host
  set file "[decode_filename "$file"]"     ;# decode %20 to space
  set numN 0
  set rows -1
  if {$nentry < 0} { Error "nentry<0"; return -1 }
  # (nentry == num_entries) ? append : delete or replace
  # ($entryI($nentry) == 0) ? append
  if {$server == 0 && $nentry <= $num_entries} {
    set ftmp $file.tmp
    if [catch {open $file r} in] { Error "EdFl: open $file failed"; return 1 }
    if [catch {open $ftmp w} fo] { Error "EdFl: open $ftmp failed"; return 1 }
    # copy head
    set numH 0
    while {![eof $in]} {
      gets $in line 
      if {[scan $line "%d/%d/%d" emm edd eyy] == 3} { break }
      if {"$line"!=""} {
        incr numH
        puts $fo "$line"         ;# copy data set
      } 
    }
    DEBUG "EditFile wrote $numH lines header"
    set numN 0
    for {set x 0} {$x<$num_entries || $x<=$nentry} {incr x} {
      if {$entryF($x)!=$nfile} {continue}
      if {"$entryN($x)"==""}   {continue}    ;# removed data set
      incr numN   ;# number of data set within (1..n)
      set  entryI($x) $numN
      puts $fo "$entryD($x)"
      if {"$entryR($x)"!=""} { puts $fo "R\t$entryR($x)" }
      puts $fo "N\t$entryN($x)"
    }
    DEBUG "EditFile wrote $numN data sets"
    close $fo
    close $in
    # ToDo: test if ok
    file rename -force $file $file.bak 
    file rename -force $ftmp $file
  } elseif { $server != 0 } {
    global flistO flistH
    OpenSocket  $nfile             ;# check if open, timout ca. 5s
    set in      $flistO($nfile)
    set handle  $flistH($nfile)
    if {"$in" == "" || $handle < 0} { return 1 }
    DEBUG "EditFile reset fileevent socket=$in"
    fileevent $in readable ""
    if { "$entryN($nentry)" == "" } {
      DEBUG "send: d$handle $entryI($nentry)"
      puts  $in "d$handle $entryI($nentry)" ;# delete
      flush $in
      set entryI($nentry) 0                 ;# mark as deleted? (insert)
    } else {                                ;# edit or append_if_idx=0
      DEBUG "send: w$handle $entryI($nentry) $entryD($nentry)\\"
      puts $in "w$handle $entryI($nentry) $entryD($nentry)\\" ;# idx=0 new
      if {"$entryR($nentry)"!=""} {
       DEBUG "send: R\t$entryR($nentry)\\" 
       puts $in "R\t$entryR($nentry)\\" 
      }
      DEBUG "send: N\t$entryN($nentry)"
      puts $in "N\t$entryN($nentry)"
      flush $in
      #   set line [gets $in]      ;# w[t|f]<row>
      set line [get_line $in]      ;# w[t|f]<row>
      if {$::timeout} { Error "EditFile timeout"; return }
      DEBUG "recv: $line"
      if {[string first "wt" "$line"] != 0} \
        { Error "write file $name@$host"; close $in; return 3 }
      scan "$line" "%*c%*c%d" idx
      set entryI($nentry) $idx
      DEBUG "EditFile store netplan-idx=$idx to dataset=$nentry"
    }
    DEBUG "EditFile set fileevent socket=$in"
    fileevent $in readable "ListenToSocket $in"
  } else { return -1 } ;# unsupported case (ToDo)
  return 0
}

# listen to one socket (can provide multiple handles)
#  - not sure if we can have racing conditions here (security)
#  - called if input data is available or connection is broken
#  - only one ListenToSocket per host to avoid double updates for two files
# ToDo: 1st read \\-ending sequence into tcl-list
#       2nd parse the read list
proc ListenToSocket { chan } {
  global flistO flistH numL
  global  num_entries entryD entryN entryR entryI entryF alist
  set update  0   ;# Flag "ShowMonth needed"
  set nB      0   ;# buffered lines
  set no      -1  ;# data file
  set x       -1  ;# data entry
  set handle  -1  ;# file within netplan connection
  fileevent $chan readable   ;# disable eventhandler
  DEBUG "ListenToSocket triggered socket=$chan"
  # can receive:
  #  Rt$handle $row  ...\\...  # update
  #  Rf$handle $row            # deleted
  #  ?Error ...\\...
  set line "\\"
  while {"[string index "$line" end]" == "\\" && ![eof $chan]} {
    # set line [gets $chan]
    set line [get_line $chan] 
    if {$::timeout} { Error "LTS timeout"; break }
    DEBUG "LTS recv: $line"
    set buff($nB) "$line"
    incr nB
  }
  # recalculate file number from channel and index
  if {"[string range "$buff(0)" 0 0]"=="R"} {
    scan $buff(0) "%*c%*c%d %d" handle idx
    for {set no 0} {$no<$numL} {incr no} {   ;# search handle
      if {$flistO($no)==$chan && $flistH($no)==$handle} { break }
    }
    DEBUG "LTS: found fileno $no (if less than $numL)"
    if {$no>=$numL} { return } ;# should not happen
    for {set x 0} {$x<$num_entries} {incr x} {
      if {$entryI($x)==$idx && $entryF($x)==$no} { break }
    }
    DEBUG "LTS: found entry $x (if less than $num_entries)"
  }
  if {"[string range "$buff(0)" 0 1]"=="?Error"} {   ;#  got netplan error
     return
  } \
  elseif {"[string range "$buff(0)" 0 1]"=="Rf"} {   ;#  delete entry
      # ToDo: remove index from alist and todolist
      set alen [llength $alist]
      for {set y 0} {$y < $alen} {incr y} {
        if {"[lindex $alist $y]"=="$x"} {
          set alist [lreplace $alist $y $y]
          break 
        }
      }
      DEBUG "LTS: found index $y (if less than $alen deleted)"
      if {$y>=$alen} {DEBUG "LTS * * * Warning * * * possible bug"}
      set update 1  ;#  force redraw (ToDo: only if shown month)
  } \
  elseif {"[string range "$buff(0)" 0 1]"=="Rt"} {
      DEBUG "overwrite data-set $x at file no=$no"
      set entryD($x) "1/1/1970 99:99:99 0:0:0 0:0:0 0:0:0 ---------- 0 0"
      set entryR($x) ""
      set entryN($x) ""   ;# note
      set entryF($x) $no  ;# file no.
      set entryI($x) $idx ;# append index for netplan
      if {$x>=$num_entries} {
        lappend  alist $x
        incr num_entries
        DEBUG "enlarge data-set by idx=$x (num_entries=$num_entries)"
      }
      DEBUG "LTS: update entry $x"
      for {set y 0} {$y<$nB} {incr y} {
        set line $buff($y)
        if {[scan $line "Rt%*d %*d %s" ndate] == 1 } {
          set skip [string first "$ndate" "$line"]
          set entryD($x) "[string range "$line" $skip 99]"
        } elseif  { "[string index "$line" 0]" == "N" } {
          set entryN($x) "[string range "$line" 2 99]"
        } elseif  { "[string index "$line" 0]" == "R" } {
          set entryR($x) "[string range "$line" 2 99]"
        }
      }
      set update 1
  } else { DEBUG "Warning: unexpected code received" }
  # check for unexpected disconnection 
  # (without, the eventhandler will called endless and consumes all CPU)
  if {[eof $chan]} {  ;# unexpected lost connection (line="")
    for {set no 0} {$no<$numL} {incr no} {   ;# search handle
      if {$flistO($no)==$chan} { 
        Error "connection no=$no closed"
        set flistO($no) ""
        set flistH($no) -1
      }
    }
    DEBUG "ListenToSocket reset fileevent socket=$chan"
    return ;# dont set event handler back
  }
  # ToDo: insert/edit entry in list
  # now we do primitiv and slow reread
  # or delete entries of that file and reload only that file
  if {$update == 1} { ShowMonth 0  }   ;# only ShowMonth
  if {$update == 3} { ReadFiles }   ;# incl. ShowMonth, ToDo: make it obsolete
  fileevent $chan readable "ListenToSocket $chan"  ;# enable eventhandler
}

proc OpenSocket { no } {
    global numL flistO flistH flistU
    # - check if socket is open (implicite done)
    # - check if other connection to server is open and copy socket name
    set xname ""         ;# against scan error on tclkit + XP
    set xserver ""
    set xhost ""
    scan "$flistU($no)" "%*s%s%*s%*d%*d%*d%*d%*d%d%s%*d" xname xserver xhost
    if {![info exist flistO($no)]} { set flistO($no) "" }
    if {![info exist flistH($no)]} { set flistH($no) -1 }
    set in     $flistO($no)
    set handle -1
    if {"$in" != ""} {   ;# check if it is still open
      if [catch {set x [fblocked $in]}] {  ;# x=0 if connected
        Error "fblocked failed on $in"
        set flistO($no) ""
        set in ""
      }
    }
    DEBUG "OpenSocket no= $no name= $xname host= $xhost  socket= $flistO($no)"
    if {"$flistO($no)" == ""} {
      set flistH($no) -1         ;# reset handle if no socket open
      for {set x 0} {$x < $numL} {incr x} {
        set name   ""    ;# against scan error on tclkit + XP
        set server  0    ;# against scan error on tclkit + XP
        set host   ""    ;# against scan error on tclkit + XP
        scan "$flistU($x)" "%*s%s%*s%*d%*d%*d%*d%*d%d%s%*d" name server host
        if {![info exist flistO($x)]} { set flistO($x) "" }
        if {"$host" == "$xhost" && $xserver == $server && "$flistO($x)"!=""} {
          set flistO($no) $flistO($x)
          set in          $flistO($x)
          break;
        }
      }
    }
    # - open socket
    if {"$flistO($no)" == ""} {
      set flistH($no) -1         ;# reset handle if no socket open
      if [catch {set in [socket $xhost 2983]}] {  ;# server also possible
        Error "connection to $xhost:2983 failed"
        return  -1
      }
      DEBUG "connect $xhost:2983  socket= $in"
      while {![eof $in]} { ;# break at timeout 
        set line [get_line $in] 
        if {$::timeout} { Error "OpenSocket timeout"; break }
        DEBUG "recv: $line"
        if {[string first "!t" "$line"] == 0} break  ;# !t2.1 enter ? for help
      }
      if {[string first "!t" "$line"] != 0} \
        { Error "no connection to netplan@$xhost"; return -2 }
      set flistO($no) $in
      global ver user pc
      DEBUG "send: =plan4tcl-$ver-$user@$pc<uid=0,gid=0,pid=[pid]>"
      puts  $in   "=plan4tcl-$ver-$user@$pc<uid=0,gid=0,pid=[pid]>"
      flush $in
      # use "." on netplan to list all connected clients
      # ToDo: netplan -a can respond with a "?Error ...\\"-message
      # DEBUG "OpenSocket set fileevent socket=$in for no=$no"
      # fileevent $in readable "ListenToSocket $no"
      # ToDo: buffer input and read from buffer?
    }
    
    # check for open handle
    # if {$handle != -1} {   ;# check if it is still open
    #   difficult to check
    # }
    if {$flistH($no) == -1} {
      set handle -1
      for {set x 0} {$x < $numL} {incr x} {
        set name   ""    ;# against scan error on tclkit + XP
        set server  0    ;# against scan error on tclkit + XP
        set host   ""    ;# against scan error on tclkit + XP
        scan "$flistU($x)" "%*s%s%*s%*d%*d%*d%*d%*d%d%s%*d" name server host
        if {![info exist flistH($x)]} { set flistH($x) -1 }
        if {"$host" == "$xhost" && $xserver == $server && $xname == $name &&\
             $flistH($x)!=-1} {
          set flistH($no) $flistH($x)
          set handle      $flistH($x)
          break;
        }
      }
    }
    # open handle
    if {$flistH($no) == -1} {
      set handle -1
      # DEBUG "OpenSocket reset fileevent socket=$in for no=$no"
      # fileevent $in readable ""
      # ToDo: buffer input and read from buffer?
      DEBUG "$in.send: o$xname"
      puts  $in   "o$xname"   ;# open urzs (file and name works?)
      flush $in
      # skip possible error message from "="-command
      # set line [gets $in]  ;# otw31   # open true writable N=31 or ?Error
      set line [get_line $in] 
      if {$::timeout} { Error "OpenSocket timeout"; break }
      DEBUG "recv: $line"
      if {[string first "?Error" "$line"] == 0} {
        while {"[string index "$line" end]" == "\\" && ![eof $in]} {
          set line [get_line $in] 
          if {$::timeout} { Error "OpenSocket timeout"; break }
          DEBUG "recv: $line"
        }
        set line [get_line $in] 
        if {$::timeout} { Error "OpenSocket timeout"; break }
        DEBUG "recv: $line"
      }
      if {[string first "ot" "$line"] != 0} \
         { Error "open remote file $xname@$xhost"; close $in; return }
      if {[string first "otr" "$line"] == 0} \
         { DEBUG "open remote file $xname@$xhost read only!" }
      set handle   0   ;# against scan error on tclkit + XP
      scan "$line" "%*c%*c%*c%d" handle
      # set flistO($no) $in     ;# dummy socket (ToDo: call CloseSocket $no ?)
      set flistH($no) $handle ;# dummy file no
      # DEBUG "handle=$handle line=$line"
      DEBUG "send: n$handle"
      puts  $in "n$handle" ;# read num rows
      flush $in
      # set line [gets $in]      ;# n31 rows
      set line [get_line $in] 
      if {$::timeout} { Error "OpenSocket timeout"; break }
      DEBUG "recv: $line"
      set rows   0   ;# against scan error on tclkit + XP
      scan "$line" "%*c%*d%d" rows
      # DEBUG "rows=$rows line=$line"
    }
    DEBUG "OpenSocket finished, socket= $in  handle=$handle"
    # return 0
}

# close all sockets (when server name or file name has changed)
proc CloseSockets { } {
  global flistO flistH numL
  # - close all open files
  #   - if element of file list dont exist, set dummy value
  for {set x 0} {$x < $numL} {incr x} {
    if {[info exists flistO($x)] != 1} { set flistO($x) "" }
    if {[info exists flistH($x)] != 1} { set flistH($x) -1 }
  }
  for {set x 0} {$x < $numL} {incr x} {
    if {"$flistO($x)" != ""} {
      set fd_socket $flistO($x)
      DEBUG "CloseSocket reset fileevent socket=$fd_socket"
      fileevent $fd_socket readable ""
      for {set y $x} {$y < $numL} {incr y} {
        if {"$flistO($y)"=="$fd_socket"} {
          if {$flistH($y)>=0} { puts $fd_socket "c$flistH($y)" } ;# close
          set flistO($y) ""       ;# reset socket name
          set flistH($y) -1       ;# reset file number
        }
      }
      DEBUG "send q to $fd_socket"
      puts $fd_socket "q"         ;# send quit
      catch {close $fd_socket}    ;# close, so we dont need flushing
    }
  }
  return 0
}

# ToDo: store also modification time and check regularly for updates
proc ReadFileList { file } {
  global num_entries flistU numL
  CloseSockets        ;# close open sockets before read new
  set numL 0
  #  man 4 plan (with installed day planner)
  #  plan_geb /home/jschulen/doc/plan_geb 0  3 0 0 0 0 localhost 0
  #  name file noWeekView color noMonthView alarm hidebits server hostname 0
  if [catch {open "$file" r} in] { 
    Error "ReadFileList: open $file failed"
    return  
  }
  if {[ gets $in line] >=0} {
    if { [string first "plan V1.8" "$line"] != 0 } {
      Error  "reading $file expect plan V1.8 but dont found it"
    }
  }
  while {[ gets $in line] >=0} {
    if { [string first "u" "$line"] == 0 } {
      set flistU($numL) "$line"
      incr numL
    }
  }
  close $in
  DEBUG "$numL file entries stored (cfg=$file)"
  # now we have to reread the files
}

# ToDo: Read remote plan into cash-file so even show termins if net is down
# ToDo: add red warn-icon if net is down 

#bind . <Alt-a> {focus .user.ent1}

# 1st create a list of today appointments (every day)
# if time has come, show and delete element from the list
# add new today appointments if files are updated + redraw
set old [clock seconds]
proc SetClock { } {
 global nowHHMM now old todolist entryD entryN entryR entryF flistU wdone
 global alist
 set now   [clock seconds]
 set nowHHMM "[clock format $now -format "%H:%M"]"  ;# format small month
 # DEBUG "SetClock nowHHMM= $nowHHMM = [clock format $now -format "%a %w %d.%m.%Y  %H:%M"]"
 if {![info exists wdone(2)]} {set wdone(2) {}}   ;# early warned
 if {![info exists wdone(3)]} {set wdone(3) {}}   ;# late  warned
 .mon.head.date configure -text "$nowHHMM"
 # a=Mon..Sun
 wm iconname . "[clock format $now -format "%H:%M %a"]"
 # test for new day and recreate todo list (ToDo)
 # JS-2012-11-30 fix 24h-to-early warning!? on TZ=:CET
 # if {[expr ($now / 86400) - ($old / 86400)] != 0}
 if {[clock format $now  -format "%y-%m-%d"]\
  != [clock format $old  -format "%y-%m-%d"]} {
   DEBUG "new day [clock format $now -format "%y-%m-%d %H:%M"], redraw month"
   ShowMonth 0
   # wegen TZ TErmine von tag+1 drin! 2013-11-21
#   set todolist [GetList     $now $now $alist]
   set todolist [GetList     [clock format $now  -format "%y-%m-%d"]\
          [clock format $now  -format "%y-%m-%d"] $alist]
# 2012-11-30 removed for simplicity
#   set todolist [concat [GetList     $now $now $alist]\
#                        [GetWarnList $now $now $alist]]
   set wdone(2) {}   ;# early warned
   set wdone(3) {}   ;# late  warned
   DEBUG "set todolist = $todolist"
 }
# DEBUG "start update2"
 update
# DEBUG "end   update2"
 # check todo list
 set tHH   0   ;# against scan error on tclkit + XP
 set tMM   0   ;# against scan error on tclkit + XP
 scan "$nowHHMM" "%d:%d" tHH tMM
 for {set x 0} {$x<[llength $todolist]} {incr x} {
   set xx [lindex $todolist $x]
   set nhh   0   ;# against scan error on tclkit + XP
   set nmm   0   ;# against scan error on tclkit + XP
   set whh   0   ;# against scan error on tclkit + XP
   set wmm   0   ;# against scan error on tclkit + XP
   set ahh   0   ;# against scan error on tclkit + XP
   set amm   0   ;# against scan error on tclkit + XP
   scan "$entryD($xx)" "%*s %d:%d:%*d %*s %d:%d:%*d %d:%d:%*d"\
        nhh nmm whh wmm ahh amm  ;# time early-warning(green), late-warning(yellow)
   set alarm 0
   scan "$flistU($entryF($xx))" "%*s%*s%*s%*d%*d%*d%d%*d%*d%*s%*d" alarm
   # no Warning if 00:00
   # Check if (Warn-)Time reached
   # DEBUG "SetClock $tHH:$tMM Alarm=$alarm $nhh:$nmm ($whh:$wmm,$ahh:$amm) no=$xx, grp=$entryF($xx) todo= $todolist done= $wdone(2), $wdone(3)"
   if {$alarm>0 && $nhh<25} {   ;# nhh=99 no alarm
     if {($tHH*60+$tMM) - ($nhh*60+$nmm - ($whh*60+$wmm)) >= 0} {set alarm 2}
     if {($tHH*60+$tMM) - ($nhh*60+$nmm - ($ahh*60+$amm)) >= 0} {set alarm 3}
     if {($tHH*60+$tMM) - ($nhh*60+$nmm)                  >= 0} {set alarm 4}
     if {($tHH*60+$tMM) - ($nhh*60+$nmm) - 15             >= 0} {set alarm 0}
   }
   set wtype [lindex {No Check Early_Warning Late_Warning Alarm} $alarm]
   if {$alarm>1 && $alarm<4} {
     # check if already alarmed
     if { [lsearch -exact $wdone($alarm) $xx] >= 0 } {continue}
     lappend wdone($alarm) $xx
   }     
   if {$alarm>1} {
     DEBUG "SetClock $tHH:$tMM alarm=$alarm $nhh:$nmm ($whh:$wmm,$ahh:$amm) no=$xx $wtype triggered, grp=$entryF($xx) todo= $todolist done= $wdone(2), $wdone(3)"
     # puts -nonewline "\x07"; flush stdout ;# ring a tone
     # background 1h verfaerben? xsetroot -bg 
     bell -nice
     msgBox .msgAlarm$xx "$wtype $xx" \
      "Plan4tcl $wtype at $nhh:[format "%02d" $nmm]\n\n$entryN($xx)"
   }
 
   if {$alarm>3 || $alarm==0 || $nhh>24} {
     set todolist [lreplace $todolist $x $x]  ;# remove, it is obsolete
     set x [expr $x - 1]
     DEBUG "SetClock $tHH:$tMM no=$xx removed, todo= $todolist done= $wdone(2), $wdone(3)"
   }
 }
 set old $now
 after 30000 SetClock   ;# 30s (for 60s we may skip a minute on busy CPU)
}

#############################################################################
# configure default fontsize
# myfont 0

#  own-file dateiname cfg nur ersetzt wenn Datei lesbar? sonst bleibt cfg
#  suse:   v1.8.7 looks at .dayplan etc. (link to .plan.dir/dayplan)
#  debian: v1.8.4 looks at .plan.dir/dayplan etc.
#      caching global files?
# store modification date/time and look regularly for updates
proc ReadFiles { } {
 global numL num_entries cfg user flistU alist todolist old
 set numL 0
 set alist {}  ;# reset index-list to all entries
 ReadFileList $cfg
 set num_entries 0
 set server "dummy" ;# without we get an "can't read ...: no such variable"
 set host   "dummy" ;#   ... with tclkit-win32 on XP (not on linux, wine!)
 for {set x 0} {$x<$numL} {incr x} {
   set name  ""   ;# against scan error on tclkit + XP
   set file  ""   ;# against scan error on tclkit + XP
   set server 0   ;# against scan error on tclkit + XP
   set host  ""   ;# against scan error on tclkit + XP
   # ToDo: Problem: Spaces in FileNames and Pathnames under XP
   #   write a parser for backspaces? "\\"="\" "\_"=" " ? compatibility?
   scan "$flistU($x)" "%*s%s%s%*d%*d%*d%*d%*d%d%s%*d" name file server host
   set file "[decode_filename $file]"    ;# %20 to space
   ReadFile $x $name $file $server $host
 }
 ShowMonth 0
 set todolist [GetList [clock format $old -format "%Y-%m-%d"]\
                       [clock format $old -format "%Y-%m-%d"] $alist]
 DEBUG "ReadFiles: set todolist = $todolist"
}

# called by EditFileList
proc WriteFileList { no } {
  global cfg numL flistU home
  global fl_name fl_file fl_serv fl_host fl_warn
  DEBUG "WriteFileList no= $no"
  if [catch {open "$cfg" r} in] { 
    Error "WriteFileList: open cfg=$cfg failed"
    return 1  
  }
  if [catch {open "$cfg.tmp" w} fo] { 
    Error "WriteFileList: open $cfg.tmp failed"
    return 1  
  }
  set subN 0
  while {[ gets $in line] >=0} {
    if { ([string first "u\t" $line] >= 0) } {
      DEBUG "WriteFileList subN= $subN"
      if {$subN == $no || ($subN == $numL-1 && $no==$numL) } {
        if {$no==0 && "$fl_name($no)"==""} { Error "entry 0 can't be deleted" }
        if {$no>0  || ($no==0 && "$fl_name($no)"!="")} { ;# write or left blank
          if {$no == $numL} { puts $fo "$line"} ;# append mode
          # u filename/loginname path nowview wcolor nomview alarm ...
          set file  ""   ;# against scan error on tclkit + XP
          set path  ""   ;# against scan error on tclkit + XP
          set i1     0   ;# against scan error on tclkit + XP
          set i2     0   ;# against scan error on tclkit + XP
          set i3     0   ;# against scan error on tclkit + XP
          set i4     0   ;# against scan error on tclkit + XP
          set i5     0   ;# against scan error on tclkit + XP
          set iserv  0   ;# against scan error on tclkit + XP
          set host  ""   ;# against scan error on tclkit + XP
          set i7     0   ;# against scan error on tclkit + XP
          scan "$flistU($no)" "%*s%s%s%d%d%d%d%d%d%s%d" name path\
             i1 i2 i3 i4 i5 iserv host i7
          set newU "[format "%-15s %-20s" $fl_name($no) [encode_filename "$fl_file($no)"]] $i1  $i2 $i3 $fl_warn($no) $i5 $fl_serv($no) $fl_host($no) $i7"
          # ToDo: copy/rename if new filename?
          DEBUG "WriteFileList insert at: $line"
          if {"$fl_name($no)" != ""} {
            # ToDo: remove from list? and correct list index
            DEBUG "WriteFileList insert     u\t$newU"
            puts $fo "u\t$newU"
            set flistU($no) "$newU"
          }
          incr subN
          continue
        }
      }
      incr subN
    }
    puts $fo "$line"  ;# copy datasets
  }
  close $fo
  close $in
  # ToDo: mark flistX as invalid?
  file rename -force "$cfg" "$cfg.bak"
  file rename -force "$cfg.tmp" "$cfg"
}

proc EditFileList { } {
 global numL flistU flistH flistO home host user pc
 set ww .fl
 catch {destroy .fl}  ;# destroy if Edit is called again
 toplevel .fl
 wm title .fl "File List"
 frame .fl.ft
 pack .fl.ft -side top
 label .fl.ft.grp  -text "No"          -width 6
 label .fl.ft.name -text "Name"        -width 16
 label .fl.ft.serv -text "Server"      -width 5
 label .fl.ft.file -text "Local path"  -width 30
 label .fl.ft.host -text "Server Host" -width 20
 label .fl.ft.warn -text "Alarm"       -width 5
 pack .fl.ft.grp .fl.ft.name .fl.ft.serv .fl.ft.file .fl.ft.host\
      .fl.ft.warn -side left
 global fl_name fl_file fl_serv fl_host fl_warn
 # ToDo: check for double files or names, remove/rename file
 for {set x 0} {$x<[expr $numL + 1]} {incr x} {
   set grp "[expr $x+1]:"
   if {$x >= $numL} {
     set flistU($x) "u\tnew [encode_filename $home]/plan_$x.dat 0 0 0 0 0 0 $pc 0"
     set flistO($x) ""   ;# default closed
     set flistH($x) -1
     set grp "new:"
   }
   set name  ""   ;# against scan error on tclkit + XP
   set file  ""   ;# against scan error on tclkit + XP
   set warn    0  ;# against scan error on tclkit + XP
   set server  0  ;# against scan error on tclkit + XP
   set host  ""   ;# against scan error on tclkit + XP
   scan "$flistU($x)" "%*s%s%s%*d%*d%*d%d%*d%d%s%*d" name file warn server host
   if {$x >= $numL} { set name "" } ;# mark as empty
   DEBUG "[format "%2d: %-15s %-20s %d %d %s" $x $name $file $server $warn $host]"
   frame .fl.f$x
   pack .fl.f$x -side top
   set fl_name($x) $name     ;# group name
   set fl_file($x) [decode_filename $file]    ;# local filename
   set fl_serv($x) $server   ;# if server 
   set fl_host($x) $host     ;# name
   set fl_warn($x) $warn     ;# Alarm enabled?
   label       .fl.f$x.grp  -text "$grp"              -width 6\
      -background "[string range\
         "#ddd#dbb#bdb#ddb#bbd#dbd#bdd#bbb" \
         [expr ($x%8)*4] [expr ($x%8)*4+3]]"
   entry       .fl.f$x.name -textvariable fl_name($x) -width 16
   checkbutton .fl.f$x.serv -variable     fl_serv($x) -width 5
   entry       .fl.f$x.file -textvariable fl_file($x) -width 30
   entry       .fl.f$x.host -textvariable fl_host($x) -width 20
   checkbutton .fl.f$x.warn -variable     fl_warn($x) -width 5
   pack .fl.f$x.grp .fl.f$x.name .fl.f$x.serv .fl.f$x.file .fl.f$x.host\
     .fl.f$x.warn -side left
 }
 frame .fl.bt
 pack .fl.bt -side top
 button .fl.bt.ok    -text "ok" -underline 0 -command {
   CloseSockets ;# for the case that the server or file name has changed
   for {set x 0} {$x<[expr $numL + 1]} {incr x} {
     if {"$fl_name($x)"==""} { Log "discard entry $x" }  ;# delete?
     if {"$fl_file($x)"==""} { continue }
     if {"$fl_host($x)"==""} { continue }
     WriteFileList $x   ;# ToDo close if socket and name has changed
   }
   # DEBUG "x=$x numL=$numL"
   if { "$fl_name($numL)" != "" } {
     # ToDo: create file if not readable and not server
     set x $numL
     set f1 ""
     if {$fl_serv($x) == 0} {
       Log "New datafile $fl_file($x)"
       if [catch {open "$fl_file($x)" r} f1] {   ;# file readable?
         if [catch {open "$fl_file($x)" w} f1] { ;# create it
           Error "create datafile $fl_file($x)"
         } else {
           Log "EditFileList: empty datafile $fl_file($x) created"
           puts $f1 "# datafile $fl_file($x) created by plan4tcl"
         }
       } else {
         Log "EditFileList: datafile $fl_file($x) does already exist"
       }
       if {"$f1" != ""} { catch { close $f1 } }
     }
     incr numL
   }
   ReadFiles
   destroy .fl
 }
 button .fl.bt.abort -text "abort" -underline 0 -command { destroy .fl }
 button .fl.bt.help  -text "help"  -underline 0 -command {
  msgBox .helpFileList "Help FileList" \
   "If you want to remove a file entry, exit and edit the config file.\
    \nThe name identifies the file on the netplan server if the server\
    \ncheck box is checked. If you change file or server name, data is\
    \nnot transferred to the new named file.
 "
 }
 pack .fl.bt.ok .fl.bt.abort .fl.bt.help -side left
}

DEBUG "L2039"
ReadFiles   ;# incl. ShowMonth 0
DEBUG "L2041"

# DEBUG "[GetList 2005-08-08 2005-08-08 $alist]"
# DEBUG "2005-08-24 [GetWarnList 2005-08-24 2005-08-24 $alist]"
# DEBUG "2005-08-25 [GetWarnList 2005-08-25 2005-08-25 $alist]"

SetClock
DEBUG "L2048"

## 2012-11-30 faster if seperated? no still 14s on 6M/64k-DSL
#for {set week 0} {$week<6} {incr week} {
#  for {set wday 0} {$wday<7} {incr wday} {
#    bind  $w.w$week.d$wday.l <ButtonPress-1>   { ShowDay "%W"} ;# 2012-11-30
#    bind  $w.w$week.d$wday.t <ButtonPress-1>   { ShowDay "%W"}
#    bind  $w.w$week.d$wday   <ButtonPress-1>   { ShowDay "%W"} ;#2012-11-30
#  }
#}

# read data fuer TAG=m/d/yyyy
# ~/.plan.dir/dayplan
#  or call plan plan -t [ab_wann [Tage]]
#  Thu, 28.7.05    -       -       jschulen: Kind Feiern? Ankuend!
#  Sat, 30.7.05    -       -       jschulen: Herbert grillen
#  Mon, 15.8.05    12:00   -       jschulen: Betriebsarzt
