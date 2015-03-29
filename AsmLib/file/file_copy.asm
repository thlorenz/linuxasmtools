
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
  extern build_file_open
  extern build_write_open
  extern file_open,file_write,file_read,file_close
  extern lib_buf

lib_buf_size  equ	600

;****f* file/file_copy *
;
; NAME
;>1 file
;  file_copy - copy one file
; INPUTS
;    ch  = flags (these flags are for reading file)
;           bit 1 (0000 0001) = full path or local file
;           bit 2 (0000 0010) = full path or file at $HOME/[base]
;           (this register optional if full path is provided)
;           (it is ok to set both bits, local path checked first)
;    ebx = ptr to (from) filename
;    cl  = flags (write file flags)
;                0000 0001 - write to local directory or full path if given
;                0000 0010 - write to $HOME or full path if given
;                0000 0100 - use existing write attributes
;                0000 1000 - file attributes are from input file,
;                -           (ignore 0100 flag)
;                0001 0000 - append to existing file if found
;    edx = ptr to (destination) filename
;    ebp = ptr to enviornment pointer if any flag = 2
; OUTPUT
;    eax = negative error code or success if positive
; NOTES
;    source file: file_copy.asm
;<
; * ----------------------------------------------
;*******
  global file_copy
file_copy:
  push	ecx
  push	edx
  mov	[cf_env],ebp
;
; open (from)
;
  mov	al,ch			;get flags in al
  xchg	ebp,ebx			;ebp=name ptr ebx=env ptrs
  call	build_file_open		;return eax=handle/error edx=permissions
  pop	ebx			;get filename ptr
  pop	esi			;get flags to esi
  js	cf_exit1		;exit if error
  mov	[cf_from_handle],eax
  mov	[cf_perms],edx
;
; open destination
;
  mov	ebp,[cf_env]
  mov	edx,[cf_perms]		;permissions
  call	build_write_open
  js	cf_exit1
  mov	[cf_to_handle],eax
;
; read block
;
cf_loop:
  mov	ebx,[cf_from_handle]
  mov	edx,lib_buf_size
  mov	ecx,lib_buf
  call	file_read
  js	cf_exit 		;exit if error
  jz	cf_exit			;jmp if all data written
;
; write block
;
  mov	ebx,[cf_to_handle]
  mov	edx,eax			;get size of last read
  mov	ecx,lib_buf
  call	file_write
  jmp	short cf_loop
;
cf_exit:
  mov	ebx,[cf_to_handle]
  call	file_close
cf_exit2:
  mov	ebx,[cf_from_handle]
  call	file_close
cf_exit1:
  ret

  [section .data]
cf_env 		dd	0	;enviornment ptrs
cf_from_handle	dd	0
cf_to_handle	dd	0
cf_perms	dd	0
  [section .text]

;****f* file/file_list_copy *
; NAME
;>1 file
;  file_list_copy - copy files on list
; INPUTS
;    esi = ptr to file list
;          file list contains asciiz names
;          example:  file_list: db <from flag>
;                               db 'from_name1',0
;                               db <to flag>
;                               db 'to_name1',0
;                               db 0  ;end of  table
;         from flags
;           bit 1 (0000 0001) = full path or local file
;           bit 2 (0000 0010) = full path or file at $HOME/[base]
;           (this register optional if full path is provided)
;           (it is ok to set both bits, local path checked first)
;          destination flags
;                0000 0001 - write to local directory or full path if given
;                0000 0010 - write to $HOME or full path if given
;                0000 0100 - check for existing file and preserve attributes
;                0000 1000 - file attributes from in-file, ignore 0100 flag
;                0001 0000 - append to existing file if found
;    ebp = env ptr if any flags have bit 2 set ($HOME paths)
; NOTES
;    source file:  file_copy.asm
;<
; * ----------------------------------------------
;*******
  global file_list_copy
file_list_copy:
  mov	[cf_env],ebp	;save enviornment

flc_lp:
  lodsb
  mov	ch,al		;move flags to ch
  mov	ebx,esi		;get ptr to filename
flc_lp2:
  lodsb			;scan to end of filename
  or	al,al
  jnz	flc_lp2

  lodsb			;get flags
  mov	cl,al		;move flags to cl
  mov	edx,esi		;get ptr to file 2 name  
flc_lp3:
  lodsb			;scan to end of filename
  or	al,al
  jnz	flc_lp3

  mov	ebp,[cf_env]
  push	esi
  call	file_copy
  pop	esi
  cmp	byte [esi],0	;done?
  jnz	flc_lp
  ret    
;-------------

