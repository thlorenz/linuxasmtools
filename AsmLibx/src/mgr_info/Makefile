
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
#OP = EX
OP=LIB
#
# select any of the following
#    DEBUG = yes (include test code and debug info)
#
DEBUG=no

########################################################################          
ifeq ($(OP),EX)
LIBS := /usr/lib/asmlibx.a /usr/lib/asmlib.a
 
AS = nasm
ifeq ($(DEBUG),yes)
ASFLAGS := -felf -g
DEFINES := -DDEBUG
else
ASFLAGS := -felf -O 999
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

$(objs):

pre:
	touch *.asm


clean:
	rm -f *~
	touch $(srcs)  

endif

########################################################################          
ifeq ($(OP),LIB)

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
	rm -f *~
	rm -f *.o
	touch $(srcs)  

endif
