
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
  extern str_move
  extern dir_read_grow
  extern lib_buf
  extern compare_mask
;------------------------------------------------------
;>1 dir
;dir_walk - traverse directory and return selected paths
; inputs: esi = ptr to starting path
;         ebx = optional ptr to string with file mask:
;                  *xxxx  or xxxx*
;               The file mask is not applied to directories.
;               if ebx=0 then all files match mask
;         ecx = flags  ch - 01 return directories bit
;                         - 02 return files if mask allows
;                         - 04 return sym links
;                         - 08 return all non file,dir,symlink
;                      cl - max depth for recursion, 0=current level only
;         edx = process to call when a match occurs, the return
;               input to process is:
;                           eax=ptr to path string
;                           ecx=ptr to current match (also at end of path)
;                           [lib_buf] has stat_struc (see structures)
;               output from process is:
;                           eax=0 continue
;                           eax non-zero = abort directory walk and exit
;               the return process is called each time a path matches
;               the criteria (mask and flags).
;         eax = ptr to buffer, get using memory_init or call kernel function 45
;
; output: eax = 0 (success) or negative error number
;<
;-----------------------------------------------------------------
  global dir_walk
dir_walk:
  mov	[mask_ptr],ebx
  mov	[process_to_call],edx
  mov	[dents_buffer_top_ptr],eax
  mov	byte [depth],cl
  mov	byte [bit_flag],ch
;save the initial path
  mov	edi,the_path
  call	str_move		;move the path
  cmp	byte [edi -1],'/'	;does path end with '/'
  je	ffs_05			;jmp if path ends with '/'
  mov	al,'/'
  stosb				;put '/' at end of path
  mov	al,0
  stosb				;terminate path
ffs_05:
  mov	[path_end_ptr],edi

recurse:
  mov	ebx,the_path
;  mov	edi,[dents_buffer_top_ptr]
;  mov	ecx,80000		;buffer size 
  mov	eax,[dents_buffer_top_ptr]
  call	dir_read_grow		;open,read,close a directory
  jns	ffs_10			;jmp if good read
ffs_donej:
  xor	eax,eax			;set continue flag
  jmp	ffs_done		;exit if read error

ffs_10:
  mov	edx,[dents_buffer_top_ptr]
ffs_loop1:
  xor	ebx,ebx			;clear ebx
  cmp	dword [edx+4],0		;check if offset zero
  je	ffs_donej		;jmp if end of directory
  cmp	word [edx+8],0
  je	ffs_donej		;jmp if record length zero
  mov	esi,edx			;get pointer to this entry
  add	esi,8			;move past inode and offset
  mov	bx,[esi]		;get length of this record
  add	edx,ebx			;compute next entry position
  mov	[dents_buffer_entry_ptr],edx
  add	esi,2			;move forward to filename
  cmp	byte [esi],'.'
  jne	ffs_ok			;jmp if not possible header entry
  cmp	byte [esi+1],0
  je	ffs_nextj		;skip this "." header entry
  cmp	byte [esi+1],'.'
  jne	ffs_ok			;jmp if not possible header entry
  cmp	byte [esi+2],0
  je	ffs_nextj		;skip this ".." header entry
ffs_ok:
;
; we have found a valid entry, at [esi], check type and file mask
;
  mov	edi,esi			;get append item
  mov	[current_entry],esi
  mov	esi,the_path
  call	build_path
  mov	ebx,the_path
  mov	ecx,lib_buf
  mov	eax,107			;fstat
  int	80h
  or	eax,eax
  js	ffs_donej		;jmp if file not found (error)
;
; decode file type
;
  mov	ax,0f000h
  and	ax,[lib_buf + stat_struc.st_mode]
  cmp	ah,80h			;check if file
  je	ffs_15			;jmp if file
  cmp	ah,0a0h			;check if sym-link
  jne	ffs_20			;jmp if not sym link
  test	byte [bit_flag],4
  jnz	ffs_17			;jmp if symlink of interest
ffs_nextj:
  jmp	ffs_next		;jmp if symlink not of interest
;regular file found, check if file bit set
ffs_15:
  test	byte [bit_flag],2	;are files to be returned
  jz	ffs_nextj		;jmp if files are not of interest
;check if file mask active
ffs_17:
  mov	ecx,[mask_ptr]		;get mask ptr
  jecxz	ffs_call		;jmp if no mask active
;check file [current_entry] against the mask in [ecx]
  mov	esi,ecx
  mov	edi,[current_entry]
  call	compare_mask
  jne	ffs_nextj
ffs_call:
  mov	eax,the_path		;give caller the path
  mov	ecx,[current_entry]	;give caller the entry
  call	[process_to_call]
  or	eax,eax			;check if quit requested
  jnz	ffs_donej2
  jmp	ffs_next
;check if this entry is a directory
ffs_20:  
  cmp	ah,40h			;check if directory
  je	ffs_40			;jmp if directory entry
;check if caller wants to see "other"
  test	byte [bit_flag],8
  jnz	ffs_call		;report "other" to caller
  jmp	ffs_next		;jmp if "other" files are ignored
ffs_donej2:
  jmp	ffs_done
;does caller want to see directories?
ffs_40:
 test	byte [bit_flag],1	;check if directories of interest
  jz	check_recursion
  mov	eax,the_path
  mov	ecx,[current_entry]	;give caller the entry
  call	[process_to_call]
  or	eax,eax
  jnz	ffs_donej2
;can we recurse on this directory?
check_recursion:
  cmp	byte [depth],0
  je	ffs_next		;jmp if at max depth in dir tree
  dec	byte [depth]
  mov	eax,[path_end_ptr]	;append '/' to end of this dir
  mov	byte [eax],'/'
  inc	eax
  mov	byte [eax],0
  mov	[path_end_ptr],eax	;save new ptr
  push	eax
  mov	eax,[dents_buffer_entry_ptr]
  push	eax
;stack has path append ptr, and processing point in dents buf
;**************
  call	recurse			;
;**************
  mov	ebx,eax			;save return status from process/
  inc	byte [depth]		;indicate we are back from lower level
  pop	eax
  mov	[dents_buffer_entry_ptr],eax
;strip last entry off the_path
  pop	edi			;restore path end ptr
  or	ebx,ebx
  jnz	ffs_donej2		;exit if abort request from process
ffs_clp5:
  dec	edi
  cmp	byte [edi],'/'
  jne	ffs_clp5		;loop till first entry stripped off
ffs_clp6:
  dec	edi
  cmp	byte [edi],'/'
  jne	ffs_clp6		;loop till another entry stripped off
  mov	byte [edi+1],0		;truncate the_path
;reread dents for this dir
  mov	ebx,the_path
;  mov	edi,[dents_buffer_top_ptr]
;  mov	ecx,80000		;buffer size 
  mov	eax,[dents_buffer_top_ptr]
  call	dir_read_grow		;open,read,close a directory

ffs_next:
  mov	edx,[dents_buffer_entry_ptr]	;move to next record
  jmp	ffs_loop1
ffs_done:
  ret


;-----------------------------------------------------------------
;
;build path for execution or open
;  input: edi = filename
;         esi = path base
;
build_path:
  lodsb
  cmp	al,0
  jne	build_path	;loop till end of path
  dec	esi
bp_lp1:
  cmp	byte [esi],'/'
  je	bp_append
  dec	esi
  jmp	short bp_lp1	;scan back till '/' found
bp_append:
  xchg	esi,edi
  inc	edi		;move past '/'
bp_lp2:
  lodsb
  stosb
  cmp	al,0
  jne	bp_lp2		;loop till name appended
  dec	edi
  mov	[path_end_ptr],edi
  ret


;-----------------------
  [section .data]
mask_ptr:	dd	0
process_to_call: dd	0
dents_buffer_top_ptr dd	0	;top of buffer from caller
dents_buffer_entry_ptr dd 0	;current processing point in dents buf
depth		db	0
bit_flag	db	0	;
path_end_ptr	dd	0	;ptr to current path end
the_path: times 200 db 0
current_entry: dd	0	;temp ptr to current entry
  [section .text]

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

;  -
;  The following flags are defined for the st_mode field
;  -
;  S_IFMT   0170000 bitmask for the file type bitfields
;  S_IFSOCK 0140000 socket
;  S_IFLNK  0120000 symbolic link
;  S_IFREG  0100000 regular file
;  S_IFBLK  0060000 block device
;  S_IFDIR  0040000 directory
;  S_IFCHR  0020000 character device
;  S_IFIFO  0010000 fifo
;  S_ISUID  0004000 set UID bit
;  S_ISGID  0002000 set GID bit (see below)
;  S_ISVTX  0001000 sticky bit (see below)
;  S_IRWXU  0000700 mask for file owner permissions
;  S_IRUSR  0000400 owner has read permission
;  S_IWUSR  0000200 owner has write permission
;  S_IXUSR  0000100 owner has execute permission
;  S_IRWXG  0000070 mask for group permissions
;  S_IRGRP  0000040 group has read permission
;  S_IWGRP  0000020 group has write permission
;  S_IXGRP  0000010 group has execute permission
;  S_IRWXO  0000007 mask for permissions for others (not in group)
;  S_IROTH  0000004 others have read permission
;  S_IWOTH  0000002 others have write permisson
;  S_IXOTH  0000001 others have execute permission


