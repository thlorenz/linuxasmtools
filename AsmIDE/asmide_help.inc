     AsmIDE - Integrated Development Enviornment for Assembler

Introduction
------------

AsmIDE provides tools to develop assembler programs.  Included
is a editor, debugger, library, reference system, and tools to
simplify selecting/calling assemblers.  The goal is to make
assembler coding easy.

Invoking AsmIDE
---------------

AsmIDE can be started with or without a filename.  If
no filename is provided, it will provide a menu of options.

Start-up process
----------------

Initially AsmIDE needs a source file name
or existing file.  If a file name is provided
it will read this file and work can begin.  If
a new file name is needed, it also asks about
assemblers and gives the option of inserting
a standard source template.

We can help AsmIDE determine the assembler type
by using the following file name extensions:

  sourcefile.nasm  <- nasm source
  sourcefile.fasm  <- fasm source
  sourcefile.yasm  <- yasm source
  sourcefile.s     <- as source

Development process
-------------------

Program development consists of the steps:
 0. design program          (F1 calls assembler reference)
 1. edit source file        (editor window is default state)
 2. compile                 (F3 calls compiler)
 3. fix compile errors      (error window appears after compile)
 4. debug compiled program  (F4 calls debugger)

AsmIDE provides tools for each step.  Additionally it will
check installed programs and warn if anything is missing.
The following utilities are required:

 - ld  (GNU link utility)
 - make (GNU compile tool)
 - touch (GNU file status updater)

Step 0 (design)
  AsmIDE can't do design, but it can help with exploring
  the Linux programming enviornment.  It can also describe
  library functions that make coding much easier.  Both of
  these services are provided by AsmRef.  Pressing the
  F1 key will bring up a menu of information that can be
  selected with up/down cursor keys.

Step 1 edit
  AsmIDE starts in the editor and uses the standard
  cursor movement and edit keys.  They are:

  up arrow - cursor up
  down arrow - cursor down
  right arrow - cursor right
  left arrow - cursor left
  del - delete char
  rubout - delete char to left
  home - start of line
  end - end of line

  Other editing functions are attached to function keys
  and are described below.
  
Step 2 compile
  Programs can be compiled at any time by pressing
  the F3 key.  Results are shown in top window and
  a small edit window is kept at bottom.

Step 3 fix errors
  Compile errors show in top window and will remain
  until the F9 key is pressed.  We can fix errors and
  keep compiling until a executable is created.

Step 4 debug
  Once a executable exists, the F4 key will start the
  debugger.
  

F1-AsmRef
---------

AsmRef provides a menu of Linux assembler information.

F2-Help
-------

This is the help information

F3-Compile
----------

The compile function will try to determine which assembler
to use by the following steps:
 1. check source file extensions for: nasm,yasm,fasm,s
 2. look for existing asmide_makefile and use it.
 3. ask which assembler to use.
When the assembler is determined, the asmide_makefile is
written and used by compile. If AsmIDE gets confused about
which assembler to use, delete the file asmide_makefile
and it will restart the assembler selection process.

F4-Debug
--------

The debugger function calls minibug which is installed
with AsmIDE

F5-Insert File
--------------

Insert file is a editor function, that inserts a file
at cursor posstion.

F6-Goto Line
------------

The goto function asks for a line number, then moves
the cursor to selected line.

F7-Find text
------------

Find will search for text and ignores the case of characters.

F8-Cut Line
-----------

Cut line removes the line at cursor position.

F9-Close compile window
-----------------------

After compile this window appears and can be removed
by pressing F9.

F10 - exit and save
-------------------

When F10 is  pressed the origional file is renamed
with a '~" at end, and the edited file saved.

