#
# usage:  make         - compile asmref executable
#         make clean   - touch all source files
#         make install - install files
#         make release - create release file
#
local = $(shell pwd)
home = $(HOME)
version := $(shell cat VERSION)
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
ASFLAGS := -felf -g
DEFINES := -DDEBUG
else
ASFLAGS := -felf
DEFINES=
endif
T = asm

LD = ld
LDFLAGS =

targets := $(shell dir *.$(T) | sed -e 's/.$(T)//g')
srcs := $(shell dir *.$(T))
objs := $(shell dir *.$(T) | sed -e 's/.$(T)/.o/g')     


# template for each source compile
%.o:    %.$(T)
	$(AS) $(ASFLAGS) $(DEFINES) $<

# template for link
%:      %.o
	$(LD) $^ $(LFLAGS) -o $@ $(LIBS)

all:	pre $(targets)

#$(objs):

pre:
	touch *.asm

$(targets):

#
# the "install" program uses flags
#        -D       create any needed directories
#        -s       strip executables
#        -m 644   set file attributes to 644 octal
install:	asmide
	@if test -w /etc/passwd ; \
	then \
	 echo "installing asmref in /usr/bin" ; \
	 install ../AsmRef/asmref /usr/bin/asmref ; \
	 install ../AsmLinks/asmlinks /usr/bin/asmlinks ; \
	 install -D -m 666 ../AsmRef/asmref.1.gz /usr/share/man/man1/asmref.1.gz ; \
	 echo "installing  support documents at /usr/share/doc/asmref" ; \
	 if [ ! -d /usr/share/doc/asmref ] ; \
	   then \
	   mkdir -m 777 /usr/share/doc/asmref ; \
	   fi ; \
	 if [ ! -d /usr/share/doc/asmref/cpu ] ; \
	   then \
	   mkdir -m 777 /usr/share/doc/asmref/cpu ; \
	   fi ; \
	 if [ ! -d /usr/share/doc/asmref/kfun ] ; \
	   then \
	   mkdir -m 777 /usr/share/doc/asmref/kfun ; \
	   fi ; \
	 if [ ! -d /usr/share/doc/asmref/kinfo ] ; \
	   then \
	   mkdir -m 777 /usr/share/doc/asmref/kinfo ; \
	   fi ; \
	 if [ ! -d /usr/share/doc/asmref/lib ] ; \
	   then \
	   mkdir -m 777 /usr/share/doc/asmref/lib ; \
	   fi ; \
	 if [ ! -d /usr/share/doc/asmref/progs ] ; \
	   then \
	   mkdir -m 777 /usr/share/doc/asmref/progs ; \
	   fi ; \
	 if [ ! -d /usr/share/doc/asmref/snippets ] ; \
	   then \
	   mkdir -m 777 /usr/share/doc/asmref/snippets ; \
	   fi ; \
	 if [ ! -d /usr/share/doc/asmref/term ] ; \
	   then \
	   mkdir -m 777 /usr/share/doc/asmref/term ; \
	   fi ; \
	 if [ ! -d /usr/share/doc/asmref/tutor ] ; \
	   then \
	   mkdir -m 777 /usr/share/doc/asmref/tutor ; \
	   fi ; \
	 if [ ! -d /usr/share/doc/asmref/unix ] ; \
	   then \
	   mkdir -m 777 /usr/share/doc/asmref/unix ; \
	   fi ; \
	install -D -m 666 ../doc/cpu/* /usr/share/doc/asmref/cpu/ ; \
	install -D -m 666 ../doc/kfun/* /usr/share/doc/asmref/kfun/ ; \
	install -D -m 666 ../doc/kinfo/* /usr/share/doc/asmref/kinfo/ ; \
	install -D -m 666 ../doc/lib/* /usr/share/doc/asmref/lib/ ; \
	install -D -m 666 ../doc/progs/* /usr/share/doc/asmref/progs/ ; \
	install -D -m 666 ../doc/snippets/* /usr/share/doc/asmref/snippets/ ; \
	install -D -m 666 ../doc/term/* /usr/share/doc/asmref/term/ ; \
	install -D -m 666 ../doc/tutor/* /usr/share/doc/asmref/tutor/ ; \
	install -D -m 666 ../doc/unix/* /usr/share/doc/asmref/unix/ ; \
	install -D -m 666 ../AsmRef/asmref.lnk /usr/share/doc/asmref/ ; \
	install -D -m 666 ../AsmRef/k_name_calls.lnk /usr/share/doc/asmref/ ; \
	install -D -m 666 ../AsmRef/k_num_calls.lnk /usr/share/doc/asmref/ ; \
	install -D -m 666 ../AsmRef/k_type_calls.lnk /usr/share/doc/asmref/ ; \
	install -D -m 666 ../AsmRef/k_code.lnk /usr/share/doc/asmref/ ; \
	install -D -m 666 ../AsmRef/asmlibe.lnk /usr/share/doc/asmref/ ; \
	install -D -m 666 ../AsmRef/asmlibxe.lnk /usr/share/doc/asmref/ ; \
	echo "installing minibug in /usr/bin" ; \
	install -s ../MiniBug/minibug /usr/bin/minibug ; \
	install -D -m 666 ../MiniBug/minibug.1.gz /usr/share/man/man1/minibug.1.gz ; \
	install -D -m 644 ../asmlib.a /usr/lib/asmlib.a ; \
	install -s asmide /usr/bin/asmide ; \
	else \
	  echo "-" ; \
	  echo "Root access needed to install at /usr/bin and /usr/share/asmmgr" ; \
	  echo "aborting install, switcht to root user with su or sudo then retry" ; \
	  fi \

uninstall:
	@if test -w /etc/passwd ; \
	then \
	 echo "uninstalling asmref at /usr/bin" ; \
	 rm -f /usr/bin/asmref ; \
	 rm -f /usr/share/man/man1/asmref.1.gz ; \
	 echo "uninstalling  support documents at /usr/share/doc/asmref" ; \
	rm -f -r /usr/share/doc/asmref/* ; \
	rmdir /usr/share/doc/asmref ; \
	 echo "uninstalling minibug in /usr/bin" ; \
	 rm -f /usr/bin/minibug ; \
	 echo "uninstalling  support programs for minibug" ; \
	 rm -f /usr/share/man/man1/minibug.1.gz ; \
	 rm -f /usr/lib/asmlib.a ; \
	 rm -f /usr/bin/asmide ; \
	else \
	  echo "-" ; \
	  echo "Root access needed to uninstall at /usr/bin " ; \
	  echo "aborting uninstall, swittch to root user with su or sudo then retry" ; \
	  fi \

clean:
	rm -f ../doc/*~
	rm -f asmref.o *~
	rm -f release/*
	-rmdir release

doc:
	../txt2man -t AsmIDE asmide.txt | gzip -c > asmide.1.gz 

release: tar deb rpm

tar:
	strip asmide
	if [ ! -e "../release" ] ; then mkdir ../release ; fi
	tar cfz ../release/asmide-$(version).tar.gz -C .. AsmIDE MiniBug asmlib.a AsmRef AsmLinks doc AsmIDE/AsmIDE_install.txt

deb:
	sudo checkinstall -D --pkgversion=$(version) --pakdir=../release --maintainer=jeff@linuxasmtools.net -y

rpm:
	sudo checkinstall -R --pkgversion=$(version) --pakdir=../release -y --pkgname=asmide
	sudo chown --reference Makefile ../release/asmide*
	rm -f backup*


