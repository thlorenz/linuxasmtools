
;   Copyright (C) 2007 Jeff Owens
;
;   This program is free software: you can redistribute it and/or modify
;   it under the terms of the GNU General Public License as published by
;   the Free Software Foundation, either version 3 of the License, or
;   (at your option) any later version.
;
;   This program is distributed in the hope that it will be useful,
;   but WITHOUT ANY WARRANTY; without even the implied warranty of
;   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;   GNU General Public License for more details.
;
;   You should have received a copy of the GNU General Public License
;   along with this program.  If not, see <http://www.gnu.org/licenses/>.


  [section .text align=1]

  [section .text]

  extern stack_env_ptr

;****f* env/
; NAME
;>1 env
;  save_stack_ptrs - save information from stack
; INPUTS
;    esp = stack ptr before any pops or pushes
; OUTPUT
;    stack_args_ptr - global ptr to: number or args,
;                     followed by arg ptrs.
;    stack_env_ptr  - global ptr to enviornment ptrs
;    stack_aux_ptr  - global ptr to aux data. Each entry
;                     consists or "code" followed by "data"
;                     (see codes)
;    syscall        - kernel entery found in aux data area
;
; NOTES
;    source file:  save_stack_ptrs.asm
;
;    codes taken from /usr/include/elf.h 
;       AT_NULL		0		/* End of vector */
;       AT_IGNORE	1		/* Entry should be ignored */
;       AT_EXECFD	2		/* File descriptor of program */
;       AT_PHDR		3		/* Program headers for program */
;       AT_PHENT	4		/* Size of program header entry */
;       AT_PHNUM	5		/* Number of program headers */
;       AT_PAGESZ	6		/* System page size */
;       AT_BASE		7		/* Base address of interpreter */
;       AT_FLAGS	8		/* Flags */
;       AT_ENTRY	9		/* Entry point of program */
;       AT_NOTELF	10		/* Program is not ELF */
;       AT_UID		11		/* Real uid */
;       AT_EUID		12		/* Effective uid */
;       AT_GID		13		/* Real gid */
;       AT_EGID		14		/* Effective gid */
;       AT_CLKTCK	17		/* Frequency of times() */
;       AT_PLATFORM	15		/* String identifying platform.  */
;       AT_HWCAP	16		/* Machine dependent hints about
;       AT_FPUCW	18		/* Used FPU control word.  */
;       AT_DCACHEBSIZE	19		/* Data cache block size.  */
;       AT_ICACHEBSIZE	20		/* Instruction cache block size.  */
;       AT_UCACHEBSIZE	21		/* Unified cache block size.  */
;       AT_IGNOREPPC	22		/* Entry should be ignored.  */
;      	AT_SECURE	23		/* Boolean, was exec setuid-like?  */
;       AT_SYSINFO	32
;       AT_SYSINFO_EHDR	33
;       AT_L1I_CACHESHAPE	34
;       AT_L1D_CACHESHAPE	35
;       AT_L2_CACHESHAPE	36
;       AT_L3_CACHESHAPE	37
;<
;  * ----------------------------------------------
;*******
  global save_stack_ptrs
save_stack_ptrs:
  cld
  mov	esi,esp
  lodsd			;get return address
  mov	[stack_args_ptr],esi
lp1:
  lodsd
  or	eax,eax
  jnz	lp1		;loop till start of env ptrs
  mov	[stack_env_ptr],esi
lp2:
  lodsd
  or	eax,eax
  jnz	lp2		;loop till start of env ptrs
  mov	[stack_aux_ptr],esi
;find syscall 
  mov	ecx,20
lp3:
  lodsd			;get code
  cmp	eax,byte 20h
  lodsd			;get data for this code
  je	found_it
  loop	lp3
  jmp	ssp_exit
found_it:
  mov	[syscall],eax
ssp_exit:
  ret

int_80:  int	byte 80h
	ret
;---------------
  [section .data]
  global stack_args_ptr,stack_aux_ptr,syscall
stack_args_ptr:	dd 0
;stack_env_ptr:	dd 0
stack_aux_ptr:	dd 0
syscall:	dd int_80

%ifdef DEBUG
;Programs can call kernel directly and bypass "int 80h" by
;looking up a kernel entry point on the stack.  The stack
;is organized as follows:
; - parameter count
; - parameter 1 (ptr to our name)
; - (additional ptrs here)
; - 0 = terminator for paramerer ptrs
; - enviro ptr 1
; - enviro ptr 2
; - (additional ptrs here)
; - 0 = terminator for enviro ptrs
; - aux information area, with dword pairs.  Each
;   pair consists of code,data.  The type of data
;   is specified by code.  A code of 20h is the
;   sysenter kernel entry address.
; - 0 = terminator for aux area
; - strings table
;
; compile with:   nasm -felf -g program_name
; link with:      ld program_name.o program_name
;
; The following code search the stack for kernel entry
; and stores it.  Then, it displays a message using the
; kernel entry vector.
  [section .text]
  global _start
_start:
  call	save_stack_ptrs
  mov   ecx, msg          ; string to print (not 0-terminated!)
  mov   edx,msg_end - msg
  mov   eax, 4            ; write
  mov   ebx, 1            ; fd 1: stdout
  call  [syscall]
  mov	eax,1
  call	[syscall]
;----------
  [section .data]
syscall:    dd 0              ; for making syscalls
msg         db 0ah,"Syscall vector call", 0Ah
msg_end:

%endif