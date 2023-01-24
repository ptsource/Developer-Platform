#!/usr/bin/python

from Tkinter import *
from tkMessageBox import *

# Calculator is a class derived from Frame.  Frames, being someone generic,
# make a nice base class for whatever you what to create.
class Calculator(Frame):

    # Create and return a packed frame.
    def frame(this, side): 
        w = Frame(this)
        w.pack(side=side, expand=YES, fill=BOTH)
        return w

    # Create and return a button.
    def button(this, root, side, text, command=None): 
        w = Button(root, text=text, command=command) 
        w.pack(side=side, expand=YES, fill=BOTH)
        return w

    # Enter a digit.
    need_clr = False
    def digit(self, digit):
        if self.need_clr:
            self.display.set('')
            self.need_clr = False
        self.display.set(self.display.get() + digit)

    # Change sign.
    def sign(self):
        need_clr = False
        cont = self.display.get()
        if len(cont) > 0 and cont[0] == '-':
            self.display.set(cont[1:])
        else:
            self.display.set('-' + cont)

    # Decimal
    def decimal(self):
        self.need_clr = False
        cont = self.display.get()
        lastsp = cont.rfind(' ')
        if lastsp == -1:
            lastsp = 0
        if cont.find('.',lastsp) == -1:
            self.display.set(cont + '.')

    # Push a function button.
    def oper(self, op):
        self.display.set(self.display.get() + ' ' + op + ' ')
        self.need_clr = False

    # Calculate the expressoin and set the result.
    def calc(self):
        try:
            self.display.set(`eval(self.display.get())`)
            self.need_clr = True
        except:
            showerror('Operation Error', 'Illegal Operation')
            self.display.set('')
            self.need_clr = False

    def __init__(self):
        Frame.__init__(self)
        self.option_add('*Font', 'Verdana 12 bold')
        self.pack(expand=YES, fill=BOTH)
        self.master.title('Simple Calculator')

        # The StringVar() object holds the value of the Entry.
        self.display = StringVar()
        e = Entry(self, relief=SUNKEN, textvariable=self.display)
        e.pack(side=TOP, expand=YES, fill=BOTH)

        # This is a nice loop to produce the number buttons.  The Lambda
        # is an anonymous function.
        for key in ("123", "456", "789"):
            keyF = self.frame(TOP)
            for char in key:
                self.button(keyF, LEFT, char,
                            lambda c=char: self.digit(c))

        keyF = self.frame(TOP)
        self.button(keyF, LEFT, '-', self.sign)
        self.button(keyF, LEFT, '0', lambda ch='0': self.digit(ch))
        self.button(keyF, LEFT, '.', self.decimal)

        # The frame is used to hold the operator buttons.
        opsF = self.frame(TOP)
        for char in "+-*/=":
            if char == '=':
                btn = self.button(opsF, LEFT, char, self.calc)
            else:
                btn = self.button(opsF, LEFT, char, 
                                  lambda w=self, s=char: w.oper(s))

        # Clear button.
        clearF = self.frame(BOTTOM)
        self.button(clearF, LEFT, 'Clr', lambda w=self.display: w.set(''))

# Make a new function for the - sign.  Maybe for . as well.  Add event
# bindings for digits to call the button functions.

# This allows the file to be used either as a module or an independent
# program.
if __name__ == '__main__':
    Calculator().mainloop()