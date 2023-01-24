#!/bin/python

# Simple button demo.
from Tkinter import *

# Change the label text
def changelab():
    lab.configure(text="A Pushed Button!")

# Create the root window.
root = Tk()

# Create a label.
lab = Label(root, text="A Button")

# Make the label appear.
lab.grid(row=0, column=0)

# Make a button and make it appear.
but = Button(root, text="Push Me", command=changelab)
but.grid(row=1, column=0)

# Push the on button
root.mainloop()
