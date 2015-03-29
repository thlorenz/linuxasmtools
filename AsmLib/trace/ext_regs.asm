
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

  extern trace_pid

;----------------------------------------------------------------
;>1 trace
;  trace_fregsget - get registers of traced process
; INPUTS
;         [trace_pid] global variable set to child pid
;                     before calling this function.
;         esi = pointer to register storeage area
;               
; OUTPUT  eax = 0 if success
;         flags set for jz (success)
;                       js (error)
;   if success ecx points to register structure as follows:
;   user_i387_struct struc
;    .cwd resd 1 ;control word
;    .swd resd 1 ;status word
;    .twd resd 1 ;tag word
;    .fip resd 1 ;instruction offset
;    .fcs resd 1 ;selector,opcode 
;    .foo resd 1 ;data offset
;    .fos resd 1 ;data selector
;    .fd0 rest 1 ;80bit register
;    .fd1 rest 1 ;80bit register
;    .fd2 rest 1
;    .fd3 rest 1
;    .fd4 rest 1
;    .fd5 rest 1
;    .fd6 rest 1
;    .fd7 rest 1
;   endstruc
;
; NOTES
;    "trace_fregsget" copies the traced process registers
;    to buffer pointed at by -esi-
;<
  global trace_fregsget
trace_fregsget:
  mov	ecx,[trace_pid]
  xor	edx,edx		;unused register
  mov	ebx,14		;getregs request code
  mov	eax,26		;ptrace kernel request
  int	80h
  or	eax,eax
  ret

;----------------------------------------------------------------
;>1 trace
;  trace_fxregsget - get registers of traced process
; INPUTS
;         [trace_pid] global variable set to child pid
;                     before calling this function.
;         esi = pointer to register storeage area
;               
; OUTPUT  eax = 0 if success
;         flags set for jz (success)
;                       js (error)
;   if success ecx points to register structure as follows:
;
;       struc fxsr
;        .cwd	resw 1; control word
;        .swd	resw 1; status word
;        .twd	resw 1; tag word
;        .fop	resw 1;
;        .fip	resd 1;
;        .fcs	resd 1;
;        .foo	resd 1;
;        .fos	resd 1;
;        .mxcsr	resd 1;
;        .reserved resw 2 ;
;        .fd0	resb 16 ;floating reg
;        .fd1	resb 16
;        .fd2	resb 16
;        .fd3	resb 16
;        .fd4	resb 16
;        .fd5	resb 16
;        .fd6	resb 16
;        .fd7	resb 16
;        .xmm0	resb 16 ;XMM reg
;        .xmm1	resb 16
;        .xmm2	resb 16
;        .xmm3	resb 16
;        .xmm4	resb 16
;        .xmm5	resb 16
;        .xmm6	resb 16
;        .xmm7	resb 16
;        .padding resd 56;
;       endstruc
;
; NOTES
;    "trace_fxregsget" copies the traced process registers
;    to buffer pointed at by -esi-
;<
  global trace_fxregsget
trace_fxregsget:
  mov	ecx,[trace_pid]
  xor	edx,edx		;unused register
  mov	ebx,18		;getregs request code
  mov	eax,26		;ptrace kernel request
  int	80h
  or	eax,eax
  ret

;----------------------------------------------------------------
;>1 trace
;  trace_fregsset - set registers of traced process
; INPUTS
;         [trace_pid] global variable set to child pid
;                     before calling this function.
;         esi = pointer to register storeage area
;   struct user_i387_struct
;    .cwd resd 1 ;control word
;    .swd resd 1 ;status word
;    .twd resd 1 ;tag word
;    .fip resd 1 ;instruction offset
;    .fcs resd 1 ;selector,opcode 
;    .foo resd 1 ;data offset
;    .fos resd 1 ;data selector
;    .fd0 rest 1 ;80bit register
;    .fd1 rest 1 ;80bit register
;    .fd2 rest 1
;    .fd3 rest 1
;    .fd4 rest 1
;    .fd5 rest 1
;    .fd6 rest 1
;    .fd7 rest 1
;   endstruc
;               
; OUTPUT  eax = 0 if success
;         flags set for jz (success)
;                       js (error)
;
; NOTES
;    "trace_fregsset" copies the data to traced process
;    registers.
;<
  global trace_fregsset
trace_fregsset:
  mov	ecx,[trace_pid]
  mov	ebx,15		;getregs request code
  mov	eax,26		;ptrace kernel request
  int	80h
  or	eax,eax
  ret

;----------------------------------------------------------------
;>1 trace
;  trace_fxregsset - set registers of traced process
; INPUTS
;         [trace_pid] global variable set to child pid
;                     before calling this function.
;         esi = pointer to register storeage area
;       struc fxsr
;        .cwd	resw 1; control word
;        .swd	resw 1; status word
;        .twd	resw 1; tag word
;        .fop	resw 1;
;        .fip	resd 1;
;        .fcs	resd 1;
;        .foo	resd 1;
;        .fos	resd 1;
;        .mxcsr	resd 1;
;        .reserved resw 2 ;
;        .fd0	resb 16 ;floating reg
;        .fd1	resb 16
;        .fd2	resb 16
;        .fd3	resb 16
;        .fd4	resb 16
;        .fd5	resb 16
;        .fd6	resb 16
;        .fd7	resb 16
;        .xmm0	resb 16 ;XMM reg
;        .xmm1	resb 16
;        .xmm2	resb 16
;        .xmm3	resb 16
;        .xmm4	resb 16
;        .xmm5	resb 16
;        .xmm6	resb 16
;        .xmm7	resb 16
;        .padding resd 56;
;       endstruc
;               
; OUTPUT  eax = 0 if success
;         flags set for jz (success)
;                       js (error)
;
; NOTES
;    "trace_fxregsset" copies the data to traced process
;    registers.
;<
  global trace_fxregsset
trace_fxregsset:
  mov	ecx,[trace_pid]
  mov	ebx,19		;getregs request code
  mov	eax,26		;ptrace kernel request
  int	80h
  or	eax,eax
  ret

