
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
  extern screenline
  extern file_status_handle
  extern dword_to_ascii
  extern log_num,log_str,log_eol,log_regtxt
  [section .text]

struc stat_struc
.st_dev: resd 1 ;device
.st_ino: resd 1 ;inode
.st_mode: resw 1 ;see below
.st_nlink: resw 1 ;number of hard links
.st_uid: resw 1 ;user ID of owner
.st_gid: resw 1 ;group ID of owner
.st_rdev: resd 1 ;device type (if inode device)
.st_size: resd 1 ;total size in bytes
.st_blksize: resd 1 ;blocksize for filesystem I/O
.st_blocks: resd 1 ;number of blocks allocated
.st_atime: resd 1 ;time of last access
.__unused1: resd 1
.st_mtime: resd 1 ;time of last modification
.__unused2: resd 1
.st_ctime: resd 1 ;time of last change
.__unused3: resd 1
.__unused4: resd 1
.__unused5: resd 1
; --- stat_struc_size
endstruc

;   The following flags are defined for the st_mode field
;   -
;   S_IFMT 0170000 bitmask for the file type bitfields
;   S_IFSOCK 0140000 socket
;   S_IFLNK 0120000 symbolic link
;   S_IFREG 0100000 regular file
;   S_IFBLK 0060000 block device
;   S_IFDIR 0040000 directory
;   S_IFCHR 0020000 character device
;   S_IFIFO 0010000 fifo
;   S_ISUID 0004000 set UID bit
;   S_ISGID 0002000 set GID bit (see below)
;   S_ISVTX 0001000 sticky bit (see below)
;   S_IRWXU 00700 mask for file owner permissions
;   S_IRUSR 00400 owner has read permission
;   S_IWUSR 00200 owner has write permission
;   S_IXUSR 00100 owner has execute permission
;   S_IRWXG 00070 mask for group permissions
;   S_IRGRP 00040 group has read permission
;   S_IWGRP 00020 group has write permission
;   S_IXGRP 00010 group has execute permission
;   S_IRWXO 00007 mask for permissions for others (not in group)
;   S_IROTH 00004 others have read permission
;   S_IWOTH 00002 others have write permisson
;   S_IXOTH 00001 others have execute permission
; NOTES
;   file: file_basics.asm
;   stat_struc is held in temporary buffer and may be overwritten
;   -by next library call.


struc termios_struc
.c_iflag: resd 1
.c_oflag: resd 1
.c_cflag: resd 1
.c_lflag: resd 1
.c_line: resb 1
.c_cc: resb 19
endstruc

;---------------------------------------------------------
;****f* err/log_fd *
; NAME
;>1 log-error
;  log_fd - log status of file descriptor
; INPUTS
;    eax = fd (file descriptor)
; NOTES
;    source file: log_fd.asm
;<
;  * ----------------------------------------------
;*******
  global log_fd
log_fd:
  pusha
  mov	[fd],eax	;save file descriptor
  mov	eax,' fd='
  call	log_regtxt
  mov	eax,[fd]
  call	log_num
  mov	ebx,eax
  call	file_status_handle
;   eax = result if negative file does not exist and sign
;   bit is set for js jns jump
;   if eax positive then dx = permissions
;   if eax positive ecx = ptr to stat struct (below)
  jns	lf_ok		;jmp if valid fd
  mov	esi,invalid_msg
  call	log_str
  jmp	lf_end1
lf_ok:
  call	decode_type

  mov	eax,54		;ioctl
  mov	ebx,[fd]
  mov	ecx,5401h	;TCGETS
  mov	edx,screenline
  int	80h

  call	decode_termios

  mov	eax,55		;fcntl
  mov	ebx,[fd]
  mov	ecx,1		;F_GETFD
  mov	edx,screenline	;
  int	80h		;returns flag in eax
  mov	esi,close_ex1
  test	al,1
  jnz	lf_10
  mov	esi,close_ex2
lf_10:
  call	log_str

  mov	eax,[fd]
  mov	edi,destination
  call	dword_to_ascii
  mov	byte [edi],0	;terminate string
  
  mov	eax,85		;readlink
  mov	ebx,proc_entry
  mov	ecx,screenline
  mov	edx,20		;buf size
  int	80h

  mov	esi,screenline
  call	log_str

lf_end1:
  call	log_eol
  popa
  ret	
;--------------
  [section .data]
fd:	dd	0
type:   db	0,0,0,0,0
invalid_msg: db 'invalid fd',0
close_ex1:	db 'fd-close-on-ex ',0
close_ex2:	db 'fd_open-on-ex ',0

proc_entry: db '/proc/self/fd/'
destination: db 0,0,0,0,0


  [section .text]
;---------------
decode_type:
  mov	ebx,[ecx + stat_struc.st_mode]
  and	ebx,170000q	;isolate type bits
;   S_IFLNK 0120000 symbolic link
;   S_IFREG 0100000 regular file
;   S_IFBLK 0060000 block device
;   S_IFDIR 0040000 directory
;   S_IFCHR 0020000 character device
;   S_IFIFO 0010000 fifo
  mov	eax,'synk'  
  cmp	ebx,120000q
  je	dt_done		;jmp if symbolic link
  mov	eax,'file'
  cmp	ebx,100000q
  je	dt_done		;jmp if file
  mov	eax,'blk '
  cmp	ebx,60000q
  je	dt_done		;jmp if block device  
  mov	eax,'dir '
  cmp	ebx,40000q
  je	dt_done		;jmp if directory
  mov	eax,'char'
  cmp	ebx,20000q
  je	dt_done
  mov	eax,'fifi'
  cmp	ebx,100000q
  je	dt_done
  mov	eax,'typ?'
dt_done:
  call	log_regtxt
  mov	esi,blank
  call	log_str
  ret
;-------------------------------------
decode_termios:
  mov	ebx,[screenline + termios_struc.c_lflag]
  mov	esi,raw1
  test	ebx,2
  jnz	dt_1
  mov	esi,raw2
dt_1:
  call	log_str
  mov	esi,echo1
  test	ebx,10q
  jz	dt_2
  mov	esi,echo2
dt_2:
  call	log_str
  ret

raw1: db ' no-'
raw2: db 'raw ',0
echo1: db ' no-'
echo2: db 'echo'
blank:	db ' ',0
;---------------------------------------

    
  

