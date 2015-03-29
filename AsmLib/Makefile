#
# usage:  make  - make library and test program
#         make test - make test program
#         make clean - touch all source files
#         make doc - extract documentation from sources
#         make install - install to $HOME/.asmide/asmlib.a
#         make release - create a release tar.gz file
#
here = $(shell pwd)
version = $(shell cat VERSION)
user = $(shell whoami)

dirs := syscall char str str_conv terminal crt env blk str_cmp dir \
        file widget sort sys \
        str_parse date process log-error random draw file2 database hash \
        menu signal timer \
        trace math memory xterm dis compress sound list terminfo \
        dcache vt


# template for each source compile
%.o:    %.asm
	nasm -g -f elf $<

# shell command to execute make in all directories
DO_MAKE = @ for i in $(dirs); do $(MAKE) -C $$i $@; done

sam:  pre all lib

all:  $(dirs)
	$(DO_MAKE)

pre:
	./make_syscall
srcs := $(foreach dir,$(dirs),$(wildcard $(dir)/*.asm))     
objs := $(foreach dir,$(dirs),$(wildcard $(dir)/*.o))     

lib:
#	rm -f asmlib.a
#	ar rcs asmlib.a $(objs)
	find . -name '*.o' -exec ar rcs asmlib.a '{}' ';'
	mv -f asmlib.a ../
#	strip ../asmlib.a	;do not enable, kills link


test:  test.o
	ld -static -o test test.o asmlib.a
	rm -f test.o

test.o:	test.asm
	~/bin/nasm -g -f elf -o test.o test.asm

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
	install -D -m 644 ../asmlib.a /usr/lib/asmlib.a ; \
	else \
	  echo "Must be root to install library at /usr/lib." ; \
	fi  

uninstall:
	@echo "user="$(user)
	@if [ $(user) = "root" ]; then \
	  rm -f /usr/lib/asmlib.a ; \
	else \
	  echo "Must be root to uninstall library at /usr/lib." ; \
	fi  
	

doc:
	asmpub -f2 -n -s -r3 -i -oasmlib -k $(here)/'*.asm'
	cp -f header1.txt ../asmlib.txt
	cat ../VERSION >> ../asmlib.txt
	cat header2.txt >> ../asmlib.txt
	cat asmlib.index >> ../asmlib.txt
	cat header3.txt >> ../asmlib.txt
	cat asmlib.txt >> ../asmlib.txt
	cat USAGE_NOTES.TXT >> ../asmlib.txt
	cp -f ../asmlib.txt ../doc/lib/asmlib.txt
	cp -f header2.txt asmlib_index.txt
	cat asmlib.index >> asmlib_index.txt
	rm -f ../asmlib.txt
	cp -f asmlib.txt doc-pak/
	cp -f asmlib_index.txt doc-pak/

release: tar deb rpm

tar:
	if [ ! -e "../release" ] ; then mkdir ../release ; fi
	tar cfz ../release/asmlib-$(version).tar.gz -C .. AsmLib

deb:
	sudo checkinstall -D --pkgversion=$(version) --pakdir=../release --maintainer=jeff@linuxasmtools.net -y

rpm:
	sudo checkinstall -R --pkgversion=$(version) --pakdir=../release -y --pkgname=asmlib
	sudo chown --reference Makefile ../release/asmlib*
	rm -f backup*



