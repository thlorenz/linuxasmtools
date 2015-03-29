
#
# usage:  make         - compile asmedit executable
#         make clean   - touch all source files
#         make install - install files
#         make release - create release file
#
local = $(shell pwd)
home = $(HOME)
version := $(shell cat VERSION)
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
# hunt for library file, if this fails then set LIBS to file location
# hunt at local dir, parent dir, then at $HOME/.a/
lib1 = $(shell if test -f asmlib.a ; then echo asmlib.a ; fi)
lib2 = $(shell if test -f ../asmlib.a ; then echo ../asmlib.a ; fi)
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
	touch *.asm
	  @if test -e $(LIBS) ; then \
             echo "asmlib found, compilng asmfile" ; \
          else  \
	     echo "asmlib not found, needed by asmfile" ; \
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
	echo "installing asmfile in /usr/bin" ; \
	install -s asmfile /usr/bin ; \
	install -D asmfile.1.gz /usr/share/man/man1/ ; \
	 echo "installing  support programs at /usr/share/asmfile" ; \
	 install -D scripts/viewer /usr/share/asmfile/viewer ; \
	 install -D scripts/upak /usr/share/asmfile/upak ; \
	 install -D scripts/pak /usr/share/asmfile/pak ; \
	 install -D scripts/compar /usr/share/asmfile/compar ; \
	 install -D scripts/print /usr/share/asmfile/print ; \
	else \
	  echo "need to be root for install to /usr/bin" ; \
	  echo "switch to root for /usr/bin install " ; \
	fi

uninstall:
	@if test -w /etc/passwd ; \
        then \
	echo "uninstalling asmfile from /usr/bin" ; \
	rm -f /usr/bin/asmfile ; \
	rm -f /usr/share/man/man1/asmfile.1.gz ; \
	 echo "uninstalling  support programs at /usr/share/asmfile" ; \
	 rm -f /usr/share/asmfile/viewer ; \
	 rm -f /usr/share/asmfile/upak ; \
	 rm -f /usr/share/asmfile/pak ; \
	 rm -f /usr/share/asmfile/compar ; \
	 rm -f /usr/share/asmfile/print ; \
	 rm -f /usr/share/asmfile/* ; \
	 rmdir /usr/share/asmfile ; \
	else \
	echo "need to be root for uninstall" ; \
	fi

clean:
	rm -f asmfile.o *~
	touch $(srcs)  

doc:
	../txt2man -t AsmFile asmfile.txt | gzip -c > asmfile.1.gz 


release: tar deb rpm

tar:
	strip asmfile
	if [ ! -e "../release" ] ; then mkdir ../release ; fi
	tar cfz ../release/asmfile-$(version).tar.gz -C .. AsmFile

deb:
	sudo checkinstall -D --pkgversion=$(version) --pakdir=../release --maintainer=jeff@linuxasmtools.net -y

rpm:
	sudo checkinstall -R --pkgversion=$(version) --pakdir=../release -y --pkgname=asmfile
	sudo chown --reference Makefile ../release/asmfile*
	rm -f backup*


