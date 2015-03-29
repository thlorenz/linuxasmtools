
#
# usage:  make         - compile asmedit executable
#         make clean   - touch all source files
#         make install - install files
#         make release - create release file
#
local = $(shell pwd)
home = $(HOME)
version := $(shell cat VERSION)
assembler = nasm

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
ifeq "$(assembler)" "nasm"
CC = nasm
DEBUG = -g
CFLAGS = -f elf
T = asm
endif

ifeq "$(assembler)" "as"
CC = as
DEBUG = -gstabs
CFLAGS = -o $@
T = s
endif

ifeq "$(assembler)" "yasm"
CC = yasm
DEBUG = -g stabs
CFLAGS = -f elf
T = asm
endif


ifeq "$(assembler)" "fasm"
CC = fasm
DEBUG =
CFLAGS =
T = asm
LD = echo
endif

SHELL = /bin/bash
here = $(shell pwd)

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

all:	pre $(targets)

$(objs):

pre:
	touch $(srcs)  
#
# the "install" program uses flags
#        -D       create any needed directories
#        -s       strip executables
#        -m 644   set file attributes to 644 octal
install:
	@if test -w /etc/passwd ; \
	then \
	 echo "installing asmview in /usr/bin" ; \
	  install -s asmview /usr/bin ; \
	  install -m 777 viewer /usr/bin ; \
	  install -D -m 666 asmview.1.gz /usr/share/man/man1/ ; \
	else \
	  echo "-" ; \
	  echo "Root access needed to install at /usr/bin" ; \
	  echo "aborting install, swithct to root user with su or sudo then retry" ; \
	  fi \

uninstall:
	@if test -w /etc/passwd ; \
	then \
	echo "uninstalling asmview at /usr/bin" ; \
	rm -f /usr/bin/asmview ; \
	rm -f /usr/bin/viewer ; \
	rm -f /usr/share/man/man1/asmview.1.gz ; \
	else \
	echo "-" ; \
	echo "Root access needed to uninstall at /usr/bin " ; \
	echo "aborting uninstall, switcht to root user with su or sudo then retry" ; \
	fi \


clean:
	rm -f asmview.o *~

doc:
	../txt2man -t AsmView asmview.txt | gzip -c > asmview.1.gz 


release: tar deb rpm

tar:
	strip asmview
	if [ ! -e "../release" ] ; then mkdir ../release ; fi
	tar cfz ../release/asmview-$(version).tar.gz -C .. AsmView

deb:
	sudo checkinstall -D --pkgversion=$(version) --pakdir=../release --maintainer=jeff@linuxasmtools.net -y

rpm:
	sudo checkinstall -R --pkgversion=$(version) --pakdir=../release -y --pkgname=asmview
	sudo chown --reference Makefile ../release/asmview*
	rm -f backup*



