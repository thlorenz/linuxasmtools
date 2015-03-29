
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
	extern	random_seed
;****f* random/random_dword *
; NAME
;>1 random
;  random_dword - generate random dword
; INPUTS
;    none
; OUTPUT
;    eax = random value
; NOTES
;   source file: random2.asm
;<
; * ----------------------------------------------
;*******

;  inputs:  none
;  output:  dx,ax = random value
 [section .data]
prev_rand	dd	0		;previous random, used as seed
rand_delta	dw	0		;delta lo-hi randow words
init_flag4	db	0		;set to 1 if initialized

permute1	EQU	0B303h
permute2	EQU	02D8Dh
  [section .text]

;------------------------------
  global random_dword
random_dword:
	cmp	byte [init_flag4],0
	jne	cont4
	call	rw3_init
cont4:	push	si
	push	di
	xor	di,di
	mov	ax,permute1
	mul	word [prev_rand]
	mov	si,ax		
	mov	bx,dx
	add	bx,ax		
	mov	cx,dx

	mov	ax,permute2
	mul	word [prev_rand+2]
	add	bx,ax			
	adc	cx,dx
	adc	di,0
	add	cx,ax			
	adc	di,dx

	mov	ax,permute2-permute1	
	mul	word [rand_delta]	
	add	bx,ax			
	adc	cx,dx
	adc	di,0

	shl	bx,1
	rcl	cx,1
	rcl	di,1			
	shr	bx,1			

	add	si,cx			
	adc	bx,di			

	mov	[prev_rand+2],bx		;save random number
	mov	[prev_rand],si		;  as seed for next entry
	mov	ax,si				;pass back result in DX:AX
	mov	dx,bx
	sub	si,bx
	mov	[rand_delta],si
	pop	di
	pop	si
	ret
;----------------------------------------
rw3_init:
	call	random_seed
	mov	dx,ax
	rol	dx,1
	mov	[prev_rand],ax
	mov	[prev_rand+2],dx
	sub	ax,dx
	mov	[rand_delta],dx
	mov	byte [init_flag4],1
	ret
