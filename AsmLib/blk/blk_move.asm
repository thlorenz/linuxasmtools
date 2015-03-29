
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
;***************  file:  dis.asm  *********************


;--------------------------------------------
;>1 blk
;   blk_bmove - move large block bytes
; INPUTS    esi = ptr to source block
;           edi = ptr to destination buffer
;           ecx = number of bytes to move
;
; OUTPUT    esi - points to end of input block
;           edi - points to end of output block
;           ecx - zero   
;
; NOTES:  Source file is blk_move.asm
;         Block moves will be faster if data is
;         dword aligned.  Put "align 4" on segments
;         and on buffers
;         If input esi and edi are dword aligned, a
;         faster move will occur.
;<
;--------------------------------------------
  global blk_bmove
blk_bmove:
  cld
  push	ecx
  shr	ecx,2
  call  blk_dmove
  pop	ecx
  and	ecx,3
  jecxz	bb_exit
  movsb
  dec	ecx
  jecxz	bb_exit
  movsb
  dec	ecx
  jecxz	bb_exit
  movsb
bb_exit:
  ret
;--------------------------------------------
;>1 blk
;   blk_dmove - move large block of dwords
; INPUTS    esi = ptr to source block
;           edi = ptr to destination buffer
;           ecx = number of dwords to move
;
; OUTPUT    esi - points to end of input block
;           edi - points to end of output block
;           ecx - zero   
;
; NOTES:  Source file is blk_move.asm
;         Block moves will be faster if data is
;         dword aligned.  Put "align 4" on segments
;         and on buffers
;         If input esi and edi are dword aligned, a
;         faster move will occur.
;<
;--------------------------------------------
  global blk_dmove
blk_dmove:
  jecxz	bd_exit
  cld
  rep	movsd
bd_exit:
  ret

%ifdef DEBUG
global main,_start
main:
_start:
  mov	esi,data1
  mov	edi,buffer
  mov	ecx,13
  call	blk_bmove
  mov	eax,1
  int	byte 80h

 [section .data]
data1: db 1,2,3,4,5,6,7,8,9,0,1,2,3
buffer: times 14 db 0
%endif
