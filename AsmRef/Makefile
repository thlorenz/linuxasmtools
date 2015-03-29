#
# usage:  make         - compile asmref executable
#         make clean   - touch all source files
#         make install - install files
#         make release - create release file
#
local = $(shell pwd)
home = $(HOME)
version := $(shell cat VERSION)

all:

#
# the "install" program uses flags
#        -D       create any needed directories
#        -s       strip executables
#        -m 644   set file attributes to 644 octal
install:
	@if test -w /etc/passwd ; \
	then \
	 echo "installing asmref in /usr/bin" ; \
	 install asmref /usr/bin/asmref ; \
	 install ../AsmLinks/asmlinks /usr/bin/asmlinks ; \
	 install -D -m 666 asmref.1.gz /usr/share/man/man1/asmref.1.gz ; \
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
	install -D -m 666 asmref.lnk /usr/share/doc/asmref/ ; \
	install -D -m 666 k_name_calls.lnk /usr/share/doc/asmref/ ; \
	install -D -m 666 k_num_calls.lnk /usr/share/doc/asmref/ ; \
	install -D -m 666 k_type_calls.lnk /usr/share/doc/asmref/ ; \
	install -D -m 666 k_code.lnk /usr/share/doc/asmref/ ; \
	install -D -m 666 asmlibe.lnk /usr/share/doc/asmref/ ; \
	install -D -m 666 asmlibxe.lnk /usr/share/doc/asmref/ ; \
	else \
	  echo "-" ; \
	  echo "Root access needed to install at /usr/bin and /usr/share/asmmgr" ; \
	  echo "aborting install, swithct to root user with su or sudo then retry" ; \
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
	else \
	  echo "-" ; \
	  echo "Root access needed to uninstall at /usr/bin " ; \
	  echo "aborting uninstall, switcht to root user with su or sudo then retry" ; \
	  fi \

clean:
	rm -f ../doc/*~
	rm -f asmref.o *~
	rm -f release/*
	-rmdir release

doc:
	../txt2man -t AsmRef asmref.txt | gzip -c > asmref.1.gz 

release: tar deb rpm

tar:
	if [ ! -e "../release" ] ; then mkdir ../release ; fi
	tar cfz ../release/asmref-$(version).tar.gz -C .. AsmRef AsmLinks doc


deb:
	sudo checkinstall -D --pkgversion=$(version) --pakdir=../release --maintainer=jeff@linuxasmtools.net -y

rpm:
	sudo checkinstall -R --pkgversion=$(version) --pakdir=../release -y --pkgname=asmref
	sudo chown --reference Makefile ../release/asmref*
	rm -f backup*






