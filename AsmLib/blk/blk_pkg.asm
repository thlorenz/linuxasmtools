
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
;****f* blk/blk_insert_bytes *
;
; NAME
;>1 blk
;  blk_insert_bytes - insert data into block
;    The character beyond block end will be
;    propagated and at end of expanded block.
; INPUTS
;    edi = insert point
;    ebp = block end ptr (not end of buffer)
;    eax = lenght of insert string
;    esi = string to insert
; OUTPUT
;    ebp = adjusted block end ptr
; NOTES
;   file blk_pkg.asm
;   The function blk_finsert_bytes is prefered over
;   blk_insert_bytes.  Older function is being
;   depreciated
;<
; * ---------------------------------------------
;*******
  global blk_insert_bytes
blk_insert_bytes:
  push	esi
  call blk_make_hole		;edi = location to open
  pop	esi
  call blk_move			;eax=length, esi=from, edi=to
  ret

;****f* blk/blk_make_hole *
;
; NAME
;>1 blk
;  blk_make_hole - make hole in data block for insert
;    The created hole is not cleared, and end character
;    beyond end of block is propagated.
; INPUTS
;    edi = insert point (address)
;    ebp = end of data (not end of buffer)
;    eax = number of characters to insert
; OUTPUT
;    ebp = adjust data block end ptr 
; NOTES
;    all registers destroyed
;    file blk_pkg.asm
;   The function blk_fmake_hole is prefered over
;   blk_make_hole.  Older function is being
;   depreciated
;<
;  * ----------------------------------------------
;*******
  global blk_make_hole
blk_make_hole:
  push	edi
  or eax,eax			;exit if insert of zero bytes
  jz mh_ret
  mov esi,ebp			;file end ptr -> esi
  lea ecx,[esi+1]
  sub ecx,edi
  lea edi,[esi+eax]
  std
  rep movsb
  cld
  add ebp,eax			;adjust file end ptr
  clc
mh_ret:
  pop	edi
  ret

;****f* blk/blk_del_bytes *
;
; NAME
;>1 blk
;  blk_del_bytes - delete area from block of data
;    The freeded area at end of block is not cleared.
; INPUTS
;    eax = number of bytes to delete
;    edi = ptr to top of delete area
;    ebp = end of data area.
; OUTPUT
;    ebp = adusted file end ptr
; NOTES
;    all registers destroyed
;    file blk_pkg.asm
;   The function blk_fdel_bytes is prefered over
;   blk_del_hole.  Older function is being
;   depreciated
;<
;  * ----------------------------------------------
;*******
  global blk_del_bytes
blk_del_bytes:
  or eax,eax
  jz db_exit		;jmp if delete count = 0
  push edi
  mov ecx,ebp		;get file end ptr
  sub ecx,edi
  lea esi,[edi+eax]
  sub ecx,eax
  inc ecx
  cld
  rep movsb
  neg eax
  pop edi		;
  add ebp,eax
  clc
db_exit:
  ret


;****f* blk/blk_move *
;
; NAME
;>1 blk
;  blk_move - move block of data
; INPUTS
;    eax = move length
;    esi = from address
;    edi = to address
; OUTPUT
;    edi - unchanged
; NOTES
;    file blk_pkg.asm
;    see also, str_move
;<
;  * ----------------------------------------------
;*******
  global  blk_move
blk_move:
  push edi
  mov ecx,eax
  cld
  rep movsb
  pop edi
  clc
  ret

