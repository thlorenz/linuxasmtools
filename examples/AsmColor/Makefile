
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
lib2 = $(shell if test -f ../../AsmLib/asmlib.a ; then echo ../../AsmLib/asmlib.a ; fi)
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
             echo "asmlib found, compilng Ainfo" ; \
          else  \
	     echo "asmlib not found, needed by Ainfo" ; \
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
	echo "installing asmcolor in /usr/bin" ; \
	install -s asmcolor /usr/bin ; \
	install -D -m 666 asmcolor.1.gz /usr/share/man/man1/ ; \
	else \
	  echo "need to be root for install to /usr/bin" ; \
	  echo "switch to root for /usr/bin install " ; \
	fi

uninstall:
	@if test -w /etc/passwd ; \
	then \
	echo "uninstalling asmcolor in /usr/bin" ; \
	rm -f /usr/bin/asmcolor ; \
	else \
	  echo "need to be root for install to /usr/bin" ; \
	  echo "switch to root for /usr/bin install " ; \
	fi


clean:
	rm -f ainfo.o *~
	touch $(srcs)  

doc:
	../../txt2man -t AsmColor asmcolor.txt | gzip -c > asmcolor.1.gz 

release: tar deb rpm

tar:
	strip asmcolor
	if [ ! -e "../../release" ] ; then mkdir ../../release ; fi
	tar cfz ../../release/asmcolor-$(version).tar.gz -C .. AsmColor


deb:
	sudo checkinstall -D --pkgversion=$(version) --pakdir=../../release --maintainer=jeff@linuxasmtools.net -y

rpm:
	sudo checkinstall -R --pkgversion=$(version) --pakdir=../../release -y --pkgname=asmcolor
	sudo chown --reference Makefile ../../release/asmcolor*
	rm -f backup*
 




