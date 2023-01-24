#!/usr/bin/python

#
# This shows the canvas widget, and a few other random things worth having a
# look at.
#

from Tkinter import *
from tkMessageBox import *
import random
import sys

main = Tk()
main.title("Canvas")

# Create the canvase.
cwid = 300
cheight = 300
canvas = Canvas(main, width=cwid, height=cheight, bg='blue')
canvas.pack()

#
# Simple actions.
def oval_act(ev):
    showerror(main, "Don't click on the oval.")

#showerror(main, "You're in the oval, at " + str(ev.x) + " " + str(ev.y))

colors = [ 'red', 'green', 'yellow', '#9977FF',  '#225555' ]
def rect_act(obj):
    global colors
    c = colors.pop()
    colors = [c] + colors
    canvas.itemconfigure(rect, fill=c)

# Draw some shapes and bind them to button events.
oval = canvas.create_oval(10, 30, 150, 100, fill='white')
canvas.tag_bind(oval, '<Button-1>', oval_act)
rect = canvas.create_rectangle(100, 130, 250, 250, fill='red')
canvas.tag_bind(rect, '<Button-1>', rect_act)
coords = canvas.create_text(160, 50, anchor='nw', text='')

# Make the oval update the mouse position.
def disp(ev):
    canvas.itemconfigure(coords, text = "%d,%d" % (ev.x, ev.y))
    
def undisp(ev):
    canvas.itemconfigure(coords, text = "")

canvas.tag_bind(oval, '<Enter>', disp)
canvas.tag_bind(oval, '<Motion>', disp)
canvas.tag_bind(oval, '<Leave>', undisp)

# Exit button
exbut = Button(main, text='Exit', command=sys.exit)
canvas.create_window(250,70,window=exbut)

# Randomly moving dot.
dot = False
def redot():
    global dot
    if dot: canvas.delete(dot)
    dotx = random.randrange(0,cwid-10)
    doty = random.randrange(0,cwid-10)
    dot = canvas.create_oval(dotx, doty, dotx+10, doty+10, fill='#9999FF')
    main.after(1000,redot)
redot()

main.mainloop()