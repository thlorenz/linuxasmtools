
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
;****f* asmedit/a_error *
; NAME
;>1 plugin
;  show_sys_err - display error messages
; INPUTS
;    usage:  show_sys_err <error number>
; OUTPUT
;    show_sys_err displays a message and waits
;    for key press.
; NOTES
;   file: show_sys_err.asm
;   This program called by AsmEdit to display error
;   information.
;
; example:  error 1
;
; The kernel error numbers are built in, and passing a number
; will show text for each error number.   
;<
; * ----------------------------------------------
;*******
;  
 [section .text]

global	_start

_start:
main:
  cld

  mov	edi,message_buffer2
  pop	eax			;get parameter count
  pop	ebx			;get pointer to program name
  cmp	al,1
  ja	parameter_entered
  mov	dword [error_number],0
  mov	al,'0'
  stosb				;put 0 in message
  mov	al,0ah
  stosb
  jmp	lookup_msg
	
parameter_entered:
  pop	esi
  push	esi
er_lp1:
  lodsb
  stosb
  or	al,al
  jnz	er_lp1			;loop till error# moved
  mov	al,0ah
  mov	byte [edi -1],al
;
; move error text to message
;
  pop	esi
  call	ascii_to_decimal
  or	ecx,ecx
  jns	save_error
  neg	ecx
save_error:
  mov	[error_number],ecx	;save error number
;
; scan messages to find error text
;
lookup_msg:
  mov	esi,error_table
  mov	ebx,[error_number]	;entered by caller
  xor	ecx,ecx			;error count
error_scan:
  cmp	ecx,ebx			;are we at error text
  je	have_message		;jmp if message found
scan_lp1:
  lodsb
  or	al,al
  jnz	scan_lp1		;loop till end of message
  cmp	byte [esi],0		;end of table
  je	bad_error_number	;jmp if message not in table
  inc	ecx			;bump message counter
  jmp	error_scan		;continue error scan

bad_error_number:
  mov	esi,error_table
;
; esi points at error message
; edi points at storage point in message_buffer
;
have_message:
  lodsb
  stosb
  or	al,al
  jnz	have_message
;
  mov	byte [edi -1],0ah
;
; now move wait for key message
;
  mov	esi,wait_msg
er_lp2:
  lodsb
  stosb
  or	al,al
  jnz	er_lp2

  mov	ecx,message_buffer
  call	display_asciiz
;
; read one key
;
  mov	eax,3			;read
  mov	ebx,1			;stdin
  mov	ecx,message_buffer	;buffer
  mov	edx,1			;buffer length
  int	80h
;
; exit
;
  mov	eax,1
  mov	ebx,0
  int	80h  


;-------------------------------
; display_asciiz - output string
;  input: ecx - ponter to string
;
	%define stdout 0x1
	%define stderr 0x2

display_asciiz:
  xor edx, edx
.count_again:	
  cmp [ecx + edx], byte 0x0
  je .done_count
  inc edx
  jmp .count_again
.done_count:	
  mov eax, 0x4			; system call 0x4 (write)
  mov ebx, stdout			; file desc. is stdout
  int 0x80
  ret
;-----------------------------------
; convert ascii to decimal
;  input: esi = ptr to asciiz
;  output; ecx = integer

ascii_to_decimal:
  mov	ecx,0
  mov	bl,9
  cld
atd_lp:
  lodsb
  sub al,'0'
  js atd_exit
  cmp al,bl
  ja atd_exit
  lea ecx,[ecx+4*ecx]
  lea ecx,[2*ecx+eax]
  jmp short atd_lp
atd_exit:
  ret
  

;*********************************************************************
 [section .data]

message_buffer	db	0ah,0ah,'Error Number #'
message_buffer2 times 200 db 0
wait_msg	db	'Press <Enter> key to continue',0ah,0ah,0

error_number	dd	0	;parameter $1


error_table:
 db "no error number provided",0 ;		 0
 db "Operation not permitted",0 ;EPERM		 1	
 db "No such file or directory",0 ;ENOENT	 2	
 db "No such process",0 	 ;ESRCH		 3	
 db "Interrupted system call",0 ;EINTR		 4	
 db "I/O error",0 		 ;EIO		 5	
 db "No such device or address",0 ;ENXIO	 6	
 db "Arg list too long",0 	 ;E2BIG		 7	
 db "Exec format error",0 	 ;ENOEXEC	 8	
 db "Bad file number",0 	 ;EBADF		 9	
 db "No child processes",0 	 ;ECHILD	10	
 db "Try again",0 	 ;EAGAIN		11	
 db "Out of memory",0 	 ;ENOMEM		12	
 db "Permission denied",0  ;EACCES		13	
 db "Bad address",0 	 ;EFAULT		14	
 db "Block device required",0 ;ENOTBLK		15	
 db "Device or resource busy",0 ;EBUSY		16	
 db "File exists",0 		;EEXIST		17	
 db "Cross-device link",0 	 ;EXDEV		18	
 db "No such device",0 	 ;ENODEV		19	
 db "Not a directory",0  ;ENOTDIR		20	
 db "Is a directory",0  	;EISDIR		21	
 db "Invalid argument",0 	;EINVAL		22	
 db "File table overflow",0 ;ENFILE		23	
 db "Too many open files",0 ;EMFILE		24	
 db "Not a typewriter",0 	;ENOTTY		25	
 db "Text file busy",0  ;ETXTBSY		26	
 db "File too large",0 		 ;EFBIG		27	
 db "No space left on device",0 ;ENOSPC		28	
 db "Illegal seek",0 	 ;ESPIPE		29	
 db "Read-only file system",0 ;EROFS		30	
 db "Too many links",0 	 ;EMLINK		31	
 db "Broken pipe",0 		 ;EPIPE		32	
 db "Math argument out of domain of func",0 ;EDOM 33	
 db "Math result not representable",0 ;ERANGE	34	
 db "Resource deadlock would occur",0 ;EDEADLK	35	
 db "File name too long",0  ;ENAMETOOLONG	36	
 db "No record locks available",0 ;ENOLCK	37	
 db "Function not implemented",0 ;ENOSYS	38	
 db "Directory not empty",0 	;ENOTEMPTY	39	
 db "Too many symbolic links encountered",0 ;ELOOP 40	
 db "Operation would block",0 ;EWOULDBLOCK	41	
 db "No message of desired type",0 ;ENOMSG	42	
 db "Identifier removed",0 ;EIDRM		43	
 db "Channel number out of range",0 ;ECHRNG	44	
 db "Level 2 not synchronized",0 ;EL2NSYNC	45	
 db "Level 3 halted",0	 ;EL3HLT		46	
 db "Level 3 reset",0	 ;EL3RST		47	
 db "Link number out of range",0 ;ELNRNG	48	
 db "Protocol driver not attached",0 ;EUNATCH	49	
 db "No CSI structure available",0 ;ENOCSI	50	
 db "Level 2 halted",0 ;EL2HLT		51	
 db "Invalid exchange",0 ;EBADE		52	
 db "Invalid request descriptor",0 ;EBADR	53	
 db "Exchange full",0 ;EXFULL		54	
 db "No anode",0 ;ENOANO		55	
 db "Invalid request code",0 ;EBADRQC		56	
 db "Invalid slot",0 ;EBADSLT		57	
 db "Resource deadlock would occur",0 ;EDEADLK	58	
 db "Bad font file format",0 ;EBFONT		59	
 db "Device not a stream",0 ;ENOSTR		60	
 db "No data available",0 ;ENODATA		61	
 db "Timer expired",0 ;ETIME		62	
 db "Out of streams resources",0 ;ENOSR		63	
 db "Machine is not on the network",0 ;ENONET	64	
 db "Package not installed",0 ;ENOPKG		65	
 db "Object is remote",0 ;EREMOTE		66	
 db "Link has been severed",0 ;ENOLINK		67	
 db "Advertise error",0 ;EADV		68	
 db "Srmount error",0 ;ESRMNT		69	
 db "Communication error on send",0 ;ECOMM	70	
 db "Protocol error",0 ;EPROTO		71	
 db "Multihop attempted",0 ;EMULTIHOP	72	
 db "RFS specific error",0 ;EDOTDOT		73	
 db "Not a data message",0 ;EBADMSG		74	
 db "Value too large for defined data type",0 ;EOVERFLOW	75	
 db "Name not unique on network",0 ;ENOTUNIQ	76	
 db "File descriptor in bad state",0 ;EBADFD	77	
 db "Remote address changed",0 ;EREMCHG		78	
 db "Can not access a needed shared library",0 ;ELIBACC		79	
 db "Accessing a corrupted shared library",0 ;ELIBBAD		80	
 db ".lib section in a.out corrupted",0 ;ELIBSCN		81	
 db "Attempting to link in too many shared libraries",0 ;ELIBMAX		82	
 db "Cannot exec a shared library directly",0 ;ELIBEXEC	83	
 db "Illegal byte sequence",0 ;EILSEQ		84	
 db "Interrupted system call should be restarted",0 ;ERESTART	85	
 db "Streams pipe error",0 ;ESTRPIPE	86	
 db "Too many users",0 ;EUSERS		87	
 db "Socket operation on non-socket",0 ;ENOTSOCK	88	
 db "Destination address required",0 ;EDESTADDRREQ	89	
 db "Message too long",0 ;EMSGSIZE	90	
 db "Protocol wrong type for socket",0 ;EPROTOTYPE	91	
 db "Protocol not available",0 ;ENOPROTOOPT	92	
 db "Protocol not supported",0 ;EPROTONOSUPPORT	93	
 db "Socket type not supported",0 ;ESOCKTNOSUPPORT	94	
 db "Operation not supported on transport endpoint",0 ;EOPNOTSUPP	95	
 db "Protocol family not supported",0 ;EPFNOSUPPORT	96	
 db "Address family not supported by protocol",0 ;EAFNOSUPPORT	97	
 db "Address already in use",0 ;EADDRINUSE	98	
 db "Cannot assign requested address",0 ;EADDRNOTAVAIL	99	
 db "Network is down",0 ;ENETDOWN	100	
 db "Network is unreachable",0 ;ENETUNREACH	101	
 db "Network dropped connection because of reset",0 ;ENETRESET	102	
 db "Software caused connection abort",0 ;ECONNABORTED	103	
 db "Connection reset by peer",0 ;ECONNRESET	104	
 db "No buffer space available",0 ;ENOBUFS		105	
 db "Transport endpoint is already connected",0 ;EISCONN		106	
 db "Transport endpoint is not connected",0 ;ENOTCONN	107	
 db "Cannot send after transport endpoint shutdown",0 ;ESHUTDOWN	108	
 db "Too many references: cannot splice",0 ;ETOOMANYREFS	109	
 db "Connection timed out",0 ;ETIMEDOUT	110	
 db "Connection refused",0 ;ECONNREFUSED	111	
 db "Host is down",0 ;EHOSTDOWN	112	
 db "No route to host",0 ;EHOSTUNREACH	113	
 db "Operation already in progress",0 ;EALREADY	114	
 db "Operation now in progress",0 ;EINPROGRESS	115	
 db "Stale NFS file handle",0 ;ESTALE		116	
 db "Structure needs cleaning",0 ;EUCLEAN		117	
 db "Not a XENIX named type file",0 ;ENOTNAM		118	
 db "No XENIX semaphores available",0 ;ENAVAIL		119	
 db "Is a named type file",0 ;EISNAM		120	
 db "Remote I/O error",0 ;EREMOTEIO	121	
 db "Quota exceeded",0 ;EDQUOT		122	
 db "No medium found",0 ;ENOMEDIUM	123	
 db "Wrong medium type",0 ;EMEDIUMTYPE	124	
; system errors end here. program errors begin
 db 'Data file corrupted',0	;	125
 db 'use -Add- to create entry',0 ;	126
 db 'Segmentation - memory access signal',0 ;127
 db 'Segmentation - INTO instruction signal',0  ;128
 db 'Segmentation - BOUND instruction signal',0 ;129
 db 'SIGTRAP - trace breakpoint signal',0 ;130
 db 'SIGTRAP - breakpoint set signal',0 ;131
 db 'SIGILL - Illegal opcode signal',0 ;132
 db 'SIGILL - Illegal operand signal',0 ;133
 db 'SIGILL - Illegal addressing signal',0 ;134
 db 'SIGILL - Illegal trap signal',0 ;135
 db 'SIGILL - privileged opcode signal',0 ;136
 db 'SIGILL - privileged register signal',0 ;137
 db 'SIGILL - coprocessor error signal',0 ;138
 db 'SIGILL - stack error signal',0 ;139
 db 'SIGFPE - integer divide by zero signal',0 ;140
 db 'SIGFPE - integer overflow signal',0  ;141
 db 'SIGFPE - floating point divide by zero signal',0 ;142
 db 'SIGFPE - floating point overflow signal',0 ;143
 db 'SIGFPE - floating point underflow signal',0 ;144
 db 'SIGFPE - floating point inexact signal',0 ;145
 db 'SIGFPE - floating point invalid signal',0 ;146
 db 'SIGFPE - floating subscript out of range signal',0 ;147
 db 0	;end of table
