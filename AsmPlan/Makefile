
#
# usage:  make         - compile asmedit executable
#         make clean   - touch all source files
#         make install - install files
#         make release - create release file
#
local = $(shell pwd)
home = $(HOME)
version := $(shell cat VERSION)

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

all:	pre asmplan

asmplan: asmplan.o 
	ld -e main -o asmplan asmplan.o $(LIBS)

asmplan.o: asmplan.asm edit.inc setup.inc exit.inc search.inc help.inc
	nasm -g -felf -O99 -o asmplan.o asmplan.asm

pre:
	touch *.asm
	  @if test -e $(LIBS) ; then \
             echo "asmlib found, compilng AsmPlan" ; \
          else  \
	     echo "asmlib not found, needed by AsmPlan" ; \
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
	 echo "installing asmplan in /usr/bin" ; \
	  install -s asmplan /usr/bin ; \
	 install -D -m 666 asmplan.1.gz /usr/share/man/man1/asmplan.1.gz ; \
	else \
	  echo "-" ; \
	  echo "Root access needed to install at /usr/bin " ; \
	  echo "aborting install, swithct to root user with su or sudo then retry" ; \
	  fi \

uninstall:
	@if test -w /etc/passwd ; \
	then \
	echo "uninstalling asmplan at /usr/bin" ; \
	rm -f /usr/bin/asmplan ; \
	rm -f /usr/share/man/man1/asmplan.1.gz ; \
	echo "uninstalling demo plan in /$HOME/.asmplan" ; \
	rm -f  $(home)/.asmplan/plan/demo ; \
	rm -f  $(home)/.asmplan/plan/hints ; \
	echo "-----------------------------" ; \
	echo "remove all stored todos? y/n" ; \
	read AKEY ; \
	echo "-----------------------------" ; \
	  if [ $(AKEY) = "y" ] ; then \
	  echo "removing all todo files" ; \
	  rm -f $(home)/.asmplan/plan/* ; \
	  rmdir $(home)/.asmplan/plan ; \
	  rm -f $(home)/.asmplan/* ; \
	  rmdir $(home)/.asmplan ; \
	  fi ;  \
	else \
	echo "-" ; \
	echo "Root access needed to uninstall at /usr/bin and /usr/share/asmmgr" ; \
	echo "aborting uninstall, switcht to root user with su or sudo then retry" ; \
	fi 


clean:
	rm -f asmplan.o *~
	rm -f release
	-rmdir release

doc:
	../txt2man -t AsmPlan asmplan.txt | gzip -c > asmplan.1.gz 

release: tar deb rpm

tar:
	strip asmplan
	if [ ! -e "../release" ] ; then mkdir ../release ; fi
	tar cfz ../release/asmplan-$(version).tar.gz -C .. AsmPlan

deb:
	sudo checkinstall -D --pkgversion=$(version) --pakdir=../release --maintainer=jeff@linuxasmtools.net -y

rpm:
	sudo checkinstall -R --pkgversion=$(version) --pakdir=../release -y --pkgname=asmplan
	sudo chown --reference Makefile ../release/asmplan*
	rm -f backup*





