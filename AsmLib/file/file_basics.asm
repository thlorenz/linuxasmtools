
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

  [section .text]


;****f* file/file_status_name *
; NAME
;>1 file
;  file_status_name - check filename exists and get status
; INPUTS
;    ebx = ptr to full path name.
; OUTPUT
;    eax = result if negative file does not exist and sign
;                 bit is set for js jns jump
;                 if eax positive then dx = permissions
;                 if eax positive ecx = ptr to stat struct (below)
;      
;     struc	stat_struc
;     .st_dev: resd 1        ;device
;     .st_ino: resd 1        ;inode
;     .st_mode: resw 1       ;see below
;     .st_nlink: resw 1      ;number of hard links
;     .st_uid: resw 1        ;user ID of owner
;     .st_gid: resw 1        ;group ID of owner
;     .st_rdev: resd 1       ;device type (if inode device)
;     .st_size: resd 1       ;total size in bytes
;     .st_blksize: resd 1    ;blocksize for filesystem I/O
;     .st_blocks: resd 1     ;number of blocks allocated
;     .st_atime: resd 1      ;time of last access
;     .__unused1: resd 1	
;     .st_mtime: resd 1      ;time of last modification
;     .__unused2: resd 1
;     .st_ctime: resd 1      ;time of last change
;     .__unused3: resd 1
;     .__unused4: resd 1
;     .__unused5: resd 1
;     ;  ---  stat_struc_size
;     endstruc
;      
;     The following "octal" flags are defined for the st_mode field
;      
;              0170000 bitmask for the file type bitfields
;
;     S_IFSOCK 0140000 socket
;     S_IFLNK  0120000 symbolic link
;     S_IFREG  0100000 regular file
;     S_IFBLK  0060000 block device
;     S_IFDIR  0040000 directory
;     S_IFCHR  0020000 character device
;     S_IFIFO  0010000 fifo
;     S_ISUID  0004000 set UID bit
;     S_ISGID  0002000 set GID bit (see below)
;     S_ISVTX  0001000 sticky bit (see below)
;
;              00700   mask for file owner permissions
;
;     S_IRUSR  00400   owner has read permission
;     S_IWUSR  00200   owner has write permission
;     S_IXUSR  00100   owner has execute permission
;
;              00070   mask for group permissions
;
;     S_IRGRP  00040   group has read permission
;     S_IWGRP  00020   group has write permission
;     S_IXGRP  00010   group has execute permission
;
;              00007   mask for permissions for others (not in group)
;
;     S_IROTH  00004   others have read permission
;     S_IWOTH  00002   others have write permisson
;     S_IXOTH  00001   others have execute permission
; NOTES
;    file: file_basics.asm
;    stat_struc is held in temporary buffer and may be overwritten
;     by next library call.
;<
;  * ----------------------------------------------
;*******
;****f* file/file_status_handle *
; NAME
;>1 file
;  file_status_handle - check filename exists and get status
; INPUTS
;    ebx = file descriptor (handle)
; OUTPUT
;    eax = result if negative file does not exist and sign
;                   bit is set for js jns jump
;                 if eax positive then dx = permissions
;                 if eax positive ecx = ptr to stat struct (below)
;      
;     struc	stat_struc
;     .st_dev: resd 1           ;device
;     .st_ino: resd 1           ;inode
;     .st_mode: resw 1          ;see below
;     .st_nlink: resw 1 	;number of hard links
;     .st_uid: resw 1		;user ID of owner
;     .st_gid: resw 1		;group ID of owner
;     .st_rdev: resd 1  	;device type (if inode device)
;     .st_size: resd 1  	;total size in bytes
;     .st_blksize: resd 1	;blocksize for filesystem I/O
;     .st_blocks: resd 1	;number of blocks allocated
;     .st_atime: resd 1	        ;time of last access
;     .__unused1: resd 1	
;     .st_mtime: resd 1  	;time of last modification
;     .__unused2: resd 1
;     .st_ctime: resd 1	        ;time of last change
;     .__unused3: resd 1
;     .__unused4: resd 1
;     .__unused5: resd 1
;     ;  ---  stat_struc_size
;     endstruc
;      
;     The following "octal" flags are defined for the st_mode field
;      
;              0170000 bitmask for the file type bitfields
;
;     S_IFSOCK 0140000 socket
;     S_IFLNK  0120000 symbolic link
;     S_IFREG  0100000 regular file
;     S_IFBLK  0060000 block device
;     S_IFDIR  0040000 directory
;     S_IFCHR  0020000 character device
;     S_IFIFO  0010000 fifo
;     S_ISUID  0004000 set UID bit
;     S_ISGID  0002000 set GID bit (see below)
;     S_ISVTX  0001000 sticky bit (see below)
;
;              00700   mask for file owner permissions
;
;     S_IRUSR  00400   owner has read permission
;     S_IWUSR  00200   owner has write permission
;     S_IXUSR  00100   owner has execute permission
;
;              00070   mask for group permissions
;
;     S_IRGRP  00040   group has read permission
;     S_IWGRP  00020   group has write permission
;     S_IXGRP  00010   group has execute permission
;
;              00007   mask for permissions for others (not in group)
;
;     S_IROTH  00004   others have read permission
;     S_IWOTH  00002   others have write permisson
;     S_IXOTH  00001   others have execute permission
; NOTES
;    file: file_basics.asm
;    stat_struc is held in temporary buffer and may be overwritten
;    by next library call.
;<
;  * ----------------------------------------------
;*******
  global file_status_name
  global file_status_handle
file_status_handle:
  mov	eax,108
  jmp	short fsn_10
file_status_name:
  mov	eax,107
fsn_10:
  mov	ecx,lib_buf + 200	;use lib_buf for fstat buffer
  int	80h
  or	eax,eax
  js	fe_exit			;jmp if file does not exist
  mov	edx,[lib_buf + 200 + stat_struc.st_mode]
  and	edx,777q		;file permisions
fe_exit:
  ret
;****f* file/file_open_rd *
;
; NAME
;>1 file
;  file_open_rd - open named file
; INPUTS
;     ebx = ptr to full path for file.
; OUTPUT
;     eax = negative err# if file can not be accessed
;           flags set for js jns jump
;           else eax = file handle of open file
;     dx  = file permissions if eax positive
;     [lib_buf + 200] contains stat_struc (see file_status_*)
; NOTES
;    file:  file_basics.asm
;<
;  * ----------------------------------------------
;*******
;****f* file/file_open *
; NAME
;>1 file
;  file_open - open named file
; INPUTS
;    ebx = ptr to full file path
;    ecx = access flags
;      O_RDONLY          00
;      O_WRONLY          01
;      O_RDWR            02
;
;      O_CREAT           0100
;      O_EXCL            0200
;      O_NOCTTY          0400
;      O_TRUNC           01000
;      O_APPEND          02000
;      O_NONBLOCK        04000
;      O_NDELAY          O_NONBLOCK
;      O_SYNC            010000 specific to ext2 fs and block devices
;      FASYNC            020000 fcntl, for BSD compatibility
;      O_DIRECT          040000 direct disk access hint-currently ignored
;      O_LARGEFILE       0100000
;      O_DIRECTORY       0200000 must be a directory
;      O_NOFOLLOW        0400000 don't follow links;
;
;    edx = permissions used if file created
;      S_ISUID           04000 set user ID on execution
;      S_ISGID           02000 set group ID on execution
;      S_ISVTX           01000 sticky bit
;      S_IRUSR           00400 read by owner(S_IREAD)
;      S_IWUSR           00200 write by owner(S_IWRITE)
;      S_IXUSR           00100 execute/search by owner(S_IEXEC)
;      S_IRGRP           00040 read by group
;      S_IWGRP           00020 write by group
;      S_IXGRP           00010 execute/search by group
;      S_IROTH           00004 read by others
;      S_IWOTH           00002 write by others
;      S_IXOTH           00001 execute/search by others
; OUTPUT
;    eax = negative if error (error number)
;    eax = positive file handle if success
;          flags are set for js jns jump
; NOTES
;    source file:  file_basics.asm
;<
;  * ----------------------------------------------
;*******
  global file_open_rd
  global file_open
file_open_rd:
  call	file_status_name
  js	of_exit			;exit if file does not exist
  xor	ecx,ecx
 
file_open:			;entry for other opens
  mov	eax,5
  int	80h
  or	eax,eax
of_exit:
  ret

;****f* file/file_close *
; NAME
;>1 file
;  file_close - close opened file
; INPUTS
;    ebx = file handle (file descriptor)
; OUTPUT
;    eax = negative if error (error number)
;          flag bits set for js jns jumps
; NOTES
;    source file:  file_basics.asm
;<
;  * ----------------------------------------------
;*******
  global file_close
file_close:
  mov	eax,6
  int	80h
  or	eax,eax
  ret

;****f* file/file_length_name *
; NAME
;>1 file
;  file_length_name - get length of named file
; INPUTS
;    ebx = ptr to full path for file
; OUTPUT
;    eax = negative if error (error number)
;          flag bits set for js jns jumps
;          else (eax positive) file length
; NOTES
;    file:  file_basics.asm
;<
;  * ----------------------------------------------
;*******
;****f* file/file_length_handle *
; NAME
;>1 file
;  file_length_handle - get length of file using descriptor
; INPUTS
;    ebx = file handle (file descriptor)
; OUTPUT
;    eax = negative if error (error number)
;          flag bits set for js jns jumps
;          else (eax positive) file length
; NOTES
;    source file:  file_basics.asm
;<
;  * ----------------------------------------------
;*******
  global file_length_name
  global file_length_handle
file_length_name:
  call	file_status_name
  jmp	short flh_10
file_length_handle:
  call	file_status_handle
flh_10:
  or	eax,eax
  js	flh_exit			;jmp if file does not exist
  mov	eax,[lib_buf + 200 + stat_struc.st_size]
flh_exit:
  ret

;****f* file/file_read *
; NAME
;>1 file
;  file_read - read n bytes from open file
; INPUTS
;    ebx = file descriptor (handle)
;    edx = buffer  size
;    ecx = buffer ptr
; OUTPUT
;    eax contains a negative error code or
;        a positive count of bytes read.
; NOTES
;   source file: file_basics.asm
;<
; * ----------------------------------------------
;*******
  global file_read
file_read:
  mov	eax,3			;read file
  int	80h			;go read file
  or	eax,eax
  ret

;****f* file/file_write *
; NAME
;>1 file
;  file_write - write n bytes to open file
; INPUTS
;    ebx = file descriptor (handle)
;    edx = number of bytes to write
;    ecx = buffer ptr
; OUTPUT
;    eax contains a negative error code or
;        a positive count of bytes written
; NOTES
;   source file: file_basics.asm
;<
; * ----------------------------------------------
;*******
  global file_write
file_write:
  mov	eax,4			;write file
  int	80h			;go write file
  or	eax,eax
  ret
;****f* file/file_simple_read *
; NAME
;>1 file
;  file_simple_read - open & read file to buffer, then close
; INPUTS
;    ebx = ptr to full path for file.
;    edx = buffer  size
;    ecx = buffer ptr
; OUTPUT
;    eax contains a negative error code or
;        a positive count of bytes read
;        the sign bit is set for js/jns 
; NOTES
;   source file: file_basics.asm
;<
; * ----------------------------------------------
;*******
  global file_simple_read
file_simple_read:
  push	ecx
  push	edx
  xor	ecx,ecx			;set open read only
  xor	edx,edx
  call	file_open
  pop	edx			;restore buffer length
  pop	ecx			;restore buffer ptr
  js	fsr_exit		;exit if error
  mov	ebx,eax			;move file handle
  call	file_read
  push	eax
  call	file_close
  pop	eax
fsr_exit:
  or	eax,eax
  ret
