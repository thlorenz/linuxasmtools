
#
# usage:  make         - compile asmedit executable
#         make clean   - touch all source files
#         make install - install files
#         make release - create release file
#
# Note: if linker gives warning "can not find start" it may
#       be a nasm bug. Caused by adding the -O2 optimize flag,
#       or the symbol _start may need to be public.  Some debuggers
#       need a start label of "main" made public. - jeff
######################################################
#
# modify the following as needed
#
# select one of the following:
#    EX = build all executables
#    LIB = build objects only
#          or build test programs if DEBUG=yes
#
OP = EX
#OP=LIB
#
# select any of the following
#    DEBUG = yes (include test code and debug info)
#
DEBUG=yes

########################################################################          
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
 
# the following variables are probably ok

#local = $(shell pwd)
#home = $(HOME)
#SHELL = /bin/bash
#here = $(shell pwd)

AS = nasm
ifeq ($(DEBUG),yes)
ASFLAGS := -felf -g -O99
DEFINES := -DDEBUG
else
ASFLAGS := -felf
DEFINES=
endif
T = .asm

LD = ld
LDFLAGS =

version = $(shell cat VERSION)

#dirs = $(shell dir -d *)
srcs := $(shell dir *$(T))
targets := $(subst .asm,, $(srcs))
#targets := $(shell dir *$(T) | sed -e 's/$(T)//g')
objs := $(subst .asm,.o, $(srcs))
#objs := $(shell dir *$(T) | sed -e 's/$(T)/.o/g')     


# template for each source compile
%.o:    %$(T)
	$(AS) $(ASFLAGS) $(DEFINES) $<

# template for link
%:      %.o
	$(LD) $^ $(LFLAGS) -o $@ $(LIBS)

all:	pre $(targets)

$(objs):

pre:
	touch *.asm


clean:
	touch $(srcs)  


doc:
	../txt2man -t AsmDis asmdis.txt | gzip -c > asmdis.1.gz 

#
# the "install" program uses flags
#        -D       create any needed directories
#        -s       strip executables
#        -m 644   set file attributes to 644 octal
install:
	@if test -w /etc/passwd ; \
	then \
	 echo "installing asmdis in /usr/bin" ; \
	 install -s asmdis  /usr/bin/asmdis ; \
	 echo "installing  support programs at /usr/share/asmmgr" ; \
	 install -D -m 666 asmdis_help.txt /usr/share/doc/asmref/asmdis_help.txt ; \
	 install -D -m 666 asmdis.1.gz /usr/share/man/man1/asmdis.1.gz ; \
	else \
	  echo "-" ; \
	  echo "Root access needed to install at /usr/bin " ; \
	  echo "aborting install, swithct to root user with su or sudo then retry" ; \
	  fi \
#
# asmpre is not uninstalled, it may be needed by other asmide programs
#
uninstall:
	@if test -w /etc/passwd ; \
	then \
	 echo "uninstalling asmdis in /usr/bin" ; \
	 rm -f /usr/bin/asmdis ; \
	 echo "uninstalling  support programs for asmdis" ; \
	 rm -f /usr/share/doc/asmref/asmdis_help.txt ; \
	 rm -f /usr/share/man/man1/asmdis.1.gz ; \
	else \
	  echo "-" ; \
	  echo "Root access needed to uninstall at /usr/bin and /usr/share/asmmgr" ; \
	  echo "aborting uninstall, switcht to root user with su or sudo then retry" ; \
	  fi \



release: tar deb rpm

tar:
	strip asmdis
	if [ ! -e "../release" ] ; then mkdir ../release ; fi
	tar cfz ../release/asmdis-$(version).tar.gz -C .. AsmDis ElfDecode

deb:
	sudo checkinstall -D --pkgversion=$(version) --pakdir=../release --maintainer=jeff@linuxasmtools.net -y

rpm:
	sudo checkinstall -R --pkgversion=$(version) --pakdir=../release -y --pkgname=asmdis
	sudo chown --reference Makefile ../release/asmdis*
	rm -f backup*

