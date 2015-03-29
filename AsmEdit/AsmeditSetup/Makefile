# Generic makefile to compile and produce binary for all
# .asm files in local directory
#
# usage:  make  - make all asm files
#         make clean - touch all source files
#         make doc - extract documentation from sources
######################################################
#
# modify the following as needed
#
# select assembler, nasm, fasm, as, yasm
#
assembler := nasm
#
# copy stripped executables to parent directory?  yes,no
#
copy_executable := yes

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
 
#LFLAGS =
LFLAGS = -static


here = $(shell pwd)

all: pre asmedit_setup

pre:
	touch *.asm

asmedit_setup:	asmedit_setup.o
	ld -static -o asmedit_setup asmedit_setup.o $(LIBS)

asmedit_setup.o: asmedit_setup.asm
	nasm -g -felf -o asmedit_setup.o asmedit_setup.asm


clean:
	touch *.asm  
	rm -f a.ini

