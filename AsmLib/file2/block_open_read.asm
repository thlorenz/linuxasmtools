
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
  extern lib_buf
  extern env_home2
  extern str_move

  [section .text]

;>1 file2
;  block_open_read - open existing file as read-only
; INPUTS
;    ebx = ptr to full file path or local file.
;          full path is indicated by a '/' at start of name.
; 
; OUTPUT
;    eax = negative if error (error number)
;        = positive file handle if success
;          flags are set for js jns jump
;    ebx = file handle if eax positive
; NOTES
;    source file:  block_open_read.asm
;<
;  * ----------------------------------------------
;*******
  global block_open_read
block_open_read:
  mov	eax,107
fsn_10:
  mov	ecx,lib_buf + 200	;use lib_buf for fstat buffer
  int	80h
  or	eax,eax
  js	of_exit			;jmp if file does not exist

  xor	ecx,ecx			;open read only
  mov	eax,5
  int	80h
  or	eax,eax
  mov	ebx,eax
of_exit:
  ret

;--------------------------------------------------------
;>1 file2
;  block_open_home_read - open existing file as read-only
; INPUTS
;    ebx = ptr to partial path to append to $HOME directory
; 
; OUTPUT
;    eax = negative if error (error number)
;        = positive file handle if success
;          flags are set for js jns jump
;    ebx = file handle if eax positive
; NOTES
;    source file:  block_open_read.asm
;<
;  * ----------------------------------------------
;*******
  global block_open_home_read
block_open_home_read:
  push	ebx
  mov	edi,lib_buf+400	;location to build filename
  call	env_home2
  pop	esi		;get input filename
  call	str_move

  mov	ebx,lib_buf+400	;restore pointer to full file name
  mov	eax,107
  mov	ecx,lib_buf + 200	;use lib_buf for fstat buffer
  int	80h
  or	eax,eax
  js	bof_exit		;jmp if file does not exist

  xor	ecx,ecx			;open read only
  mov	eax,5
  int	80h
  or	eax,eax
  mov	ebx,eax
bof_exit:
  ret
