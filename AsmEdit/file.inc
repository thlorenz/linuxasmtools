;**********************  file.inc ****************************
;
; Before utilizing these functions the following setup is
; required:
;  1. the [base] pointer needs to be created and must point at
;     our work directory
;  2. the variables file_end_ptr and editbuf_end need to exist
;  3. the routines move_asciiz, make_hole, and find_home need to exist.
;
;-------------------
; [section .data]
;env_ptr	dd	0
base	dd	base_dir
base_dir db	'/usr/share/asmedit/',0
; [section .text]
;------------------


;---------
 [section .bss]
fname_ptr	resd	1	;callers file name
fbuffer_ptr	resd	1	;callers buf ptr
fflag		resb	1	;callers flags
;file_end_ptr	resd	1	;end of data in buffer
;fbuf_segment_end	resd	1	;end of buffer
path_buf	resb	300	;buffer to build full path to file
file_len	resd	1	;lenght of file read
file_handle	resd	1	;handle of read file
 [section .text]

 [section .text]

;---------------------------------------------------------
; save_file_parms - save entry condition
;  inputs: eax = filename ptr
;          ebx = buffer
;          dl  = flags
; output: sets edi = path_buf
;
save_file_parms:
 mov	[fname_ptr],eax	;save file name
  mov	[fbuffer_ptr],ebx		;save lenght of buffer
  mov	[fflag],dl
  mov	edi,path_buf
  ret

;********************************************************
; file_write - write file and close
;  input: eax = file name ptr           
;         ebx = buffer
;         ecx = lenght of write
;          dl = flags 0000 0001 - write to local directory or full path if given
;                     0000 0010 - write to $HOME/[base] or full path if given
;                     0000 0100 - check for existing file and preserve attributes
;                     0000 1000 - file attributes are in ebp
; 
;     if bit 2 (0000 0010) is set we also need to provide a pointer to the
;        base directory name.  [base]
;
;  output:  eax = 0 or + normal
;               = -x error occured
; 
file_write:
  mov	[file_len],ecx		;save buffer to write
  call	save_file_parms
  
  cmp	byte [eax],'/'		;check if full path provided
  jne	fw_02			; jmp if partial path
  mov	esi,eax			;get file name ptr
  call	move_asciiz
  jmp	fw_20			; jmp if full path

fw_02:
  test	dl,01h			;check if file in current dir
  jnz	fw_10			; jmp if file in current dir
;
; file not local, so must be in $HOME, search path for $HOME
;
fw_05:
  call	build_homebase
  js	fw_exit
  jmp	fw_20
;
; file is local (current dir) , ask kernel for our location.
;
fw_10:
  call	build_current_path
  js	fw_exit			;jmp if error
;
; path_buf now has the full path of our file
;
fw_20:
  mov	edx,666q		;preload file permissions
  test	byte [fflag],04h	;do we need to look for existing file
  jnz	fw_22			;jmp if no checks needed
  test	byte [fflag],08h
  jz	fw_30			;jmp if attributes not provided in ebp
  mov	edx,ebp
  jmp	fw_30
;
; check for existing file and get attributes
;
fw_22:
  mov	eax,107
  mov	ebx,path_buf
  mov	ecx,fstatbuf
  int	80h
  or	eax,eax
  js	fw_30			;jmp if this is a new file
  mov	edx,[st_mode]
  and	edx,777q		;file permisions

;  mov	eax,[st_mtime]
;  mov [accesstime+utimbuf_struc.modtime],eax

;
; file permissions  in edx, open file
;
fw_30:
  mov	ecx,1102q		;access bits create, truncate
  call	open_file
  or	eax,eax
  js	fw_exit		;jmp if error

  mov	ebx,eax			;move file descriptor to ebx
  mov	ecx,[fbuffer_ptr]	;ptr to buffer
  mov	edx,[file_len]		;get file lenght
  mov	eax,4			;write file
  int	80h
  or	eax,eax
  js	fw_exit			;jmp if error
  mov	eax,6			;close file code
  int	80h			;
fw_exit:
  ret

;--------------------------------------------------------
; file_read - read file from disk
;
; inputs: eax = pointer to file name
;         ebx = buffer pointer or insert point in editbuf
;         dl  = file_flag        (0000 0000) = full path provided
;                          bit 1 (0000 0001) = full path or local file
;                          bit 2 (0000 0010) = full path or file at $HOME/[base]
;                                (base is global pointer to string)
;                          bit 3 (0000 0100) = create file if missing
;                                (eax must = ptr to full path of file)
;                          bit 4 (0000 1000) = simple file, non-expanding.
;                          bit 5 (0001 0000) = insert data into expanding editbuf (see notes)
;                          bit 6 (0010 0000) = fill expanding editbuf (see notes)
;
;           notes:  if bits 5 or 6 are set, then global variables are used
;                   as follows:
;                    editbuf = name of buffer
;                    [file_end_ptr] = pointer to character past last character
;                                     read from file.  First non-insert initializes this
;                    [fbuf_segment_end] = ponter to last available location in fbuf.
;                                    (needs to be initialized externally)
;
;         if bit 2 is set a pointer to stack env pointers is needed, [env_ptr]
;                  and the [base] pointer is used to find $HOME/[base]/file
;
;         if bits 1 & 2 set, both are checked starting with local first.  A full
;                  path will always be checked before bits 1 and 2
;
;         if create bit is set and bits 1 and 2 are set.  It will create the file
;                  locally.
;
; output: eax = file length if no errors, created files have length of zero
;               -xxx if error code from kernel
;               -2   if file not found
;         ebp = file attributes if eax contains file length
;         sign bit set on exit for js/jns instruction.
;
;-------------------------------------------------------------------------

file_read:
  call	save_file_parms
  cmp	byte [eax],'/'		;check if full path provided
  je	fr_20			; jmp if full path
  test	dl,01h			;check if file in current dir
  jnz	fr_10			; jmp if file in current dir
;
; file not local, so must be in $HOME, search path for $HOME
;
fr_05:
  call	build_homebase
  js	fr_24b			;jmp if error
  jmp	fr_22
;
; file is local (current dir) , ask kernel for our location.
;
fr_10:
  call	build_current_path
  js	fr_24b			;jmp if error
;
; path_buf now has the full path of our file
; check if file exists
;
  call	open_read_only
  jns	fr_get_len	;jmp if file exists
;
; check if create needed
;
  test	byte [fflag],04h	;check if create specified
  jnz	fr_25			; jmp if create needed
;
; file is not local, check if $HOME/[base] bit set
;
  test	byte [fflag],2
  jz	fr_24a		;jmp if file not found and create bit not set
  mov	edi,path_buf
  jmp	fr_05		;go check in $HOME/[base]
;
; edi = pointer into filename build buffer
;
fr_20:
  mov	esi,[fname_ptr]
  call	move_asciiz
;
; path_buf now has the full path of our file
; check if file exists
;
fr_22:
  call	open_read_only
  jns	fr_get_len	;jmp if file exists
;
; file does not exist, check if create bit set
;
fr_24:
  test	byte [fflag],04h	;check if create specified
  jnz	fr_25			; jmp if create needed
fr_24a:
  mov	eax,-2			;indicate file not found
fr_24b:
  jmp	fr_exit			; jmp if not allowed to create file
;
; we need to create this file
;
fr_25:
  mov ecx, 1101q	;get create flags, WRONLY,CREAT,TRUNC
  mov	edx,644q	;file permisions
  call	open_file
  js	fr_exitx	;exit with error code in eax
  mov	ebx,eax		;move handle to ebx
  xor	eax,eax		;indicate file created
  mov	ebp,644q	;put attributes in ebp
  jmp	fr_close_file	;go close file and exit
;
; we have found the file and opened it.  The file descriptor is in eax
;
fr_get_len:
  mov	[file_handle],eax	;save file handle
  call file_length			;returns eax=length-of-file ebx=handle
  js	fr_exitx		;exit if error code returned in eax
  mov	[file_len],eax		;;save lenght of read
  test	byte [fflag],08h	;check if simple file
  jnz	fr_read			;jmp if simple file read, no checks
;
; compute buffer size needed to read file
;
  mov	ebx,[editbuf_ptr]
  test	byte [fflag],10h	;check if insert
  jz	fr_30			;jmp if not insert
  mov	ebx,[file_end_ptr]	;get starting point for insert
fr_30:
  add	ebx,eax			;compute new file end point
  add	ebx,32000		;add in work space
  cmp	ebx,[editbuf_end]	;check if room in buffer
  jb	fr_40			;jmp if room in buffer
;
; we need a bigger buffer, try to expand buffer
;
  mov	eax,45			;extend segment to address in ebx
  int	80h			;  call SysBrk
  or	eax,eax
fr_exitx:
  js	fr_exit			;jmp if error
  mov	[editbuf_end],ebx
;
; we have room in buffer, now check if insert or normal read
;
fr_40:
  test	byte [fflag],10h	;check if insert
  jz	fr_read			; jmp if not insert
  mov	eax,[file_len]		;get file lenght
  mov	edi,[fbuffer_ptr]	;get insert point for data
  call make_hole

fr_read:
  mov	eax,3			;read file
  mov	ebx,[file_handle]	;open file handle
  mov	ecx,[fbuffer_ptr]	;buffer
  mov	edx,[file_len]		;lenght of read
  int	80h			;go read file
  or	eax,eax
  js	fr_close_file		;jmp if error
;
; get file attributes
;
  push	eax		;save read error code
  mov	eax,108
  mov	ecx,fstatbuf
  int	80h
  or	eax,eax
  js	fr_skip		;skip attribute save if error
  xor	eax,eax
  mov	ax,[st_mode]
  and	ax,777q
  mov	ebp,eax
fr_skip:
  pop	eax
;
; eax = exit code   ebx = file descriptor
;  
fr_close_file:
  push	eax
  mov	eax,6
  int	80h		;close file
  pop	eax		;restore error code from read
;
; if bits 5 or 6 set put do extra processing ?
;
fr_exit:
  or	eax,eax		;set sign bit
  ret  
;--------------------------------------
; input: edi = pointer into path_buf
; output:  eax = 0 and no sign bit = path_buf has path minus our file name
;          eax = -x error , sigh bit set
;
build_homebase:
  call	find_home		;get $HOME directory
  js	fw_18			;jmp if error
;  mov	al,'/'
;  stosb
  mov	esi,[base]
  call	move_asciiz
  jmp	fw_16			;go add file name

;--------------------------------------
; input: [fname_ptr] has file name
; output: eax = 0 & no sign bit set = path_buf has path plus our file name
;         eax = -x and sign bit set = error
;
build_current_path:
  mov	ebx,path_buf		;get pointer to path_buf
  mov	ecx,300			;size of buffer
  mov	eax,183			;kernel call - get default dir
  int	80h
  or	eax,eax
  js	fw_18			;jmp if error
;
; move edi forward to end of our current dir name
;
  mov	edi,ebx			;move path_buf start to edi
fw_15:
  inc	edi
  cmp	byte [edi],0
  jne	fw_15
; entry point for build_homebase
fw_16:
  mov	al,'/'
  stosb
;
; edi = pointer into filename build buffer
;
  mov	esi,[fname_ptr]
  call	move_asciiz
  xor	eax,eax
fw_18:
  ret
;------------------------------------------------
; file_length to end of file and return end ptr
;  input: ebx = filehandle
; output: eax = + file length
;               - error number 
;
file_length:
  xchg ebx,eax
  push byte 2
  pop edx
  xor ecx,ecx
  mov eax,19
  int 80h
  or	eax,eax
  js fl_exit
  xor edx,edx
  push eax		;save file length
  xor	ecx,ecx
  mov	eax,19
  int	80h		;seek to start of file
  pop eax		;restore file length
fl_exit:
  ret


;-------------------------------------------------------
; input:  path_buf = file name
; output:  eax = + file handle
;                - error number
;
open_read_only:
  mov	eax,33			;access kernel call
  mov	ebx,path_buf
  mov	ecx,4  			;check for read permission
  int	80h
  or	eax,eax
  js	of_exit			;exit if file does not exist
  xor	ecx,ecx
open_file:			;entry for other opens
  mov	ebx,path_buf
  mov	eax,5
  int	80h
  or	eax,eax
of_exit:
  ret

;--------------------------------------------------------------------
; find_home - find home varialbe
;  input:  edi = buffer pointer to save $HOME
; output:  eax = 0 success & no sign bit set
;          eax = -x error and sign bit set
;
find_home:
  mov	ebx,[enviro_ptrs]
fh_10:
  or	ebx,ebx
  jz	fh_50		;jmp if home path not found
  mov	esi,[ebx]
  or	esi,esi
  jz	fh_50		;jmp if home path not found
  cmp	dword [esi],'HOME'
  jne	fh_12		;jmp if not found yet
  cmp	byte [esi + 4],'='
  je	fh_20		;jmp if HOME found
fh_12:
  add	ebx,byte 4
  jmp	fh_10		;loop  back and keep looking
;
; we have found HOME
;
fh_20:
  add	esi,byte 5		;move to start of home path
;
; assume edi points at execve_buf
;
fh_30:
  call	move_asciiz
  xor	eax,eax
  jmp	fh_60
fh_50:
  mov	eax,-2
  or	eax,eax			;set sign bit
fh_60:
  ret  

;-------------------------------------------------------------
 [section .bss]
		
fstatbuf:
fstat_buf:
st_dev: resd	1
st_ino: resd 1
st_mode: resw 1
st_nlink: resw 1
st_uid: resw 1
st_gid: resw 1
st_rdev: resd 1
st_size: resd 1
st_blksize: resd 1
st_blocks: resd 1
st_atime: resd 1
__unused1: resd 1
st_mtime: resd 1
__unused2: resd 1
st_ctime: resd 1
__unused3: resd 1
__unused4: resd 1
__unused5: resd 1

 [section .text]
