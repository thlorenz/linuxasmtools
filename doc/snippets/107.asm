; lstat - function example


  global _start
_start:
  mov	eax,107	;lstat function#
  mov	ebx,filename
  mov	ecx,buf
  int	80h


_exit:
  mov	eax,1	;exit function#
  int	80h	;exit
;------------
;---
  [section .data]

filename: db 'test.asm',0

buf:  ;  struc	stat_struc
st_dev: dd 0	;device
st_ino: dd 0	;inode
st_mode: dw 0	;see below
st_nlink: dw 0	;number of hard links
st_uid: dw 0	;user ID of owner
st_gid: dw 0	;group ID of owner
st_rdev: dd 0	;device type (if inode device)
st_size: dd 0	;total size in bytes
st_blksize: dd 0;blocksize for filesystem I/O
st_blocks: dd 0	;number of blocks allocated
st_atime: dd 0	;time of last access
__unused1: dd 0	
st_mtime: dd 0	;time of last modification
__unused2: dd 0
st_ctime: dd 0	;time of last change
__unused3: dd 0
__unused4: dd 0
__unused5: dd 0



;  ;  ---  stat_struc_size
;  endstruc
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
;
;
;       The value st_size gives the size of the file (if it is a  regular  file
;       or  a  symlink)  in  bytes.  The size of a symlink is the length of the
;       pathname it contains, without trailing NUL.
;
;       The value st_blocks gives the size of  the  file  in  512-byte  blocks.
;       (This  may  be  smaller than st_size/512 e.g. when the file has holes.)
;       The value st_blksize gives the "preferred" blocksize for efficient file
;       system  I/O.  (Writing to a file in smaller chunks may cause an ineffi-
;       cient read-modify-rewrite.)
;
;       Not all of the Linux filesystems implement  all  of  the  time  fields.
;       Some  file system types allow mounting in such a way that file accesses
;       do not cause an  update  of  the  st_atime  field.  (See  `noatime'  in
;       mount.)
;
;       The  field  st_atime  is  changed  by file accesses, e.g. by execve,
;       mknod, pipe, utime and read  (of  more  than  zero  bytes).
;       Other routines, like mmap, may or may not update st_atime.
;
;       The  field st_mtime is changed by file modifications, e.g. by mknod,
;       truncate, utime and write (of more than  zero  bytes).   More-
;       over, st_mtime of a directory is changed by the creation or deletion of
;       files in that directory.  The st_mtime field is not changed for changes
;       in owner, group, hard link count, or mode.
;
;       The  field  st_ctime is changed by writing or by setting inode informa-
;       tion (i.e., owner, group, link count, mode, etc.).
;
;       The following POSIX macros are defined to check the file type:
;
;              S_ISREG(m)  is it a regular file?
;
;              S_ISDIR(m)  directory?
;
;              S_ISCHR(m)  character device?
;
;              S_ISBLK(m)  block device?
;
;              S_ISFIFO(m) fifo?
;
;              S_ISLNK(m)  symbolic link? (Not in POSIX.1-1996.)
;
;              S_ISSOCK(m) socket? (Not in POSIX.1-1996.)
;
;       The set GID bit (S_ISGID) has several special uses: For a directory  it
;       indicates  that  BSD  semantics is to be used for that directory: files
;       created there inherit their group ID from the directory, not  from  the
;       effective  gid  of  the creating process, and directories created there
;       will also get the S_ISGID bit set.  For a file that does not  have  the
;       group  execution  bit (S_IXGRP) set, it indicates mandatory file/record
;       locking.
;
;       The `sticky' bit (S_ISVTX) on a directory means that  a  file  in  that
;       directory  can  be renamed or deleted only by the owner of the file, by
;       the owner of the directory, and by root.
;
;RETURN VALUE
;       On success, zero is returned.  On error a negative code is returned
;
;ERRORS
;       EBADF  filedes is bad.
;
;       ENOENT A component of the path file_name does not exist, or the path is
;              an empty string.
;
;       ENOTDIR
;              A component of the path is not a directory.
;
;       ELOOP  Too many symbolic links encountered while traversing the path.
;
;       EFAULT Bad address.
;
;       EACCES Permission denied.
;
;       ENOMEM Out of memory (i.e. kernel memory).
;
;       ENAMETOOLONG
;              File name too long.
;
;
;SEE ALSO
;       chmod, chown, readlink, utime lstat fstat
;
;