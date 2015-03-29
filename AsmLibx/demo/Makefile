
#
# usage:  make         - compile asmedit executable
#         make clean   - touch all source files
#         make install - install files
#         make release - create release file
#
# Note: if linker gives warning "can not find start" it may
#       be a nasm bug. Caused by adding the -O2 optimize flag,
#       or the symbol _start may need to be public.  Some debuggers
#       need a start label of "main" made public.
######################################################
#
# modify the following as needed
#
# select one of the following:
#    EX = build all executables
#    LIB = build objects only
#          or build test programs if DEBUG=yes
#
OP = EX
#OP=LIB
#
# select any of the following
#    DEBUG = yes (include test code and debug info)
#
DEBUG=yes

########################################################################          
ifeq ($(OP),EX)
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
 
# the following variables are probably ok

#local = $(shell pwd)
#home = $(HOME)
#SHELL = /bin/bash
#here = $(shell pwd)

AS = nasm
ifeq ($(DEBUG),yes)
ASFLAGS := -felf -g -O 999
DEFINES := -DDEBUG
else
ASFLAGS := -felf -O 999
DEFINES=
endif
T = asm

LD = ld
LDFLAGS =


#dirs = $(shell dir -d *)
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

$(objs):

pre:
	touch *.asm


clean:
	rm -f asmpub.o *~
	touch $(srcs)  

endif

########################################################################          
ifeq ($(OP),LIB)
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


dirs = $(shell dir -d *)
targets := $(shell dir *.$(T) | sed -e 's/.$(T)//g')
srcs := $(shell dir *.$(T))
objs := $(shell dir *.$(T) | sed -e 's/.$(T)/.o/g')     


# template for each source compile
%.o:    %.$(T)
	$(AS) $(ASFLAGS) $(DEFINES) $<

# template for link
%:      %.o
	$(LD) $^ $(LFLAGS) -o $@ $(LIBS)


ifeq ($(DEBUG),yes)
all:	pre1 $(targets)

$(objs):

else

all: pre2 $(objs)

#$(objs):

endif

pre1:
	touch *.asm

pre2:
	touch *.asm


clean:
	rm -f asmpub.o *~
	touch $(srcs)  

endif
