## How to use context help

If you have a  (.chm) which explains something based on keyword index, then you can set up user tools to look up keyword you just have typed in without escaping from the editor.
The following example shows how to set up 'User Tools' to use LaTeX help file. We assume that you have LaTeX help file (LATEX2E.CHM) in the following directory.
C:\texmf\doc\latex\help\LATEX2E.CHM
1. Open Preferences dialog box and select User Tools page
2. Select an empty slot and fill with the following arguments.

 * Menu Text: LaTeX Context Help
 * Command: C:\texmf\doc\latex\help\LATEX2E.CHM
 * Argument: $(CurrWord)
 * Initial dir: $(FileDir)
 * Hot key: F1
 * Close on exit: Yes
 * Save before execute: No
After that, you can press F1 to see the search index when the caret is on the word you want to look up.
