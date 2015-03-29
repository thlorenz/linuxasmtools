# Generic makefile to compile and produce binary for all
# source files in local directory
#
# usage:  make  - make all asm files
#         make clean - touch all source files
# Note: if linker gives warning "can not find start" it may
#       be a nasm bug. Caused by adding the -O2 optimize flag,
#       or the symbol _start may need to be public.  Some debuggers
#       need a start label of "main" made public.
######################################################
#
# modify the following as needed
#
# select assembler, nasm, fasm, as, yasm
#
assembler :=nasm
#                      
#
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
LD = ld

# the following variables are probably ok
######################################################
CC = nasm
DEBUG = -g
CFLAGS = -f elf
T = asm

SHELL = /bin/bash
here = $(shell pwd)

version = $(shell cat VERSION)
dirs = $(shell dir -d *)
targets := $(shell dir *.$(T) | sed -e 's/.$(T)//g')
srcs := $(shell dir *.$(T))
objs := $(shell dir *.$(T) | sed -e 's/.$(T)/.o/g')     


# template for each source compile
%.o:    %.$(T)
	$(CC) $(DEBUG) $(CFLAGS) $<

# template for link
%:      %.o
	$(LD) $^ $(LFLAGS) -o $@ $(LIBS)

all:	clean $(targets)

$(objs):

clean:
	touch $(srcs)  
	  @if test -e $(LIBS) ; then \
             echo "asmlib found, compilng project" ; \
          else  \
	     echo "asmlib not found, needed by project" ; \
             suspend ; \
          fi
#
# the "install" program uses flags
#        -D       create any needed directories
#        -s       strip executables
#        -m 644   set file attributes to 644 octal
install:
	@if test -w /etc/passwd ; \
	then \
	 echo "installing asmproject in /usr/bin" ; \
	 install -s asmproject /usr/bin/asmproject ; \
	 install -D -m 666 asmproject.1.gz /usr/share/man/man1/asmproject.1.gz ; \
	else \
	  echo "-" ; \
	  echo "Root access needed to install at /usr/bin " ; \
	  echo "aborting install, switch to root user with su or sudo then retry" ; \
	  fi \
#
# asmide programs
#
uninstall:
	@if test -w /etc/passwd ; \
	then \
	 echo "uninstalling asmproject in /usr/bin" ; \
	 rm -f /usr/bin/asmproject ; \
	 echo "uninstalling  support programs for asmproject" ; \
	 rm -f /usr/share/man/man1/asmproject.1.gz ; \
	else \
	  echo "-" ; \
	  echo "Root access needed to uninstall at /usr/bin " ; \
	  echo "aborting uninstall, switch to root user with su or sudo then retry" ; \
	  fi \

doc:
	../txt2man -t AsmProject asmproject.txt | gzip -c > asmproject.1.gz 

release: tar deb rpm

tar:
	strip asmproject
	if [ ! -e "../release" ] ; then mkdir ../release ; fi
	tar cfz ../release/asmproject-$(version).tar.gz -C .. AsmProject


deb:
	sudo checkinstall -D --pkgversion=$(version) --pakdir=../release --maintainer=jeff@linuxasmtools.net -y

rpm:
	sudo checkinstall -R --pkgversion=$(version) --pakdir=../release -y --pkgname=asmproject
	sudo chown --reference Makefile ../release/asmproject*
	rm -f backup*






