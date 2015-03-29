# Generic makefile to compile and produce binary for all
# .asm files in local directory
#
# usage:  make  - make all asm files
#         make clean - touch all source files
#         make doc - extract documentation from sources
######################################################
#
# modify the following as needed
#
# select assembler, nasm, fasm, as, yasm
#
assembler := nasm
#
# copy stripped executables to parent directory?  yes,no
#
copy_executable := yes

home = $(HOME)
version := $(shell cat VERSION)
SHELL = /bin/bash
here = $(shell pwd)
#                      
#
# hunt for library file, if this fails then set LIBS to file location
# hunt at local dir, parent dir, then at $HOME/.a/
lib1 = $(shell if test -f asmlib.a ; then echo asmlib.a ; fi)
lib2 = $(shell if test -f ..//asmlib.a ; then echo ..//asmlib.a ; fi)
lib3 = $(shell if test -f ../../asmlib.a ; then echo ../../asmlib.a ; fi)
lib4 = $(shell if test -f /usr/lib/asmlib.a ; then echo /usr/lib/asmlib.a ; fi)

ifeq "$(lib4)" ""
#$(shell echo "$HOME/.a library not found" )
else
LIBS := $(lib4)
endif

ifeq "$(lib3)" ""
#$(shell echo "../../ library not found" )
else
LIBS := $(lib3)
endif
  
ifeq "$(lib2)" ""
#$(shell echo "no parent library")
else
LIBS := $(lib2)
endif

ifeq "$(lib1)" ""
#$(shell echo "no local library")
else
LIBS := $(lib1)
endif

ifeq "$(LIBS)"  ""
LIBS = asmlib.a
endif
 
#LFLAGS =
LFLAGS = -static

# the following variables are probably ok
######################################################
ifeq "$(assembler)" "nasm"
CC = nasm
DEBUG = -g
CFLAGS = -O2 -f elf
endif

ifeq "$(assembler)" "as"
CC = as
DEBUG = -stabs
CFLAGS =
endif

ifeq "$(assembler)" "yasm"
CC = yasm
DEBUG = -g stabs
CFLAGS = -f elf
endif


ifeq "$(assembler)" "fasm"
CC = fasm
DEBUG =
CFLAGS =
endif

SHELL = /bin/bash
here = $(shell pwd)

.SUFFIXES : .o .asm

dirs = $(shell dir -d *)
targets := $(shell dir *.asm | sed -e 's/.asm//g')
srcs := $(shell dir *.asm)
objs := $(shell dir *.asm | sed -e 's/.asm/.o/g')     


# template for each source compile
%.o:    %.asm
	$(CC) $(DEBUG) $(CFLAGS) $<

# template for link
%:      %.o
	ld $^ $(LFLAGS) -o $@ $(LIBS)

all:	pre $(targets) post

$(objs):

pre:
	 touch *.asm
	  @if test -e $(LIBS) ; then \
             echo "asmlib found, compilng FileSet" ; \
          else  \
	     echo "asmlib not found, needed by FileSet" ; \
             suspend ; \
          fi

post:
#ifeq "$(copy_executable)" "yes"
#	@for d in $(targets); do echo $$d ; cp $$d ../../ ; strip ../../$$d ; done
#endif
#	cp -f a_status ../../
#	strip ../../a_config

#
# the "install" program uses flags
#        -D       create any needed directories
#        -s       strip executables
#        -m 644   set file attributes to 644 octal
install:
	@if test -w /etc/passwd ; \
	then \
	 echo "installing fileset in /usr/bin" ; \
	 install -s fileset /usr/bin/fileset ; \
	 install -D -m 666 fileset.1.gz /usr/share/man/man1/fileset.1.gz ; \
	else \
	  echo "-" ; \
	  echo "Root access needed to install at /usr/bin " ; \
	  echo "aborting install, switch to root user with su or sudo then retry" ; \
	  fi \


uninstall:
	  if test -w /etc/passwd ; \
	  then \
	  echo "we are root, uninstall /usr/bin/fileset" ; \
	  rm -f /usr/bin/fileset ; \
	  rm -f /usr/share/man/man1/fileset.1.gz ; \
	  else \
	  echo "no local /bin and we do not have root status" ; \
	  echo "switch to root for /usr/bin install or create local /bin directory" ; \
	  echo "Note: /bin directory may need to be placed in path" ; \
	  fi \

clean:
	rm -f fileset.o *~
	touch $(srcs)  
	rm -f release/*
	-rmdir release

doc:
	../txt2man -t FileSet fileset.txt | gzip -c > fileset.1.gz 


release: tar deb rpm

tar:
	strip fileset
	if [ ! -e "../release" ] ; then mkdir ../release ; fi
	tar cfz ../release/fileset-$(version).tar.gz -C .. FileSet

deb:
	sudo checkinstall -D --pkgversion=$(version) --pakdir=../release --maintainer=jeff@linuxasmtools.net -y

rpm:
	sudo checkinstall -R --pkgversion=$(version) --pakdir=../release -y --pkgname=fileset
	sudo chown --reference Makefile ../release/fileset*
	rm -f backup*






