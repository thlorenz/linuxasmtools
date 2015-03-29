
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
  extern dir_status
  extern lib_buf
  extern str_move
  extern dir_change
  extern dir_current
;-------------------------------------------

%ifndef INCLUDES
struc dir_block
.handle			resd 1 ;set by dir_open
.allocation_end		resd 1 ;end of allocated memory
.dir_start_ptr		resd 1 ;ptr to start of dir records
.dir_end_ptr		resd 1 ;ptr to end of dir records
.index_ptr		resd 1 ;set by dir_index
.record_count		resd 1 ;set by dir_index
.work_buf_ptr		resd 1 ;set by dir_sort
dir_block_struc_size:
endstruc

  struc	stat_struc
.st_dev: resd 1
.st_ino: resd 1
.st_mode: resw 1
.st_nlink: resw 1
.st_uid: resw 1
.st_gid: resw 1
.st_rdev: resd 1
.st_size: resd 1
.st_blksize: resd 1
.st_blocks: resd 1
.st_atime: resd 1
.__unused1: resd 1
.st_mtime: resd 1
.__unused2: resd 1
.st_ctime: resd 1
.__unused3: resd 1
.__unused4: resd 1
.__unused5: resd 1
;  ---  stat_struc_size
  endstruc

%endif

; structure describing a directory entry
struc dtype
.d_size	resd 1	;byte size for fstat .st_size
.d_mode	resw 1	;type information from fstat .st_mode 
.d_uid  resw 1  ;owner code
.d_sort resb 1  ;sort code
.d_type  resb 1  ;type code (see below)
.d_nam resb 1	;directory name (variable length)
endstruc
;type codes = directory   = / sort=1
;             link to dir = ~ sort=2
;             socket      = = sort=3
;             char dev    = - sort=4
;             block dev   = + sort=5
;             pipe        = | sort=6
;             symlink     = @ sort=7
;             orphan link = ! sort=8
;             executable  = * sort=9
;             normal file = space sort=10
;

;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;>1 dir
;  dir_type - Add type information to indexed directory
;     dir_type is called by dir_sort_by_name and dir_sort_by_type.
;     Normally it is not called as a standalone function.
;  INPUTS
;     esi = ptr to path of this directory (ends with '/')
;     eax = ptr to open dir_block
;
;     struc dir_block
;      .handle			;set by dir_open
;      .allocation_end		;end of allocated memory
;      .dir_start_ptr		;ptr to start of dir records
;      .dir_end_ptr		;ptr to end of dir records
;      .index_ptr		;set by dir_index
;      .record_count		;set by dir_index
;      .work_buf_ptr		;set by dir_sort
;      dir_block_struc_size
;     endstruc
;
;     Note: dir_type is usually called after dir_index
;           or dir_open_indexed
;
;  OUTPUT     eax = negative if error, else it contains
;                   a ptr to the dir_block
;     The index now points to a directory entries with
;     the following structure:
;
;     struc dtype
;      .d_size	resd 1	;byte size for fstat .st_size
;      .d_mode	resw 1	;type information from fstat .st_mode 
;      .d_uid   resw 1  ;owner code
;      .d_sort  resb 1  ;length byte from dent structure
;      .d_type  resb 1  ;type code (see below)
;      .d_nam resb 1	;directory name (variable length)
;     endstruc
;type codes = directory   = / sort=1
;             link to dir = ~ sort=2
;             socket      = = sort=3
;             char dev    = - sort=4
;             block dev   = + sort=5
;             pipe        = | sort=6
;             symlink     = @ sort=7
;             orphan link = ! sort=8
;             executable  = * sort=9
;             normal file = space sort=10
;
;  NOTE
;     source file is dir_type.asm
;     related functions are: dir_open - allocate memory & read
;                            dir_index - allocate memory & index
;                            dir_open_indexed - dir_open + dir_index
;                            dir_sort - allocate memory & sort
;                            dir_open_sorted - open,index,sort
;                            dir_close_file - release file
;                            dir_close_memory - release memory
;                            dir_close - release file and memory
;
;<
;  * ----------------------------------------------
;store file codes in dirent's, put codes infront of file name.

  global dir_type
dir_type:
  push	eax
  mov	[our_path],esi
  mov	ebp,[eax + dir_block.index_ptr]	;sort_pointers
gt_loop1:
  mov	edi,[ebp]
  or	edi,edi
  jz	gt_donej		;jmp if empty directory
  add	edi,10			;move to filename
  mov	esi,[our_path]
  call	build_path1

  mov	ebx,[our_path]		;default_path
  call	dir_status

  or	eax,eax
  jns	gt_fill			;jmp if file found
;found we get error -75 with some character devices.
;If we assume all errors are char. devices it seems to work.
  jmp	char_dev
gt_donej:
  jmp	gt_err			;jmp if file not found
gt_fill:
  mov	ebx,[ebp]		;get pointer to dtype struc
;store st_size from fstat -> d_size
  mov	eax,[ecx+stat_struc.st_size]
  mov	[ebx + dtype.d_size],eax
;store st_mode from fstat -> d_type
  mov	ax,[ecx+stat_struc.st_mode]
  mov	[ebx + dtype.d_mode],ax
;store st_uid for fstat -> d_uid
  mov	ax,[ecx+stat_struc.st_uid]
  mov	[ebx + dtype.d_uid],ax
;
; decode file type
;
  mov	al,0e0h
  and	al,[ecx+stat_struc.st_mode+1]
  shr	al,5	;0=pipe 1=char 2=dir 3=block 4=file 5=sym 6=sock
;   
  dec	al
  js	pipe
  jz	char_dev
  sub	al,2
  js	directory
  jz	block_dev
  sub	al,2
  js	file_type
  jz	symlink
;assume socket
  mov	al,"3"	;sort
  mov	ah,'='
  jmp	short gt_store
pipe:
  mov	al,"6"
  mov	ah,'|'
  jmp	short gt_store
char_dev:
  mov	al,'4'
  mov	ah,'-'
  jmp	short gt_store
directory:
  mov	al,"1"
  mov	ah,'/'
  jmp	short gt_store
block_dev:
  mov	al,'5'
  mov	ah,'+'
  jmp	short gt_store
file_type:
  mov	al,'9'	;sort
  mov	ah,'*'	;execute
  test	[ecx+stat_struc.st_mode],word 01001001b ;any execute bits set?
  jnz	gt_store	;jmp if executeable
  mov	al,'a'	;normal file
  mov	ah,' '  ;normal file = space
  jmp	short gt_store
;check if directory or orphan
symlink:
  call	handle_link
;store sort & type al=sort ah=type
gt_store:
  mov	ebx,[ebp]		;get pointer to name
  mov	[ebx + dtype.d_sort],ax ;al=sort key ah=d_type
;move to next index 
  add	ebp,4
  jmp	gt_loop1
gt_err:

gt_done:
  pop	eax
  ret
;
;-----------------------------------------------------------------
;handle_link:

handle_link:
;we have found a symlink, check type, read target into lib_buf
  mov	esi,[our_path]
  mov	edi,lib_buf+400	;buf+400 origional path
  call	str_move

  mov	eax,85			;read link sys-call code
  mov	ebx,lib_buf+400		;buf+400 origional path
  mov	ecx,lib_buf+200		;buf+200 for symlink target
  mov	edx,400			;lib_buf_size
  int	80h			;call kernel
  or	eax,eax
  js	mp_exitj		;ignore if error
  add	eax,lib_buf+200		;compute end of data
  mov	byte [eax],0		;put zero at end of data
; check if symlink points to dir
  mov	ebx,lib_buf+200		;buf+200 symlink target
  call	dir_status		;results go to lib_buf [ecx]
mp_exitj:
  js	mp_orphan		;if error then exit
  mov	eax,0f000h
  and	eax,[ecx+stat_struc.st_mode]
  cmp	ah,80h
  mov	al,'@'			;symlink file
  je	mp_50			;jmp if symlink file
;status says we have a directory, but some /dev entires
;give this status if they point to /proc entry. possibly
;other cases, try nlink field?
;  cmp	[ecx+stat_struc.st_nlink],word 2
;  jne	mp_50			;assume directory
mp_49:
  mov	al,'~'			;symlink dir
mp_50:
  mov	[symlink_flag],al	;set local flag
;check access to file/dir/symlink
mp_55:
  mov	ebx,lib_buf+200		;buf+200 symlink target
  mov	ecx,4			;R_OK is it ok to read
  mov	eax,33			;access kernel call
  int	80h 			;can we read this dir?
  or	eax,eax
  js	mp_orphan		;exit if error
;check if we can enter directory
  cmp	[symlink_flag],byte '~'	;is this a directory entry
  jne	mp_file			;jmp if not dir
;save current dir
;  call	dir_current
;  mov	esi,ebx
;  mov	edi,lib_buf+200
;  call	str_move
;check if we can switch to new dir
  mov	ebx,lib_buf+200		;buf+200 symlink target
  call	dir_change
;restore origional directory
  push	eax
  mov	ebx,lib_buf+400		;buf+400 origional path
  call	dir_change
  pop	eax			;restore results of dir change
  or	eax,eax
  js	mp_orphan		;exit if access failed
;directory access ok
  mov	al,'2'		;sort for sym dir
  mov	ah,'~'
  jmp	short mp_exit
mp_file:
  mov	al,'7'		;sym link file
  mov	ah,'@'
  jmp	short mp_exit
mp_orphan:
  mov	al,'8'
  mov	ah,'!'
mp_exit:
  ret

;--------
  [section .data]
symlink_flag:	db 0	;"@"=file "~"=dir
  [section .text]
;-----------------------------------------------------------------
; build path for execution or open
;  input: edi = filename
;         esi = path base ending with '/'
;
build_path1:
  lodsb
  cmp	al,0
  jne	build_path1	;loop till end of path
  dec	esi
bpp_lp1:
  cmp	byte [esi],'/'
  je	bpp_append
  dec	esi
  jmp	short bpp_lp1	;scan back till '/' found
bpp_append:
  xchg	esi,edi
  inc	edi		;move past '/'
bpp_lp2:
  lodsb
  stosb
  cmp	al,0
  jne	bpp_lp2		;loop till name appended
  ret

  [section .data]
our_path	dd	0
  [section .text]

;---------------------------------------------------------------
