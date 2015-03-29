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
