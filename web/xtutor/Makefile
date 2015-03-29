
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
LIBS := /usr/lib/asmlibx.a $(lib4)
endif

ifeq "$(lib3)" ""
#$(shell echo "../../ library not found" )
else
LIBS := ../../asmlibx.a $(lib3)
endif
  
ifeq "$(lib2)" ""
#$(shell echo "no parent library")
else
LIBS := ..//asmlibx.a $(lib2)
endif

ifeq "$(lib1)" ""
#$(shell echo "no local library")
else
LIBS := asmlibx.a $(lib1)
endif

ifeq "$(LIBS)"  ""
LIBS = asmlibx.a asmlib.a
endif
 
# the following variables are probably ok

#local = $(shell pwd)
#home = $(HOME)
#SHELL = /bin/bash
#here = $(shell pwd)

AS = nasm
ifeq ($(DEBUG),yes)
ASFLAGS := -felf -g -O999
DEFINES := -DDEBUG
else
ASFLAGS := -felf -O999
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
#	$(AS) $(ASFLAGS) $(DEFINES) -l $*.lst $<

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
	../txt2man -t xhelper xhelper.txt | gzip -c > xhelper.1.gz 

#
# the "install" program uses flags
#        -D       create any needed directories
#        -s       strip executables
#        -m 644   set file attributes to 644 octal
install:
	@if test -w /etc/passwd ; \
	then \
	 echo "installing xhelper in /usr/bin" ; \
	 install -s xhelper /usr/bin/xhelper ; \
	 install -D -m 666 xhelper.1.gz /usr/share/man/man1/xhelper.1.gz ; \
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
	 echo "uninstalling xhelper in /usr/bin" ; \
	 rm -f /usr/bin/xhelper ; \
	 echo "uninstalling  support programs for xhelper" ; \
	 rm -f /usr/share/man/man1/xhelper.1.gz ; \
	else \
	  echo "-" ; \
	  echo "Root access needed to uninstall at /usr/bin " ; \
	  echo "aborting uninstall, switch to root user with su or sudo then retry" ; \
	  fi \



release: tar rpm

tar:
	strip xhelper
	if [ ! -e "../release" ] ; then mkdir ../release ; fi
	tar cfz ../release/xhelper$(version)tar.gz -C .. Xhelper

rpm:
