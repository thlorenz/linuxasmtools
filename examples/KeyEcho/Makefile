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

#------------------------------------------

local = $(shell pwd)
home = $(HOME)
version := $(shell cat VERSION)

all:	key_echo


key_echo:	key_echo.o
	ld -static -o key_echo key_echo.o $(LIBS)

key_echo.o: key_echo.asm
	nasm -g -felf -o key_echo.o key_echo.asm
#
# the "install" program uses flags
#        -D       create any needed directories
#        -s       strip executables
#        -m 644   set file attributes to 644 octal
install:
	@if test -w /etc/passwd ; \
	then \
	echo "installing key_echo in /usr/bin" ; \
	install -s key_echo /usr/bin ; \
	else \
	  echo "need to be root for install to /usr/bin" ; \
	  echo "switch to root for /usr/bin install " ; \
	fi

uninstall:
	@if test -w /etc/passwd ; \
	then \
	echo "uninstalling key_echo in /usr/bin" ; \
	rm -f /usr/bin/key_echo ; \
	else \
	  echo "need to be root for install to /usr/bin" ; \
	  echo "switch to root for /usr/bin install " ; \
	fi


release: tar deb rpm

tar:
	strip key_echo
	if [ ! -e "../../release" ] ; then mkdir ../../release ; fi
	tar cfz ../../release/key_echo-$(version).tar.gz -C .. KeyEcho


deb:
	sudo checkinstall -D --pkgversion=$(version) --pakdir=../../release --maintainer=jeff@linuxasmtools.net -y
rpm:
	sudo checkinstall -R --pkgversion=$(version) --pakdir=../../release -y --pkgname=key_echo
	sudo chown --reference Makefile ../../release/key_echo*
	rm -f backup*
 



