# Generic makefile to compile and produce binary for all
# .asm files in local directory
#
#
# usage:  make         - compile asmedit executable
#         make clean   - touch all source files
#         make install - install files
#         make uninstall - uninstall all files
#         make release - create release file
#
######################################################


local = $(shell pwd)
home = $(HOME)
version := $(shell cat VERSION)
SHELL = /bin/bash
here = $(shell pwd)
#
# modify the following as needed
#
# select assembler, nasm, fasm, as, yasm
#
assembler := nasm
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

# the following variables are probably ok
######################################################
ifeq "$(assembler)" "nasm"
CC = nasm
DEBUG = -g
CFLAGS = -O99 -f elf
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

.SUFFIXES : .o .asm

dirs := Setup

srcs := $(foreach dir,$(dirs),$(wildcard $(dir)/*.asm))     

objs := $(foreach dir,$(dirs),$(wildcard $(dir)/*.o))     

# shell command to execute make in all directories
#DO_MAKE = @ for i in $(dirs); do $(MAKE) -C $$i $@; done
DO_MAKE = @if test -e $(LIBS) ; then for i in $(dirs); \
             do $(MAKE) -C $$i $@; done ; \
          else  \
             echo "asmlib.a needed for compile" ; \
          fi


# template for each source compile
%.o:    %.asm $(incs)
	$(CC) $(DEBUG) $(CFLAGS) $<

# template for link
%:      %.o
	ld $^ $(LFLAGS) -o $@ $(LIBS)

#####################################################
# Makefile section:  AsmMgr
#####################################################
all:  pre $(dirs) post
	$(DO_MAKE)

pre:
	touch asmmgr.asm
	echo "building asmmgr"
	touch Setup/*.asm
	
post: asmmgr

clean:
	find . -name '*.o' -depth -exec rm -f '{}' \;
	find . -name '*~' -depth -exec rm -f '{}' \;
	find . -name '*' -depth -exec touch '{}' \;
	find . -type f -path '*.'test -depth -exec rm -f '{}' \;

#
# the "install" program uses flags
#        -D       create any needed directories
#        -s       strip executables
#        -m 644   set file attributes to 644 octal
install:
	@if test -w /etc/passwd ; \
	then \
	 echo "installing asmmgr in /usr/bin" ; \
	 install -s asmmgr /usr/bin/asmmgr ; \
	 install -s ../AsmProject/asmproject /usr/bin/asmproject ; \
	 install -s ../AsmMenu/asmmenu /usr/bin/asmmenu ; \
	 install -s ../FileSet/fileset /usr/bin/fileset ; \
	 install  scripts/opener /usr/bin/opener ; \
	 install  scripts/viewer /usr/bin/viewer ; \
	 echo "installing  support programs at /usr/share/asmmgr" ; \
	 install -D -m 666 asmmgr.1.gz /usr/share/man/man1/asmmgr.1.gz ; \
	 install -D -s Setup/setup /usr/share/asmmgr/setup ; \
	 install -D -m 666 tables/top_buttons.tbl /usr/share/asmmgr/top_buttons.tbl ; \
	 install -D -m 666 tables/config.tbl /usr/share/asmmgr/config.tbl ; \
	 install -D -m 666 tables/project.tbl /usr/share/asmmgr/project.tbl ; \
	 install -D scripts/upak /usr/share/asmmgr/upak ; \
	 install -D scripts/pak /usr/share/asmmgr/pak ; \
	 install -D scripts/compar /usr/share/asmmgr/compar ; \
	 install -D scripts/print /usr/share/asmmgr/print ; \
	 install -D scripts/find /usr/share/asmmgr/find ; \
	 install -D scripts/quit /usr/share/asmmgr/quit ; \
	 install -D scripts/make /usr/share/asmmgr/make ; \
	 install -D scripts/debug /usr/share/asmmgr/debug ; \
	else \
	  echo "-" ; \
	  echo "Root access needed to install at /usr/bin and /usr/share/asmmgr" ; \
	  echo "aborting install, swithct to root user with su or sudo then retry" ; \
	  fi \

uninstall:
	@if test -w /etc/passwd ; \
	then \
         if test -e /usr/bin/asmfile ; then \
	     echo "------------------------------------" ; \
	     echo "Warning some files needed by AsmFile" ; \
	     echo "will also be uninstalled" ; \
	     echo "Reinstalling AsmFile will fix this problem" ; \
	     echo "------------------------------------" ; \
	     echo "press <Enter> to continue" ; \
	     read KEY ; \
	 fi ; \
	 echo "uninstalling asmmgr in /usr/bin" ; \
	 rm -f /usr/bin/asmmgr ; \
	 rm -f /usr/bin/asmproject ; \
	 rm -f /usr/bin/opener ; \
	 rm -f /usr/bin/viewer ; \
	 echo "uninstalling  support programs at /usr/share/asmmgr" ; \
	 rm -f /usr/share/asmmgr/setup ; \
	 rm -f /usr/share/asmmgr/top_buttons.tbl ; \
	 rm -f /usr/share/asmmgr/config.tbl ; \
	 rm -f /usr/share/asmmgr/upak ; \
	 rm -f /usr/share/asmmgr/pak ; \
	 rm -f /usr/share/asmmgr/compar ; \
	 rm -f /usr/share/asmmgr/print ; \
	 rm -f /usr/share/asmmgr/find ; \
	 rm -f /usr/share/asmmgr/quit ; \
	 rm -f /usr/share/asmmgr/make ; \
	 rm -f /usr/share/asmmgr/debug ; \
	 rm -f /usr/share/asmmgr/* ; \
	 rmdir /usr/share/asmmgr ; \
	else \
	  echo "-" ; \
	  echo "Root access needed to uninstall at /usr/bin and /usr/share/asmmgr" ; \
	  echo "aborting uninstall, switcht to root user with su or sudo then retry" ; \
	  fi \

doc:
	../txt2man -t AsmMgr asmmgr.txt | gzip -c > asmmgr.1.gz 


release: tar deb rpm

tar:
	strip asmmgr
	if [ ! -e "../release" ] ; then mkdir ../release ; fi
	tar cfz ../release/asmmgr-$(version).tar.gz -C .. AsmMgr AsmProject FileSet AsmMenu AsmView examples/AsmColor


deb:
	sudo checkinstall -D --pkgversion=$(version) --pakdir=../release --maintainer=jeff@linuxasmtools.net -y

rpm:
	sudo checkinstall -R --pkgversion=$(version) --pakdir=../release -y --pkgname=asmmgr
	sudo chown --reference Makefile ../release/asmmgr*
	rm -f backup*




