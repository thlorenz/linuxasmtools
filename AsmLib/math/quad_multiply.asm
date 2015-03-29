
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
;
;>1 math
;  quad_multiply - multiply 64 bit values
; INPUTS
;   edx,eax = value 1
;   ecx,ebx = value 2
; OUTPUT:
;   edx,ecx,ebx,eax = result
; NOTES
;   source file: quad_multiply.asm
;<
; * ----------------------------------------------
  global quad_multiply
quad_multiply:
        push    esi                      ; save registers
        push    edi
        push    ebp                      ; set up stack frame

        mov     edi,edx                   ; save copy of argument 1
        mov     esi,eax

        mul     ebx                      ; arg1 low * arg2 low
        mov     [v1],eax
        mov     [v2],edx

        mov     eax,edi                   ; arg1 high * arg2 high
        mul     ecx
        mov     [v3],eax
        mov     ebp,edx			;save v4

        mov     eax,edi                   ; arg1 high * arg2 low
        mul     ebx
        add     [v2],eax                   ; accumulate result
        adc     [v3],edx
        adc     ebp,0

        mov     eax,esi                   ; arg1 low * arg2 high
        mul     ecx
        add     [v2],eax                   ; accumulate result
        adc     [v3],edx
        adc     ebp,0
;
; load up return registers, dx,cx,bx,ax
;
	mov	edx,ebp			;get v4
	mov	ecx,[v3]
	mov	ebx,[v2]
	mov	eax,[v1]
	
        pop     ebp                      ; restore registers
        pop     edi
        pop     esi
	ret

  [section .data]
v1	dd	0		;temp value 1
v2	dd	0		;temp value 2
v3	dd	0		;temp value 3
;v4	dd	0		;temp value 4 (in BP )
  [section .text]


