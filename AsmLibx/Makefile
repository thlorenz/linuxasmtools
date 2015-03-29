#
# usage:  make  - make library and test program
#         make test - make test program
#         make clean - touch all source files
#         make doc - extract documentation from sources
#         make install - install to $HOME/.asmide/asmlibx.a
#         make release - create a release tar.gz file
#
here = $(shell pwd)
version = $(shell cat VERSION)
user = $(shell whoami)

dirs := src/keyboard src/mouse src/server src/win_color \
        src/win_ctrl src/win_info src/win_text src/xtest \
        src/mgr_info src/mgr_ctrl
srcs := $(foreach dir,$(dirs),$(wildcard $(dir)/*.asm))     
objs := $(foreach dir,$(dirs),$(wildcard $(dir)/*.o))     

# template for each source compile
%.o:    %.asm
	nasm -g -f elf $<

# shell command to execute make in all directories
DO_MAKE = @ for i in $(dirs); do $(MAKE) -C $$i $@; done

sam:  all lib

all:  $(dirs)
	$(DO_MAKE)

lib:
#	rm -f asmlib.a
#	ar rcs asmlibx.a $(objs)
	find ./src -name '*.o' -exec ar rcs asmlibx.a '{}' ';'
#	strip ../asmlib.a	;do not enable, kills link
	cp asmlibx.a ../asmlibx.a

clean:
	find . -depth -name '*.o' -exec rm -f '{}' \;
	find . -depth -name '*~' -exec rm -f '{}' \;
	find . -depth -name '*' -exec touch '{}' \;
	find . -depth -type f -path '*.'test -exec rm -f '{}' \;

#
# the "install" program uses flags
#        -D       create any needed directories
#        -s       strip executables
#        -m 644   set file attributes to 644 octal
install:
	@echo "user="$(user)
	@if [ $(user) = "root" ]; then \
	install -D -m 644 asmlibx.a /usr/lib/asmlibx.a ; \
	else \
	  echo "Must be root to install library at /usr/lib." ; \
	fi  

uninstall:
	@echo "user="$(user)
	@if [ $(user) = "root" ]; then \
	  rm -f /usr/lib/asmlibx.a ; \
	else \
	  echo "Must be root to uninstall library at /usr/lib." ; \
	fi  
	

doc:
	find . -depth -name '*~' -exec rm -f '{}' \;
	asmpub -f2 -n -s -r3 -i -odocs/libx -k $(here)/src/'*.asm'
	cp -f docs/header1.txt docs/asmlibx.txt
	cat VERSION >> docs/asmlibx.txt
	cat docs/header2.txt >> docs/asmlibx.txt
	cat docs/libx.index >> docs/asmlibx.txt
	cat docs/header3.txt >> docs/asmlibx.txt
	cat docs/libx.txt >> docs/asmlibx.txt
	cat docs/USAGE_NOTES.TXT >> docs/asmlibx.txt
	cp -f docs/asmlibx.txt  ../doc/lib/asmlibx.txt
	rm -f docs/libx.txt
	mv -f docs/libx.index docs/asmlibx_index.txt
	
release: tar deb rpm

tar:
	if [ ! -e "../release" ] ; then mkdir ../release ; fi
	tar cfz ../release/asmlibx-$(version).tar.gz -C .. AsmLibx


deb:
	sudo checkinstall -D --pkgversion=$(version) --pakdir=../release --maintainer=jeff@linuxasmtools.net -y

rpm:
	sudo checkinstall -R --pkgversion=$(version) --pakdir=../release -y --pkgname=asmlibx
	sudo chown --reference Makefile ../release/asmlibx*
	rm -f backup*




