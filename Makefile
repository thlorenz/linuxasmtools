#
#
# usage:  make         - compile asmedit executable
#         make clean   - touch all source files
#         make install - install files
#         make release - create release file
#
# note: to create a release
#           1. make clean
#           2. make
#           3. make release  (needed for make doc web)
#           2. make doc
#           4. make release  (create new release with updated docs)
#           5. make doc      (add asmtools-...tar.gz with latest
######################################################
local = $(shell pwd)
home = $(HOME)
version := $(shell cat VERSION)

SHELL = /bin/bash
here = $(shell pwd)

#dirs - used for install,uninstall
dirs = AsmLib AsmLibx AsmEdit AsmMgr AsmRef AsmPlan AsmPub AsmSrc \
       AsmView AsmFind AsmTimer ElfDecode AsmDis AsmBug AsmFile \
       AsmTrace AsmLinks AsmMenu FileBrowse FileSet MiniBug Domac Tracex \
       Xhelper Copy AsmIDE 
#adirs - used as destination for README,COPYING,INSTALL files
adirs = AsmLib AsmLibx AsmEdit AsmMgr AsmRef \
        examples/FormatDoc examples/KeyEcho examples/CrtTest \
	examples/Ainfo examples/AsmColor AsmView AsmFind AsmTimer \
	AsmDis AsmBug AsmFile AsmTrace AsmLinks AsmMenu \
	examples/Sort examples/StepTest examples/WalkTest \
	FileBrowse FileSet AsmPlan AsmPub ElfDecode MiniBug Domac \
        AsmSrc Tracex Xhelper Copy AsmIDE 
#cdirs - used for compiles 
cdirs = AsmLib AsmLib_tutor AsmLibx AsmEdit AsmMgr AsmRef \
        examples/FormatDoc examples/KeyEcho examples/CrtTest \
	examples/Ainfo examples/AsmColor \
	examples/Sort examples/StepTest examples/WalkTest \
	AsmMenu AsmEdit/AsmeditSetup FileBrowse \
	AsmEdit/ShowSysErr AsmPlan AsmPub\
	FileSet AsmMgr/Setup ElfDecode\
        AsmView AsmFind AsmTimer \
	AsmDis AsmBug AsmFile AsmTrace AsmLinks MiniBug Domac \
	Tracex Xhelper Copy AsmIDE 
#ddirs - used to make documentation
ddirs = AsmLib AsmLib_tutor AsmLibx AsmBug AsmDis AsmEdit AsmMenu AsmFile FileSet \
	AsmFind AsmLinks AsmMgr AsmProject AsmPlan AsmPub \
	AsmRef AsmSrc AsmTimer AsmTrace AsmView MiniBug Domac Tracex \
	Xhelper Copy  web
#rdirs - used to make releases
rdirs = AsmLib AsmLib_tutor AsmLibx AsmEdit AsmMgr AsmRef AsmPlan AsmPub AsmSrc \
       AsmView AsmFind AsmTimer AsmMenu \
       FileBrowse FileSet examples/Ainfo examples/AsmColor \
       examples/CrtTest examples/FormatDoc examples/KeyEcho \
       examples/Sort examples/StepTest examples/WalkTest \
       AsmDis AsmBug AsmFile AsmTrace AsmLinks AsmProject \
       ElfDecode MiniBug Domac Tracex Xhelper Copy AsmIDE \
       

# shell command to execute make in all directories
DO_MAKE = @ for i in $(dirs); do $(MAKE) -C $$i $@; done
DO_INSTALL = @ for i in $(dirs); do $(MAKE) -C $$i install; done
DO_UNINSTALL = @ for i in $(dirs); do $(MAKE) -C $$i uninstall; done
DO_RELEASE = @ for i in $(rdirs); do $(MAKE) -C $$i release; done
DO_DOC = @ for i in $(ddirs); do $(MAKE) -C $$i doc; done

all:  $(cdirs)
	$(DO_MAKE)


doc:	post doc2


post:
	for i in $(adirs); do cp -f README $(here)/$$i/README; done
	for i in $(adirs); do cp -f COPYING $(here)/$$i/COPYING; done
	for i in $(adirs); do cp -f INSTALL $(here)/$$i/INSTALL; done

doc2:	$(ddirs)
	@if test -e /usr/bin/asmpub ; \
	then \
	for i in $(ddirs); do $(MAKE) -C $$i doc; done ; \
	else \
	echo "AsmPub needed to rebuild documentation" ; \
	echo "After this install try  -  make doc" ; \
	echo "press  Enter key to continue" ; \
	read AKEY ; \
	fi


install:
	$(DO_INSTALL)

uninstall:
	$(DO_UNINSTALL)
	@if test -w /etc/passwd ; \
	then \
	 echo "uninstalling /tmp files" ; \
	 rm -f /tmp/asmedit.tmp.* ; \
	 rm -f /tmp/find.tmp ; \
	 rm -f /tmp/tmp.dir ; \
	 rm -f /tmp/left.0 ; \
	 rm -f /tmp/right.0 ; \
	 rm -f /usr/share/man/man1/asmtools.1.gz ; \
	else \
	  echo "-" ; \
	  echo "Root access needed to uninstall /tmp files" ; \
	  echo "aborting uninstall, switch to root user with su or sudo then retry" ; \
	  fi
	
clean:
	find . -depth -name '*.o' -exec rm -f '{}' \;
	find . -depth -name '*~' -exec rm -f '{}' \;
	find . -depth -name '*tar.gz' -exec rm -f '{}' \;
	find . -depth -name '.abugrc' -exec rm -f '{}' \;
	rm -f release/*
	if [ -e "release" ] ; then rmdir release ; fi

release: tar deb rpm

tar:
	if [ ! -e "release" ] ; then mkdir release ; fi
	rm -f release/*.tar.gz
	rm -f release/*.deb
	rm -f release/*.rpm
	tar cfz ./release/asmtools-$(version).tar.gz --exclude=release --exclude="web/out/*.gz" --exclude="web/out/*.deb" --exclude="web/out/*.rpm" -C .. asmtools
	$(DO_RELEASE)


deb:
	sudo checkinstall -D --pkgversion=$(version) --pakdir=./release --maintainer=jeff@linuxasmtools.net -y --pkgname=asmtools

rpm:
	sudo checkinstall -R --pkgversion=$(version) --pakdir=./release -y --pkgname=asmtools
	sudo chown --reference Makefile ./release/asmtools*
	rm -f backup*


