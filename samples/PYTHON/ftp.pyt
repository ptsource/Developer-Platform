#!/usr/bin/python

import sys
import re
from Tkinter import *
from tkMessageBox import *
from ftplib import *

# Python DESPERATELY needs ++.  This little class could be exended in
# several ways, but it does what I need here.
class counter:
    '''This class takes an initial integer, and delivers a sequence of 
       increasing values.'''
    def __init__(self, i):
        self.val = i

    # This is i++
    def up(self):
        'Increment and get old value'
        i = self.val
        self.val = self.val + 1
        return i

# Close the connection and terminate pgm.
def term(conn):
    "Close the connection, if possible, then quit."
    if conn:
        try:
            conn.quit()
        except:
            try:
                conn.close()
            except:
                "Nothing"
    sys.exit()

# Login window.
class LoginWindow:
    '''The login window asks for the remote host and the user credentials,
       and a button to initiate the login when the fields are ready.'''

    # Generate s label/entry pair for the login window.  These will be 
    # appropriately gridded on row row inside par.  Text box has width
    # width and places its contents into the reference $ref.  If $ispwd,
    # treat it as a password entry box.  Returns the text variable which
    # gives access to the entry.
    def genpair(self, row, text, width, ispwd=False):
        "Generate a label and entry box pair."
        tbut = Label(self.main, text = text)
        tvar = StringVar(self.main)
        lab = Entry(self.main, background='white', 
                    foreground='black', 
                    textvariable=tvar,
                    width=width)
        if ispwd: lab.configure(show='*')
        tbut.grid(row=row, column=0, sticky='nse')
        lab.grid(row=row, column=1, sticky='nsw')

        return tvar

    # Log into the remote host.  If successful, start the directory loader.
    # Modes are: 1: Anonymous, 2: User, 3: Return, which does anon if the
    # user infor was not filled in, and user otw.
    def do_login(self, mode):
        '''Login action'''
        
        host = self.host.get()
        acct = self.acct.get()
        password = self.password.get()

        # Adjust user data by mode.
        if mode == 1 or (mode == 3 and not acct and not password):
            acct ='anonymous'
            if not password:
                password = 'anonymous'

        # Make sure we're all filled in.
        if not host or not acct or not password:
            showerror(self.main,"You must provide a user name and password.")
            return

        # Attempt to connect to the remote host and log in
        try:
            self.conn = FTP(host, acct, password)
            self.conn.set_pasv(True)
        except:
            descr = sys.exc_info()[1]
            showerror(self, descr)
            return

        self.listwin.setconn(self.conn)
        self.main.destroy()

    def __init__(self, main, listwin, titfont, titcolor):
        self.main = Toplevel(main)
        self.main.title('FTP Login')

        self.listwin = listwin
        self.conn = 0

        # This counts through the rows, which makes it easier to modify
        # the program.
        row = counter(0)

        # Label at the top of window.
        toplab = Label(self.main, text="FTP Server Login", justify='center',
                       font=titfont, foreground=titcolor)
        toplab.grid(row=row.up(), column=0, columnspan=2, sticky='news')

        # Hostname entry
        self.host = self.genpair(row.up(), 'Host:', 25)

        # Login buttons
        bframe = Frame(self.main)
        bframe.grid(row=row.up(), column=0, columnspan=2, sticky='news')
        go = Button(bframe, text='Anon. Login',
                    command=lambda mode=1: self.do_login(mode))
        go.pack(side='left', expand='yes', fill='both')
        go = Button(bframe, text='User Login',
                    command=lambda mode=2: self.do_login(mode))
        go.pack(side='left', expand='yes', fill='both')

        # Login and password entries.
        self.acct = self.genpair(row.up(), 'Login:', 15)
        self.password = self.genpair(row.up(), 'Password:', 15, True)

        stop = Button(self.main, text='Exit', 
                      command=lambda c=self.conn: term(c))
        stop.grid(row=row.up(),column=0, columnspan=2, 
                  sticky='news')

        # CR same as pushing login.
        self.main.bind('<KeyPress-Return>',
                       lambda event, mode=3: self.do_login(mode))

class FileWindow(Frame):
    def __init__(self, main):
        Frame.__init__(self, main)

        # Set up the title appearance.
        titfont = ( 'Arial', 16, 'bold' )
        titcolor = '#228800'

        self.conn = 0

        # Label at top.
        toplab = Label(self, text='FTP Download Agent',
                       justify='center', font=titfont,
                       foreground=titcolor)
        toplab.pack(side=TOP, fill=X)

        # Status label.
        self.statuslab = Label(self, text='Not Logged In',
                          justify = 'center')
        self.statuslab.pack(side=TOP, fill=X)

        # Exit button
        exbut = Button(self, text = 'Exit', 
                       command=lambda c=self.conn: term(c))
        exbut.pack(side=BOTTOM, fill=X)

        # List area with scroll bar.  The list area is disabled since we
        # don't want the user to type into it.
        self.listarea = Text(self, height=10, width=40, cursor='sb_left_arrow',
                             state=DISABLED)
        scr = Scrollbar(self, command=self.listarea.yview)
        self.listarea.configure(yscrollcommand=scr.set)
        scr.pack(side=RIGHT, fill=Y)
        self.listarea.pack(side=LEFT)

        # This RE is needed to match file names from DIR
        self.filere = re.compile('^[\-d]([r\-][w\-][x\-]){3}')

        # Bind the system exit button to our exit.
        main.protocol('WM_DELETE_WINDOW', lambda c=self.conn: term(c))

        # Create the login window.
        LoginWindow(main, self, titfont, titcolor)

    # This is the call-back for the FTP libraries which receives lines of
    # of dir listing from the FTP server.
    def dirent(self, line):
        "Handle one line of the directory listing."

        # Real lines start with the perm bits.  And we don't want specials.
        if self.filere.search(line) == None: return

        # Extract the useful parts, toss the bones.  The limit keeps us from
        # dividing file names containing spaces.
        parts = line.split(None, 9)
        if len(parts) < 9: return
        fn = parts.pop()
        if fn == '..': self.sawdots = True
        if parts[0][0] == 'd':
            self.dirs.append(fn)
        else:
            self.files.append(fn)

    # Change the color of a tag for entering and leaving.  Unfortunately, there
    # is no active color for tags in a text box.
    def recolor(self, tag, color):
        "Set the color of a particular tagged area in the list area"
        self.listarea.tag_config(tag, foreground=color)

    # Do a CD and load the contents.  If there is no directory name, skip
    # the CD.
    def load_dir(self, dir):
        "Change to a directory and load its content into the listing window."
        if dir:
            try:
                self.conn.cwd(dir)
            except:
                showerror(self, sys.exc_info()[1])
            self.statuslab.configure(text="[Loading " + dir + "]")
        else:
            self.statuslab.configure(text='[Loading Home Dir]')
        self.update()

        # Get the list of files.
        self.files = [ ]
        self.dirs = [ ]
        self.sawdots = False
        self.conn.retrlines('LIST', self.dirent)

        # Add .. if not present, then sort the list.
        if not self.sawdots: self.dirs.append('..')
        self.files.sort()
        self.dirs.sort()

        # Clear the old contents from the directory listing box.
        self.listarea.configure(state='normal')
        self.listarea.delete('1.0',END)

        # Fill in the directories.  Bind for directory load (us).
        ct = 0
        while self.dirs != []:
            fn = self.dirs.pop(0)
            tagname = "fn" + str(ct)
            self.listarea.insert(END, fn+"\n", tagname)
            self.listarea.tag_config(tagname, foreground='#4444ff')
            self.listarea.tag_bind(tagname, '<Button-1>', 
                                  lambda w, f=fn: self.load_dir(f))
            self.listarea.tag_bind(tagname, '<Enter>', 
                                  lambda w, t=tagname, c='#0000aa':
                                   self.recolor(t,c), '+')
            self.listarea.tag_bind(tagname, '<Leave>', 
                                  lambda w, t=tagname, c='#4444ff':
                                   self.recolor(t,c), '+')
            ct = ct + 1

        # Fill in the files. Bind for download.
        while self.files != []:
            fn = self.files.pop(0)
            tagname = "fn" + str(ct)
            self.listarea.insert(END, fn+"\n", tagname)
            self.listarea.tag_config(tagname, foreground='red')
            self.listarea.tag_bind(tagname, '<Button-1>', 
                                  lambda w, f=fn: self.dld_file(f))
            self.listarea.tag_bind(tagname, '<Enter>', 
                                  lambda w, t=tagname, c='#880000':
                                   self.recolor(t,c), '+')
            self.listarea.tag_bind(tagname, '<Leave>', 
                                  lambda w, t=tagname, c='red':
                                   self.recolor(t,c), '+')
            ct = ct + 1

        # Lock it up so the user can't mess with it.
        self.listarea.configure(state='disabled')

        # Update the status label.
        try:
            loc = self.conn.pwd()
        except:
            showerror(self, sys.exc_info()[1])
            loc = '???'
        self.statuslab.configure(text=loc)

    # Download the file.
    def dld_file(self,fn):
        "Perform a file download."

        # Attempt to open the local file.
        try:
            ofn = open(fn, 'w')
        except:
            showerror(self, sys.exc_info()[1])
            return

        # Announce.
        self.statuslab.configure(text="[Retrieving" + fn + "]")
        self.update()

        # Get the file.
        try:
            self.conn.retrbinary('RETR ' + fn, ofn.write)
        except:
            showerror(self, sys.exc_info()[1])
            self.statuslab.configure(text='')
        else:
            self.statuslab.configure(text='Got ' + fn)
        ofn.close()

    # This is a hook that the login window calls after a successful login.
    # The login window makes the connection and attempts to login.  When this
    # succeeds, it calls setconn() and destroys itself.  Setconn records the
    # connection (which the login box created), then does the initial
    # directory load.
    def setconn(self, conn):
        "Set the connection and perform the initial directory load"

        self.conn = conn
        self.load_dir('')

# Create the main window, set the default colors, create the GUI, then
# fire the sucker up.
main = Tk()
main.title("FTP Download")
main.option_add("*background", '#E6E6FA')
main.option_add("*activebackground", '#FFE6FA')
main.option_add("*foreground", '#0000FF')
main.option_add("*activeforeground", '#0000FF')
FileWindow(main).pack()

main.mainloop()
