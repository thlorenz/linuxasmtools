# LinuxAsmTools

[website](https://thlorenz.github.io/linuxasmtools-net/)

## Disclaimer

This collection was created by Jeff Owens and downloaded from [the only place I could
find](http://home.myfairpoint.net/fbkotler/asmtools-0.9.69.tar.gz) as indicated in [this
thread](http://forum.nasm.us/index.php?topic=1056.5;wap2).

Originally they were hosted at [linuxasmtools.net](http://linuxasmtools.net), but that site seems to be down.

## LICENSE

As far as I could gather most/all of the code was released under the GPL3+ license.

```asm
;   Copyright (C) 2007 Jeff Owens
;
;   This program is free software: you can redistribute it and/or modify
;   it under the terms of the GNU General Public License as published by
;   the Free Software Foundation, either version 3 of the License, or
;   (at your option) any later version.
;
;   This program is distributed in the hope that it will be useful,
;   but WITHOUT ANY WARRANTY; without even the implied warranty of
;   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;   GNU General Public License for more details.
;
;   You should have received a copy of the GNU General Public License
;   along with this program.  If not, see <http://www.gnu.org/licenses/>.
```

## Original Readme

This package is part of AsmTools (a collection of
programs for assembler developent on Linux X86 cpu's.)


The AsmTool family consists of:
  debuggers
  editors
  file managerss
  disassemblers
  libraries
  utilities
  sample programs
  
For support and discussions signup at yahoogroups
mailing list DesktopLinuxAsm. To join by email
send a blank email to:

   DesktopLinuxAsm-subscribe@yahoogroups.com

Or visit http://groups.yahoo.com/group/DesktopLinuxAsm

The latest version of programs and additional
information is available at either:

 http://thlorenz.github.io/linuxasmtools-net    (terminal/console programs)
 http://thlorenz.github.io/linuxasmtools-net/x   (x window programs)

Individual program may be at source forge.
Construct the sourceforge URL as follows:

 http://sourceforge.net/projects/asmedit
 http://sourceforge.net/projects/asmbug
 http://sourceforge.net/projects/asmref
 http://sourceforge.net/projects/asmmgr

 
Installing
----------

see file INSTALL for more information.
The AsmTool package consists of many programs which
can be installed separatly.  All programs are
selfcontained but the file managers and asmedit
assume other programs are available.

The easiest way to get started is to install the
complete package (AsmTools).  To read the documentation
install AsmRef and execute it in a terminal.  If sudo
isn't available use "su". 

   cd AsmRef
   sudo make install
   asmref


Limitations
-----------

AsmTool programs only run on X86 processors using
the Linux kernel version 2.4 or later.  It isn't
portable to other UNIX flavors but over 90 percent
of all UNIX installations are for Linux X86.

Most AsmTools runs in a console and terminal.  When
run in the console, only keyboard commands are
available. The console/terminal programs are
built using asmlib.

AsmTools that require a x server are:
  asmbug - debugger
  tracex - trace x server communication
  xhelper - automate desktop programss
  asmlibx - library needed to build asmbug
            and xhelper


Features
--------

Many of the AsmTool programs are described within
AsmRef and that may be a good place to begin.  Each
program also has some additional documentation in
the source files.

When programs are installed as a .deb or .rpm look
for documentation at:

  /usr/share/doc/asmref
  /usr/share/doc/(name of package)
  man (name of package)
