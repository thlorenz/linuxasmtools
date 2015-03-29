#
# usage:  make         - compile asmedit executable
#         make clean   - touch all source files
#         make install - install files
#         make release - create release file
#
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
home = $(HOME)
here = $(shell pwd)
version = $(shell cat VERSION)
usr=$(shell basename $(HOME) )

ifeq "$(assembler)" "nasm"
CC = nasm
DEBUG = -g
CFLAGS = -f elf -O99
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

dirs := AsmeditSetup ShowSysErr

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


all:  pre $(dirs) post
	$(DO_MAKE)

pre:
	touch	*.asm
	touch AsmeditSetup/*.asm
	touch ShowSysErr/*.asm

post: asmedit


doc:
	../txt2man -t AsmEdit asmedit.txt | gzip -c > asmedit.1.gz 

#
# the "install" program uses flags
#        -D       create any needed directories
#        -s       strip executables
#        -m 644   set file attributes to 644 octal
install:
	@if test -w /etc/passwd ; \
	then \
	 echo "installing asmedit in /usr/bin" ; \
	 install -s -m 777 asmedit /usr/bin ; \
	 install -s ../AsmMenu/asmmenu /usr/bin/asmmenu ; \
	 echo "installing  support programs at /usr/share/asmedit" ; \
	 install -D -s ../FileBrowse/file_browse /usr/share/asmedit/file_browse ; \
	 install -D -s ShowSysErr/show_sys_err /usr/share/asmedit/show_sys_err ; \
	 install -D -s -m 777 AsmeditSetup/asmedit_setup /usr/share/asmedit/asmedit_setup ; \
	 install -D Scripts/a.f3 /usr/share/asmedit/a.f3 ; \
	 install -D Scripts/a.f4 /usr/share/asmedit/a.f4 ; \
	 install -D Scripts/a.f5 /usr/share/asmedit/a.f5 ; \
	 install -D Scripts/a.f6 /usr/share/asmedit/a.f6 ; \
	 install -D Scripts/a.f7 /usr/share/asmedit/a.f7 ; \
	 install -D -m 666 asmedit.1.gz /usr/share/man/man1/asmedit.1.gz ; \
	  if test -e /usr/bin/a ; \
	  then \
	  echo "no shortcut (a) to asmedit in /usr/bin" ; \
	  else \
	  install -m 766 --owner=$(usr) a /usr/bin ; \
	  fi \
	else \
	  echo "-" ; \
	  echo "Root access needed to install at /usr/bin and /usr/share/asmedit" ; \
	  echo "aborting install, switch to root user with su or sudo then retry" ; \
	fi

uninstall:
	@if test -w /etc/passwd ; \
	then \
	 echo "uninstalling asmedit from /usr/bin" ; \
	 rm -f /usr/bin/asmedit ; \
	 rm -f /usr/bin/asmmenu ; \
	 rm -f /usr/share/man/man1/asmedit.1.gz ; \
	 echo "uninstalling  support programs at /usr/share/asmedit" ; \
	 rm -f /usr/share/asmedit/file_browse ; \
	 rm -f /usr/share/asmedit/show_sys_err ; \
	 rm -f /usr/share/asmedit/asmedit_setup ; \
	 rm -f /usr/share/asmedit/a.f3 ; \
	 rm -f /usr/share/asmedit/a.f4 ; \
	 rm -f /usr/share/asmedit/a.f5 ; \
	 rm -f /usr/share/asmedit/a.f6 ; \
	 rm -f /usr/share/asmedit/a.f7 ; \
	 rm -f /usr/share/asmedit/* ; \
	 rmdir /usr/share/asmedit ; \
	else \
	  echo "-" ; \
	  echo "Root access needed to uninstall /usr/share/asmedit" ; \
	  echo "aborting uninstall, switch to root user with su or sudo then retry" ; \
	  fi
	@if test -d $(HOME)/bin ; \
	then \
	echo "removing shortcut (a) to asmedit in $(HOME)/bin" ; \
	rm -f $(HOME)/bin/a ; \
	fi \

clean:
	find . -name '*.o' -depth -exec rm -f '{}' \;
	find . -name '*~' -depth -exec rm -f '{}' \;
	find . -name '*' -depth -exec touch '{}' \;
	rm -f asmedit.o *~
	rm -f release/*
	-rmdir release

release: tar deb rpm

tar:
	strip asmedit
	if [ ! -e "../release" ] ; then mkdir ../release ; fi
	tar cfz ../release/asmedit-$(version).tar.gz -C .. AsmBug AsmMenu FileBrowse

deb:
	sudo checkinstall -D --pkgversion=$(version) --pakdir=../release --maintainer=jeff@linuxasmtools.net -y

rpm:
	sudo checkinstall -R --pkgversion=$(version) --pakdir=../release -y --pkgname=asmedit
	sudo chown --reference Makefile ../release/asmedit*
	rm -f backup*

