
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
  extern child_pid
  
;----------------------------------------------------------------
;>1 trace
;  trace_upeek - get data from kernel(user) memory
; INPUTS
;         [child_pid] global variable set to child pid
;                     before calling this function.
;         edx = address index (see below)
;         esi = pointer to storage dword
;               
; OUTPUT  eax = 0 if success
;         flags set for jz (success)
;                       js (error)
; NOTES
;    "trace_upeek" copies data from kernel memory
;    to our buffer.
;
;    The user area data format is from kernel file user.h
;    WARNING - the kernel may change this structure and the
;    file user.h needs to be monitored for changes.
;    WARNING - only index values 000h-040h appear to be
;    correct in kernel 2.6.12 ?
;    
;      index  contents
;      -----  ----------------------------
;       000h   ebx
;       004h   ecx
;       008h   edx
;       00ch   esi
;       010h   edi
;       014h   ebp
;       018h   eax
;       01ch   ds
;       020h   es
;       024h   fs
;       028h   gs
;       02ch   orig_eax
;       030h   eip
;       034h   cs
;       038h   eflags
;       03ch   esp
;       040h   ss
;       044h   u_fpvalid -floating point state flag, not implemented
;                floating point registers struc follows
;       048h   cwd
;       04ch   swd
;       050h   twd
;       054h   fip
;       058h   fcs
;       05ch   foo
;       060h   fos
;       064h - 0B3  filler
;       0B4h   u_tsize  text segment size
;       0B8h   u_dsize  data segment size
;       0BCh   u_ssize  stack segment size
;       0C0h   start_code starting adr
;       0C4h   start_stack starting address (top)
;       0C8h   signal signal that caused core dump
;       0CCh   reserved
;               struct user_regs_struct*	u_ar0;
;       0D0h   ebx
;       0D4h   ecx
;       0D8h   edx
;       0Dch   esi
;       0E0h   edi
;       0E4h   ebp
;       0E8h   eax
;       0Ech   ds
;       0F0h   es
;       0F4h   fs
;       0F8h   gs
;       0Fch   orig_eax
;       100h   eip
;       104h   cs
;       108h   eflags
;       10ch   esp
;       110h   ss
;             struct user_fpregs_struct*	u_fpstate;
;       114h   cwd
;       118h   swd
;       11ch   twd
;       120h   fip
;       124h   fcs
;       128h   foo
;       12ch   fos
;       130h - 17fh filler
;       
;       180h   magic
;       184h   u_comm [32]
;       1a4h   u_debugreg [8];
;
;    Source file: trace_user.inc
;<
  global trace_upeek
trace_upeek:
  mov	ecx,[child_pid]
  mov	ebx,3		;peekuser request code
  mov	eax,26		;ptrace kernel request
  int	80h
  or	eax,eax
  ret

;----------------------------------------------------------------
;>1 trace
;  trace_upeek_bytes - get string from kernel memory
; INPUTS
;         [child_pid] global variable set to child pid
;                     before calling this function.
;         edx = address index within kernel
;         esi = pointer to storage dword
;         edi = number of bytes to read
;               
; OUTPUT  eax = 0 if success
;         flags set for jz (success)
;                       js (error)
; NOTES
;    "trace_upeek" copies data from kernel memory
;    to our buffer.
;    Source file: trace_user.inc
;<
  global trace_upeek_bytes
trace_upeek_bytes:
tub_lp1:
  test	edi,0fffffffch	;is count greater than 3
  jz	tub_50		;jmp if count 3 or less
;count is 4 or greater
  call	trace_upeek
  js	tub_done	;jmp if error
  sub	edi,4		;adjust count
  add	esi,4		;move forward in buffer
  add	edx,4		;move forward in kernel memory
  jmp	short tub_lp1
;count is 3 or less
tub_50:
  or	edi,edi
  jz	tub_done	;jmp if no more bytes to read
  push	esi		;save buffer
  mov	esi,temp_dword;temporary buffer
  call	trace_upeek
  js	tub_done	;jmp if error
  pop	ecx		;restore callers buffer ptr
  xchg	edi,ecx
;edi=callers buffer  ecx=count  esi=ptr to dword read
  cld
  rep	movsb
tub_done:
  or	eax,eax
  ret

;----------------------------------------------------------------
;>1 trace
;  trace_upoke - store data into kernel menory
; INPUTS
;         [child_pid] global variable set to child pid
;                     before calling this function.
;         edx = address index with kernel memory
;         esi = data to stuff           
;               
; OUTPUT  eax = 0 if success
;         flags set for jz (success)
;                       js (error)
; NOTES
;    "trace_upoke" copies data from our buffer to
;    kernel memory.  
;    WARNING - not all areas of kernel memory can
;    be written.
;    Source file: trace_user.inc
;<
  global trace_upoke
trace_upoke:
  mov	ecx,[child_pid]
  mov	ebx,5		;pokeuser request code
  mov	eax,26		;ptrace kernel request
  int	80h
  or	eax,eax
  ret

;----------------------------------------------------------------
;>1 trace
;  trace_upoke_bytes - store string into kernel memory
; INPUTS
;         [child_pid] global variable set to child pid
;                     before calling this function.
;         edx = address index with kernel memory
;         esi = pointer to stuff data
;         edi = count of bytes to store
;               
; OUTPUT  eax = 0 if success
;         flags set for jz (success)
;                       js (error)
; NOTES
;    "trace_upoke" copies data from our buffer to
;    kernel memory.
;    WARNING not all areas of kernel memory an
;    be written.
;    Source file: trace_user.inc
;<
  global trace_upoke_bytes
trace_upoke_bytes:
tu_lp1:
  test	edi,0fffffffch	;is count greater than 3
  jz	tub_40		;jmp if count 3 or less
;count is 4 or greater
  push	esi		;save ptr to input data
  mov	esi,[esi]	;get data
  call	trace_upoke
  pop	esi		;restore input data ptr
  js	tu_done		;jmp if error
  sub	edi,4		;adjust count
  add	esi,4		;move forward in buffer
  add	edx,4		;move forward kernel memory
  jmp	short tu_lp1
;count is 3 or less, read dword from child and
;insert partial data, then write out adjusted dword
; edi = count of remaining bytes
; esi = ptr to input buffer
; edx = output address index(in kernel memory) 
tub_40:
  push	esi		;save buffer pointer
  mov	esi,temp_dword
  call	trace_upeek	;get current contents of kernel memory
  pop	esi
  js	tu_done
  mov	ecx,edi		;count to ecx
;  mov	edi,esi		;edi = input buffer ptr
  mov	edi,temp_dword
  cld
  rep	movsb		;move partial kernel data to dword
;write final dword
  mov	esi,[temp_dword];restore buffer
  call	trace_upoke	;write final dword
tu_done:
  or	eax,eax
  ret    

;-------------------
  [section .data]
temp_dword	dd	0
  [section .text]
;-------------------
