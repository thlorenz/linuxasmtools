
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
; NAME
;>1 blk
;  blk_finsert_bytes - insert data into block
; INPUTS
;    edi = insert point
;    ebp = block end ptr (beyond end of valid data)
;          this is not end of buffer, just data end.
;    eax = lenght of insert string
;    esi = address of string to insert
; OUTPUT
;    ebp = adjusted block end ptr
; NOTES
;   file: blk_fill_pkg.asm
;   It is callers responsibility to check if buffer
;   is big enought to hold increased data size after
;   insert.
;<
; * ---------------------------------------------
;*******
  global blk_finsert_bytes
blk_finsert_bytes:
  push	esi
  call blk_fmake_hole		;edi = location to open
  pop	esi
  call blk_fmove			;eax=length, esi=from, edi=to
  ret

;
; NAME
;>1 blk
;  blk_fmake_hole - make hole and fill with zeros
;    Create a hole in block of data and fill with
;    zeroed bytes.
; INPUTS
;    edi = hole creation point (address)
;    ebp = file end address (beyond last valid byte)
;    eax = size of hole (number of bytes to insert)
; OUTPUT
;    ebp = adjusted file end ptr 
; NOTES
;    file: blk_fill_pkg.asm
;    hole is filled with zero bytes
;<
;  * ----------------------------------------------
;*******
  global blk_fmake_hole
blk_fmake_hole:
  push	edi
  push	eax
  or eax,eax			;exit if insert of zero bytes
  jz mh_ret
;compute length of move
  mov	ecx,ebp
  sub	ecx,edi
;;  sub	ecx,eax
;compute -from- ptr
  lea	esi,[ebp-1]		;-from- ptr
;compute -to- ptr
  mov	edi,esi
  add	edi,eax
  std
  rep movsb
  add ebp,eax			;adjust file end ptr
;fill hole with zeros
  mov	ecx,eax
  xor	eax,eax
bmh_fill_lp:
  stosb
  loop	bmh_fill_lp
  cld
  clc
mh_ret:
  pop	eax
  pop	edi
  ret


;
; NAME
;>1 blk
;  blk_fdel_bytes - delete area from block of data
;    After deletion the block will be decreased in
;    size.  Freeded area will be filled with zeros.
; INPUTS
;    eax = number of bytes to delete
;    edi = ptr to top of delete area
;    ebp = end of data block
; OUTPUT
;    ebp = adusted data block end ptr
; NOTES
;    file blk_fill_pkg.asm
;    
;<
;  * ----------------------------------------------
;*******
  global blk_fdel_bytes
blk_fdel_bytes:
  or eax,eax
  jz dbb_exit		;jmp if delete count = 0
  push edi
  mov ecx,ebp		;get file end ptr
  sub ecx,edi
  lea esi,[edi+eax]
  sub ecx,eax
  jecxz	dbb_skip	;exit if no move
  cld
  rep movsb
dbb_skip:
  sub	ebp,eax
;fill end with zeros
  mov	ecx,eax
  xor	eax,eax
  rep	stosb
  pop edi		;
  clc
dbb_exit:
  ret


;  blk_move - move block of data
; INPUTS
;    eax = move length
;    esi = from
;    edi = to
; OUTPUT
;    edi - unchanged
; NOTES
;    file blk_fill_pkg.asm
;    see also, str_move
;*******
  global  blk_fmove
blk_fmove:
  push edi
  mov ecx,eax
  cld
  rep movsb
  pop edi
  clc
  ret


%ifdef TEST

 global _start
_start:
  mov	edi,insert_point
  mov	ebp,block_end
  mov	eax,length
  mov	esi,insert_string
  call	blk_insert_bytes
  mov	eax,length
  mov	esi,insert_point	;actuall delete point
;ebp is end of file
  call	blk_del_bytes		;epb=end of file
  mov	eax,1
  int	80h
;----
  [section .data]
test_block:
 db 'here->'
insert_point:
 db '<-end of file'
block_end
 times 7 db 0ffh		;test byte
insert_string: db 'insert'
length equ 6

%endif

  [section .text]


