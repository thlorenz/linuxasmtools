;----------- file: decode_descript.inc -------------------------------

;The following is a desciption of what happens when a
;kernel function is traced.
;
;When a kernel function is found the table in
;decode_ptr.inc is used to find entries in this file.
;Each entry here (decode_descript.inc) describes how to
;log a kernel function.  The fields are:
;  1. asciiz name of kernel function.
;  2. ptr to code handling this function.
;     Usually this is a generic program (p_generic).
;  3. Remaining fields are defined by the handling
;     function.
;
;The p_generic handler for kernel functions, uses a
;list of byte codes to process a function.  These
;control codes are:
;
;control codes 
zero	equ	0	;end of string
_bx	equ	1	;start of ebx def
_cx	equ	2	;start of ecx def
_dx	equ	3	;start of edx def
_si	equ	4	;start of edi def
_di	equ	5	;start of esi def
_bp	equ	6	;start of ebp def
_txt	equ	7	;the following asciiz string is inserted in output
_buf1	equ	8	;last reg is ptr, reg edx has length (dumps hex bytes)
_struc_byte  equ	9	;last reg is ptr,  db 'asciiz text'... ends with 0
_struc_word  equ	10	;last reg is ptr,  db 'asciiz text'... ends with 0
_struc_dword  equ	11	;last reg is ptr,  db 'asciiz text'... ends with 0
_eol	equ	12	;insert eol
_buf2	equ	13	;asciiz text, last reg displayed is ptr to asciiz
_scan	equ	14	;scan [last_reg] ptr forward till non-zero
_ptr	equ	15	;last reg ptr is [ptr] -> new last reg ptr

_end	equ	-1	;end of definition

;---------------------------------------------------------
access:
 db 'access',0
 dd p_generic		;process
 db _end		;no parameters or returns

exit:                  	; terminate the current process
 db 'exit',0           	; kernel function name
 dd p_generic		; handler for register report
 db _bx,_txt,'return_code',0,_eol ;EBX=xxxxxxxxh return_code
 db _end		;end of entry

fork:                  	; create a child process 
 db 'fork',0           	; create a child process 
 dd p_generic		;process
 db _end

read:                  ; read from a file descriptor
 db 'read',0                  ; read from a file descriptor
 dd p_generic		;process
 db _bx,_txt,'  fd',0,_eol
 db _cx,_txt,'  buffer',0,_buf1,_eol
 db _dx,_txt,'  length',0,_eol
 db _end

write:                 ; write to a file descriptor
 db 'write',0                 ; write to a file descriptor
 dd p_generic		;process
 db _bx,_txt,'  fd',0,_eol
 db _cx,_txt,'  buffer',0
   db _buf1,_eol
 db _dx,_txt,'  length',0,_eol
 db _end

open:                  ; open and possibly create a file or device
 db 'open',0                  ; open and possibly create a file or device
 dd p_generic		;process
 db _bx,_txt,'  filename',0,_buf2,_eol
 db _cx,_txt,'  flags',0,_eol
 db _dx,_txt,'  permissions (0=defaults)',0,_eol
 db _txt,' (open returns file-descriptor or error)',0,_eol
 db _end

close:                 ; close a file descriptor
 db 'close',0                 ; close a file descriptor
 dd p_generic		;process
 db _bx,_txt,'file descriptor',0,_eol
 db _end

waitpid:               ; wait for process termination  
 db 'waitpid',0               ; wait for process termination  
 dd p_generic		;process
 db _bx,_txt,'pid',0,_eol ;EBX=xxxxxxxxh pid
 db _cx,_txt,'status_ptr -> ',0
   db _struc_byte, _txt,'stat ',0
   db _struc_byte, _txt,'signal',0
   db _eol
 db _dx,_txt,'options',0,_eol
 db _end

creat:                 ; create a file
 db 'creat',0                 ; create a file
 dd p_generic		;process
 db _bx,_txt,'  filename',0,_buf2,_eol
 db _cx,_txt,'  permissions (0=defaults)',0,_eol
 db _end

link:                  ; make a new name for a file
 db 'link',0                  ; make a new name for a file
 dd p_generic		;process
 db _bx,_txt,'  existing file',0,_buf2,_eol
 db _cx,_txt,'  link name    ',0,_buf2,_eol
 db _end

unlink:                ; delete a name and possibly the file it refers to
 db 'unlink',0                ; delete a name and possibly the file it refers to
 dd p_generic		;process
 db _bx,_txt,'  filename',0,_buf2,_eol
 db _end

execve:                ; execute program
 db 'execve',0                ; execute program
 dd p_generic		;process
 db _bx,_txt,'  pointer to path',0,_buf2,_eol
 db _cx,_txt,'  pointer to path list',0,_eol
 db _dx,_txt,'  pointer to enviornment',0,_eol
 db _end

chdir:                 ; change working directory
 db 'chdir',0                 ; change working directory
 dd p_generic		;process
 db _bx,_txt,' pointer to new dir ',0,_buf2,_eol
 db _end

time:                  ; get time in seconds
 db 'time',0                  ; get time in seconds
 dd p_generic		;process
 db _txt,' (seconds returned in eax)',0,_eol
 db _bx,_txt,' ptr to time storage or zero',0,_eol
 db _end

mknod:                 ; create a special or ordinary file
 db 'mknod',0                 ; create a special or ordinary file
 dd p_generic		;process
 db _bx,_txt,'  filename',0,_buf2,_eol
 db _cx,_txt,'  permissions',0,_eol
 db _dx,_txt,'  device if ecx has S_IFCHR or S_IFBLK bit set',0,_eol
 db _end

chmod:                 ; change permissions of a file
 db 'chmod',0                 ; change permissions of a file
 dd p_generic		;process
 db _bx,_txt,'  filename',0,_buf2,_eol
 db _cx,_txt,'  permissions',0,_eol
 db _end

lchown:                ; change ownership of a file
 db 'lchown',0                ; change ownership of a file
 dd p_generic		;process
 db _bx,_txt,'  filename',0,_buf2,_eol
 db _cx,_txt,'  new owner id, or -1 to ignore',0,_eol
 db _dx,_txt,'  new group id, or -1 to ignore',0,_eol
 db _end

break:                 ; UNIMPLEMENTED
 db 'break',0                 ; UNIMPLEMENTED
 dd p_generic		;process
 db _end

oldstat:               ; obsolete
 db 'oldstat',0               ; obsolete
 dd p_generic		;process
 db _end

lseek:                 ; reposition read/write file offset
 db 'lseek',0                 ; reposition read/write file offset
 dd p_generic		;process
 db _bx,_txt,'  filename',0,_buf2,_eol
 db _cx,_txt,'  seek offset',0,_eol
 db _dx,_txt,'  0=seek rel start, 1=relative current 2=rel end',0,_eol
 db _txt,' (lseek returns new file position or error)',0,_eol
 db _end

getpid:                ; process identification
 db 'getpid',0                ; process identification
 dd p_generic		;process
 db _end

mount:                 ; mount and unmount filesystems
 db 'mount',0                 ; mount and unmount filesystems
 dd p_generic		;process
 db _bx,_txt,'  device',0,_buf2,_eol
 db _cx,_txt,'  mount point',0,_buf2,_eol
 db _dx,_txt,'  mount type',0,_eol
 db _si,_txt,'  mount flags',0,_eol
 db _di,_txt,'  mount data ptr ->',0,_struc_dword,0,_eol
 db _end

umount:                ; mount and unmount filesystems
 db 'umount',0                ; mount and unmount filesystems
 dd p_generic		;process
 db _bx,_txt,'  mount point',0,_buf2,_eol
 db _cx,_txt,'  umount flags',0,_eol
 db _end

setuid:                ; set user identity
 db 'setuid',0                ; set user identity
 dd p_generic		;process
 db _bx,_txt,'  user id (UID)',0,_eol
 db _end

getuid:                ; get user identity 
 db 'getuid',0                ; get user identity 
 dd p_generic		;process
 db _txt,' (user id returned in eax)',0,_eol
 db _end

stime:                 ; set time
 db 'stime',0                 ; set time
 dd p_generic		;process
 db _bx,_txt,'  new time ptr ->',0,_struc_dword,0,_eol
 db _end

ptrace:                ; process trace
 db 'ptrace',0                ; process trace
 dd p_generic		;process
 db _bx,_txt,' action',0,_eol
 db _cx,_txt,' target process id',0,_eol
 db _dx,_txt,' address (eip) of target',0,_eol
 db _si,_txt,' data ptr ->',0,_struc_dword,0,_eol
 db _end

alarm:                 ; set an alarm clock for delivery of a signal
 db 'alarm',0                 ; set an alarm clock for delivery of a signal
 dd p_generic		;process
 db _bx,_txt,' time in seconds',0,_eol
 db _end

oldfstat:              ; obsolete DO NOT USE
 db 'oldfstat',0              ; obsolete DO NOT USE
 dd p_generic		;process
 db _end

pause_:                 ; wait for signal
 db 'pause',0                 ; wait for signal
 dd p_generic		;process
 db _end

utime:                 ; change access and/or modification times  30
 db 'utime',0                 ; change access and/or modification times
 dd p_generic		;process
 db _bx,_txt,'filename',0,_buf2,_eol
 db _cx,_txt,'time_ptr -> ',0
   db _struc_dword, _txt,'seconds ',0
   db _struc_dword, _txt,'usec',0
   db _struc_dword, _txt,'seconds ',0
   db _struc_dword, _txt,'usec',0
   db _eol
 db _end

stty:                  ; UNIMPLEMENTED     31
 db 'stty',0                  ; UNIMPLEMENTED
 dd p_generic		;process
 db _end

gtty:                  ; UNIMPLEMENTED     32
 db 'gtty',0                  ; UNIMPLEMENTED
 dd p_generic		;process
 db _end

access_:                ; check user's permissions for a file 33
 db 'access',0                ; check user's permissions for a file
 dd p_generic		;process
 db _bx,_txt,'filename',0,_buf2,_eol
 db _cx,_txt,'access mode',0,_eol
 db _end

nice:                  ; change process priority
 db 'nice',0                  ; change process priority
 dd p_generic		;process
 db _bx,_txt,' priority downstep increment',0,_eol
 db _end

ftime:                 ; UNIMPLEMENTED return date and time
 db 'ftime',0                 ; UNIMPLEMENTED return date and time
 dd p_generic		;process
 db _end

sync:                  ; commit buffer cache to disk
 db 'sync',0                  ; commit buffer cache to disk
 dd p_generic		;process
 db _end

kill:                  ; send signal to a process
 db 'kill',0                  ; send signal to a process
 dd p_generic		;process
 db _bx,_txt,' code (pid,-group,0=all in grp,-1=all but first in grp)',0,_eol
 db _cx,_txt,' signal number',0,_eol
 db _end

rename:                ; change the name or location of a file
 db 'rename',0                ; change the name or location of a file
 dd p_generic		;process
 db _bx,_txt,'old path',0,_buf2,_eol
 db _cx,_txt,'new path',0,_buf2,_eol
 db _end

mkdir:                 ; create a directory
 db 'mkdir',0                 ; create a directory
 dd p_generic		;process
 db _bx,_txt,'create dir',0,_buf2,_eol
 db _end

rmdir:                 ; delete a directory
 db 'rmdir',0                 ; delete a directory
 dd p_generic		;process
 db _bx,_txt,'remove dir',0,_buf2,_eol
 db _end

dup:                   ; duplicate a file descriptor
 db 'dup',0                   ; duplicate a file descriptor
 dd p_generic		;process
 db _bx,_txt,' fd to dup',0,_eol
 db _end

pipe:                  ; create pipe
 db 'pipe',0                  ; create pipe
 dd p_generic		;process
 db _bx,_txt,' ptr -> ',0
   db _struc_dword, _txt,'=from fd ',0
   db _struc_dword, _txt,'=to fd',0
   db _eol
 db _end

times_:                 ; get process times
 db 'times',0                 ; get process times
 dd p_generic		;process
 db _txt,' time since boot in eax ',0,_eol
 db _end

prof:                  ; UNIMPLEMENTED
 db 'prof',0                  ; UNIMPLEMENTED
 dd p_generic		;process
 db _end

brk:                   ; change data segment size
 db 'brk',0                   ; change data segment size
 dd p_generic		;process
 db _bx,_txt,'new address, or if zero address returned',0,_eol
 db _end

setgid:                ; set group identity
 db 'setgid',0                ; set group identity
 dd p_generic		;process
 db _bx,_txt,' group id (GID)',0,_eol
 db _end

getgid:                ; get group identity
 db 'getgid',0                ; get group identity
 dd p_generic		;process
 db _txt,' group id (GID) returned in eax',0,_eol
 db _end

signal:                ; ANSI C signal handling
 db 'signal',0                ; ANSI C signal handling
 dd p_generic		;process
 db _bx,_txt,' signal number',0,_eol
 db _cx,_txt,' signal handler',0,_eol
 db _end

geteuid:               ; get user identity
 db 'geteuid',0               ; get user identity
 dd p_generic		;process
 db _end

getegid:               ; get group identity
 db 'getegid',0               ; get group identity
 dd p_generic		;process
 db _end

acct:                  ; switch process accounting on or off
 db 'acct',0                  ; switch process accounting on or off
 dd p_generic		;process
 db _bx,_txt,' process account log file ptr, or zero)',0,_buf2,_eol
 db _end

umount2:               ; mount and unmount filesystems
 db 'umount2',0               ; mount and unmount filesystems
 dd p_generic		;process
 db _bx,_txt,'  mount point',0,_buf2,_eol
 db _cx,_txt,'  umount2 flag 0=normal 1=force',0,_eol
 db _end

lock_:                  ; UNIMPLEMENTED
 db 'lock',0                  ; UNIMPLEMENTED
 dd p_generic		;process
 db _end

ioctl:                 ; control device
 db 'ioctl',0                 ; control device
 dd p_generic		;process
 db _bx,_txt,'  file descriptor',0,_eol
 db _cx,_txt,'  command',0,_eol
 db _dx,_txt,'  ptr ->',0,_eol
 db _end

fcntl:                 ; manipulate file descriptor
 db 'fcntl',0                 ; manipulate file descriptor
 dd p_fcntl		;process
; db _bx,_txt,'  file descriptor',0,_eol
; db _cx,_txt,'  command',0,_eol
; db _dx,_txt,'  ptr ->',0,_eol
 db _end

mpx:                   ; UNIMPLEMENTED
 db 'mpx',0                   ; UNIMPLEMENTED
 dd p_generic		;process
 db _end

setpgid:               ; set process group 
 db 'setpgid',0               ; set process group 
 dd p_generic		;process
 db _bx,_txt,'  process group id',0,_eol
 db _end

ulimit:                ; UNIMPLEMENTED
 db 'ulimit',0                ; UNIMPLEMENTED
 dd p_generic		;process
 db _end

oldolduname:           ; obsolete
 db 'oldolduname',0           ; obsolete
 dd p_generic		;process
 db _end

umask:                 ; set file creation mask
 db 'umask',0                 ; set file creation mask
 dd p_generic		;process
 db _bx,_txt,'  permission mask',0,_eol
 db _txt,'  (retruns previous mask)',0,_eol
 db _end

chroot:                ; change root directory
 db 'chroot',0                ; change root directory
 dd p_generic		;process
 db _bx,_txt,'  root path',0,_buf2,_eol
 db _end

ustat:                 ; get file system statistics 
 db 'ustat',0                 ; get file system statistics 
 dd p_generic		;process
 db _end

dup2:                  ; duplicate a file descriptor
 db 'dup2',0                  ; duplicate a file descriptor
 dd p_generic		;process
 db _bx,_txt,'  old fd',0,_eol
 db _cx,_txt,'  new fd',0,_eol
 db _txt,' (returns new fd if successful)',0,_eol
 db _end

getppid:               ; get process identification
 db 'getppid',0               ; get process identification
 dd p_generic		;process
 db _txt,' (returns process id (PID) of parent',0,_eol
 db _end

getpgrp:               ; set/get process group
 db 'getpgrp',0               ; set/get process group
 dd p_generic		;process
 db _txt,' (returns process group (GID) of parent',0,_eol
 db _end

setsid:                ; creates a session and sets the process group ID
 db 'setsid',0                ; creates a session and sets the process group ID
 dd p_generic		;process
 db _txt,' (returns new process group id',0,_eol
 db _end

sigaction:             ; POSIX signal handling
 db 'sigaction',0             ; POSIX signal handling
 dd p_generic		;process
 db _bx,_txt,' Signal#',0,_eol
 db _cx,_txt,' new action ptr -> ',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,'=handler',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,'=mask',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,'=flag',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,'=(unused)',0,_eol
 db _dx,_txt,' old action ptr -> ',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,'=handler',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,'=mask',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,'=flag',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,'=(unused)',0,_eol
 db _end

sgetmask:              ; retrieves the signal mask of the set of currently blocked signals
 db 'sgetmask',0              ; retrieves the signal mask of the set of currently blocked signals
 dd p_generic		;process
 db _end

ssetmask:              ; sets the signal mask of the set of currently blocked signals
 db 'ssetmask',0              ; sets the signal mask of the set of currently blocked signals
 dd p_generic		;process
 db _end

setreuid:              ; set real and/or effective user ID
 db 'setreuid',0              ; set real and/or effective user ID
 dd p_generic		;process
 db _bx,_txt,'  ruid or -1 to ignore',0,_eol
 db _cx,_txt,'  euid or -1 to ignore',0,_eol
 db _end

setregid:              ; set real and / or effective group ID
 db 'setregid',0              ; set real and / or effective group ID
 dd p_generic		;process
 db _bx,_txt,'  rgid or -1 to ignore',0,_eol
 db _cx,_txt,'  egid or -1 to ignore',0,_eol
 db _end

sigsuspend:            ; POSIX signal handling functionsx
 db 'sigsuspend',0            ; POSIX signal handling functionsx
 dd p_generic		;process
 db _bx,_txt,' temp mask',0,_eol
 db _end

sigpending:            ; POSIX signal handling functions
 db 'sigpending',0            ; POSIX signal handling functions
 dd p_generic		;process
 db _bx,_txt,' ptr to buffer (pending signals)',0,_struc_dword,_txt,' ',0,_struc_dword,_eol
 db _end

sethostname:           ; set host name 
 db 'sethostname',0           ; set host name 
 dd p_generic		;process
 db _bx,_txt,' hostname ',0,_buf2,_eol
 db _end

setrlimit:             ; set resource limits and usage
 db 'setrlimit',0             ; set resource limits and usage
 dd p_generic		;process
 db _bx,_txt,' item to set',0,_eol
 db _cx,_txt,' ptr to values ',0,_struc_dword,_txt,'=soft',0,_struc_dword,_txt,'hard',0,_eol
 db _end

getrlimit:             ; get resource limits and usage
 db 'getrlimit',0             ; get resource limits and usage
 dd p_generic		;process
 db _bx,_txt,' item to get',0,_eol
 db _cx,_txt,' ptr to values ',0,_struc_dword,_txt,'=soft',0,_struc_dword,_txt,'hard',0,_eol
 db _end

getrusage:             ; get resource limits and usage
 db 'getrusage',0             ; get resource limits and usage
 dd p_generic		;process
 db _bx,_txt,' selection#',0,_eol
 db _cx,_txt,' rusage buffer ptr -> ',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' ut_sec',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' ut_usec',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' st_sec',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' st_usec',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' ru_maxrss',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' ru_ixrss',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' ru_idrss',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' ru_minflt',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' ru_majflt',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' ru_nswap',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' ru_inblock',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' ru_oublock',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' ru_msgsnd',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' ru_msgrcv',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' ru_nsignals',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' ru_nvcsw',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' ru_nivcsw',0,_eol
   db _eol
 db _end

gettimeofday:          ; get time
 db 'gettimeofday',0          ; get time
 dd p_generic		;process
 db _bx,_txt,' time ptr -> ',0,_struc_dword,_txt,'=sec ',0,_struc_dword,_txt,'=usec',0,_eol
 db _cx,_txt,' (unused) zone ptr -> ',0,_struc_dword,_txt,'=min ',0,_struc_dword,_txt,'=dst',0,_eol
 db _end

settimeofday:          ; set time
 db 'settimeofday',0          ; set time
 dd p_generic		;process
 db _bx,_txt,' time ptr -> ',0,_struc_dword,_txt,'=sec ',0,_struc_dword,_txt,'=usec',0,_eol
 db _cx,_txt,' (unused) zone ptr -> ',0,_struc_dword,_txt,'=min ',0,_struc_dword,_txt,'=dst',0,_eol
 db _end

getgroups:             ; get list of supplementary group IDs
 db 'getgroups',0             ; get list of supplementary group IDs
 dd p_generic		;process
 db _bx,_txt,' size of buffer',0,_eol
 db _cx,_txt,' ptr to -> ',0,_struc_word,_txt,' ',0,_struc_word,_txt,' ',0,_struc_word,_txt,' ',0,_struc_word,_txt,' ...',0,_eol
 db _txt,'  (returns group count)',0,_eol
 db _end

setgroups:             ; set list of supplementary group IDs
 db 'setgroups',0             ; set list of supplementary group IDs
 dd p_generic		;process
 db _bx,_txt,' size of groups',0,_eol
 db _cx,_txt,' ptr to -> ',0,_struc_word,_txt,' ',0,_struc_word,_txt,' ',0,_struc_word,_txt,' ',0,_struc_word,_txt,' ...',0,_eol
 db _end

select:                ; synchronous I/O
 db 'oldselect',0                ; synchronous I/O
 dd p_generic		;process
 db _bx,_txt,' select struc ptr ->',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' fd+1',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' ptr to read fd',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' ptr to write fd',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' ptr to except fd',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' ptr to wait time',0,_eol
 db _end

symlink:               ; make a new name for a file
 db 'symlink',0               ; make a new name for a file
 dd p_generic		;process
 db _bx,_txt,'  old path',0,_buf2,_eol
 db _cx,_txt,'  new path',0,_buf2,_eol
 db _end

oldlstat:              ; obsolete
 db 'oldlstat',0              ; obsolete
 dd p_generic		;process
 db _end

readlink:              ; read value of a symbolic link
 db 'readlink',0              ; read value of a symbolic link
 dd p_generic		;process
 db _bx,_txt,'  filename',0,_buf2,_eol
 db _cx,_txt,'  buffer',0,_buf2,_eol
 db _dx,_txt,'  buf length',0,_eol
 db _end

uselib:                ; select shared library
 db 'uselib',0                ; select shared library
 dd p_generic		;process
 db _bx,_txt,'  library',0,_buf2,_eol
 db _end

swapon:                ; start/stop swapping to file/device
 db 'swapon',0                ; start/stop swapping to file/device
 dd p_generic		;process
 db _bx,_txt,'  swap path',0,_buf2,_eol
 db _cx,_txt,'  flags',0,_eol
 db _end

reboot:                ; reboot or enable/disable Ctrl-Alt-Del
 db 'reboot',0                ; reboot or enable/disable Ctrl-Alt-Del
 dd p_generic		;process
 db _bx,_txt,'  magic1',0,_eol
 db _cx,_txt,'  magic2',0,_eol
 db _dx,_txt,'  flags',0,_eol
 db _si,_txt,'  args',0,_buf2,_eol
 db _end

readdir:               ; read directory entry
 db 'readdir',0               ; read directory entry
 dd p_generic		;process
 db _bx,_txt,'  fd',0,_eol
 db _cx,_txt,'  ptr to one dent',0,_eol
 db _end

mmap:                  ; map or unmap files or devices into memory
 db 'mmap',0                  ; map or unmap files or devices into memory
 dd p_generic		;process
 db _bx,_txt,'  mmap struc ptr ->',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' mem adr',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' length',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' prot flag',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' flags',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' fd',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' offset',0,_eol
 db _txt,' (returns memory address)',0,_eol
 db _end

munmap:                ; unmap files or devices into memory
 db 'munmap',0                ; unmap files or devices into memory
 dd p_generic		;process
 db _bx,_txt,' start adr',0,_eol
 db _cx,_txt,' length',0,_eol
 db _end

truncate:              ; truncate file to specified length 
 db 'truncate',0              ; truncate file to specified length 
 dd p_generic		;process
 db _bx,_txt,' filename ptr->',0,_buf2,_eol
 db _cx,_txt,' new length',0,_eol
 db _end

ftruncate:             ; truncate file to specified length 
 db 'ftruncate',0             ; truncate file to specified length 
 dd p_generic		;process
 db _bx,_txt,' fd',0,_eol
 db _cx,_txt,' new length',0,_eol
 db _end

fchmod:                ; change permissions of a file
 db 'fchmod',0                ; change permissions of a file
 dd p_generic		;process
 db _bx,_txt,' fd',0,_eol
 db _cx,_txt,' new permissions',0,_eol
 db _end

fchown:                ; change ownership of a file 
 db 'fchown',0                ; change ownership of a file 
 dd p_generic		;process
 db _bx,_txt,' fd',0,_eol
 db _cx,_txt,' new owner',0,_eol
 db _dx,_txt,' new group',0,_eol
 db _end

getpriority:           ; get program scheduling priority
 db 'getpriority',0           ; get program scheduling priority
 dd p_generic		;process
 db _bx,_txt,' who, 0=process 1=group 2=user',0,_eol
 db _cx,_txt,' which, id',0,_eol
 db _txt,' (returns priority)',0,_eol
 db _end

setpriority:           ; set program scheduling priority
 db 'setpriority',0           ; set program scheduling priority
 dd p_generic		;process
 db _bx,_txt,' who, 0=process 1=group 2=user',0,_eol
 db _cx,_txt,' which, id',0,_eol
 db _dx,_txt,' new priority',0,_eol
 db _end

profil:                ; UNIMPLEMENTED execution time profile
 db 'profil',0                ; UNIMPLEMENTED execution time profile
 dd p_generic		;process
 db _end

statfs:                ; get file system statistics
 db 'statfs',0                ; get file system statistics
 dd p_generic		;process
 db _bx,_txt,' path',0,_buf2,_eol
 db _cx,_txt,' buffer->',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' f_type',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' f_bsize',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' f_blocks',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' f_bfree',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' f_bavauk',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' f_files',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' f_ffree',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' f_fsid',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' f_namelen',0,_eol
 db _end

fstatfs:               ; get file system statistics
 db 'fstatfs',0               ; get file system statistics
 dd p_generic		;process
 db _bx,_txt,' fd',0,_eol
 db _cx,_txt,' buffer->',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' f_type',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' f_bsize',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' f_blocks',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' f_bfree',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' f_bavauk',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' f_files',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' f_ffree',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' f_fsid',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' f_namelen',0,_eol
 db _end

ioperm:                ; set port input/output permissions
 db 'ioperm',0                ; set port input/output permissions
 dd p_generic		;process
 db _bx,_txt,' port',0,_eol
 db _cx,_txt,' length',0,_eol
 db _dx,_txt,' flag 0=off 1=on',0,_eol
 db _end

socketcall:            ; socket system calls
 db 'socketcall',0            ; socket system calls
 dd p_socket		;process
 db _end

syslog:                ; read and/or clear kernel message ring buffer
 db 'syslog',0                ; read and/or clear kernel message ring buffer
 dd p_generic		;process
 db _bx,_txt,' operation type',0,_eol
 db _cx,_txt,' buffer',0,_buf2,_eol
 db _dx,_txt,' buffer length',0,_eol
 db _end

setitimer:             ; set an interval timer
 db 'setitimer',0             ; set an interval timer
 dd p_generic		;process
 db _bx,_txt,' which timer',0,_eol
 db _cx,_txt,' ivalue ptr -> ',0,_struc_dword,_txt,' ',0,_struc_dword,_txt,' ',0,_struc_dword,_txt,' ',0,_struc_dword,_eol
 db _dx,_txt,' ovalue ptr -> ',0,_struc_dword,_txt,' ',0,_struc_dword,_txt,' ',0,_struc_dword,_txt,' ',0,_struc_dword,_eol
 db _end

getitimer:             ; get  value of an interval timer
 db 'getitimer',0             ; get  value of an interval timer
 dd p_generic		;process
 db _bx,_txt,' which timer',0,_eol
 db _cx,_txt,' ivalue ptr -> ',0,_struc_dword,_txt,' ',0,_struc_dword,_txt,' ',0,_struc_dword,_txt,' ',0,_struc_dword,_eol
 db _end

stat:                  ; get file status
 db 'stat',0                  ; get file status
 dd p_generic		;process
 db _bx,_txt,'  filename',0,_buf2,_eol
 db _cx,_txt,'  ptr to stat_struc ->',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' st_dev:',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' st_ino:',0,_eol
 db _txt,'  ',0,_struc_word,_txt,' st_mode:',0,_eol
 db _txt,'  ',0,_struc_word,_txt,' st_nlink:',0,_eol
 db _txt,'  ',0,_struc_word,_txt,' st_uid:',0,_eol
 db _txt,'  ',0,_struc_word,_txt,' st_gid:',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' st_rdev: device type (if inode device)',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' st_size: total size in bytes',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' st_blksize: blocksize for filesystem I/O',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' st_blocks: number of blocks allocated',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' st_atime: time of last access',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' __unused1',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' st_mtime: time of last modification',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' __unused2',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' st_ctime: time of last change',0,_eol
 db _end

lstat:                 ; get file status
 db 'lstat',0                 ; get file status
 dd p_generic		;process
 db _bx,_txt,'  filename',0,_buf2,_eol
 db _cx,_txt,'  ptr to stat_struc ->',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' st_dev:',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' st_ino:',0,_eol
 db _txt,'  ',0,_struc_word,_txt,' st_mode:',0,_eol
 db _txt,'  ',0,_struc_word,_txt,' st_nlink:',0,_eol
 db _txt,'  ',0,_struc_word,_txt,' st_uid:',0,_eol
 db _txt,'  ',0,_struc_word,_txt,' st_gid:',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' st_rdev: device type (if inode device)',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' st_size: total size in bytes',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' st_blksize: blocksize for filesystem I/O',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' st_blocks: number of blocks allocated',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' st_atime: time of last access',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' __unused1',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' st_mtime: time of last modification',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' __unused2',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' st_ctime: time of last change',0,_eol
 db _end

fstat:                 ; get file status
 db 'fstat',0                 ; get file status
 dd p_generic		;process
 db _bx,_txt,'  fd',0,_eol
 db _cx,_txt,'  ptr to stat_struc ->',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' st_dev:',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' st_ino:',0,_eol
 db _txt,'  ',0,_struc_word,_txt,' st_mode:',0,_eol
 db _txt,'  ',0,_struc_word,_txt,' st_nlink:',0,_eol
 db _txt,'  ',0,_struc_word,_txt,' st_uid:',0,_eol
 db _txt,'  ',0,_struc_word,_txt,' st_gid:',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' st_rdev: device type (if inode device)',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' st_size: total size in bytes',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' st_blksize: blocksize for filesystem I/O',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' st_blocks: number of blocks allocated',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' st_atime: time of last access',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' __unused1',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' st_mtime: time of last modification',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' __unused2',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' st_ctime: time of last change',0,_eol
 db _end

olduname:              ; obsolete
 db 'olduname',0              ; obsolete
 dd p_generic		;process
 db _end

iopl:                  ; change I/O privilege level
 db 'iopl',0                  ; change I/O privilege level
 dd p_generic		;process
 db _bx,_txt,' privilege level',0,_eol
 db _end

vhangup:               ; virtually hangup the current tty
 db 'vhangup',0               ; virtually hangup the current tty
 dd p_generic		;process
 db _end

idle:                  ; make process 0 idle
 db 'idle',0                  ; make process 0 idle
 dd p_generic		;process
 db _end

vm86old:               ; enter virtual 806 mode
 db 'vm86old',0               ; enter virtual 8086 mode
 dd p_generic		;process
 db _end

wait4:                 ; wait for process termination, BSD style
 db 'wait4',0                 ; wait for process termination, BSD style
 dd p_generic		;process
 db _bx,_txt,' pid',0,_eol
 db _cx,_txt,' ptr to status -> ',0,_struc_word,_eol
 db _dx,_txt,' options',0,_eol
 db _si,_txt,' ptr to rusage',0,_eol
 db _end

swapoff:               ; stop swapping to file/device
 db 'swapoff',0               ; stop swapping to file/device
 dd p_generic		;process
 db _bx,_txt,'  path',0,_buf2,_eol
 db _end

sysinfo:               ; returns information on overall system statistics
 db 'sysinfo',0               ; returns information on overall system statistics
 dd p_generic		;process
 db _bx,_txt,'  ptr to sysinfo_struc ->',0,_eol
 db _txt,' ',0,_struc_dword,_txt,' uptime seconds since boot',0,_eol
 db _txt,' ',0,_struc_dword,_txt,' 1 min load avg',0,_eol
 db _txt,' ',0,_struc_dword,_txt,' 5 min load avg',0,_eol
 db _txt,' ',0,_struc_dword,_txt,' 15 min load avg',0,_eol
 db _txt,' ',0,_struc_dword,_txt,' totalram',0,_eol
 db _txt,' ',0,_struc_dword,_txt,' freeram',0,_eol
 db _txt,' ',0,_struc_dword,_txt,' sharedram',0,_eol
 db _txt,' ',0,_struc_dword,_txt,' bufferram - Memory used by buffers',0,_eol
 db _txt,' ',0,_struc_dword,_txt,' totalswap',0,_eol
 db _txt,' ',0,_struc_dword,_txt,' freeswap - swap space still available',0,_eol
 db _txt,' ',0,_struc_word,_txt,' procs - Number of current processes',0,_eol
 db _txt,' ',0,_struc_word,_txt,' pad',0,_eol
 db _txt,' ',0,_struc_dword,_txt,' totalhigh - Total high memory size',0,_eol
 db _txt,' ',0,_struc_dword,_txt,' freehigh - Available high memory',0,_eol
 db _txt,' ',0,_struc_dword,_txt,' mem_unit - Memory unit size in bytes',0,_eol
 db _txt,' ',0,_struc_dword,_txt,' resb 8  Padding for libc5',0,_eol
 db _end

ipc:                   ; System V IPC system calls
 db 'ipc functions',0                   ; System V IPC system calls
 dd p_ipc		;process
 db _end

fsync:                 ; synchronize  a file's complete in-core state with
 db 'fsync',0                 ; synchronize  a file's complete in-core state with
 dd p_generic		;process
 db _bx,_txt,'  fd (file descriptor)',0,_eol
 db _end

sigreturn:             ; return from signal handler and cleanup stack frame
 db 'sigreturn',0             ; return from signal handler and cleanup stack frame
 dd p_generic		;process
 db _end

clone:                 ; create a child process
 db 'clone',0                 ; create a child process
 dd p_generic		;process
 db _bx,_txt,' flags',0,_eol
 db _cx,_txt,' ptr to child stack',0,_eol
 db _dx,_txt,' ptr to registers',0,_eol
 db _si,_txt,' ptr to parent_tidptr',0,_eol
 db _di,_txt,' ptr to child_tidptr',0,_eol
 db _end

setdomainname:         ; get/set domain name
 db 'setdomainname',0         ; get/set domain name
 dd p_generic		;process
 db _bx,_txt,' domain name ptr ->',0,_buf2,_eol
 db _cx,_txt,' length of name',0,_eol
 db _end

uname:                 ; get name and information about current kernel
 db 'uname',0                 ; get name and information about current kernel
 dd p_generic		;process
 db _bx,_txt,' ptr to strings ',0,_eol
   db _txt,'  sys_name',0,_buf2,_eol
   db _scan
   db _txt,'  sys_rel',0,_buf2,_eol
   db _scan
   db _txt,'  sys_release',0,_buf2,_eol
   db _scan
   db _txt,'  sys_version',0,_buf2,_eol
   db _scan
   db _txt,'  sys_machine',0,_buf2,_eol
   db _scan
   db _txt,'  sys_domain',0,_buf2,_eol
 db _end

modify_ldt:            ; get or set ldt
 db 'modify_ldt',0            ; get or set ldt
 dd p_generic		;process
 db _bx,_txt,' function',0,_eol
 db _cx,_txt,' ptr',0,_eol
 db _dx,_txt,' count',0,_eol
 db _end

adjtimex:              ; tune kernel clock
 db 'adjtimex',0              ; tune kernel clock
 dd p_generic		;process
 db _bx,_txt,' ptr to struc',0,_eol
 db _end

mprotect:              ; control allowable accesses to a region of memory
 db 'mprotect',0              ; control allowable accesses to a region of memory
 dd p_generic		;process
 db _bx,_txt,' address',0,_eol
 db _cx,_txt,' length',0,_eol
 db _dx,_txt,' prot flags',0,_eol
 db _end

sigprocmask:           ; POSIX signal handling functions
 db 'sigprocmask',0           ; POSIX signal handling functions
 dd p_generic		;process
 db _bx,_txt,' how (0=block 1=unblock 2=set)',0,_eol
 db _cx,_txt,' set ptr ->',0,_struc_dword,_eol
 db _dx,_txt,' save ptr ->',0,_struc_dword,_eol
 db _end

create_module:         ; create a loadable module entry
 db 'create_module',0         ; create a loadable module entry
 dd p_generic		;process
 db _bx,_txt,' name ptr ->',0,_buf2,_eol
 db _cx,_txt,' size',0,_eol
 db _end

init_module:           ; initialize a loadable module entry
 db 'init_module',0           ; initialize a loadable module entry
 dd p_generic		;process
 db _bx,_txt,' name ptr ->',0,_buf2,_eol
 db _cx,_txt,' image ptr',0,_eol
 db _end

delete_module:         ; delete a loadable module entry 
 db 'delete_module',0         ; delete a loadable module entry 
 dd p_generic		;process
 db _bx,_txt,' name ptr ->',0,_buf2,_eol
 db _end

get_kernel_syms:       ; retrieve exported kernel and module symbols 
 db 'get_kernel_syms',0       ; retrieve exported kernel and module symbols 
 dd p_generic		;process
 db _bx,_txt,' ptr to buf or zero',0,_eol
 db _end

quotactl:              ; manipulate disk quotas
 db 'quotactl',0              ; manipulate disk quotas
 dd p_generic		;process
 db _end

getpgid:               ; set/get process group
 db 'getpgid',0               ; set/get process group
 dd p_generic		;process
 db _bx,_txt,' process group id or zero',0,_eol
 db _end

fchdir:                ; change working directory
 db 'fchdir',0                ; change working directory
 dd p_generic		;process
 db _bx,_txt,' fd',0,_eol
 db _end

bdflush:               ; start, flush, or tune buffer-dirty-flush daemon
 db 'bdflush',0               ; start, flush, or tune buffer-dirty-flush daemon
 dd p_generic		;process
 db _bx,_txt,' function',0,_eol
 db _end

sysfs:                 ; get file system type information
 db 'sysfs',0                 ; get file system type information
 dd p_generic		;process
 db _bx,_txt,' option',0,_eol
 db _cx,_txt,' arg1 ptr ->',0,_eol
 db _dx,_txt,' arg2 ptr ->',0,_eol
 db _end

personality:           ; set the process execution domain
 db 'personality',0           ; set the process execution domain
 dd p_generic		;process
 db _bx,_txt,' persona or -1 to get current persona',0,_eol
 db _end

afs_syscall:           ; UNIMPLEMENTED 
 db 'afs_syscall',0           ; UNIMPLEMENTED 
 dd p_generic		;process
 db _end

setfsuid:              ; set user identity used for file system checks
 db 'setfsuid',0              ; set user identity used for file system checks
 dd p_generic		;process
 db _bx,_txt,' fsuid',0,_eol
 db _end

setfsgid:              ; set group identity used for file system checks
 db 'setfsgid',0              ; set group identity used for file system checks
 dd p_generic		;process
 db _bx,_txt,' fsgid',0,_eol
 db _end

llseek:                ; reposition read/write file offset
 db 'llseek',0                ; reposition read/write file offset
 dd p_generic		;process
 db _bx,_txt,' fd',0,_eol
 db _cx,_txt,'  high adr',0,_eol
 db _dx,_txt,'  low adr',0,_eol
 db _si,_txt,' ptr to qword result->',0,_struc_dword,_txt,' ',0,_struc_dword,_eol
 db _di,_txt,' whence 0=rel origon',0,_eol
 db _end

getdents:              ; get directory entries
 db 'getdents',0              ; get directory entries
 dd p_generic		;process
 db _bx,_txt,' fd',0,_eol
 db _cx,_txt,' buffer ptr',0,_eol
 db _dx,_txt,' buffer size',0,_eol
 db _end

newselect:             ; sync I/O multiplexing
 db 'newselect',0             ; sync I/O multiplexing
 dd p_generic		;process
 db _bx,_txt,' event count +1',0,_eol
 db _cx,_txt,' input event ptr ->',0,_struc_dword,_txt,' ...',0,_eol
 db _dx,_txt,' output event ptr ->',0,_struc_dword,_txt," ...",0,_eol
 db _si,_txt,' exception event ptr ->',0,_struc_dword,_txt," ...",0,_eol
 db _di,_txt,' timeout ptr -> ',0,_struc_dword,_txt,"=sec",0,_struc_dword,_txt,"=usec",0,_eol
 db _end

flock:                 ; apply or remove an advisory lock on an open file
 db 'flock',0                 ; apply or remove an advisory lock on an open file
 dd p_generic		;process
 db _bx,_txt,' fd',0,_eol
 db _cx,_txt,' operation',0,_eol
 db _end

msync:                 ; synchronize a file with a memory map
 db 'msync',0                 ; synchronize a file with a memory map
 dd p_generic		;process
 db _bx,_txt,' start adr',0,_eol
 db _cx,_txt,' lenght',0,_eol
 db _dx,_txt,' flags',0,_eol
 db _end

readv:                 ; read data into multiple buffers
 db 'readv',0                 ; read data into multiple buffers
 dd p_generic		;process
 db _bx,_txt,' fd',0,_eol
 db _cx,_txt,' buffer array ptr ->',0,_eol
 db _dx,_txt,' number of buffers',0,_eol
 db _end

writev:                ; read or write a vector
 db 'writev',0                ; read or write a vector
 dd p_generic		;process
 db _bx,_txt,' fd',0,_eol
 db _cx,_txt,' buffer array ptr ->',0,_eol
 db _dx,_txt,' number of buffers',0,_eol
 db _end

getsid:                ; get session ID
 db 'getsid',0                ; get session ID
 dd p_generic		;process
 db _end

fdatasync:             ; synchronize a file's in-core data with that on disk
 db 'fdatasync',0             ; synchronize a file's in-core data with that on disk
 dd p_generic		;process
 db _bx,_txt,' fd',0,_eol
 db _end

sysctl:                ; read/write system parameters
 db 'sysctl',0                ; read/write system parameters
 dd p_generic		;process
 db _bx,_txt,' struc ptr ->',0,_eol
  db _txt,'  ',0,_struc_dword,_txt,'  name ptr',0,_eol
  db _txt,'  ',0,_struc_dword,_txt,'  name length',0,_eol
  db _txt,'  ',0,_struc_dword,_txt,'  oldvalue ptr',0,_eol
  db _txt,'  ',0,_struc_dword,_txt,'  oldvalue len ptr',0,_eol
  db _txt,'  ',0,_struc_dword,_txt,'  newvalue ptr',0,_eol
  db _txt,'  ',0,_struc_dword,_txt,'  newvalue len ptr',0,_eol
 db _end

mlock:                 ; disable paging for some parts of memory 
 db 'mlock',0                 ; disable paging for some parts of memory 
 dd p_generic		;process
 db _end

munlock:               ; reenable paging for some parts of memory
 db 'munlock',0               ; reenable paging for some parts of memory
 dd p_generic		;process
 db _end

mlockall:              ; disable paging for calling process
 db 'mlockall',0              ; disable paging for calling process
 dd p_generic		;process
 db _end

munlockall:            ; reenable paging for calling process
 db 'munlockall',0            ; reenable paging for calling process
 dd p_generic		;process
 db _end

sched_setparam:        ; set scheduling parameters
 db 'sched_setparam',0        ; set scheduling parameters
 dd p_generic		;process
 db _bx,_txt,' pid',0,_eol
 db _cx,_txt,' param ptr ->',0,_struc_dword,_eol
 db _end

sched_getparam:        ; get scheduling parameters
 db 'sched_getparam',0        ; get scheduling parameters
 dd p_generic		;process
 db _bx,_txt,' pid',0,_eol
 db _cx,_txt,' param ptr ->',0,_struc_dword,_eol
 db _end

sched_setscheduler:    ; set scheduling algo/param
 db 'sched_setscheduler',0    ; set scheduling algo/param
 dd p_generic		;process
 db _bx,_txt,' pid',0,_eol
 db _cx,_txt,' policy',0,_eol
 db _dx,_txt,' parameter ptr ->',0,_struc_dword,_txt,' ...',0,_eol
 db _end

sched_getscheduler:    ; get scheduling algo/param
 db 'sched_getscheduler',0    ; get scheduling algo/param
 dd p_generic		;process
 db _bx,_txt,' pid',0,_eol
 db _end

sched_yield:           ; yield the processor
 db 'sched_yield',0           ; yield the processor
 dd p_generic		;process
 db _end

sched_get_priority_max:; get maximum priority value
 db 'sched_get_priority_max',0; get maximum priority value
 dd p_generic		;process
 db _end

sched_get_priority_min:; get minimum priority value
 db 'sched_get_priority_min',0; get minimum priority value
 dd p_generic		;process
 db _end

sched_rr_get_interval: ; get the SCHED_RR interval for the named process
 db 'sched_rr_get_interval',0 ; get the SCHED_RR interval for the named process
 dd p_generic		;process
 db _bx,_txt,' pid',0,_eol
 db _cx,_txt,' timespec ptr -> ',0,_struc_dword,_txt,'(sec) ',0,_struc_dword,_txt,'(nanosec)',0,_eol
 db _end

nanosleep:             ; pause execution for a specified time
 db 'nanosleep',0             ; pause execution for a specified time
 dd p_generic		;process
 db _bx,_txt,'time_ptr -> ',0
   db _struc_dword
   db _txt,'(seconds) ',0
   db _struc_dword
   db _txt,'(nanoseconds)',0
   db _eol
 db _cx,_txt,'sig_int -> ',0
   db _struc_dword
   db _txt,'(seconds) ',0
   db _struc_dword
   db _txt,'(nanoseconds)',0,_eol
 db _end

mremap:                ; re-map a virtual memory address
 db 'mremap',0                ; re-map a virtual memory address
 dd p_generic		;process
 db _bx,_txt,' old adr',0,_eol
 db _cx,_txt,' old len',0,_eol
 db _dx,_txt,' new len',0,_eol
 db _si,_txt,' flags',0,_eol
 db _di,_txt,' new adr',0,_eol
 db _end

setresuid:             ; set real user ID
 db 'setresuid',0             ; set real user ID
 dd p_generic		;process
 db _bx,_txt,' real user id',0,_eol
 db _cx,_txt,' effective user id',0,_eol
 db _dx,_txt,' saved effective user id',0,_eol
 db _end

getresuid:             ; get real, effective and saved user or group ID
 db 'getresuid',0             ; get real, effective and saved user or group ID
 dd p_generic		;process
 db _bx,_txt,' real user id ptr -> ',0,_struc_dword,_eol
 db _cx,_txt,' effective user id ptr -> ',0,_struc_dword,_eol
 db _dx,_txt,' saved effective user id ptr ->',0,_struc_dword,_eol
 db _end

vm86:                  ; enter virtual 8086 mode
 db 'vm86',0                  ; enter virtual 8086 mode
 dd p_generic		;process
 db _bx,_txt,' function',0,_eol
 db _cx,_txt,' struc ptr',0,_eol
 db _end

query_module:          ; query the kernel for bits pertaining to modules
 db 'query_module',0          ; query the kernel for bits pertaining to modules
 dd p_generic		;process
 db _end

poll:                  ; wait for some event on a file descriptor
 db 'poll',0                  ; wait for some event on a file descriptor
 dd p_generic		;process
 db _bx,_txt,' ptr to array (fd,request,returned) -> ',0,_struc_dword,_txt,' ',0,_struc_word,_txt,' ',0,_struc_word,_txt,' ..',0,_eol
 db _cx,_txt,' number of elements in array',0,_eol
 db _dx,_txt,' timeout in ms',0,_eol
 db _end

nfsservctl:            ; syscall interface to kernel nfs daemon
 db 'nfsservctl',0            ; syscall interface to kernel nfs daemon
 dd p_generic		;process
 db _bx,_txt,' cmd',0,_eol
 db _cx,_txt,' args ptr',0,_eol
 db _dx,_txt,' return ptr',0,_eol
 db _end

setresgid:             ; set real/effective/saved set-group ID
 db 'setresgid',0             ; set real/effective/saved set-group ID
 dd p_generic		;process
 db _bx,_txt,' real group id',0,_eol
 db _cx,_txt,' effective group id',0,_eol
 db _dx,_txt,' saved effective group id',0,_eol
 db _end

getresgid:             ; get real/effective/saved set-group ID
 db 'getresgid',0             ; get real/effective/saved set-group ID
 dd p_generic		;process
 db _bx,_txt,' real group id ptr -> ',0,_struc_dword,_eol
 db _cx,_txt,' effective group id ptr -> ',0,_struc_dword,_eol
 db _dx,_txt,' saved effective group id ptr ->',0,_struc_dword,_eol
 db _end

prctl:                 ; operations on a process
 db 'prctl',0                 ; operations on a process
 dd p_generic		;process
 db _bx,_txt,' option',0,_eol
 db _txt,' (up to 4 parameters follow, depending upon option)',0,_eol
 db _end

rt_sigreturn:          ; real time sigreturn
 db 'rt_sigreturn',0          ; real time sigreturn
 dd p_generic		;process
 db _end

rt_sigaction:          ; setup rt sighnd (RTL)
 db 'rt_sigaction',0          ; setup rt sighnd (RTL)
 dd p_generic		;process
 db _bx,_txt,' Signal#',0,_eol
 db _cx,_txt,' new action ptr -> ',0
   db _txt,'  ',0,_struc_dword, _txt,'=handler',0
   db _txt,'  ',0,_struc_dword, _txt,'=flag',0,_eol
 db _dx,_txt,' old action ptr -> ',0
   db _txt,'  ',0,_struc_dword, _txt,'=handler',0
   db _txt,'  ',0,_struc_dword, _txt,'=flag',0,_eol
 db _si,_txt,' sigset size (bytes, usually 8)',0,_eol
 db _end

rt_sigprocmask:        ; real time sigprocmask
 db 'rt_sigprocmask',0        ; real time sigprocmask
 dd p_generic		;process
 db _bx,_txt,' how (0=block 1=unblock 2=set)',0,_eol
 db _cx,_txt,' sigset -> mask=',0,_struc_dword,_txt,' ',0,_struc_dword,0,_eol
 db _dx,_txt,' sigset -> mask=',0,_struc_dword,_txt,' ',0,_struc_dword,0,_eol
 db _si,_txt,' sigset size (bytes, usually 8)',0,_eol
 db _end

rt_sigpending:         ; real time sigaction
 db 'rt_sigpending',0         ; real time sigaction
 dd p_generic		;process
 db _bx,_txt,' sigset -> mask=',0,_struc_dword,_txt,' ',0,_struc_dword,0,_eol
 db _cx,_txt,' sigset size (bytes, usually 8)',0,_eol
 db _end

rt_sigtimedwait:       ; real time sigtimedwait
 db 'rt_sigtimedwait',0       ; real time sigtimedwait
 dd p_generic		;process
 db _bx,_txt,' uthese ptr to signal mask -> ',0,_struc_dword,_eol
 db _cx,_txt,' uinfo ptr',0,_eol
 db _dx,_txt,' time ptr -> ',0,_struc_dword,_txt,'(sec} ',0,_struc_dword,_txt,'(nsec) ',0,_eol
 db _si,_txt,' size',0,_eol
 db _end

rt_sigqueueinfo:       ; real time sigqueueingo
 db 'rt_sigqueueinfo',0       ; real time sigqueueingo
 dd p_generic		;process
 db _bx,_txt,' pid',0,_eol
 db _cx,_txt,' signal#',0,_eol
 db _dx,_txt,' ptr to uinfo',0,_eol
 db _end

rt_sigsuspend:         ; real time sigsuspend
 db 'rt_sigsuspend',0         ; real time sigsuspend
 dd p_generic		;process
 db _bx,_txt,' ptr mask ->',0,_struc_dword,_eol
 db _end

pread64:               ; read/write without moving file descriptor
 db 'pread64',0               ; read/write without moving file descriptor
 dd p_generic		;process
 db _bx,_txt,' fd',0,_eol
 db _cx,_txt,' buffer',0,_eol
 db _dx,_txt,' buffer length',0,_eol
 db _si,_txt,' offset',0,_eol
 db _end

pwrite64:              ; write to file descriptor at offset
 db 'pwrite64',0              ; write to file descriptor at offset
 dd p_generic		;process
 db _bx,_txt,' fd',0,_eol
 db _cx,_txt,' buffer',0,_eol
 db _dx,_txt,' buffer length',0,_eol
 db _si,_txt,' offset',0,_eol
 db _end

chown:                 ; change ownership of a file
 db 'chown',0                 ; change ownership of a file
 dd p_generic		;process
 db _bx,_txt,'  filename',0,_buf2,_eol
 db _cx,_txt,'  new owner id, or -1 to ignore',0,_eol
 db _dx,_txt,'  new group id, or -1 to ignore',0,_eol
 db _end

getcwd:                ; get current working directory
 db 'getcwd',0                ; get current working directory
 dd p_generic		;process
 db _bx,_txt,'  buffer for dir',0,_buf2,_eol
 db _cx,_txt,'  buf length',0,_eol
 db _end

capget:                ; get process capabilities
 db 'capget',0                ; get process capabilities
 dd p_generic		;process
 db _bx,_txt,' ptr to header',0,_eol
 db _cx,_txt,' ptr to data',0,_eol
 db _end

capset:                ; set process capabilities
 db 'capset',0                ; set process capabilities
 dd p_generic		;process
 db _bx,_txt,' ptr to header',0,_eol
 db _cx,_txt,' ptr to data',0,_eol
 db _end

sigaltstack:           ; get or set alternate signal stack content
 db 'sigaltstack',0           ; get or set alternate signal stack content
 dd p_generic		;process
 db _bx,_txt,' stack def ptr -> ',0,_struc_dword,_txt,'(def ptr) ',0,_struc_dword,_txt,'(flags) ',0,_struc_dword,_txt,'(size)',0,_eol
 db _cx,_txt,' default stack def ptr -> ',0,_struc_dword,_txt,'(def ptr) ',0,_struc_dword,_txt,'(flags) ',0,_struc_dword,_txt,'(size)',0,_eol
 db _dx,_txt,' stack adr',0,_eol
 db _end

sendfile:              ; transfer data between file descriptors
 db 'sendfile',0              ; transfer data between file descriptors
 dd p_generic		;process
 db _bx,_txt,' out fd',0,_eol
 db _cx,_txt,' in fd',0,_eol
 db _dx,_txt,' in offset ptr ->',0,_struc_dword,_eol
 db _si,_txt,' transfer size',0,_eol
 db _end

getpmsg:               ; UNIMPLEMENTED
 db 'getpmsg',0               ; UNIMPLEMENTED
 dd p_generic		;process
 db _end

putpmsg:               ; UNIMPLEMENTED
 db 'putpmsg',0               ; UNIMPLEMENTED
 dd p_generic		;process
 db _end

vfork:                 ; create a child process and block parent
 db 'vfork',0                 ; create a child process and block parent
 dd p_generic		;process
 db _end

ugetrlimit:            ; UNIMPLEMENTED
 db 'ugetrlimit',0            ; UNIMPLEMENTED
 dd p_generic		;process
 db _bx,_txt,' resource (0=self)',0,_eol
 db _cx,_txt,' rlimit ptr',0,_eol
 db _end

mmap2:                 ; map files or devices into memory
 db 'mmap2',0                 ; map files or devices into memory
 dd p_generic		;process
 db _bx,_txt,' page',0,_eol
 db _cx,_txt,' size',0,_eol
 db _dx,_txt,' prot',0,_eol
 db _si,_txt,' flags',0,_eol
 db _di,_txt,' fd',0,_eol
 db _bp,_txt,' offset (if needed)',0,_eol
 db _end

truncate64:            ; truncates file to the specified length (LFS version of truncate)
 db 'truncate64',0            ; truncates file to the specified length (LFS version of truncate)
 dd p_generic		;process
 db _bx,_txt,' filename ptr->',0,_buf2,_eol
 db _cx,_txt,' new length (low bits)',0,_eol
 db _dx,_txt,' new length (high bits)',0,_eol
 db _end

ftruncate64:           ; truncates file to the specified length (LFS version of ftruncate)
 db 'ftruncate64',0           ; truncates file to the specified length (LFS version of ftruncate)
 dd p_generic		;process
 db _bx,_txt,' fd',0,_eol
 db _cx,_txt,' new length (low bits)',0,_eol
 db _dx,_txt,' new length (high bits)',0,_eol
 db _end

stat64:                ; obtains information about a file (LFS version of stat)
 db 'stat64',0                ; obtains information about a file (LFS version of stat)
 dd p_generic		;process
 db _bx,_txt,'  filename',0,_buf2,_eol
 db _cx,_txt,'  ptr to stat_struc ->',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' st_dev:',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' st_ino:',0,_eol
 db _txt,'  ',0,_struc_word,_txt,' st_mode:',0,_eol
 db _txt,'  ',0,_struc_word,_txt,' st_nlink:',0,_eol
 db _txt,'  ',0,_struc_word,_txt,' st_uid:',0,_eol
 db _txt,'  ',0,_struc_word,_txt,' st_gid:',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' st_rdev: device type (if inode device)',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' st_size: total size in bytes',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' st_blksize: blocksize for filesystem I/O',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' st_blocks: number of blocks allocated',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' st_atime: time of last access',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' __unused1',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' st_mtime: time of last modification',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' __unused2',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' st_ctime: time of last change',0,_eol
 db _end

lstat64:               ; obtains information about a file (LFS version of lstat)
 db 'lstat64',0               ; obtains information about a file (LFS version of lstat)
 dd p_generic		;process
 db _bx,_txt,'  filename',0,_buf2,_eol
 db _cx,_txt,'  ptr to stat_struc ->',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' st_dev:',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' st_ino:',0,_eol
 db _txt,'  ',0,_struc_word,_txt,' st_mode:',0,_eol
 db _txt,'  ',0,_struc_word,_txt,' st_nlink:',0,_eol
 db _txt,'  ',0,_struc_word,_txt,' st_uid:',0,_eol
 db _txt,'  ',0,_struc_word,_txt,' st_gid:',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' st_rdev: device type (if inode device)',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' st_size: total size in bytes',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' st_blksize: blocksize for filesystem I/O',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' st_blocks: number of blocks allocated',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' st_atime: time of last access',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' __unused1',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' st_mtime: time of last modification',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' __unused2',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' st_ctime: time of last change',0,_eol
 db _end

fstat64:               ; obtains information about a file (LFS version of fstat)
 db 'fstat64',0               ; obtains information about a file (LFS version of fstat)
 dd p_generic		;process
 db _bx,_txt,'  fd',0,_eol
 db _cx,_txt,'  ptr to stat_struc ->',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' ',0,_struc_dword,_txt,' st_dev:',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' ',0,_struc_dword,_txt,' st_ino:',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' st_mode:',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' st_nlink:',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' st_uid:',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' st_gid:',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' ',0,_struc_dword,_txt,' st_rdev: device type (if inode device)',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' ',0,_struc_dword,_txt,' st_size: total size in bytes',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' ',0,_struc_dword,_txt,' st_blksize: blocksize for filesystem I/O',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' ',0,_struc_dword,_txt,' st_blocks: number of blocks allocated',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' st_atime: time of last access',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' __unused1',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' st_mtime: time of last modification',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' __unused2',0,_eol
 db _txt,'  ',0,_struc_dword,_txt,' st_ctime: time of last change',0,_eol
 db _end

lchown32:              ; UNIMPLEMENTED
 db 'lchown32',0              ; UNIMPLEMENTED
 dd p_generic		;process
 db _bx,_txt,'  filename',0,_buf2,_eol
 db _cx,_txt,'  new owner id, or -1 to ignore',0,_eol
 db _dx,_txt,'  new group id, or -1 to ignore',0,_eol
 db _end

getuid32:              ; UNIMPLEMENTED
 db 'getuid32',0              ; UNIMPLEMENTED
 dd p_generic		;process
 db _end

getgid32:              ; UNIMPLEMENTED
 db 'getgid32',0              ; UNIMPLEMENTED
 dd p_generic		;process
 db _end

geteuid32:             ; UNIMPLEMENTED
 db 'geteuid32',0             ; UNIMPLEMENTED
 dd p_generic		;process
 db _end

getegid32:             ; UNIMPLEMENTED
 db 'getegid32',0             ; UNIMPLEMENTED
 dd p_generic		;process
 db _end

setreuid32:            ; UNIMPLEMENTED
 db 'setreuid32',0            ; UNIMPLEMENTED
 dd p_generic		;process
 db _bx,_txt,'  ruid or -1 to ignore',0,_eol
 db _cx,_txt,'  euid or -1 to ignore',0,_eol
 db _end

setregid32:            ; UNIMPLEMENTED
 db 'setregid32',0            ; UNIMPLEMENTED
 dd p_generic		;process
 db _bx,_txt,'  rgid or -1 to ignore',0,_eol
 db _cx,_txt,'  egid or -1 to ignore',0,_eol
 db _end

getgroups32:           ; UNIMPLEMENTED
 db 'getgroups32',0           ; UNIMPLEMENTED
 dd p_generic		;process
 db _bx,_txt,' size of buffer',0,_eol
 db _cx,_txt,' ptr to -> ',0,_struc_dword,_txt,' ',0,_struc_dword,_txt,' ',0,_struc_dword,_txt,' ',0,_struc_dword,_txt,' ...',0,_eol
 db _txt,'  (returns group count)',0,_eol
 db _end

setgroups32:           ; UNIMPLEMENTED
 db 'setgroups32',0           ; UNIMPLEMENTED
 dd p_generic		;process
 db _bx,_txt,' size of groups',0,_eol
 db _cx,_txt,' ptr to -> ',0,_struc_dword,_txt,' ',0,_struc_dword,_txt,' ',0,_struc_dword,_txt,' ',0,_struc_dword,_txt,' ...',0,_eol
 db _end

fchown32:              ; UNIMPLEMENTED
 db 'fchown32',0              ; UNIMPLEMENTED
 dd p_generic		;process
 db _bx,_txt,' fd',0,_eol
 db _cx,_txt,' new owner',0,_eol
 db _dx,_txt,' new group',0,_eol
 db _end

setresuid32:           ; UNIMPLEMENTED
 db 'setresuid32',0           ; UNIMPLEMENTED
 dd p_generic		;process
 db _end

getresuid32:           ; UNIMPLEMENTED
 db 'getresuid32',0           ; UNIMPLEMENTED
 dd p_generic		;process
 db _bx,_txt,' real user id ptr -> ',0,_struc_dword,_eol
 db _cx,_txt,' effective user id ptr -> ',0,_struc_dword,_eol
 db _dx,_txt,' saved effective user id ptr ->',0,_struc_dword,_eol
 db _end

setresgid32:           ; UNIMPLEMENTED
 db 'setresgid32',0           ; UNIMPLEMENTED
 dd p_generic		;process
 db _end

getresgid32:           ; UNIMPLEMENTED
 db 'getresgid32',0           ; UNIMPLEMENTED
 dd p_generic		;process
 db _bx,_txt,' real group id ptr -> ',0,_struc_dword,_eol
 db _cx,_txt,' effective group id ptr -> ',0,_struc_dword,_eol
 db _dx,_txt,' saved effective group id ptr ->',0,_struc_dword,_eol
 db _end

chown32:               ; UNIMPLEMENTED
 db 'chown32',0               ; UNIMPLEMENTED
 dd p_generic		;process
 db _bx,_txt,'  filename',0,_buf2,_eol
 db _cx,_txt,'  new owner id, or -1 to ignore',0,_eol
 db _dx,_txt,'  new group id, or -1 to ignore',0,_eol
 db _end

setuid32:              ; UNIMPLEMENTED
 db 'setuid32',0              ; UNIMPLEMENTED
 dd p_generic		;process
 db _bx,_txt,'  user id (UID)',0,_eol
 db _end

setgid32:              ; UNIMPLEMENTED
 db 'setgid32',0              ; UNIMPLEMENTED
 dd p_generic		;process
 db _bx,_txt,' group id (GID)',0,_eol
 db _end

setfsuid32:            ; UNIMPLEMENTED
 db 'setfsuid32',0            ; UNIMPLEMENTED
 dd p_generic		;process
 db _bx,_txt,' fsuid',0,_eol
 db _end

setfsgid32:            ; UNIMPLEMENTED
 db 'setfsgid32',0            ; UNIMPLEMENTED
 dd p_generic		;process
 db _bx,_txt,' fsgid',0,_eol
 db _end

pivot_root:            ; change the root file system
 db 'pivot_root',0            ; change the root file system
 dd p_generic		;process
 db _bx,_txt,' ptr to new root data',0,_eol
 db _cx,_txt,' ptr to old root save',0,_eol
 db _end

mincore:               ; get information on whether pages are in core 
 db 'mincore',0               ; get information on whether pages are in core 
 dd p_generic		;process
 db _bx,_txt,' start adr',0,_eol
 db _cx,_txt,' length',0,_eol
 db _dx,_txt,' ptr to bit map -> ',0,_struc_dword,_txt,'...',0,_eol
 db _end

madvise:               ; give advice about use of memory
 db 'madvise',0               ; give advice about use of memory
 dd p_generic		;process
 db _bx,_txt,' start adr',0,_eol
 db _cx,_txt,' length',0,_eol
 db _dx,_txt,' behaviour',0,_eol
 db _end

getdents64:            ; get directory entries (LFS version of getdents)
 db 'getdents64',0            ; get directory entries (LFS version of getdents)
 dd p_generic		;process
 db _bx,_txt,' fd',0,_eol
 db _cx,_txt,' buffer ptr',0,_eol
 db _dx,_txt,' buffer size',0,_eol
 db _end

fcntl64:               ; do operations on a file descriptor (LFS version of fcntl)
 db 'fcntl64',0               ; do operations on a file descriptor (LFS version of fcntl)
 dd p_fcntl		;process
; db _bx,_txt,'  file descriptor',0,_eol
; db _cx,_txt,'  command',0,_eol
; db _dx,_txt,'  ptr ->',0,_eol
 db _end

rsbac:                 ; 
 db 'rsbac',0                 ; 
 dd p_generic		;process
 db _end

security:                 ; 
 db 'security',0                 ; 
 dd p_generic		;process
 db _end

gettid:                ; get thread identification
 db 'gettid',0                ; get thread identification
 dd p_generic		;process
 db _end

readahead:             ; read in advance one or more pages
 db 'readahead',0             ; read in advance one or more pages
 dd p_generic		;process
 db _bx,_txt,' fd',0,_eol
 db _cx,_txt,' seek',0,_eol
 db _dx,_txt,' count',0,_eol
 db _end

setxattr:              ; set an extended attribute value
 db 'setxattr',0              ; set an extended attribute value
 dd p_generic		;process
 db _bx,_txt,' path ptr-> ',0,_buf2,_eol
 db _cx,_txt,' name ptr-> ',0,_buf2,_eol
 db _dx,_txt,' value ptr -> ',0,_buf2,_eol
 db _si,_txt,' size',0,_eol
 db _di,_txt,' flags',0,_eol
 db _end

lsetxattr:             ; set extended attributes
 db 'lsetxattr',0             ; set extended attributes
 dd p_generic		;process
 db _bx,_txt,' path ptr-> ',0,_buf2,_eol
 db _cx,_txt,' name ptr-> ',0,_buf2,_eol
 db _dx,_txt,' value ptr -> ',0,_buf2,_eol
 db _si,_txt,' size',0,_eol
 db _di,_txt,' flags',0,_eol
 db _end

fsetxattr:             ; set extended attribute
 db 'fsetxattr',0             ; set extended attribute
 dd p_generic		;process
 db _bx,_txt,' fd',0,_eol
 db _cx,_txt,' name ptr-> ',0,_buf2,_eol
 db _dx,_txt,' value ptr -> ',0,_buf2,_eol
 db _si,_txt,' size',0,_eol
 db _di,_txt,' flags',0,_eol
 db _end

getxattr:              ; retrieve an extended attribute value
 db 'getxattr',0              ; retrieve an extended attribute value
 dd p_generic		;process
 db _bx,_txt,' path ptr-> ',0,_buf2,_eol
 db _cx,_txt,' name ptr-> ',0,_buf2,_eol
 db _dx,_txt,' value ptr -> ',0,_buf2,_eol
 db _si,_txt,' size',0,_eol
 db _di,_txt,' flags',0,_eol
 db _end

lgetxattr:             ; get extended attribute
 db 'lgetxattr',0             ; get extended attribute
 dd p_generic		;process
 db _bx,_txt,' path ptr-> ',0,_buf2,_eol
 db _cx,_txt,' name ptr-> ',0,_buf2,_eol
 db _dx,_txt,' value ptr -> ',0,_buf2,_eol
 db _si,_txt,' size',0,_eol
 db _di,_txt,' flags',0,_eol
 db _end

fgetxattr:             ; get extended attribute
 db 'fgetxattr',0             ; get extended attribute
 dd p_generic		;process
 db _bx,_txt,' fd',0,_eol
 db _cx,_txt,' name ptr-> ',0,_buf2,_eol
 db _dx,_txt,' value ptr -> ',0,_buf2,_eol
 db _si,_txt,' size',0,_eol
 db _di,_txt,' flags',0,_eol
 db _end

listxattr:             ; list extended attribute names
 db 'listxattr',0             ; list extended attribute names
 dd p_generic		;process
 db _end

llistxattr:            ; list extended attributes
 db 'llistxattr',0            ; list extended attributes
 dd p_generic		;process
 db _end

flistxattr:            ; list extended attribute
 db 'flistxattr',0            ; list extended attribute
 dd p_generic		;process
 db _end

removexattr:           ; remove an extended attribute
 db 'removexattr',0           ; remove an extended attribute
 dd p_generic		;process
 db _end

lremovexattr:          ; remove extended attributes
 db 'lremovexattr',0          ; remove extended attributes
 dd p_generic		;process
 db _end

fremovexattr:          ; remove extended attribute
 db 'fremovexattr',0          ; remove extended attribute
 dd p_generic		;process
 db _end

tkill:                 ; send a signal to a single process
 db 'tkill',0                 ; send a signal to a single process
 dd p_generic		;process
 db _bx,_txt,' pid',0,_eol
 db _cx,_txt,' signal',0,_eol
 db _end

sendfile64:            ; transfer data between file descriptors (LFS version of sendfile)
 db 'sendfile64',0            ; transfer data between file descriptors (LFS version of sendfile)
 dd p_generic		;process
 db _bx,_txt,' out fd',0,_eol
 db _cx,_txt,' in fd',0,_eol
 db _dx,_txt,' ptr to in offset -> ',0,_struc_dword,_txt,' ',0,_struc_dword,_eol
 db _si,_txt,' transfer size',0,_eol
 db _end

futex:                 ; Fast Userspace Locking system call
 db 'futex',0                 ; Fast Userspace Locking system call
 dd p_generic		;process
 db _bx,_txt,' address (futex) ptr -> ',0,_struc_dword,_eol
 db _cx,_txt,' value',0,_eol
 db _dx,_txt,' timespec ptr -> ',0,_struc_dword,_txt,'(sec) ',0,_struc_dword,_eol
 db _end

sched_setaffinity:     ; set a process's CPU affinity mask
 db 'sched_setaffinity',0     ; set a process's CPU affinity mask
 dd p_generic		;process
 db _bx,_txt,' pid',0,_eol
 db _cx,_txt,' length',0,_eol
 db _dx,_txt,' mask ptr -> ',0,_struc_dword,_eol
 db _end

sched_getaffinity:     ; get a process's CPU affinity mask
 db 'sched_getaffinity',0     ; get a process's CPU affinity mask
 dd p_generic		;process
 db _bx,_txt,' pid',0,_eol
 db _cx,_txt,' length',0,_eol
 db _dx,_txt,' mask ptr -> ',0,_struc_dword,_eol
 db _end

set_thread_area:       ; set a Thread Local Storage (TLS) area
 db 'set_thread_area',0       ; set a Thread Local Storage (TLS) area
 dd p_generic		;process
 db _bx,_txt,' u_info ptr ->',0,_eol
  db _txt,'    entry_number=   ',0,_struc_dword,_eol
  db _txt,'    base_addr=      ',0,_struc_dword,_eol
  db _txt,'    limit   =       ',0,_struc_dword,_eol
  db _txt,'    seg_32bit=      ',0,_struc_dword,_eol
  db _txt,'    contents=       ',0,_struc_dword,_eol
  db _txt,'    read_exec_only= ',0,_struc_dword,_eol
  db _txt,'    limit_in_pages= ',0,_struc_dword,_eol
  db _txt,'    seg_not_present=',0,_struc_dword,_eol
  db _txt,'    usable=         ',0,_struc_dword,_eol
 db _end

get_thread_area:       ; get a Thread Local Storage (TLS) area 
 db 'get_thread_area',0       ; get a Thread Local Storage (TLS) area 
 dd p_generic		;process
 db _bx,_txt,' u_info ptr ->',0,_eol
  db _txt,'    entry_number=   ',0,_struc_dword,_eol
  db _txt,'    base_addr=      ',0,_struc_dword,_eol
  db _txt,'    limit   =       ',0,_struc_dword,_eol
  db _txt,'    seg_32bit=      ',0,_struc_dword,_eol
  db _txt,'    contents=       ',0,_struc_dword,_eol
  db _txt,'    read_exec_only= ',0,_struc_dword,_eol
  db _txt,'    limit_in_pages= ',0,_struc_dword,_eol
  db _txt,'    seg_not_present=',0,_struc_dword,_eol
  db _txt,'    usable=         ',0,_struc_dword,_eol
 db _end

io_setup:              ; Create an asynchronous I/O context
 db 'io_setup',0              ; Create an asynchronous I/O context
 dd p_generic		;process
 db _bx,_txt,' nr_events (number of events)',0,_eol
 db _cx,_txt,' id_ptr ->',0,_ptr,_txt,'ctx_id (also aio_ring_base)',0,_eol
  db _txt,'   id ',0,_struc_dword,_eol
  db _txt,'   nr ',0,_struc_dword,_eol
  db _txt,'   head ',0,_struc_dword,_eol
  db _txt,'   tail ',0,_struc_dword,_eol
  db _txt,'   magic ',0,_struc_dword,_eol
  db _txt,'   compat ',0,_struc_dword,_eol
  db _txt,'   incompat ',0,_struc_dword,_eol
  db _txt,'   header len ',0,_struc_dword,_eol
  db _txt,'   event1 data ',0,_struc_dword,_txt,' ',0,_struc_dword,_eol
  db _txt,'   event1 obj (iocb ptr for this event) ',0,_struc_dword,_txt,' ',0,_struc_dword,_eol
  db _txt,'   event1 result1 ',0,_struc_dword,_txt,' ',0,_struc_dword,_txt,' (low dword is return code for EAX)',0,_eol
  db _txt,'   event1 result2 ',0,_struc_dword,_txt,' ',0,_struc_dword,_eol
 db _end

io_destroy:            ; Destroy an asynchronous I/O context 
 db 'io_destroy',0            ; Destroy an asynchronous I/O context 
 dd p_generic		;process
 db _bx,_txt,' ctxp array ptr -> ',0,_struc_dword,_txt,' ...',0,_eol
 db _end

io_getevents:          ; Read asynchronous I/O events from the completion queue
 db 'io_getevents',0          ; Read asynchronous I/O events from the completion queue
 dd p_generic		;process
 db _bx,_txt,' ctx_id (also aio_ring_base) ->',0,_eol
  db _txt,'   id ',0,_struc_dword,_eol
  db _txt,'   nr ',0,_struc_dword,_eol
  db _txt,'   head ',0,_struc_dword,_eol
  db _txt,'   tail ',0,_struc_dword,_eol
  db _txt,'   magic ',0,_struc_dword,_eol
  db _txt,'   compat ',0,_struc_dword,_eol
  db _txt,'   incompat ',0,_struc_dword,_eol
  db _txt,'   header len ',0,_struc_dword,_eol
  db _txt,'   event1 data (ptr to completion handler) ',0,_struc_dword,_txt,' ',0,_struc_dword,_eol
  db _txt,'   event1 obj (iocb ptr for this event) ',0,_struc_dword,_txt,' ',0,_struc_dword,_eol
  db _txt,'   event1 result1 ',0,_struc_dword,_txt,' ',0,_struc_dword,_txt,' (low dword is return code for EAX)',0,_eol
  db _txt,'   event1 result2 ',0,_struc_dword,_txt,' ',0,_struc_dword,_eol
 db _cx,_txt,' min_nr (minimum events)',0,_eol
 db _dx,_txt,' max_nr (maximum events)',0,_eol
 db _si,_txt,' event ptr ->',0,_struc_dword,_eol
 db _di,_txt,' timeout -> ',0,_struc_dword,_txt,'(sec) ',0,_struc_dword,_eol
 db _end

io_submit:             ; Submit asynchronous I/O blocks for processing
 db 'io_submit',0             ; Submit asynchronous I/O blocks for processing
 dd p_generic		;process
 db _bx,_txt,' ctx_id (also aio_ring base)',0,_eol
  db _txt,'   id ',0,_struc_dword,_eol
  db _txt,'   nr ',0,_struc_dword,_eol
  db _txt,'   head ',0,_struc_dword,_eol
  db _txt,'   tail ',0,_struc_dword,_eol
  db _txt,'   magic ',0,_struc_dword,_eol
  db _txt,'   compat ',0,_struc_dword,_eol
  db _txt,'   incompat ',0,_struc_dword,_eol
  db _txt,'   header len ',0,_struc_dword,_eol
 db _cx,_txt,' nr (number of events)',0,_eol
 db _dx,_txt,' iocb (event array ptr ->',0,_ptr,_txt,' ->',0,_eol 
  db _txt,'   aio_data (ptr to completion handler) ',0,_struc_dword,_txt,' ',0,_struc_dword,_eol
  db _txt,'   aio_key ',0,_struc_dword,_txt,' ',0,_struc_dword,_eol
  db _txt,'   aio_lio_opcode (0=read 1=write ..) ',0,_struc_word,_eol
  db _txt,'   aio_reqprio ',0,_struc_word,_eol
  db _txt,'   aio_fildes (fd) ',0,_struc_dword,_eol
  db _txt,'   aio_buf (io transfer buffer) ',0,_struc_dword,_txt,' ',0,_struc_dword,_eol
  db _txt,'   aio_nbytes (buffer size) ',0,_struc_dword,_txt,' ',0,_struc_dword,_eol
  db _txt,'   aio_offset ',0,_struc_dword,_txt,' ',0,_struc_dword,_eol
 db _end

io_cancel:             ; Cancel an outstanding asynchronous I/O operation
 db 'io_cancel',0             ; Cancel an outstanding asynchronous I/O operation
 dd p_generic		;process
 db _bx,_txt,' ctx_id',0,_eol
 db _cx,_txt,' ioch (event array ptr ->',0,_struc_dword,_txt,' ...',0,_eol
 db _dx,_txt,' results ->',0,_struc_dword,_txt,' ...',0,_eol
 db _end

fadvise64:             ; gives the kernel an 'advice' on how it should use a file handle
 db 'fadvise64',0             ; gives the kernel an 'advice' on how it should use a file handle
 dd p_generic		;process
 db _bx,_txt,' fd',0,_eol
 db _cx,_txt,' offset',0,_eol
 db _dx,_txt,' length',0,_eol
 db _si,_txt,' flag',0,_eol
 db _end

unknown:               ; 
 db 'unknown',0               ; 
 dd p_generic		;process
 db _end

exit_group:            ; exit all process's in group
 db 'exit_group',0            ; exit all process's in group
 dd p_generic		;process
 db _end

lookup_dcookie:        ; return a directory entry's path
 db 'lookup_dcookie',0        ; return a directory entry's path
 dd p_generic		;process
 db _bx,_txt,' cookie_low',0,_eol
 db _cx,_txt,' cookie_hi',0,_eol
 db _dx,_txt,' buffer',0,_buf2,_eol
 db _si,_txt,' length',0,_eol
 db _end

epoll_create:          ; open an epoll file descriptor
 db 'epoll_create',0          ; open an epoll file descriptor
 dd p_generic		;process
 db _bx,_txt,' size',0,_eol
 db _cx,_txt,' epfd (epoll descriptor)',0,_eol
 db _end

epoll_ctl:             ; control interface for an epoll descriptor
 db 'epoll_ctl',0             ; control interface for an epoll descriptor
 dd p_generic		;process
 db _bx,_txt,' epfd (epoll descriptor)',0,_eol
 db _cx,_txt,' op (operation)',0,_eol
 db _dx,_txt,' fd',0,_eol
 db _si,_txt,' event struc ptr',0,_eol
 db _end

epoll_wait:            ; wait for an I/O event on an epoll file descriptor
 db 'epoll_wait',0            ; wait for an I/O event on an epoll file descriptor
 dd p_generic		;process
 db _bx,_txt,' epfd (epoll descriptor)',0,_eol
 db _cx,_txt,' event ptr',0,_eol
 db _dx,_txt,' max events',0,_eol
 db _si,_txt,' timeout ptr -> ',_struc_dword,_txt,'(sec) ',0,_struc_dword,_eol
 db _di,_txt,' sigmask',0,_eol
 db _end

remap_file_pages:      ; create a non-linear file mapping
 db 'remap_file_pages',0      ; create a non-linear file mapping
 dd p_generic		;process
 db _bx,_txt,' start adr',0,_eol
 db _cx,_txt,' size',0,_eol
 db _dx,_txt,' prot',0,_eol
 db _si,_txt,' page offset',0,_eol
 db _di,_txt,' flags',0,_eol
 db _end

set_tid_address:       ; set pointer to thread ID
 db 'set_tid_address',0       ; set pointer to thread ID
 dd p_generic		;process
 db _bx,_txt,' tidptr ',0,_eol
 db _end

timer_create:          ; 
 db 'timer_create',0          ; 
 dd p_generic		;process
 db _bx,_txt,' which',0,_eol
 db _cx,_txt,' event ptr ->',0,_eol
  db _txt,'   value=',0,_struc_dword,_eol
  db _txt,'   signo=',0,_struc_dword,_eol
  db _txt,'   notify=',0,_struc_dword,_eol
  db _txt,'   compat=',0,_struc_dword,_eol
 db _dx,_txt,' assigned id ->',0,_struc_dword,_eol
 db _end

timer_settime:         ; 
 db 'timer_settime',0         ; 
 dd p_generic		;process
 db _bx,_txt,' id',0,_eol
 db _cx,_txt,' flag',0,_eol
 db _dx,_txt,' new timespec -> ',0,_eol
  db _txt,'   interval ',0,_struc_dword,_txt,'(sec) ',0,_struc_dword,_txt,'(nano)',0,_eol
  db _txt,'   expire   ',0,_struc_dword,_txt,'(sec) ',0,_struc_dword,_txt,'(nano)',0,_eol
 db _si,_txt,' old timespec -> ',0,_eol
  db _txt,'   interval ',0,_struc_dword,_txt,'(sec) ',0,_struc_dword,_txt,'(nano)',0,_eol
  db _txt,'   expire   ',0,_struc_dword,_txt,'(sec) ',0,_struc_dword,_txt,'(nano)',0,_eol
 db _end

timer_gettime:         ; 
 db 'timer_gettime',0         ; 
 dd p_generic		;process
 db _bx,_txt,' id',0,_eol
 db _cx,_txt,' timespec -> ',0,_eol
  db _txt,'   interval ',0,_struc_dword,_txt,'(sec) ',0,_struc_dword,_txt,'(nano)',0,_eol
  db _txt,'   expire   ',0,_struc_dword,_txt,'(sec) ',0,_struc_dword,_txt,'(nano)',0,_eol
 db _end

timer_getoverrun:      ; 
 db 'timer_getoverrun',0      ; 
 dd p_generic		;process
 db _bx,_txt,' id',0,_eol
 db _end

timer_delete:          ; 
 db 'timer_delete',0          ; 
 dd p_generic		;process
 db _bx,_txt,' id',0,_eol
 db _end

clock_settime:         ; set specified time
 db 'clock_settime',0         ; set specified time
 dd p_generic		;process
 db _bx,_txt,' which',0,_eol
 db _cx,_txt,' timespec -> ',0,_struc_dword,_txt,'(sec) ',0,_struc_dword,_txt,'(nano)',0,_eol
 db _end

clock_gettime:         ; get specified time
 db 'clock_gettime',0         ; get specified time
 dd p_generic		;process
 db _bx,_txt,' which',0,_eol
 db _cx,_txt,' timespec -> ',0,_struc_dword,_txt,'(sec) ',0,_struc_dword,_txt,'(nano)',0,_eol
 db _end

clock_getres:          ; get clock precision 
 db 'clock_getres',0          ; get clock precision 
 dd p_generic		;process
 db _bx,_txt,' which',0,_eol
 db _cx,_txt,' timespec -> ',0,_struc_dword,_txt,'(sec) ',0,_struc_dword,_txt,'(nano)',0,_eol
 db _end

clock_nanosleep:       ; process sleep
 db 'clock_nanosleep',0       ; process sleep
 dd p_generic		;process
 db _bx,_txt,' which',0,_eol
 db _cx,_txt,' new timespec -> ',0,_struc_dword,_txt,'(sec) ',0,_struc_dword,_txt,'(nano)',0,_eol
 db _dx,_txt,' old timespec -> ',0,_struc_dword,_txt,'(sec) ',0,_struc_dword,_txt,'(nano)',0,_eol
 db _end

statfs64:              ; obtain information about mounted file system (LFS version of statfs)
 db 'statfs64',0              ; obtain information about mounted file system (LFS version of statfs)
 dd p_generic		;process
 db _bx,_txt,' path',0,_buf2,_eol
 db _cx,_txt,' buffer->',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' f_type',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' f_bsize',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' f_blocks',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' f_bfree',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' f_bavauk',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' f_files',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' f_ffree',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' f_fsid',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' f_namelen',0,_eol
 db _end

fstatfs64:             ; obtain information about mounted file system (LFS version of fstatfs)
 db 'fstatfs64',0             ; obtain information about mounted file system (LFS version of fstatfs)
 dd p_generic		;process
 db _bx,_txt,' fd',0,_eol
 db _cx,_txt,' buffer->',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' f_type',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' f_bsize',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' f_blocks',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' f_bfree',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' f_bavauk',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' f_files',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' f_ffree',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' f_fsid',0,_eol
   db _txt,'  ',0,_struc_dword, _txt,' f_namelen',0,_eol
 db _end

tgkill:                ; send signal to one specific thread
 db 'tgkill',0                ; send signal to one specific thread
 dd p_generic		;process
 db _bx,_txt,' tgid (group id)',0,_eol
 db _cx,_txt,' pid',0,_eol
 db _dx,_txt,' signal# to send',0,_eol
 db _end

utimes:                ; change access and/or modification times of an inodetimes    
 db 'utimes',0                ; change access and/or modification times of an inodetimes    
 dd p_generic		;process
 db _bx,_txt,' filename',0,_buf2,_eol
 db _cx,_txt,' timespec -> ',0,_struc_dword,_txt,'(sec) ',_struc_dword,_eol
 db _end

fadvise64_64:          ; gives the kernel an 'advice' on how it should use a file handle
 db 'fadvise64_64',0          ; gives the kernel an 'advice' on how it should use a file handle
 dd p_generic		;process
 db _bx,_txt,' start adr',0,_eol
 db _cx,_txt,' length',0,_eol
 db _dx,_txt,' behaviour',0,_eol
 db _end

vserver:               ; UNIMPLEMENTED
 db 'vserver',0               ; UNIMPLEMENTED
 dd p_generic		;process
 db _end

mbind:                 ; set NUMA memory policy for a memory range
 db 'mbind',0                 ; set NUMA memory policy for a memory range
 dd p_generic		;process
 db _bx,_txt,' start adr',0,_eol
 db _cx,_txt,' length',0,_eol
 db _dx,_txt,' policy',0,_eol
 db _si,_txt,' mask ptr -> ',0,_struc_dword
 db _di,_txt,' flag',0,_eol
 db _end

get_mempolicy:         ; get NUMA memory policy for a process
 db 'get_mempolicy',0         ; get NUMA memory policy for a process
 dd p_generic		;process
 db _bx,_txt,' value ptr -> ',0,_struc_dword,_eol
 db _cx,_txt,' mask ptr -> ',0,_struc_dword,_eol
 db _dx,_txt,' size',0,_eol
 db _si,_txt,' addr',0,_eol
 db _di,_txt,' flags',0,_eol
 db _end

set_mempolicy:         ; set NUMA memory policy for a process
 db 'set_mempolicy',0         ; set NUMA memory policy for a process
 dd p_generic		;process
 db _bx,_txt,' policy',0,_eol
 db _cx,_txt,' bit field ptr -> ',0,_struc_dword,_eol
 db _dx,_txt,' bit count',0,_eol
 db _end

mq_open:               ; create a new POSIX message queue or open an existing queue
 db 'mq_open',0               ; create a new POSIX message queue or open an existing queue
 dd p_generic		;process
 db _end

mq_unlink:             ; 
 db 'mq_unlink',0             ; 
 dd p_generic		;process
 db _end

mq_timedsend:          ; 
 db 'mq_timedsend',0          ; 
 dd p_generic		;process
 db _end

mq_timedreceive:       ; 
 db 'mq_timedreceive',0       ; 
 dd p_generic		;process
 db _end

mq_notify:             ; enable/disable notifications for POSIX message queues
 db 'mq_notify',0             ; enable/disable notifications for POSIX message queues
 dd p_generic		;process
 db _end

mq_getsetattr:         ; get or set message queue attributes
 db 'mq_getsetattr',0         ; get or set message queue attributes
 dd p_generic		;process
 db _end

kexec_load:            ; 
 db 'kexec_load',0            ; 
 dd p_generic		;process
 db _end

waitid:                ; suspend execution of the current process until a child has changed state
 db 'waitid',0                ; suspend execution of the current process until a child has changed state
 dd p_generic		;process
 db _bx,_txt,' flag',0,_eol
 db _cx,_txt,' pid',0,_eol
 db _dx,_txt,' siginfo struc ptr',0,_eol
  db _txt,'   signo=',0,_struc_dword,_eol
  db _txt,'   code =',0,_struc_dword,_eol
  db _txt,'   error =',0,_struc_dword,_eol
 db _si,_txt,' state',0,_eol
 db _di,_txt,' ?',0,_eol
 db _end

add_key:               ; creates a new key and add it to the nominated keyring
 db 'add_key',0               ; creates a new key and add it to the nominated keyring
 dd p_generic		;process
 db _bx,_txt,' type ptr -> ',0,_struc_dword,_eol
 db _cx,_txt,' desc ptr -> ',0,_struc_dword,_eol
 db _dx,_txt,' payload string ptr -> ',0,_buf2,_eol
 db _si,_txt,' payload size',0,_eol
 db _di,_txt,' serial#',0,_eol
 db _end

keyctl:                ; kernel's key management facility manipulation functions
 db 'keyctl',0                ; kernel's key management facility manipulation functions
 dd p_key		;process
; db _bx,_txt,' operation',0,_eol
; db _cx,_txt,' p1',0,_eol
; db _dx,_txt,' p2',0,_eol
; db _si,_txt,' p3',0,_eol
; db _di,_txt,' p4',0,_eol
; db _end

ioprio_set:            ; set the I/O scheduling class and priority of one or more processes
 db 'ioprio_set',0            ; set the I/O scheduling class and priority of one or more processes
 dd p_generic		;process
 db _bx,_txt,' operation',0,_eol
 db _cx,_txt,' ID',0,_eol
 db _dx,_txt,' mask',0,_eol
 db _end

ioprio_get:            ; get the I/O scheduling class and priority of one or more processes
 db 'ioprio_get',0            ; get the I/O scheduling class and priority of one or more processes
 dd p_generic		;process
 db _bx,_txt,' op',0,_eol
 db _cx,_txt,' priority base',0,_eol
 db _end

inotify_init:          ; initialize a new inotify instance 
 db 'inotify_init',0          ; initialize a new inotify instance 
 dd p_generic		;process
 db _end

inotify_add_watch:     ; add a watch to or modify an existing watch of an initialized inotify instance
 db 'inotify_add_watch',0     ; add a watch to or modify an existing watch of an initialized inotify instance
 dd p_generic		;process
 db _bx,_txt,' fd',0,_eol
 db _cx,_txt,' path',0,_buf2,_eol
 db _dx,_txt,' mask',0,_eol
 db _end

inotify_rm_watch:      ; removes an existing watch from an inotify instance
 db 'inotify_rm_watch',0      ; removes an existing watch from an inotify instance
 dd p_generic		;process
 db _bx,_txt,' fd',0,_eol
 db _cx,_txt,' watch descriptor',0,_eol
 db _end

openat:                ; opens and possibly creates a file or device relative to a directory file descriptor
 db 'openat',0                ; opens and possibly creates a file or device relative to a directory file descriptor
 dd p_generic		;process
 db _bx,_txt,'  fd',0,_eol
 db _cx,_txt,'  filename',0,_buf2,_eol
 db _dx,_txt,'  flags',0,_eol
 db _si,_txt,'  permissions (0=defaults)',0,_eol
 db _end

mkdirat:               ; create a directory relative to a directory file descriptor
 db 'mkdirat',0               ; create a directory relative to a directory file descriptor
 dd p_generic		;process
 db _bx,_txt,'  fd',0,_eol
 db _cx,_txt,'  create dir',0,_buf2,_eol
 db _dx,_txt,'  premissions',0,_eol
 db _end

mknodat:               ; create a filesystem node relative to a directory file descriptor
 db 'mknodat',0               ; create a filesystem node relative to a directory file descriptor
 dd p_generic		;process
 db _bx,_txt,'  fd',0,_eol
 db _cx,_txt,'  name',0,_buf2,_eol
 db _dx,_txt,'  mode',0,_eol
 db _si,_txt,'  type',0,_eol
 db _end

fchownat:              ; change ownership of a file relative to a directory file descriptor
 db 'fchownat',0              ; change ownership of a file relative to a directory file descriptor
 dd p_generic		;process
 db _bx,_txt,'  fd',0,_eol
 db _cx,_txt,'  path',0,_buf2,_eol
 db _dx,_txt,'  UID',0,_eol
 db _si,_txt,'  GID',0,_eol
 db _end

futimesat:             ; change the access/modification times of an file relative to a directory desriptor
 db 'futimesat',0             ; change the access/modification times of an file relative to a directory desriptor
 dd p_generic		;process
 db _bx,_txt,' descriptor (fd)',0,_eol
 db _cx,_txt,' path ',0,_buf2,_eol
 db _dx,_txt,' timeval ptr -> ',0,_struc_dword,_txt,"=sec",0,_struc_dword,_txt,"=usec",0,_eol
 db _end

unlinkat:              ; remove a directory entry relative to a directory file descriptor
 db 'unlinkat',0              ; remove a directory entry relative to a directory file descriptor
 dd p_generic		;process
 db _bx,_txt,' descriptor (fd)',0,_eol
 db _cx,_txt,' path ',0,_buf2,_eol
 db _dx,_txt,' mask',0,0,_eol
 db _end

renameat:              ; rename a file relative to directory file descriptors
 db 'renameat',0              ; rename a file relative to directory file descriptors
 dd p_generic		;process
 db _bx,_txt,' descriptor (fd)',0,_eol
 db _cx,_txt,' path ',0,_buf2,_eol
 db _dx,_txt,' new descriptor (fd)',0,_eol
 db _si,_txt,' new path ',0,_buf2,_eol
 db _end

linkat:                ; create a file link relative to directory file descriptors
 db 'linkat',0                ; create a file link relative to directory file descriptors
 dd p_generic		;process
 db _bx,_txt,' descriptor (fd)',0,_eol
 db _cx,_txt,' path ',0,_buf2,_eol
 db _dx,_txt,' new descriptor (fd)',0,_eol
 db _si,_txt,' new path ',0,_buf2,_eol
 db _di,_txt,' flags',0,_eol
 db _end

symlinkat:             ; create a symbolic link relative to a directory file descriptor
 db 'symlinkat',0             ; create a symbolic link relative to a directory file descriptor
 dd p_generic		;process
 db _bx,_txt,' path ',0,_buf2,_eol
 db _cx,_txt,' descriptor (fd)',0,_eol
 db _dx,_txt,' link name',0,_buf2,_eol
 db _end

readlink_:              ; reads value of a symbolic link relative to a directory file descriptor
 db 'readlinkat',0              ; reads value of a symbolic link relative to a directory file descriptor
 dd p_generic		;process
 db _bx,_txt,'  fd',0,_eol
 db _cx,_txt,'  path',0,_buf2,_eol
 db _dx,_txt,'  buffer',0,_eol
 db _si,_txt,'  length',0,_eol
 db _end

fchmodat:              ; change S_ISUID, S_ISGID, S_ISVTX, and permission bits of a file 
 db 'fchmodat',0              ; change S_ISUID, S_ISGID, S_ISVTX, and permission bits of a file 
 dd p_generic		;process
 db _bx,_txt,' fd',0,_eol
 db _cx,_txt,' name',0,_buf2,_eol
 db _dx,_txt,' mode',0,_eol
 db _end

faccessat:             ; determine accessibility of a file relative to a directory file descriptor
 db 'faccessat',0             ; determine accessibility of a file relative to a directory file descriptor
 dd p_generic		;process
 db _bx,_txt,' fd',0,_eol
 db _cx,_txt,' name',0,_buf2,_eol
 db _dx,_txt,' mode',0,_eol
 db _end

ppoll:                 ; wait for an event on a file descriptor or until a signal is caught
 db 'ppoll',0                 ; wait for an event on a file descriptor or until a signal is caught
 dd p_generic		;process
 db _bx,_txt,' poll fd array -> ',0,_struc_dword,_txt,'(fd) ',0,_struc_word,_txt,'(event) ',0,_struc_word,_txt,'(revent)',0,_eol
 db _cx,_txt,' num (size of poll fd array)',0,_eol
 db _dx,_txt,' timespec -> ',0,_struc_dword,_txt,'(sec) ',0,_struc_dword,_txt,'(usec)',0,_eol
 db _si,_txt,' mask',0,_eol
 db _end

unshare:               ; allow a process to disassociate parts of its execution context 
 db 'unshare',0               ; allow a process to disassociate parts of its execution context 
 dd p_generic		;process
 db _bx,_txt,' mask',0,_eol
 db _end

sync_file_range:       ; synchronize a file segment with disk  
 db 'sync_file_range',0       ; synchronize a file segment with disk  
 dd p_generic
 db _bx,_txt,' fd',0,_eol
 db _cx,_txt,' offset',0,_eol
 db _dx,_txt,' length',0,_eol
 db _si,_txt,' flags',0,_eol
 db _end

 db 0			;end of table
