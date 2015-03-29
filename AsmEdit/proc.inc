;-------------------------------------------------
; NAME
;  process_search - search through active process's
; INPUTS
;  * eax = either buffer pointer or continue flag
;  * -     if eax = buffer ptr then this is first call
;  * -     -  and searching will begin
;  * -     if eax = 0 this is a continuation call and
;  * -     -  we will search to next match
;  * ebx = buffer size if ptr in eax
;  * ecx = match string (asciiz process name)
; OUTPUT
;  * eax = (if eax negative an error occured)
;  * -     (if eax = 0 then no match found)
;  * -     (if eax positive = ptr to process data (see below)
;  * -    Name:	init
;  * -    State:	S (sleeping)
;  * -    SleepAVG:	90%
;  * -    Tgid:	1
;  * -    Pid:	1
;  * -    PPid:	0
;  * -    TracerPid:	0
;  * -    Uid:	0	0	0	0
;  * -    Gid:	0	0	0	0
;  * -    FDSize:	32
;  * -    Groups:	
;  * -    VmSize:	    1408 kB
;  * -    VmLck:	       0 kB
;  * -    VmRSS:	     496 kB
;  * -    VmData:	     148 kB
;  * -    VmStk:	       4 kB
;  * -    VmExe:	      28 kB
;  * -    VmLib:	    1204 kB
;  * -    Threads:	1
;  * -    SigPnd:	0000000000000000
;  * -    ShdPnd:	0000000000000000
;  * -    SigBlk:	0000000000000000
;  * -    SigIgn:	ffffffff57f0d8fc
;  * -    SigCgt:	00000000280b2603
;  * -    CapInh:	0000000000000000
;  * -    CapPrm:	00000000ffffffff
;  * -    CapEff:	00000000fffffeff
;  * The above data is held in a temporary buffer (lib_buf) and
;  * may be destroyed by other library functions.  All entries of
;  * form xxxx: begin at left edge and are followed by a <tab>.  The
;  * end of each entry is a <0ah> end of line character.  No binary
;  * data is in lib_buf buffer.
; NOTES
;  * source file: process_search.asm
;  * ----------------------------------------------
;
  [section .text]
;
process_search:
  or	eax,eax			;continuation?
  je	ps_40			; jmp if continuation
;  mov	[proc_buf_ptr],eax
;  mov	[proc_buf_size],ebx
  mov	[search_string],ecx
  jmp	short ps_50		;go get next process
;
ps_40:
  xor	eax,eax
ps_50:
  call	process_walk
  or	eax,eax
  jz	ps_exit2		;exit if out of data
  js	ps_exit2		;exit if error  
;
  mov	[process_data_ptr],ecx
  add	ecx,6			;move to name start
  mov	esi,ecx
ps_60:
  cmp	byte [ecx],0ah
  je	ps_70			;jmp if end of name found
  inc	ecx
  jmp	ps_60			;loop till end of name
ps_70:
  mov	byte [ecx],0		;terminate name
  mov	edi,[search_string]
; compare strings
ps_75:
  lodsb
  or	al,al
  jz	ps_80			;jmp if at end of string1
  mov	ah,[edi]
  inc	edi
  cmp	al,ah
  je	ps_75			;loop if matching
  jmp	short ps_40		;jmp if no match
ps_80:
  cmp	byte [edi],0
  jne	ps_40			;jmp if no match
;
ps_exit1:
  mov	eax,[process_data_ptr]	;get match data
ps_exit2:
  ret

;----------------------
  [section .data]

;proc_buf_ptr	dd	0
;proc_buf_size	dd	0
search_string	dd	0

process_data_ptr dd	0


;----------------------------------------------
; NAME
;  process_walk - walk through active process's
; INPUTS
;  * eax = either buffer pointer or continue flag
;  *       if eax = buffer ptr then this is first call
;  *       -  and walking will begin
;  *       if eax = 0 this is a continuation call and
;  *       -  we will walk to next process
;  * ebx = buffer size if ptr in eax
; OUTPUT
;  * eax = number of bytes of data in buffer lib_buf
;  *     - (if eax negative an error occured)
;  *     - (if eax =  zero we are done walking)
;  * ecx = pointer to data in lib_buf (example below)
;  * -    Name:	init
;  * -    State:	S (sleeping)
;  * -    SleepAVG:	90%
;  * -    Tgid:	1
;  * -    Pid:	1
;  * -    PPid:	0
;  * -    TracerPid:	0
;  * -    Uid:	0	0	0	0
;  * -    Gid:	0	0	0	0
;  * -    FDSize:	32
;  * -    Groups:	
;  * -    VmSize:	    1408 kB
;  * -    VmLck:	       0 kB
;  * -    VmRSS:	     496 kB
;  * -    VmData:	     148 kB
;  * -    VmStk:	       4 kB
;  * -    VmExe:	      28 kB
;  * -    VmLib:	    1204 kB
;  * -    Threads:	1
;  * -    SigPnd:	0000000000000000
;  * -    ShdPnd:	0000000000000000
;  * -    SigBlk:	0000000000000000
;  * -    SigIgn:	ffffffff57f0d8fc
;  * -    SigCgt:	00000000280b2603
;  * -    CapInh:	0000000000000000
;  * -    CapPrm:	00000000ffffffff
;  * -    CapEff:	00000000fffffeff
;  * The above data is held in a temporary buffer (lib_buf) and
;  * may be destroyed by other library functions.  All entries of
;  * form xxxx: begin at left edge and are followed by a <tab>.  The
;  * end of each entry is a <0ah> end of line character.  No binary
;  * data is in lib_buf buffer.
;  * Open files are closed when end of process data is signaled by
;  * no more data.  If walk does not reach the end, the open file
;  * handle "proc_handle" should be closed by caller. 
; NOTES
;  * source file: process_walk.asm
;  * ----------------------------------------------
;*******
  [section .text]
;
process_walk:
  or	eax,eax			;continuation?
  je	pw_40			; jmp if continuation
  mov	[proc_buf_ptr],eax
  mov	[proc_buf_size],ebx
;
  mov	ebx,proc_path
  xor	ecx,ecx			;access flags rd_only
  call	file_open		;open /proc
  jns	pw_10			;jmp if open ok
  jmp	pw_exit			;exit if error
pw_10:
  mov	[proc_handle],eax
; get system table, using getdents kernel call
pw_20:
  mov	eax,141
  mov	ebx,[proc_handle]
  mov	ecx,[proc_buf_ptr]
  mov	edx,[proc_buf_size]
  int	80h			;sys_getdents
; returns zero if out of data, else buffer has record
; of form:  dd (inode number)
;           dd (offset from top of table to next record)
;           dw (size of this record)
;           db (name of this entry)
  or	eax,eax
  jnz	pw_continue1		;jmp if data read
  call	file_close
  jmp	short pw_exit		;exit if at end
pw_continue1:
  mov	[bytes_in_buffer],eax	;save read size
  mov	[current_dents_rec_ptr],ecx
;
;look at next record 
;
pw_40:
  cmp	dword [bytes_in_buffer],0
  je	pw_20				;if buffer empty read next
  mov	ebx,[current_dents_rec_ptr]
  mov	al,[ebx+10]			;get first char of name
  call	is_number
  je	pw_continue2			;jmp if entry is a named process
  mov	ax,[ebx+8]
  add	[current_dents_rec_ptr],eax
  sub	[bytes_in_buffer],eax
  jmp	short pw_40			;try next record
 
;
pw_continue2:
  lea	esi,[ebx+10]			;get ptr to name
  mov	edi,proc_append
  call	str_move
  mov	esi,status_append
  call	str_move

  mov	ebx,proc_build
  mov	ecx,lib_buf		;buffer
  mov	edx,600			;buffer size
  call	file_simple_read
; setup for next record
  push	eax
  xor	eax,eax
  mov	ebx,[current_dents_rec_ptr]
  mov	ax,[ebx+8]
  add	[current_dents_rec_ptr],eax
  sub	[bytes_in_buffer],eax
  pop	eax
pw_exit:
  ret

;----------------------
  [section .data]

proc_buf_ptr	dd	0
proc_buf_size	dd	0

  global proc_handle
proc_handle	dd	0

bytes_in_buffer	dd	0
current_dents_rec_ptr	dd	0

proc_path	db	'/proc',0
our_info_file: db "/proc/self"
status_append:	db	"/status",0

proc_build:	db	'/proc/'
proc_append:	times   20 db 0

  [section .text]
;****f* str/str_move *
;
; NAME
;  str_move - move asciiz string
; INPUTS
;  * esi = input string ptr (asciiz)
;  * edi = destination ptr
; OUTPUT
;  * edi points at zero (end of moved asciiz string)
; NOTES
;  * file str_move.asm
;  * ----------------------------------------------
;*******
  global str_move
str_move:
  cld
ms_loop:
  lodsb
  stosb
  or	al,al
  jnz	ms_loop	;loop till done
  dec	edi
  ret
;----------------------------------------------------
; NAME
;  file_open - open named file
; INPUTS
;  * ebx = ptr to full file path
;  * ecx = access flags
;  *   O_ACCMODE         0003
;  *   O_RDONLY          00
;  *   O_WRONLY          01
;  *   O_RDWR            02
;  *   O_CREAT           0100
;  *   O_EXCL            0200
;  *   O_NOCTTY          0400
;  *   O_TRUNC           01000
;  *   O_APPEND          02000
;  *   O_NONBLOCK        04000
;  *   O_NDELAY          O_NONBLOCK
;  *   O_SYNC            010000 specific to ext2 fs and block devices
;  *   FASYNC            020000 fcntl, for BSD compatibility
;  *   O_DIRECT          040000 direct disk access hint-currently ignored
;  *   O_LARGEFILE       0100000
;  *   O_DIRECTORY       0200000 must be a directory
;  *   O_NOFOLLOW        0400000 don't follow links;
;  * edx = permissions used if file created
;  *   S_ISUID           04000 set user ID on execution
;  *   S_ISGID           02000 set group ID on execution
;  *   S_ISVTX           01000 sticky bit
;  *   S_IRUSR           00400 read by owner(S_IREAD)
;  *   S_IWUSR           00200 write by owner(S_IWRITE)
;  *   S_IXUSR           00100 execute/search by owner(S_IEXEC)
;  *   S_IRGRP           00040 read by group
;  *   S_IWGRP           00020 write by group
;  *   S_IXGRP           00010 execute/search by group
;  *   S_IROTH           00004 read by others
;  *   S_IWOTH           00002 write by others
;  *   S_IXOTH           00001 execute/search by others
; OUTPUT
;  * eax = negative if error (error number)
;  * eax = positive file handle if success
;  *       flags are set for js jns jump
; NOTES
;  * file:  file_basics.asm
;  * ----------------------------------------------
;
file_open:			;entry for other opens
  mov	eax,5
  int	80h
  or	eax,eax
  ret

;----------------------------------------------
; NAME
;  file_close - close opened file
; INPUTS
;  * ebx = file handle (file descriptor)
; OUTPUT
;  * eax = negative if error (error number)
;  *       flag bits set for js jns jumps
; NOTES
;  * file:  file_basics.asm
;  * ----------------------------------------------
;
  global file_close
file_close:
  mov	eax,6
  int	80h
  or	eax,eax
  ret

;---------------------------------------------
; NAME
;  fileRead - read n bytes from open file
; INPUTS
;  * ebx = file descriptor (handle)
;  * edx = buffer  size
;  * ecx = buffer ptr
; OUTPUT
;  * eax contains a negative error code or
;  * -   a positive count of bytes read.
; NOTES
; * file: file_basics.asm
; * ----------------------------------------------
;
  global fileRead
fileRead:
  mov	eax,3			;read file
  int	80h			;go read file
  or	eax,eax
  ret

;----------------------------------
; NAME
;  fileWrite - write n bytes to open file
; INPUTS
;  * ebx = file descriptor (handle)
;  * edx = number of bytes to write
;  * ecx = buffer ptr
; OUTPUT
;  * eax contains a negative error code or
;  * -   a positive count of bytes written
; NOTES
; * file: file_basics.asm
; * ----------------------------------------------
;
  global fileWrite
fileWrite:
  mov	eax,4			;write file
  int	80h			;go write file
  or	eax,eax
  ret
;-------------------------------------
; NAME
;  file_simple_read - open & read file to buffer, then close
; INPUTS
;  * ebx = ptr to full path for file.
;  * edx = buffer  size
;  * ecx = buffer ptr
; OUTPUT
;  * eax contains a negative error code or
;  * -   a positive count of bytes read
;  * -   the sign bit is set for js/jns 
; NOTES
; * file: file_basics.asm
; * ----------------------------------------------
;
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
  call	fileRead
  push	eax
  call	file_close
  pop	eax
fsr_exit:
  or	eax,eax
  ret


;--------------------------------
; NAME
;  is_number - check if ascii number
; INPUTS
;  * al = ascii char
; OUTPUT
;  * eq flag set for je if alpha
; NOTES
; * file: /key_mouse/key_decode.asm
; * ----------------------------------------------
;
is_number:
  cmp	al,'0'
  jb	not_number
  cmp	al,'9'
  ja	not_number
  cmp	al,al
not_number:
  ret

