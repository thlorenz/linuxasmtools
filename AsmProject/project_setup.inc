  [section .text]


  extern show_box
  extern dir_status
  extern dir_create
  extern file_write_close
  extern key_mouse1
;
;------------------------------------------------------
;use form data to setup project directory and files
;-------------------------------------------------------------
; build project structure if requested:
;  inputs:
;          [buf1] = project name
;          [buf2] = project dir
;          [buf3] = project path
;          [buf4] = assembler name
;          [buf5] = debugger name
;  colors 3=selected color   4=button color
;          make1 (yes) - make2 (no)
;          src1 (yes)  - src2 (no) <-- create source template
;          bug1 (yes)  - bug2 (no) <-- create local debug script
;
; output: eax = positive if no errors (js/jns) set
;         eax = negative if errors  (js/jns) set
;
; this function is expected to be called before writting project.tbl
; Buffers available for use are: default_path (200) , path_buf (100)
;
project_setup:
  mov	edi,default_path	;location to build path
  mov	esi,buf3
  cmp	byte [esi],' '		;check for missing path
  ja	bup_lp1			;jmp if path entered
  jmp	bup_err_msg1		;go say field missing
bup_lp1:
  lodsb
  stosb
  cmp	al,' '
  ja	bup_lp1			;loop till path moved
  dec	edi
  mov	byte [edi],0		;terminate path
  push	edi
;check if directory exists already
  mov	ebx,default_path
  call	dir_status
  pop	edi			;restore ptr to end of path
  js	bup_errj		;jmp if path does not exist
; append project path and check
  mov	esi,buf2		;get ptr to project path
  cmp	byte [esi],' '
  jbe	bup_errj
  cmp	byte [esi],'/'
  je	bup_lp2
  mov	al,'/'
  stosb
bup_lp2:
  lodsb
  stosb
  cmp	al,' '
  ja	bup_lp2			;move project dir
  dec	edi
  mov	byte [edi],0		;put zero at end of path+proj_dir
;check if project directory exists
  push	edi
  mov	ebx,default_path
  call	dir_status
  pop	edi			;restore ptr to end of path
  mov	[path_end_ptr],edi	;save end of path + proj dir
  jns	bup_10			;jmp if path + dir exists
;create directory
;create the project directory
  mov	ebx,default_path
  call	dir_create
  or	eax,eax
  jns	bup_10			;jmp if ok
bup_errj:
  jmp	bup_err_msg1
;our project has a directory (in default_path), check "make" flag
bup_10:
  mov	edi,[path_end_ptr]
  mov	al,'/'
  stosb
  mov	[path_end_ptr],edi
;check if makefile wanted
  cmp	byte [make1],3		;is a makefile wanted?
  jne	bup_40			;jmp if no makefile needed
;setup path to write makefile
  mov	esi,make_fname
  mov	edi,[path_end_ptr]
  call	str_move
;stuff assembler name into makefile
  mov	esi,buf4		;assembler name
  mov	edi,make_assembler	;destination
  cmp	byte [esi],' '
  jbe	bup_errj		;abort if no assembler specified
bup_lp2a:
  lodsb
  stosb
  cmp	al,' '
  ja	bup_lp2a
  mov	word [edi -1],230ah	;stuff  0ah,"#"  at end of name
;setup to write file
  mov	ebx,default_path
  mov	eax,makefile		;ptr to data
  mov	ecx,makefile_end	;compute length
  sub	ecx,eax			; of write
  mov	ebp,[enviro_ptrs]
  mov	esi,0			;write using full path
  call	file_write_close	;write file
;check if source template wanted
bup_40:
  cmp	byte [src1],3		;is source template wanted
  je	bup_41			;jmp if source template needed
  jmp	bup_60			;jmp if no source template wanted
;use project name for source file name
bup_41:
  mov	esi,buf1
  mov	edi,[path_end_ptr]
  cmp	byte [esi],' '
  jbe	bup_errj		;exit if no project name
bup_lp3:
  lodsb
  stosb
  cmp	al,' '
  ja	bup_lp3			;move project name
  dec	edi			;move back to stuff point
  cmp	word [buf4],'as'
  jne	bup_42			;jmp if not "as"
  mov	word [edi],'.s'		;put .s at end
  add	edi,2
  jmp	short bup_46
bup_42:
  mov	dword [edi],'.asm'
  add	edi,4
bup_46:
  mov	byte [edi],0		;terminate file
;default_path now has name of source file, select file to write
  cmp	word [buf4],'as'
  je	bup_48			;jmp if 'as'
  cmp	word [buf4],'na'
  je	bup_50			;jmp if nasm
  cmp	word [buf4],'ya'
  je	bup_50			;jmp if yasm
  cmp	word [buf4],'fa'
  je	bup_52			;jmp if fasm
  jmp	bup_err_msg1	
;setup to write 'gas' source
bup_48:
  mov	eax,asm_as
  mov	ecx,asm_as_end
  sub	ecx,eax			;compute length of write
  jmp	short bup_58		;go write file
bup_50:
  mov	eax,asm_nasm_yasm
  mov	ecx,asm_nasm_yasm_end
  sub	ecx,eax
  jmp	short bup_58
bup_52:
  mov	eax,asm_fasm
  mov	ecx,asm_fasm_end
  sub	ecx,eax
bup_58:
  mov	ebx,default_path	;path & name of source file
  mov	ebp,[enviro_ptrs]
  mov	esi,0
  call	file_write_close	;write source file

;check if debug script wanted
bup_60:
  cmp	byte [bug1],3		;is debug script wanted
  jne	bup_80			;jump if not debug script wanted
;append name bug to end of default_path
  mov	edi,[path_end_ptr]
  mov	esi,debug_script
  call	str_move
;build debug file data in path_buf
  mov	edi,path_buf
  mov	esi,debug_header
  call	str_move
  mov	esi,buf5
  cmp	byte [esi],' '
  jbe	bup_err_msg1
bup_lp5:
  lodsb
  stosb
  cmp	al,' '
  jne	bup_lp5			;move debugger name
;now move project name
  mov	esi,buf1
bup_lp6:
  lodsb
  stosb
  cmp	al,' '
  jne	bup_lp6			;move name of project
  dec	edi
  mov	byte [edi],0ah
  inc	edi
  mov	byte [edi],0		;put zero at end
;write file
  mov	ebx,default_path	;filename to write (bug)
  mov	eax,path_buf		;data to write
  mov	ecx,edi			;get end of data
  sub	ecx,eax			;compute length of write
  mov	ebp,[enviro_ptrs]
  mov	edx,755q		;create an executable
  mov	esi,8h  
  call	file_write_close
bup_80:
  xor	eax,eax			;set normal exit
  jmp	bup_exit
bup_err_msg1:
  mov	esi,box_struc
  call	show_box
  call	key_mouse1
  mov	eax,-1
bup_exit:
  ret

;-----------------
  [section .data]

path_end_ptr:  dd	0

box_struc:
  dd	30003037h	;window color
  dd	box_msg
  dd	box_msg_end
  dd	0		;scroll posn
  db	30		;columns
  db	4		;rows
  db	4		;row at upper left corner
  db	4		;column at upper left corner
  dd	30003730h	;box outline color

box_msg: db 'Warning, missing field',0ah
	db  'or bad data entered',0ah
	db  'Press any key',0ah
box_msg_end:	db	0

make_fname: db 'Makefile',0

makefile:
 db '# Generic makefile to compile and produce binary for all',0ah
 db '# source files in local directory',0ah
 db '#',0ah
 db '# usage:  make  - make all asm files',0ah
 db '#         make clean - touch all source files',0ah
 db '# Note: if linker gives warning "can not find start" it may',0ah
 db '#       be a nasm bug. Caused by adding the -O2 optimize flag,',0ah
 db '#       or the symbol _start may need to be public.  Some debuggers',0ah
 db '#       need a start label of "main" made public.',0ah
 db '######################################################',0ah
 db '#',0ah
 db '# modify the following as needed',0ah
 db '#',0ah
 db '# select assembler, nasm, fasm, as, yasm',0ah
 db '#',0ah
 db 'assembler :=' 
make_assembler:
 db 'nasm                        ',0ah
 db '#',0ah
 db 'LIBS = /usr/lib/asmlib.a',0ah
 db ' ',0ah
 db '#LFLAGS =',0ah
 db 'LFLAGS = -static',0ah
 db 'LD = ld',0ah
 db 0ah
 db '# the following variables are probably ok',0ah
 db '######################################################',0ah
 db 'ifeq "$(assembler)" "nasm"',0ah
 db 'CC = nasm',0ah
 db 'DEBUG = -g',0ah
 db 'CFLAGS = -f elf',0ah
 db 'T = asm',0ah
 db 'endif',0ah
 db 0ah
 db 'ifeq "$(assembler)" "as"',0ah
 db 'CC = as',0ah
 db 'DEBUG = -gstabs',0ah
 db 'CFLAGS = -o $@',0ah
 db 'T = s',0ah
 db 'endif',0ah
 db 0ah
 db 'ifeq "$(assembler)" "yasm"',0ah
 db 'CC = yasm',0ah
 db 'DEBUG = -g stabs',0ah
 db 'CFLAGS = -f elf',0ah
 db 'T = asm',0ah
 db 'endif',0ah
 db 0ah
 db 0ah
 db 'ifeq "$(assembler)" "fasm"',0ah
 db 'CC = fasm',0ah
 db 'DEBUG =',0ah
 db 'CFLAGS =',0ah
 db 'T = asm',0ah
 db 'LD = echo',0ah
 db 'endif',0ah
 db 0ah
 db 'SHELL = /bin/bash',0ah
 db 'here = $(shell pwd)',0ah
 db 0ah
 db 'srcs = $(shell find . -maxdepth 1 -name ',27h,'*.$(T)',27h,')',0ah
 db 'targets = $(subst .$(T),,$(srcs))',0ah
 db 'objs = $(subst .$(T),.o,$(srcs))',0ah
 db 0ah
 db 0ah
 db '# template for each source compile',0ah
 db '%.o:    %.$(T)',0ah
 db '	$(CC) $(DEBUG) $(CFLAGS) $<',0ah
 db 0ah
 db '# template for link',0ah
 db '%:      %.o',0ah
 db '	$(LD) $^ $(LFLAGS) -o $@ $(LIBS)',0ah
 db 0ah
 db '$(targets):',0ah
 db 0ah
 db '$(objs):',0ah
 db 0ah
 db 'clean:',0ah
 db '	touch $(srcs)  ',0ah
 db 0ah
makefile_end:

asm_as:
  db '.data',0ah
  db 'message:',0ah
  db ' .ascii "\nHello, World!\n"',0ah
  db '.text',0ah
  db '.globl _start',0ah
  db '_start:',0ah
  db ' movl $4, %eax		#write code',0ah
  db ' movl $1, %ebx		#stdout',0ah
  db ' movl $message, %ecx	#message ptr',0ah
  db ' movl $15, %edx		#message length',0ah
  db ' int $0x80		#kernel call',0ah
  db ' movl $1, %eax		#exit code',0ah
  db ' movl $0, %ebx		#return status',0ah
  db ' int $0x80		#kernel call',0ah
asm_as_end:

asm_nasm_yasm:
  db '  global _start,main',0ah
  db 'main:',0ah
  db '_start:',0ah
  db '  mov	eax,4		;write function',0ah
  db '  mov	ebx,1		;stdout',0ah
  db '  mov	ecx,message	;message ptr',0ah
  db '  mov	edx,15		;message length',0ah
  db '  int	80h		;kernel call',0ah
  db '  mov	eax,1		;exit function',0ah
  db '  mov	ebx,0		;exit return code',0ah
  db '  int	80h',0ah
  db 0ah
  db ' [section .data]',0ah
  db "message db 0ah,'Hello, World!',0ah",0ah
asm_nasm_yasm_end:

asm_fasm:
  db 'format ELF executable',0ah
  db 'entry start',0ah
  db 0ah
  db 'segment readable writeable',0ah
  db 0ah
  db "msg db 'Hello world!',0ah",0ah
  db 'msg_size = $-msg',0ah
  db 0ah
  db 'segment readable executable',0ah
  db 0ah
  db 'start:',0ah
  db '',0ah
  db '	mov	eax,4',0ah
  db '	mov	ebx,1',0ah
  db '	mov	ecx,msg',0ah
  db '	mov	edx,msg_size',0ah
  db '	int	0x80',0ah
  db 0ah
  db '	mov	eax,1',0ah
  db '	xor	ebx,ebx',0ah
  db '	int	0x80',0ah
  db 0ah
asm_fasm_end:

debug_header: db '#!/bin/bash',0ah,0
debug_script: db 'debug',0       