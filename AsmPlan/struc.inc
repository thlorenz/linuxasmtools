
; (#0#) structures and equates **************************

O_WRONLY_CREAT_TRUNC equ 1101q

O_RDONLY equ 0
PERMS equ 644q
stdin equ 0
stdout equ 1


[section .text]
[absolute 0]
termios_struc:
.c_iflag: resd 1
.c_oflag: resd 1
.c_cflag: resd 1
.c_lflag: resd 1
.c_line: resb 1
.c_cc: resb 19
termios_struc_size:


[section .text]
[absolute 0]
winsize_struc:
.ws_row:resw 1
.ws_col:resw 1
.ws_xpixel:resw 1
.ws_ypixel:resw 1
winsize_struc_size:

default_text_field_len	equ	70
[section .text]
[absolute 0]
todo_fields:
flag_field:	resb	1
sched_field:	resb	2
year_field:	resb	4
month_field:	resb	2
day_field:	resb	2
text_field:	resb	default_text_field_len


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

