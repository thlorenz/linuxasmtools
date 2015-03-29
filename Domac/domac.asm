
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
;------------------ domac ---------------------------
%include "token.inc"

;
; input:  domac <cmd-file> <infile+file mask> <outdir>
;         where:
;                <ctrl-file> = name of file with control langage
;                <infile> = name of input data file or mask
;                           using "*" in front or back of name.
;                           (optional) 
;                <outdir>   name of output directory
;                           "." is current dir, ".." is previous
;                           If not present "out" is assumed.
;
;        note: if infile or outfile parameters are not wanted
;              use "-" as filler.
;
  extern env_stack
  extern m_setup
  extern crt_str
  extern file_length_name
  extern m_allocate
  extern block_read_all
  extern block_write_all
  extern str_move
  extern sys_shell_cmd
  extern blk_find
;  extern blk_fdel_bytes
;  extern blk_finsert_bytes
;  extern blk_fmake_hole
%include "blk_fill_pkg.inc"
  extern dword_to_ascii
;  extern dir_walk
%include "dir_walk.inc"
  extern dir_current
  extern m_release
  extern ascii_to_dword
  extern list_get_from_front
  extern list_put_at_front
  extern crt_write
;  extern blk_freplace_all
%include "blk_freplace.inc"
  extern dir_status
  extern dir_create

global _start
_start:
  cld
  call	env_stack		;save stack enviornment ptr

  call	m_setup			;setup the memory manager
  call	parse_user_parameters	;get file names
  jnc	read_cmds		;jmp if no error
  mov	al,1
  call	report_error_pre
  jmp	domac_exit
read_cmds:
;find size of control file
  mov	ebx,[cmd_filename_ptr]
  call	file_length_name	;return length in eax
  jns	allocate_cmd
  mov	al,2
  call	report_error_pre
  jmp	domac_exit
allocate_cmd:
;allocate memory for control file
  mov	[cmd_buf_length],eax
  mov	[cmd_buf_end_ptr],eax	;start end computation
  call	m_allocate
  mov	[cmd_buf_top_ptr],eax
  mov	[cmd_buf_ptr],eax
  mov	[cmd_buf_restart],eax
  add	[cmd_buf_end_ptr],eax	; end computation
;read command file
  mov	ebx,[cmd_filename_ptr]
  mov	ecx,[cmd_buf_top_ptr]
  mov	edx,[cmd_buf_length]
  call	block_read_all
  jns	recursion_check
  mov	al,3
  call	report_error_pre
  jmp	domac_exit
recursion_check:
  cmp	[infile_mask_ptr],dword 0
  jne	walk_setup
  mov	eax,[infile_path_ptr]
  call	domac_body
  jmp	short domac_exit
walk_setup:
  mov	eax,64000
  call	m_allocate	;returns allocated mem ptr in eax
  mov	esi,[infile_path_ptr]
  mov	ebx,[infile_mask_ptr]
  mov	ch,2		;return masked files
  mov	cl,0		;depth
  mov	edx,domac_body
  call	dir_walk

domac_exit:
  mov	ebx,[domac_err#]
  mov	eax,1
  int	byte 80h
;--------
  [section .data]
cmd_buf_restart:	dd 0	;top of commands
  [section .text]
;----------------------------------------------------------------
;repeat body - called by dir_walk
;----------------------------------------------------------------
;input: eax=ptr to path
;       ecx=ptr to filename at end of path
;output: eax=0 says continue

domac_body:
  mov	esi,[cmd_buf_restart]
  mov	[cmd_buf_ptr],esi	;restart command parse
  mov	[domac_status],byte 0	;restart status flag
  or	eax,eax
  jz	cmd_loop	;jmp if no input file	
  call	setup_files
  or	eax,eax
  jz	cmd_loop	;jmp if setup ok
  jmp	db_stop_exit
;---------
cmd_loop:
  call	lookup_cmd
  jnc	do_cmd
  cmp	esi,[cmd_buf_end_ptr]
  jae	amac_done		;jmp if end of buffer
do_cmd:
  test	[domac_status],byte 2	;if skip active?
  jz	cmd_call
  cmp	eax,_ifne
  ja	if_ck2
;save current status
  push	esi
  push	eax
  mov	esi,domac_status	;input ptr
  mov	edx,list_block
  call	list_put_at_front	;save status
  pop	eax
  pop	esi
  jmp	short cmd_loop
if_ck2:
  cmp	eax,_endif
  ja	cmd_loop		;ignore all commands when "if" active
cmd_call:
  call	eax			;execute command !!!!!!!!!!!!!!!!!!!!!!!!!
  test	[domac_status],byte 81h
  jz	cmd_loop		;loop until stop found
;write output file
amac_done:
  mov	ebx,[_outfilename]
  cmp	[ebx],byte 0
  jne	amac_done2
  mov	al,4
  call	report_error_pre
  jmp	short outfile_skip
amac_done2:
  mov	edx,[_outfilename+token.end]	;get end of name
  mov	[edx],byte 0			;terminate name

  xor	edx,edx		;permissions
  mov	ecx,[_infile]
  mov	esi,[_infile_end] ;get current end of infile
  sub	esi,ecx		;compute length of infile
  call	block_write_all
outfile_skip:
  mov	eax,[_infile]
  or	eax,eax
  jz	db_exit		;exit if no infile
  call	m_release
db_exit:
  xor	eax,eax			;set continue flag
db_stop_exit:
  ret
;--------------------------------------------------------------
;input: eax = pointer to infile name
setup_files:
  push	eax		;save input name
  mov	ebx,eax
;preload current dir as base
  call	dir_current
  mov	edi,infilename_buf
  mov	esi,ebx
  call	str_move	;move base to outfilename_buf
;check if full path provided
  pop	esi		;restore input name
  cmp	byte [esi],'/'	;full path provided?
  jne	ck_dots	;jmp if not full path
  mov	edi,infilename_buf ;restart name
  je	append_inname	;jmp if full path provided
;check if truncation needed
ck_dots:
  cmp	word [esi],'..' ;move back ?
  jne	dn1		;jmp if not ../
  add	esi,2		;move to start of entry
;remove end of edi
dnd_lp1:
  dec	edi
  cmp	byte [edi],'/'
  jne	dnd_lp1
  jmp	append_inname
;check if append dir provided 
dn1:
  cmp	word [esi],'./'
  jne	append_inname	;jmp if not ./
  inc	esi		;skip over .
append_inname:
  cmp	[esi],byte '/'
  je	append_inname2 ;jmp if / present
  cmp	[esi],byte '.' ;just a .
  je	af_done	;jmp if just a .
append_inname1:
  mov	al,'/'
  stosb
append_inname2:
  call	str_move	;move name if present
af_done:
  mov	[_infilename_end],edi	;save end of name
  mov	ebx,infilename_buf
  call	file_length_name
  jns	allocate_infile
  mov	al,3
  call	report_error_pre
  jmp	sf_exit
allocate_infile:
  mov	[infile_length],eax
  mov	[_infile_end],eax	;start computation of end
  shl	eax,2			;allocate big buffer
  add	eax,4000
  mov	[infile_buf_size],eax
  mov	[_infile_buf_end],eax
  call	m_allocate
  mov	[_infile],eax
;;  mov	[infile_process_ptr],eax
  add	[_infile_end],eax	;compute end of infile
  add	[_infile_buf_end],eax
;read infile
  mov	ebx,[_infilename]
  mov	edx,[infile_length]
  mov	ecx,[_infile]
  call	block_read_all
  jns	infile_skip
  mov	al,3
  call	report_error_pre
  jmp	sf_exit
infile_skip:

;construct outfile name --------
build_outfile_name:
  mov	edi,outfilename_buf
  mov	[_outfilename],edi

;preload current dir as base
  call	dir_current
  mov	esi,ebx
  call	str_move	;move base to outfilename_buf
;check if directory provided
  mov	esi,[outdir]	;get ptr to output dir
  or	esi,esi
  jnz	full_path_check	;jmp if outdir provided
  mov	esi,out_base
  jmp	append_outdir	;go move default dir (out)
;check if full path provided
full_path_check:
  cmp	byte [esi],'/'	;full path provided?
  jne	check_dots	;jmp if not full path
  mov	edi,outfilename_buf ;restart name
  je	append_outdir	;jmp if full path provided
;check if truncation needed
check_dots:
  cmp	word [esi],'..' ;move back ?
  jne	on1		;jmp if not ../
  add	esi,2		;move to start of entry
;remove end of edi
end_lp1:
  dec	edi
  cmp	byte [edi],'/'
  jne	end_lp1
  jmp	append_outdir
;check if append dir provided 
on1:
  cmp	word [esi],'./'
  jne	append_outdir	;jmp if not ./
  inc	esi		;skip over .
append_outdir:
  cmp	[esi],byte '/'
  je	append_outdir2 ;jmp if / present
  cmp	[esi],byte '.' ;just a .
  je	check_dir	;jmp if just a .
append_outdir1:
  mov	al,'/'
  stosb
append_outdir2:
  call	str_move	;move name if present

;check if directory exists
check_dir:
  push	edi
  mov	ebx,outfilename_buf
  call	dir_status
  pop	edi
  jns	dir_exists
;dir does not exist, create it
  mov	ebx,outfilename_buf
  push	edi
  call	dir_create
  pop	edi
  or	eax,eax
  jns	dir_exists	;jmp if dir created
  mov	al,5
  call	report_error_pre
  jmp	short sf_exit	;jmp if error
dir_exists:

;now append inputfile name to end
;find end of infile name
  mov	esi,infilename_buf
end_lp2:
  lodsb
  or	al,al
  jnz	end_lp2		;loop till end found
;scan back to first '/'
bak_lp1:
  dec	esi
  cmp	esi,infilename_buf
  je	move_name	;jmp if start of buffer
  cmp	byte [esi],'/'
  jne	bak_lp1
;append file name to outpath
move_name:
  cmp	byte [esi],'/'
  je	move_name2
  mov	al,'/'
  stosb
move_name2:
  call	str_move
  mov	[_outfilename_end],edi ;save name end
  xor	eax,eax
sf_exit:
  ret
;----------
  [section .data]
out_base db '/out',0
  [section .text]
;----------------------------------------------------------------
;commands
;----------------------------------------------------------------

;----------------------------------------------------------------
_ifeq:		;if
  call	parse_next_parameter
  jc	_ifeq_error
  cmp	bl,0			;check if existing token
  jne	_ifeq_error1		;jmp if first not token
  mov	ebx,eax			;ebx -> token
  mov	edx,_local_tok
  call	copy_token
  jc	_ifeq_error2		;jmp if buffer too small
  call	parse_next_parameter	;parse next entry
  jc	_ifeq_error1		;jmp if error
;save current status
  push	esi
  push	eax
  mov	esi,domac_status	;input ptr
  mov	edx,list_block
  call	list_put_at_front	;save status
  pop	eax
  pop	esi

;compute length of strings, and compare
  mov	ecx,[eax+token.end]
  sub	ecx,[eax+token.begin]	;size of parm2
  mov	edx,[_local_end]
  sub	edx,[_local_tok]	;size of parm1
  cmp	ecx,edx
  jne	_ifeq_no_match
;compare strings
  mov	esi,[eax+token.begin]
  mov	edi,[_local_tok+token.begin]
  repe	cmpsb		;compare strings
  jne	_ifeq_no_match	;jmp if not equal
  and	[domac_status],byte ~2 ;clear -if- active
  jmp	short _ifeq_exit  	
_ifeq_no_match:
  or	[domac_status],byte 2	;set -if- active
  jmp	short _ifeq_exit
_ifeq_error1:
  mov	al,6
  jmp	short _ifeq_error
_ifeq_error2:
  mov	al,7
_ifeq_error:
  call	report_error
_ifeq_exit:
  ret
;----------------------------------------------------------------
_ifne:		;if
  call	parse_next_parameter
  jc	_ifne_error1
  cmp	bl,0			;check if existing token
  jne	_ifne_error1		;jmp if first not token
  mov	ebx,eax			;ebx -> token
  mov	edx,_local_tok
  call	copy_token
  jc	_ifne_error2		;jmp if buffer too small
  call	parse_next_parameter	;parse next entry
  jc	_ifne_error1		;jmp if error
;save current status
  push	esi
  push	eax
  mov	esi,domac_status	;input ptr
  mov	edx,list_block
  call	list_put_at_front	;save status
  pop	eax
  pop	esi

;compute length of strings, and compare
  mov	ecx,[eax+token.end]
  sub	ecx,[eax+token.begin]	;size of parm2
  mov	edx,[_local_end]
  sub	edx,[_local_tok]	;size of parm1
  cmp	ecx,edx
  jne	_ifne_no_match
;compare strings
  mov	esi,[eax+token.begin]
  mov	edi,[_local_tok+token.begin]
  repe	cmpsb		;compare strings
  jne	_ifne_no_match	;jmp if not equal
  or	[domac_status],byte 2	;set -if- active
  jmp	short _ifeq_exit  	
_ifne_no_match:
  and	[domac_status],byte ~2 ;clear -if- active
  jmp	short _ifne_exit
_ifne_error1:
  mov	al,8
  jmp	short _ifne_error
_ifne_error2:
  mov	al,9
_ifne_error:
  call	report_error
_ifne_exit:
  ret
;----------------------------------------------------------------
_endif:		;if
  mov	edx,list_block
  call	list_get_from_front
  js	_endif_error
  mov	eax,[esi]	;get data
  mov	[domac_status],eax
  jmp	_endif_exit
_endif_error:
  mov	al,10
  call	report_error
_endif_exit:
  ret
;----------------------------------------------------------------
;input: esi -> "find <token1>   in  <token2>"
;                    ("string")       
;       search <token2> for match string or token
;output: set _findptr ($findptr token) to match or zero if not found
;
;notes:
;
_find:		;search and set $findptr
  push	esi
  call	parse_next_parameter
  jnc	_find_05	;jmp if parameter found
  jmp	_find_errj	;exit if error
_find_05:
  mov	ebx,[eax+token.begin]
  mov	[_find_match_strt],ebx
  mov	edx,[eax+token.end]
  mov	[_find_match_end],edx
  call	parse_next_parameter
  jc	_find_errj
  cmp	bl,0		;existing token found?
  jne	_find_errj
  mov	ebx,[eax+token.begin]
  or	ebx,ebx
  jnz	_find_ok1
  mov	al,26
  call	report_error
  jmp	_find_exit
_find_ok1:
  mov	edx,[eax+token.end]
  mov	[_find_srch_strt],ebx
  mov	[_find_srch_end],edx
  mov	[_find_host_tok],eax
;terminate the match string with  zero
  mov	edx,[_find_match_end]
  mov	al,[edx]	;get match end char and
  mov	[_find_match_end_char],al  ;save
  mov	[edx],byte 0	;terminate string or token
;setup blk_find parameters
  mov	esi,[_find_match_strt]	;match string start
  mov	edi,[_find_srch_strt]
  mov	ebp,[_find_srch_end]
  mov	edx,1		;search forward
  mov	ch,byte 0ffh	;match case
  call	blk_find
  jnc	_find_success
;notfound
  xor	eax,eax
  mov	[_findptr+token.begin],eax	;set not found state
  mov	[_findptr+token.end],eax	;set not found state
  jmp	short _find_restore
_find_errj:
  mov	al,11
  call	report_error
  jmp	_find_exit
;found it
_find_success:
  mov	[_findptr],ebx	;save find token start
  mov	eax,[_find_match_end]	;compute
  sub	eax,[_find_match_strt]	;length of match string
  add	ebx,eax			;compute end of _findptr
  mov	[_findptr_end],ebx	;save end of _findptr
;store host
  mov	eax,[_find_host_tok]
  mov	bl,[eax+token.tok#]
  mov	[_findptr+token.host#],bl ;store host#
_find_restore:	
;restore char modified for search
 mov	al,[_find_match_end_char]
 mov	ebx,[_find_match_end]
 mov	[ebx],al		;restore origional contents
_find_exit:
  pop	esi
  ret
;-----------
  [section .data]
_find_srch_strt:	dd 0
_find_srch_end:		dd 0
_find_match_strt:	dd 0
_find_match_end:	dd 0
_find_match_end_char:	db 0
_find_host_tok:		dd 0

  [section .text]
;----------------------------------------------------------------
;copy file,token or string to token
_copy:		;token copy
  push	esi
  call	parse_next_parameter
  jc	_copy_error	;exit if error
;legal first parameters are: string,file,existing token
  cmp	bl,2
  jbe	_copy01			;jmp if ok
_copy_error:
  mov	al,12
  call	report_error
  jmp	_copy_exit
;move last parse to temp token
_copy01:
  inc	ebx		;convert 0,1,2 -> 1,2,3,4
  cmp	bl,1
  jne	_copy02
;set ebx to 1-find tok  0-non find tok
  cmp	eax,_findptr	;find token
  je	_copy02		;jmp if findptr
  and	bl,~1		;remove findptr bit  
_copy02:
  mov	[_copy_decode],bl ;store 0-nonfind tok 1-findtok 2-string 3-file
;save -from- info at _local_tok  
  mov	ebx,eax		;get token adr
  mov	edx,_local_tok	;get temp save
  call	save_token
;get next parameter
  call	parse_next_parameter
  jc	_copy_error
  cmp	bl,0			;check if existing token
  je	_copyto_tok		;jmp if token
  cmp	bl,2			;check if file
  jne	_copy_error		;jmp if not tok or file
  or	[_copy_decode],byte 1000b
  jmp	short _copy04
;the from info is in _local_tok (string,file,tok)
;the -to- info is at temp_tok (eax)
_copyto_tok:
  cmp	eax,_findptr		;is this the findptr
  jne	_copy04			;jmp if not findptr
  or	[_copy_decode],byte 100b ;adjust decode
_copy04:
  mov	ebx,[_copy_decode]
  shl	ebx,2			;comvert to dword index
  add	ebx,copy_jmp_table
  call	[ebx]
_copy_exit:
  pop	esi
  ret

;-----------
;the from info is at _local_tok (string,file,tok)
;the -to- tok info is at [eax]
tok_to_nfind:	;0 copy non-findtok to non-findtok
  mov	ebx,_local_tok
  xor	edx,edx
  mov	dl,[eax+token.tok#]	;get parent tok#
  shl	edx,4
  add	edx,_infilename-16	
  call	copy_token		;set carry if error
  ret
;-----------
;the from info is in _local_tok (string,file,tok)
;the -to- info is at (eax)
ftok_to_nfind:	;1 copy findtok to non-findtok
  mov	ebx,_findptr
  xor	edx,edx
  mov	dl,[eax+token.tok#]	;get parent tok#
  shl	edx,4
  add	edx,_infilename-16	
  call	copy_token
  ret
;-----------
;the from info is in _local_tok (string,file,tok)
;the -to- info is at (eax)
str_to_nfine:	;2 copy string to non-findtok
  mov	ebx,_local_tok
  xor	edx,edx
  mov	dl,[eax+token.tok#]	;get parent tok#
  shl	edx,4
  add	edx,_infilename-16	
  call	copy_token		;set carry if error
  ret
;-----------
;the from info is in _local_tok (string,file,tok)
;the -to- info is at (eax)
file_to_nfind:	;3 copy file to non-findtok
  push	eax			;save -to- token ptr
  cmp	eax,_infile		;are we loading infile
  jne	ftn_10			;jmp if not _infile
  mov	eax,[_local_tok]	;get filename
  call	setup_files
  mov	eax,_infile		;restore infile token ptr
ftn_10:
  mov	ebx,[_local_tok]	;get file name
  call	file_length_name	;return length in eax
  jc	ptn_error2		;jmp if file not found
  pop	ebx
;check buffer size of -to- token
  xor	edx,edx
  mov	dl,[ebx+token.tok#]	;get parent tok#
  shl	edx,4
  add	edx,_infilename-16	
;
  mov	ebp,ebx			;save -to- token
  mov	ebx,[edx+token.buf_end]
  sub	ebx,[edx+token.begin]
  cmp	eax,ebx
  ja	ptn_error1		;jmp if file too large
;read file
  mov	ecx,[edx+token.begin]	;buffer ptr
  mov	edx,ebx			;buffer size to edx
  mov	ebx,[_local_tok]	;filename ptr
  call	block_read_all
;update -to- token
  add	eax,[ebp+token.begin]
  mov	[ebp+token.end],eax	;store data end
  jmp	short ptn_exit
ptn_error1:
  mov	al,14
  jmp	short ptn_error
ptn_error2:
  mov	al,13
ptn_error:
  call	report_error
ptn_exit:
  ret
;-----------
;the from info is in _local_tok (string,file,tok)
;the -to- info is at (eax)
tok_to_find:	;4 copy non-findtok to non-findtok
  mov	[_copy_to_tok],eax	;save -to- tok
;cut out old contents
  xor	ebx,ebx
  mov	bl,[eax+token.host#]
  shl	ebx,4
  add	ebx,_infilename-16	
  mov	[_copy_to_root_tok],ebx	;save root target

  mov	edi,[eax+token.begin]	;start of cut
  mov	ebp,[ebx+token.end]	;end of target tok
  mov	eax,[eax+token.end]	;compute lenght of cut
  sub	eax,edi			;eax=length of cut
  sub	[ebx+token.end],eax	;adjust target token data length
  call	blk_fdel_bytes		;set ebp to new end
;insert new contents
  mov	esi,[_local_tok]	;string to copy
  mov	eax,[_copy_to_tok]
  mov	edi,[eax+token.begin]	;insert point
  mov	eax,[_local_end]	; input string end
  sub	eax,esi			; compute length of input string
  mov	ebx,[_copy_to_root_tok]
  add	[ebx+token.end],eax	;adjust target token data length
;adjust findptr length
  mov	ebp,[_findptr+token.begin]
  add	ebp,eax			;compute new end for findptr
  mov	[_findptr+token.end],ebp
  mov	ebp,[ebx+token.end]	;get end of root (to) tok
;ebp is end of to block
  call	blk_finsert_bytes
  ret

;-----------
;the from info is in _local_tok (string,file,tok)
;the -to- info is at (eax)
find_to_find:	;5 copy findtok to findtok
  ret		;this is a nop
;-----------
;the from info is in _local_tok (string,file,tok)
;the -to- info is at (eax)
str_to_find:	;6 copy string to findtok
  mov	[_copy_to_tok],eax	;save -to- tok
;cut out old contents
  xor	ebx,ebx
  mov	bl,[eax+token.host#]
  shl	ebx,4
  add	ebx,_infilename-16	
  mov	[_copy_to_root_tok],ebx	;save root target

  mov	edi,[eax+token.begin]	;start of cut
  mov	ebp,[ebx+token.end]	;end of target tok
  mov	eax,[eax+token.end]	;compute lenght of cut
  sub	eax,edi			;eax=length of cut
  sub	[ebx+token.end],eax	;adjust target token data length
  call	blk_fdel_bytes		;set ebp to new end
;insert new contents
  mov	esi,[_local_tok]	;string to copy
  mov	eax,[_copy_to_tok]
  mov	edi,[eax+token.begin]	;insert point
  mov	eax,[_local_end]	; input string end
  sub	eax,esi			; compute length of input string
  mov	ebx,[_copy_to_root_tok]
  add	[ebx+token.end],eax	;adjust target token data length
;adjust findptr length
  mov	ebp,[_findptr+token.begin]
  add	ebp,eax			;compute new end for findptr
  mov	[_findptr+token.end],ebp
  mov	ebp,[ebx+token.end]	;get end of root (to) tok
;ebp is end of to block
  call	blk_finsert_bytes
  ret

;-----------
;the from info is in _local_tok (string,file,tok)
;the -to- info is at  (eax)
file_to_find:	;7 copy file to findtok
  mov	[_copy_to_tok],eax	;save -to- tok
;cut out old contents
  xor	ebx,ebx
  mov	bl,[eax+token.host#]
  shl	ebx,4
  add	ebx,_infilename-16	
  mov	[_copy_to_root_tok],ebx	;save root target

  mov	edi,[eax+token.begin]	;start of cut
  mov	ebp,[ebx+token.end]	;end of target tok
  mov	eax,[eax+token.end]	;compute lenght of cut
  sub	eax,edi			;eax=length of cut
  sub	[ebx+token.end],eax	;adjust target token data length
  call	blk_fdel_bytes		;set ebp to new end
;get file
  mov	ebx,[_local_tok]	;get file name
  call	file_length_name	;return length in eax
  js	ptn_error2		;jmp if file not found
  mov	ebx,[_copy_to_tok]	;get -to- tok ptr
;check buffer size of -to- token
  mov	edx,[_copy_to_root_tok]
  mov	ebp,ebx			;save -to- token
  mov	ebx,[edx+token.buf_end]
  sub	ebx,[edx+token.begin]
  cmp	eax,ebx
  ja	ptn_error1		;jmp if file too large
;make hole in target string
;    edi = hole creation point (address)
;    ebp = file end address (beyond last valid byte)
;    eax = size of hole (number of bytes to insert)
  push	eax			;save size of file
  mov	edi,[_findptr]		;get start of insert
  mov	ebp,[edx+token.end]	;end of target token
  call	blk_fmake_hole		;eax is size of hole
  mov	eax,[_copy_to_root_tok]
  mov	[eax+token.end],ebp	;adjust end of target
;read file
  pop	edx			;restore file size
  mov	ecx,[_findptr]		;buffer ptr
  mov	ebx,[_local_tok]	;filename ptr
  call	block_read_all
;update findptr
  mov	ecx,[_findptr]
  add	ecx,eax
  mov	[_findptr+token.end],ecx
  ret

;-----------
;the from info is in _local_tok (string,file,tok)
;the -to- info is at  (eax)
tok_to_file:
  mov	ebx,[eax+token.end]
  mov	byte [ebx],0		;terminate string
  mov	ebx,[eax+token.begin]	;get filename
  xor	edx,edx			;default permissions
  mov	ecx,[_local_tok+token.begin] ;get buffer
  mov	esi,[_local_tok+token.end]
  sub	esi,ecx			;compute size
  call	block_write_all
  ret
;-----------
;the from info is in _local_tok (string,file,tok)
;the -to- info is at  (eax)
findtok_to_file:
  jmp	tok_to_file
;-----------
;the from info is in _local_tok (string,file,tok)
;the -to- info is at  (eax)
string_to_file:
  jmp	tok_to_file
;-----------
;the from info is in _local_tok (string,file,tok)
;the -to- info is at  (eax)
file_to_file:
  mov	al,27
  call	report_error
  ret

;--------
  [section .data]
_copy_decode	dd 0	;
copy_jmp_table:
  dd tok_to_nfind	;0 copy non-findtok to non-findtok
  dd ftok_to_nfind	;1 copy findtok to non-findtok
  dd str_to_nfine	;2 copy string to non-findtok
  dd file_to_nfind	;3 copy file to non-findtok
  dd tok_to_find	;4 copy non-findtok to non-findtok
  dd find_to_find	;5 copy findtok to findtok
  dd str_to_find	;6 copy string to findtok
  dd file_to_find	;7 copy file to findtok
  dd tok_to_file
  dd findtok_to_file
  dd string_to_file
  dd file_to_file
  

_copy_from_tok:	dd 0	;ptr to "from" tok
_copy_to_tok:	dd 0	;ptr to "to" tok
_copy_to_root_tok dd 0	;ptr to real "to" if findptr
  [section .text]
;----------------------------------------------------------------
;expand
;       {token)
;       {front,back}
;        add another token, move ptr, search for char, insert string, insert file
_expand_string:	;inc token start ptr
  mov	al,1
  call	expand_shrink
  ret
;----------------------------------------------------------------
;shrink
;    {token)
;    {front,back)
;    sub move ptr, search for char
_shrink_string:	;sub token start ptr
  mov	al,0
  call	expand_shrink
  ret

;----
;common handler for expand/shrink
; input - al = 0(shrink) 1(expand)
;
; shrink token #front 0-token
; expand       #back  1-sting
;                     2-file
;                     3-key #till(2) ("x")
;                     4-key #number
;----
expand_shrink:
  mov	[es_flag],al	;save expand/shrink flag
  push	esi
  call	parse_next_parameter ;get token name
  jc	es_error	;exit if error
  cmp	bl,0		;token found?
  jne	es_error	;jmp if error
  mov	[es_token1],eax	;save token ptr
;look for front/back keyword
  call	parse_next_parameter ;bl=0(tok) 1(str) 2(file) 3(key) 4(num)
  cmp	bl,3
  jne	es_error
  jecxz	es_front	;jmp if front
  cmp	cl,1
  jne	es_error	;jmp if not back
  mov	ebx,8
  jmp	short es_10
es_front:
  xor	ebx,ebx
es_10:
  mov	[es_decode],ebx
  call	parse_next_parameter ;bl=0(tok) 1(str) 2(file) 3(key) 4(num)
  mov	[es_token2],eax	;save token ptr
  jc	es_error  
  test	[es_flag],byte 1 ;is this shrink? 0=shrink
  jnz	es_20		;jmp if expand
;this is -shrink-, only legal values for bl are 3,4
  cmp	bl,3
  jb	es_error
  cmp	bl,4
  ja	es_error
  add	bl,2		;adjust 3,4 - 5,6
es_20:
  or	[es_decode],bl
;compute processing from table
  mov	eax,[es_decode]
  shl	eax,2		;make dword index
  add	eax,es_jmp
  call	[eax]
  jmp	short es_exit
es_error:
  mov	al,15
  call	report_error
es_exit:
  pop	esi
  ret
;--------
;input: [es_token1] - pointer to target token
;       [es_token2] - token adjustment
token_add_front:	;0000 expand front - add token
  mov	ebx,[es_token1]
  mov	edi,[ebx+token.begin]	;insert point
  call	insert_token
  ret
;--------
;input: [es_token1] - pointer to target token
;       [es_token2] - token adjustment
string_add_front:	;0001 expand front - add string
  jmp	token_add_front
;--------
;input: [es_token1] - pointer to target token
;       [es_token2] - token adjustment
file_add_front:		;0002 expand front - add file
  mov	ecx,[es_token1]	;-to-
  mov	edi,[ecx+token.begin]	;insert point
  call	insert_file
  ret

;--------
;input: [es_token1] - pointer to target token
;       [es_token2] - token adjustment
char_left_front:	;0003 move ptr left till char found
  cmp	ecx,2		;till keyword?
  jne	clf_error3
  call	parse_next_parameter
  mov	[es_token2],eax
  mov	edx,[es_token1]
  cmp	edx,_findptr	;is this the find ptr?
  jne	clf_error2	;jmp if not find ptr
  mov	ecx,[edx+token.begin]	;get findptr front
;lookup the host token for findptr
  xor	ebx,ebx
  mov	bl,[edx+token.host#]
  shl	ebx,4		;index into tokens
  add	ebx,_infilename-16 ;get host token
  sub	ecx,[ebx+token.begin]	;compute max move left
;get character to search for
  mov	eax,[es_token2]
  mov	eax,[eax+token.begin]	;get string ptr
  mov	al,[eax]		;get character to search for
  mov	edi,[edx+token.begin]	;get findptr strng ptr
;ecx=max loop, al=char to search for edx=findptr token
clf_loop:
  jecxz	clf_error1		;jmp if not found
  dec	edi
  cmp	[edi],al
  je	clf_found
  loop	clf_loop
  mov	al,16
  jmp	short clf_error
clf_error3:
  mov	al,15
  jmp	short clf_error
clf_error2:
  mov	al,17
  jmp	short clf_error
clf_error1:
  mov	al,16
clf_error:
  call	report_error
  jmp	short clf_exit
clf_found:
  mov	[edx+token.begin],edi	;store adjusted ptr
clf_exit:
  ret
;--------
;input: [es_token1] - pointer to target token
;       [es_token2] - token adjustment
ptr_left_front:		;0004 expand front - move ptr
  mov	edx,[es_token1]
  cmp	edx,_findptr	;is this the find ptr?
  jne	plf_error1	;jmp if not find ptr
;lookup the host token for findptr
  xor	ebx,ebx
  mov	bl,[edx+token.host#]
  shl	ebx,4		;index into tokens
  add	ebx,_infilename-16 ;get host token
;edx=findptr ebx=host tok
  mov	eax,[edx+token.begin]	;get findptr front
  mov	edi,[ebx+token.begin]	;get host tok front
plf_loop:
  cmp	eax,edi
  jbe	plf_error2		;can't move left
  dec	eax
  loop	plf_loop
  mov	[edx+token.begin],eax	;set new findptr front
  jmp	short plf_exit
plf_error1:
  mov	al,17
  jmp	short plf_error
plf_error2:
  mov	al,18
plf_error:
  call	report_error
  jmp	short plf_exit
plf_exit:
  ret
;--------
;input: [es_token1] - pointer to target token
;       [es_token2] - token adjustment
;we need to parse the char 
char_right_front:	;0005 shrink front till char found
  cmp	ecx,2		;till keyword?
  jne	crf_error3
  call	parse_next_parameter
  mov	[es_token2],eax
  mov	edx,[es_token1]
  cmp	edx,_findptr	;is this the find ptr?
  jne	crf_error2	;jmp if not find ptr
;lookup the host token for findptr
  xor	ebx,ebx
  mov	bl,[edx+token.host#]
  shl	ebx,4		;index into tokens
  add	ebx,_infilename-16 ;get host token
  mov	ecx,[ebx+token.end]	;get max move ptr
  sub	ecx,[edx+token.begin]	;get findptr front
;get character to search for
  mov	eax,[es_token2]
  mov	eax,[eax+token.begin]	;get string ptr
  mov	al,[eax]		;get character to search for
  mov	edi,[edx+token.begin]	;get findptr strng ptr
;ecx=max loop, al=char to search for edx=findptr token
crf_lp:
  jecxz	crf_error1		;jmp if not found
  inc	edi
  cmp	[edi],al
  je	crf_found
  loop	crf_lp
  mov	al,16
  jmp	short crf_error
crf_error3:
  mov	al,19
  jmp	short crf_error
crf_error2:
  mov	al,17
  jmp	short crf_error
crf_error1:
  mov	al,16
crf_error:
  call	report_error
  jmp	crf_exit
crf_found:
  mov	[edx+token.begin],edi	;store adjusted ptr
crf_exit:
  ret


;--------
;input: [es_token1] - pointer to target token
;       [es_token2] - token adjustment
ptr_right_front:	;0006 shrink front by x bytes
  mov	edx,[es_token1]
  cmp	edx,_findptr	;is this the find ptr?
  jne	prf_error1	;jmp if not find ptr
;lookup the host token for findptr
  xor	ebx,ebx
  mov	bl,[edx+token.host#]
  shl	ebx,4		;index into tokens
  add	ebx,_infilename-16 ;get host token
;edx=findptr ebx=host tok
  mov	eax,[edx+token.begin]	;get findptr front
  mov	edi,[ebx+token.end]	;get host tok end
crf_loop:
  cmp	eax,edi
  jae	prf_error2		;can't move right
  inc	eax
  loop	crf_loop
  mov	[edx+token.begin],eax	;set new findptr front
  jmp	short prf_exit
prf_error1:
  mov	al,17
  jmp	short prf_error
prf_error2:
  mov	al,18
prf_error:
  call	report_error
prf_exit:
  ret
;--------
;input: [es_token1] - pointer to target token
;       [es_token2] - token adjustment
token_add_back:		;0008 expand back - add token
  mov	ebx,[es_token1]
  mov	edi,[ebx+token.end]	;insert point
  call	insert_token
  ret
;--------
;input: [es_token1] - pointer to target token
;       [es_token2] - token adjustment
string_add_back:	;0009 expand back - add string
  jmp	token_add_back
;--------
;input: [es_token1] - pointer to target token
;       [es_token2] - token adjustment
file_add_back:		;0010 expand back - add file
  mov	ecx,[es_token1]	;-to-
  mov	edi,[ecx+token.end]	;insert point
  call	insert_file
  ret
;--------
;input: [es_token1] - pointer to target token
;       [es_token2] - token adjustment
char_right_back:	;0011 move ptr right till char found
  cmp	ecx,2		;till keyword?
  jne	crb_error3
  call	parse_next_parameter
  mov	[es_token2],eax
  mov	edx,[es_token1]
  cmp	edx,_findptr	;is this the find ptr?
  jne	crb_error2	;jmp if not find ptr
;lookup the host token for findptr
  xor	ebx,ebx
  mov	bl,[edx+token.host#]
  shl	ebx,4		;index into tokens
  add	ebx,_infilename-16 ;get host token
  mov	ecx,[ebx+token.end]	;get max move ptr
  sub	ecx,[edx+token.begin]	;compute max search length
;get character to search for
  mov	eax,[es_token2]
  mov	eax,[eax+token.begin]	;get char ptr
  mov	al,[eax]		;get character to search for
  mov	edi,[edx+token.end]	;get findptr strng ptr
  or	edi,edi
  jz	crb_error4		;jmp if last find failed
;ecx=max loop, al=char to search for edx=findptr token
crb_lp:
  jecxz	crb_error1		;jmp if not found
  cmp	[edi],al
  je	crb_found
  inc	edi
  loop	crb_lp
crb_error4:
  mov	al,16
  jmp	short crb_error
crb_error3:
  mov	al,19
  jmp	short crb_error
crb_error2:
  mov	al,17
  jmp	short crb_error
crb_error1:
  mov	al,19
crb_error:
  call	report_error
  jmp	short crb_exit
crb_found:
  inc	edi
  mov	[edx+token.end],edi	;store adjusted ptr
crb_exit:
  ret
;--------
;input: [es_token1] - pointer to target token
;       [es_token2] - token adjustment
ptr_right_back:		;0012 expand back - move ptr
  xor	ebx,ebx
  mov	edx,[es_token1]
  cmp	edx,_findptr	;is this the find ptr?
  jne	prb_tok		;jmp if not find ptr
;lookup the host token for findptr
  mov	bl,[edx+token.host#]
  shl	ebx,4		;index into tokens
  add	ebx,_infilename-16 ;get host token
prb_tok:
;edx=findptr ebx=host tok (if not findptr edx=0)
  or	ebx,ebx
  jz	prb_tok2		;jmp if no findprt
  mov	eax,[edx+token.end]	;get findptr end
  mov	edi,[ebx+token.buf_end]	;get host tok end
;adjust findptr if in use
prb_loop1:
  cmp	eax,edi
  jae	prb_error		;can't move left
  inc	eax
  loop	prb_loop1
  mov	[edx+token.end],eax	;set new token end
  jmp	prb_exit
;adjust non find tok
prb_tok2:
  mov	eax,[edx+token.end]
  mov	edi,[edx+token.buf_end]
prb_loop2:
  cmp	eax,edi
  jae	prb_error
  inc	eax
  loop	prb_loop2
  mov	[edx+token.end],eax
  jmp	short prb_exit
prb_error:
  mov	al,18
  call	report_error
prb_exit:
  ret

;--------
;input: [es_token1] - pointer to target token
;       [es_token2] - token adjustment
;we need to parse the char 
char_left_back:		;0013 shrink left till char found
  cmp	ecx,2		;till keyword?
  jne	clb_error3
  call	parse_next_parameter
  mov	[es_token2],eax
  mov	edx,[es_token1]
;  cmp	edx,_findptr	;is this the find ptr?
;  jne	clb_error2	;jmp if not find ptr
;lookup the host token for findptr
  xor	ebx,ebx
  mov	bl,[edx+token.host#]
  shl	ebx,4		;index into tokens
  add	ebx,_infilename-16 ;get host token
  mov	ecx,[edx+token.end]	;get max move ptr
  sub	ecx,[edx+token.begin]	;compute max search length
;get character to search for
  mov	eax,[es_token2]
  mov	eax,[eax+token.begin]	;get char ptr
  mov	al,[eax]		;get character to search for
  mov	edi,[edx+token.end]	;get findptr strng ptr
;ecx=max loop, al=char to search for edx=findptr token
clb_lp:
  jecxz	clb_error1		;jmp if not found
  dec	edi
  cmp	[edi],al
  je	clb_found
  loop	clb_lp
  mov	al,16
  jmp	short clb_error
clb_error3:
  mov	al,19
  jmp	short clb_error
clb_error2:
  mov	al,17
  jmp	short clb_error
clb_error1:
  mov	al,16
clb_error:
  call	report_error
  jmp	short clb_exit
clb_found:
  inc	edi
  mov	[edx+token.end],edi	;store adjusted ptr
clb_exit:
  ret
;--------
;input: [es_token1] - pointer to target token
;       [es_token2] - token adjustment
ptr_left_back:		;0014 shrink left by x bytes
  xor	edx,edx
  mov	ebx,[es_token1]
  cmp	ebx,_findptr	;is this the find ptr?
  jne	plb_tok		;jmp if not find ptr
;lookup the host token for findptr
  mov	dl,[ebx+token.host#]
  shl	edx,4		;index into tokens
  add	edx,_infilename-16 ;get host token
plb_tok:
;edx=findptr ebx=host tok (if not findptr edx=0)
  or	edx,edx
  jz	plb_tok2		;jmp if no findprt
  mov	eax,[ebx+token.end]	;get findptr end
  mov	edi,[edx+token.begin]	;get findptr tok begin
;adjust findptr if in use
plb_loop1:
  dec	eax
  cmp	eax,edi
  jb	plb_error		;can't move left
  loop	plb_loop1
  mov	[ebx+token.end],eax	;set new token end
  jmp	plb_exit
;adjust non find tok
plb_tok2:
  mov	eax,[ebx+token.end]
  mov	edi,[ebx+token.begin]
plb_loop2:
  dec	eax
  cmp	eax,edi
  jb	plb_error
  loop	plb_loop2
  mov	[ebx+token.end],eax
  jmp	short plb_exit
plb_error:
  mov	al,18
  call	report_error
plb_exit:
  ret
  
;---------
  [section .data]
es_token1	dd 0	;ptr to token to work on
es_token2	dd 0	;ptr to token to work on
es_flag		db 0	;1=expand 0=shrink
es_decode	dd 0	;(see jmp table)

es_jmp		dd token_add_front	;0000 expand front - add token
		dd string_add_front	;0001 expand front - add string
		dd file_add_front	;0002 expand front - add file
		dd char_left_front	;0003 move ptr left till char found
		dd ptr_left_front	;0004 expand front - move ptr
		dd char_right_front	;0005 shrink front till char found
                dd ptr_right_front	;0006 shrink front by x bytes
		dd 0			;0007 illegal
      		dd token_add_back	;0008 expand back - add token
		dd string_add_back	;0009 expand back - add string
		dd file_add_back	;0010 expand back - add file
		dd char_right_back	;0011 move ptr right till char found
		dd ptr_right_back	;0012 expand back - move ptr
		dd char_left_back	;0013 shrink left till char found
                dd ptr_left_back	;0014 shrink left by x bytes
		dd 0			;0015 illegal
                
  [section .text]
;----------------------------------------------------------------
;always does search and replace, use "_copy" for replace only
;replace all,first, nth with (string,token,file)
_replace:	;search and replace
  call	parse_next_parameter ;get target token
  cmp	bl,0		;token parsed
  je	rep_ck		;jmp if token parsed
  jmp	rep_error1	;jmp if not token
rep_ck:
  cmp	eax,_findptr
  jne	rep_sav
  jmp	rep_error2	;findptr is illegal
rep_sav:
  mov	[target_token_ptr],eax
;get match string
  call	parse_next_parameter  ;get match string
  cmp	bl,1
  jbe	rep_20		;jmp if token or string
  jmp	rep_error1	;jmp if not token or string
rep_20:
  push	eax		;save token ptr
  mov	ebx,eax
  mov	eax,[ebx+token.end]
  sub	eax,[ebx+token.begin] ;compute length of string
  push	eax		;save string length
  add	eax,16
  call	m_allocate	;set eax=memory block
  mov	[match_string_ptr],eax
  pop	ecx		;get string lenght
  pop	ebx		;restore token ptr
  mov	esi,[ebx]	;get ptr to string	
  mov	edi,eax		;set edi=destination
  rep	movsb		;move string
  mov	[edi],byte 0
;get replacement string
  call	parse_next_parameter ; get replacement string
  cmp	bl,1
  ja	rep_error1	;jmp if not token or string
  push	eax		;save token ptr
  mov	ebx,eax
  mov	eax,[ebx+token.end]
  sub	eax,[ebx+token.begin] ;compute length of string
  push	eax		;save string length
  add	eax,16
  call	m_allocate	;set eax=memory block
  mov	[replace_string_ptr],eax
  pop	ecx		;get string lenght
  pop	ebx		;restore token ptr
  mov	esi,[ebx]	;get ptr to string	
  mov	edi,eax		;set edi=destination
  rep	movsb		;move string
  mov	[edi],byte 0
;setup to do replacement
  mov	eax,[replace_string_ptr]
  mov	ch,0ffh		;search mask
  mov	esi,[match_string_ptr]
  mov	ebx,[target_token_ptr]
  mov	edi,[ebx+token.begin]	;get start of block
  mov	ebp,[ebx+token.end]	;get end of block
  call	blk_freplace_all
  mov	ebx,[target_token_ptr]
  mov	[ebx+token.end],ebp	;store new end point
  mov	[ebp],byte 0		;put zero at end of string
  mov	eax,[replace_string_ptr]
  call	m_release
  mov	eax,[match_string_ptr]
  call	m_release
  jmp	short rep_exit
rep_error1:			;parse error
  mov	al,20
  jmp	short rep_error
rep_error2:			;can't replace in findptr
  mov	eax,21
rep_error:
  call	report_error
rep_exit:
  ret
;-------
  [section .data]
target_token_ptr	dd 0	;token to work on
match_string_ptr	dd 0	;string to search for
replace_string_ptr	dd 0	;string to insert at match
  [section .text]
;----------------------------------------------------------------
;do commands for each line in $token
;                             /file
;
_dolist:	;do action for each line
  test	[domac_status],byte 08h	;are we inside a dolist?
  jz	dl_10			;jmp if dolist inactive
  jmp	dl_error1		;jmp if dolist active
dl_10:
  call	parse_next_parameter	;expect for find token or file
  cmp	bl,2
  jbe	dl_20			;jmp if legal
  jmp	dl_error2		;jmp if illegal parameter
dl_20:
  je	dl_file
  or	bl,bl
  jz	dl_30			;jmp if legal
  jmp	dl_error2		;jmp if illegal parameter
dl_30:
;token name found
  push	eax			;save token ptr
  mov	ebx,[eax+token.end]
  sub	ebx,[eax+token.begin]	;compute length of token
  mov	eax,ebx
  push	eax			;save text size
  call	m_allocate
  mov	[next_dolist],eax		;save buffer start
  mov	[do_line_buf],eax	;save pointer
  pop	ecx			;restore data length
  add	eax,ecx			;compute end
  mov	[dobuf_end],eax	;store end of data
;copy data to allocated buffer
  pop	ebx			;get token ptr
  mov	esi,[ebx+token.begin]	;get data start
  mov	edi,[next_dolist]		;get do_token buffer
  rep	movsb			;move data
  jmp	dl_set

;file name parsed
dl_file:			;file name found
  push	eax			;save file name
  mov	ebx,[eax+token.begin]
  call	file_length_name
  jns	allocate_dofile
  mov	al,3
  call	report_error
  jmp	dl_exit
allocate_dofile:
  mov	[dofile_length],eax
  mov	[dobuf_end],eax	;start computation of end
  call	m_allocate
  mov	[next_dolist],eax
  mov	[do_line_buf],eax
  add	[dobuf_end],eax	;compute end of dofile
;read infile
  pop	ebx			;restore name token
  mov	ebx,[ebx]		;get name ptr
  mov	edx,[dofile_length]
  mov	ecx,[next_dolist]		;get do buffer
  call	block_read_all
;set end of first doline
dl_set:
  mov	esi,[next_dolist]	;get line start
dl_loop2:
  cmp	esi,[dobuf_end]
  jae	dl_line_end			;jmp if end of do
  lodsb
  cmp	al,0ah
  jne	dl_loop2
dl_line_end:
  mov	[dolist_end],esi	;update pointer

  or	[domac_status],byte 08h	;enable dolist
  mov	eax,[cmd_buf_ptr]	;get parse ptr
  mov	[parse_ptr_save],eax
  jmp	short dl_exit
dl_error1:			;dolist already active
  mov	al,22
  jmp	short dl_error
dl_error2:			;illegal parameter
  mov	al,23
dl_error:
  call	report_error
dl_exit:  
  ret
;--------
  [section .data]
dofile_length	dd 0
parse_ptr_save	dd 0
do_line_buf	dd 0
  [section .text]

;----------------------------------------------------------------
_enddo:
  test	[domac_status],byte 08h
  jz	_enddo_exit		;exit if no do active
  mov	esi,[next_dolist]		;get current ptr
ed_loop:
  lodsb
  cmp	esi,[dobuf_end]
  jae	ed_stop			;jmp if end of do
  cmp	al,0ah
  jne	ed_loop
  mov	[next_dolist],esi	;update pointer
;set end of line
ed_loop2:
  cmp	esi,[dobuf_end]
  jae	ed_line_end			;jmp if end of do
  lodsb
  cmp	al,0ah
  jne	ed_loop2
ed_line_end:
  mov	[dolist_end],esi	;update pointer

  mov	eax,[parse_ptr_save]
  mov	[cmd_buf_ptr],eax	;restart at top of loop
  jmp	_enddo_exit
;end of do loop found
ed_stop:
  and	[domac_status],byte ~08h ;clear active flag
  mov	eax,[do_line_buf]		;get buffer
  call	m_release		;release memory
_enddo_exit:
  ret
;----------------------------------------------------------------
;input: esi -> "shell ("...")
;              embedded tokens are expanded
;       example:  ^shell ("ls > files")
;output: none
;
_shell:
  mov	edi,shell_buf
;move and expand tokens
sh_mv_lp1:
  lodsb
  cmp	al,'('
  jne	sh_mv_lp1
  inc	esi
sh_mv_lp2:
  lodsb
  cmp	al,'"'	;end of string?
  jne	sh_mv_10
  cmp	[esi],byte ')'
  je	sh_launch	;jmp end of string
sh_mv_10:
  cmp	al,'$'	;possible token here?
  je	sh_expand_token
stuff_it:
  stosb
  jmp	short sh_mv_lp2
;expand token
sh_expand_token:
  dec	esi	;move back to '$'
  call	lookup_token
  jnc	sh_stuff_token
  lodsb		;get "$" back
  jmp	short stuff_it
;move token data
sh_stuff_token:
  push	esi
  shl	ecx,3
  add	ecx,_infilename	;index into token ptrs
  mov	esi,[ecx]	;get token ptr
  call	str_move	;move token
  pop	esi
  jmp	sh_mv_lp1
;execute shell cmd
sh_launch:
  push	esi
  xor	eax,eax
  stosd			;terminate string
  mov	esi,shell_buf
  call	sys_shell_cmd
  pop	esi		;restore cmd parse ptr  
  inc	esi		;move past ")" at end of string
  ret
;----------------------------------------------------------------
_stop:
  or	[domac_status],byte 01h	;done flag
  ret

;----------------------------------------------------------------
;show token text or string
_show:
  push	esi
  call	parse_next_parameter
  jc	_show_error	;exit if error
  mov	[show_token],eax
  cmp	bl,0		;string display?
  je	sh_tok		;jmp if token
  cmp	bl,1
  jne	_show_error	;jmp if not string
;sting entered
  mov	ecx,show_msg2
  call	crt_str
  
  jmp	sh_contents	;jmp if string
sh_tok:	
  mov	esi,[ll_token_ptr]
;move token to buffer
  mov	edi,show_msg_buf
sh_lp1:
  lodsb
  cmp	al,' '		;end of token name?
  je	sh_end1		;jmp if end of name
  cmp	al,0ah
  jbe	sh_end1		;jmp if end of name
  stosb
  jmp	short sh_lp1
sh_end1:
  mov	al,'='
  stosb
  mov	[edi],byte 0	;terminate msg
  mov	ecx,show_msg1
  call	crt_str
sh_contents:
;now write token string
  mov	eax,[show_token]
  mov	ecx,[eax+token.begin]
  jecxz	_show_exit		;jmp if no string here
  mov	edx,[eax+token.end]
  sub	edx,ecx		;compute length
  call	crt_write
  jmp	short _show_exit
_show_error:
 mov	al,24
 call	report_error
_show_exit:
  pop	esi
  ret
;----
  [section .data]
show_msg1:	db 0ah
show_msg_buf	times 15 db 0
show_msg2:	db 0ah,0
show_token	dd 0
  [section .text]

;----------------------------------------------------------------
;subroutines
;----------------------------------------------------------------

;----------------------------------------------------------------
;input: [es_token1] = -to- token ptr
;       [es_token2] = -from- token ptr
;       edi = insert point
;output: target string size adjusted
;        ebp = new data of data for target
insert_token:
  mov	ecx,[es_token2]		;get -from- token
  mov	esi,[ecx+token.begin]	;get insert string
  mov	eax,[ecx+token.end]	;compute
  sub	eax,[ecx+token.begin]	; length of insert string
  mov	ebx,[es_token1]		;get -to- token
  mov	ecx,eax			;move insert length to ecx
  add	ecx,[ebx+token.end]	;adjust target token length
  mov	[ebx+token.end],ecx	;adjust token size
  cmp	ebx,_findptr		;is target = _findptr?
  je	it_find			;jmp if doing _findptr
  mov	ebp,[ebx+token.end]	;end of data
  cmp	ecx,[ebx+token.buf_end] ;room in buffer for insert?
  jbe	it_ok			;jmp if still inside buffer
it_error:			;insert overflows buffer
  mov	al,25
  call	report_error
  jmp	short it_exit
;inserting into findptr, check if host has room
;ebp=_findptr eax=insert length esi=insert point
it_find:
;lookup the host token for findptr
  xor	edx,edx
  mov	dl,[ebx+token.host#]
  shl	edx,4		;index into tokens
  add	edx,_infilename-16 ;get host token
  mov	ecx,[edx+token.end] ;get end of target data
  add	ecx,eax		;compute new data end
  cmp	ecx,[edx+token.buf_end] ;new size ok
  ja	it_error	;jmp if insert too big
  mov	[edx+token.end],ecx ;adjust end of target

it_ok:
  call	blk_finsert_bytes	;eax=length esi=insert adr ebp=data end
it_exit:
 ret
;----------------------------------------------------------------
;input: [es_token1] = -to- token ptr
;       [es_token2] = -from- token ptr
;       edi = insert point
;output: target string size adjusted
;        ebp = new data of data for target
insert_file:
  mov	ecx,[es_token2]		;get -from- token
  mov	ebx,[ecx+token.begin]	;get filename ptr
  call	file_length_name	;return length in eax
  js	iff_error2		;jmp if file not found
  mov	edx,[es_token1]		;get -to- token
  mov	ecx,eax			;move insert length to ecx
  add	ecx,[edx+token.end]	;adjust target token length
  mov	[edx+token.end],ecx	;adjust token size
  cmp	edx,_findptr		;is target = _findptr?
  je	iff_find		;jmp if doing _findptr
  mov	ebp,[edx+token.end]	;end of data
  cmp	ecx,[edx+token.buf_end] ;room in buffer for insert?
  jbe	iff_ok			;jmp if still inside buffer
iff_error1:			;insert overflows buffer
  mov	al,25
  jmp	short iff_error
iff_error2:			;file not found
  mov	al,3
iff_error:
  call	report_error
  jmp	short iff_exit
;inserting into findptr, check if host has room
;ebp=_findptr eax=insert length esi=insert point
iff_find:
;lookup the host token for findptr
  xor	ebx,ebx
  mov	bl,[edx+token.host#]
  shl	ebx,4		;index into tokens
  add	ebx,_infilename-16 ;get host token
  mov	ecx,[ebx+token.end] ;get end of target data
  add	ecx,eax		;compute new data end
  cmp	ecx,[ebx+token.buf_end] ;new size ok
  ja	iff_error1	;jmp if insert too big
  mov	[ebx+token.end],ecx ;adjust end of target
  mov	edx,ebx
iff_ok:
;make hole in target string
;    edi = hole creation point (address)
;    ebp = file end address (beyond last valid byte)
;    eax = size of hole (number of bytes to insert)
  push	eax			;save size of file
;  mov	edi,[edx+token.begin]	;get start of insert
  mov	ebp,[edx+token.end]	;end of target token
  push	edi
  call	blk_fmake_hole		;eax is size of hole
  pop	edi
;read file
  pop	edx			;restore file size
  mov	ecx,edi			;insert point
  mov	ebx,[es_token2]
  mov	ebx,[ebx+token.begin]	;filename ptr
  call	block_read_all
iff_exit:
 ret

;----------------------------------------------------------------
;parse_next_parameter - get following string or token
;input: esi points at parse start point
;output: carry set = error
;                    esi unchanged
;                    edi restored
;                    eax = error number
;        nocarry = success
;                  esi updated to end of parse
;                  edi unchanged
;                  eax ptr to existing or temp token of type
;                      
;                  ebx  = 0  existing tok
;                         1  string start
;                         2  filename start
;                         3  keyword index
;                         4  number value
;                                      
;                  ecx = keyword name index only if type=keyword
;note:
;     
;     
;
parse_next_parameter:
  mov	[parse_start],esi
  push	edi
pn_lp:
  cmp	esi,[cmd_buf_end_ptr]
  jae	pn_error	;exit if error
  cmp	[esi],byte '^'
  je	pn_error	;exit if command found
  cmp	[esi],word '("' ;start of string
  je	pn_string	;jmp if string found
  cmp	[esi],byte '$'
  je	pn_token	;jmp if token found
  cmp	[esi],byte '/'
  je	pn_file		;jmp if file found
  cmp	[esi],byte '#'
  jne	pn_tail		;jmp if not keyword
  jmp	pn_keyword	;jmp if keyword of number
pn_tail:
  inc	esi
  jmp	short pn_lp	;keep looking
;
pn_error:
  stc
  mov	esi,[parse_start] ;restore parse point
  jmp	pn_exit

;parse string
pn_string:
  add	esi,2	;move past ("
  mov	[temp_tok_adr],esi
  mov	[temp_tok_type],byte 02h;set string type
  mov	[type_index],byte 1	;set string index
;move and expand tokens
pn_mv_lp2:
  cmp	[esi],word '")'
  je	pn_string_end
  inc	esi
  jmp	short pn_mv_lp2		;loop till end of string
pn_string_end:
  mov	[temp_tok_end],esi
  jmp	pn_success

;parse existing token
pn_token:
  mov	[type_index],byte 0
  call	lookup_token
  jnc	pn_token_found
  jmp	pn_error_exit
pn_token_found:
  mov	eax,ecx		;get token ptr
  jmp	pn_success2

;parse filename
pn_file:
  inc	esi		;skip over "/" indicating file
  cmp	[esi],byte "$"	;token here
  jne	pn_10_call		;jmp if not token
  push	esi
  call	lookup_token	;set ecx=token
  mov	esi,[ecx+token.begin]
  call	pn_10
  pop	esi
  add	esi,byte 2		;skip over possible /$
  jmp	pn_success
pn_10_call:
  call	pn_10
  jmp	pn_success

pn_10:
  mov	edi,temp_file_buf ;setup output buf
  mov	[temp_tok_adr],edi ;insert into temp_tok
  cmp	[esi],byte '/'	;full path
  je	pn_append	;jmp if full path
  push	esi		;save file ptr
  call	dir_current
  mov	esi,ebx
  call	str_move	;insert current dir
  pop	esi		;restore file ptr
pn_20:
  cmp	[esi],word '..' ;check if path adjust
  jne	pn_40		;jmp if not ..
;truncate path for ..
pn_lp1:
  dec	edi
  cmp	[edi],byte '/'
  jne	pn_lp1		;remove end dir
  add	esi,3		;move past "../"
  jmp	short pn_20	;go check for another ..
;check for ./
pn_40:
  cmp	[esi],word './'	;check if local append
  jne	pn_50		;jmp if not "./"
  inc	esi		;move past .
  jmp	pn_append
;assume local file name
pn_50:
  mov	al,'/'
  stosb			;add a "/"

pn_append:
  lodsb			;get char
  cmp	al,' '
  je	pn_file_tail
  cmp	al,0ah
  jbe	pn_file_tail
  stosb
  jmp	short pn_append
pn_file_tail:
  mov	[edi],byte 0	;terminate file
;setup the temp_tok
  mov	[temp_tok_end],edi
  mov	[temp_tok_type],byte 01h	;set file type
  mov	[type_index],byte 2		;set file index
  ret

;parse keyword or number
pn_keyword:
  mov	[temp_tok_adr],esi
  mov	al,[esi+1]		;get first letter/number
  cmp	al,31h
  jb	pn_key2			;jmp if keyword
  cmp	al,39h
  ja	pn_key2			;jmp if keyword

;parse number:
  inc	esi			;move to number
  call	ascii_to_dword
  mov	[temp_tok_buf],ecx	;store number value
  mov	[temp_tok_type],byte 04h	;set number type
  mov	[type_index],byte 4		;set number index
  jmp	pn_success

;parse_keyword
pn_key2:
  mov	[temp_tok_type],byte 10h	;set keyword type
  mov	[type_index],byte 3		;set keyword index
  inc	esi
  call	lookup_keyword
  jnc	pn_keyword_found
  jmp	short pn_error_exit
pn_keyword_found:
;ecx = keyword index
  jmp	pn_success2

;error code in eax
pn_error_exit:
  mov	esi,[parse_start]
  stc
  jmp	short pn_exit
pn_success:
  mov	eax,temp_tok_adr
pn_success2:
  mov	ebx,[type_index]
  clc		;set success flag 
pn_exit:
  pop	edi
  ret
;--------
  [section .data]
parse_start: dd 0

temp_tok_adr:	dd 0	;start ptr
temp_tok_end:	dd 0	;end ptr
temp_tok_buf:	dd 0	;buffer length/value
temp_tok_num:	db 0
temp_tok_host:  db 0
temp_tok_type:  db 0
temp_tok_legal: db 0

type_index:	db 0  ; = 0  existing tok
;                         1  string start
;                         2  filename start
;                         3  keyword index
;                         4  number value

  [section .text]        

;----------------------------------------------------------------
;lookup_cmd - convert command string to process ptr
;    cmd_buf_ptr
;    cmd_buf_end_ptr
;output: carry set if end of buffer
;        eax=cmd process if success
;
lookup_cmd:
  mov	esi,[cmd_buf_ptr]
nc_loop:
  cmp	esi,[cmd_buf_end_ptr]
  jae	nc_done_exit
  cmp	word [esi],'("'	;string start?
  jne	nc_skip1
  or	[domac_status],byte 04 ;set string start
nc_skip1:
  cmp	word [esi],'")'	;string end
  jne	nc_skip2
  and	[domac_status],byte ~4
nc_skip2:
  lodsb
  cmp	al,'^'
  jne	nc_loop	;loop till command found
  test	[domac_status],byte 4
  jnz	nc_loop		;jmp = ignore cmd if in string

  push	esi
  dec	esi	;move back to ^
  mov	edi,commands
  call	lookup_list
  pop	esi
  jc	nc_loop		;loop if not legal token
;token index is in ecx
  shl	ecx,2		;make dword index
  add	ecx,cmd_process_list
  mov	eax,[ecx]
  clc
  jmp	short nc_exit
nc_done_exit:
  stc
nc_exit:
  mov	[cmd_buf_ptr],esi ;update esi
  ret
;----------------------------------------------------------------
;lookup_keyword - convert keyword string to process ptr
;inputs: esi=cmd buf ptr
;output: if no carry - ecx = keyword index
lookup_keyword:
  mov	edi,keywords
  call	lookup_list
  jc	lk_exit		;exit if not found
  clc  
lk_exit:
  ret

;----------------------------------------------------------------
;lookup_token - convert token string to token block ptr
;inputs: esi=inbuf ptr
;output: ecx=ptr to token block and & no carry flag
;        esi= ptr past token name if match, if no match
;             esi restored to origional value.
;
; note: this function is different from library routine.
;       It assumes nothing about end of tokens at esi, and
;       assumes list (edi) has tokens terminated by zero.
;    
lookup_token:
  mov	edi,tokens
  call	lookup_list
  jc	lt_exit		;exit if not found
  shl	ecx,4
  add	ecx,_infilename ;compute token ptr
  clc  
lt_exit:
  ret

;---------------------------------------------------------------
;inputs: esi = parse ptr
;        edi = search table
;output: if no carry - ecx=index, esi points past parameter
;        if carry - not found, esi restored
lookup_list:
  mov	[ll_token_ptr],esi
  xor	ecx,ecx		;set index to  zero
ll_lp1:
  cmp	[edi],byte 0	;end of this list token
  je	ll_found
  cmpsb
  je	ll_lp1		;keep comparing if match
  inc	ecx
;move to next list token
ll_skip_lp:
  inc	edi
  mov	al,[edi]
  or	al,al
  jnz	ll_skip_lp	;loop till next token
  mov	esi,[ll_token_ptr] ;restart token start
  inc	edi		;move past zero at end
ll_lp2:
  cmp	byte [edi],0
  jne	short ll_lp1	;jmp if table has more entries
  stc
  mov	esi,[ll_token_ptr] ;restore esi
  jmp	short ll_exit
ll_found:
  clc
ll_exit:
  ret
;-------------
  [section .data]
ll_token_ptr: dd 0
  [section .text]
;----------------------------------------------------------------
; parse_user_inputs - get parameters
; input: esp has one push
;output: carry set if error
;        success = file names set
parse_user_parameters:
  mov	esi,esp		;get stack ptr
  lodsd			;get return address (ignore)
  lodsd			;number of parameters
  mov	ecx,eax
  sub	ecx,2
  jb	parse_error
  lodsd			;get our filename (ignore)
  lodsd			;get control file
  mov	[cmd_filename_ptr],eax
  dec	ecx
  js	pup_ok		;jmp if no infile
  lodsd
  mov	[infile_path_ptr],eax
  dec	ecx
  js	split_infile		;jmp if no outdir
  lodsd
  mov	[outdir],eax
;split infile_path_ptr into path + mask
;first find mask at end
split_infile:
  mov	edi,infilemaskbuf
  mov	esi,[infile_path_ptr]
  cmp	byte [esi],'/'		;check if full path provided
  je	got_full_path
  call	dir_current
  mov	esi,ebx		;get ptr to path
  call	str_move
  mov	al,'/'
  stosb
  mov	esi,[infile_path_ptr]
got_full_path:
  call	str_move

;move back to /
pup_lp2:
  dec	edi
  cmp	byte [edi],'/'
  jne	pup_lp2		;loop till start of mask
  mov	byte [edi],0	;terminate path
  inc	edi
  mov	[infile_mask_ptr],edi
  mov	esi,infilemaskbuf
  mov	[infile_path_ptr],esi
pup_ok:
  clc
  jmp	short parse_exit
parse_error:
  stc
parse_exit:
  ret
;----------------------------------------------------------------
;copy_token - move token data and flags to new token
;inputs: ebx =  from token block ptr
;        edx =  to token block ptr
;output: carry set if error (buffer too small)
;
copy_token:
  push	esi
  cmp	edx,_infile
  jne	ct_normal	      ;jmp if not infile
;we are filling inbuf, setup outfile also
  mov	[infilename_buf],dword 'temp'
  mov	[infilename_buf+4],byte 0
  mov	[edx+token.begin],dword temp_file_buf	;new infile buffer
  mov	[edx+token.end],dword temp_file_buf+4	;end of string
  mov	[edx+token.buf_end],dword temp_file_buf+temp_file_buf_size
  push	ebx
  push	edx
  call	build_outfile_name
  pop	ecx
  pop	ebx

ct_normal:
  mov	ecx,[ebx+token.end]   ;compute
  sub	ecx,[ebx+token.begin] ;length of token data
  mov	edi,[edx+token.begin] ;get destination buffer
  cmp	ebx,_findptr
  jne	copy_non_findptr		;skip size check if findptr
  cmp	edx,_local_tok
  jne	copy_token_ok			;jmp if not local_tok
;we are copying the findptr
;assume this is a ifeq and copying to _local_tok
  mov	esi,ebx
  mov	edi,edx
  mov	ecx,16
  rep	movsb			
  jmp	copy_token_exit
copy_non_findptr:
;verify buffer will hold data
  mov	eax,[edx+token.buf_end]
  sub	eax,edi		      ;token2 buffer length
  cmp	ecx,eax
  jbe	copy_token_ok
  stc
  jmp	short copy_token_error ;exit if buffer too small
copy_token_ok:
  mov	esi,[ebx+token.begin] ;get from buffer ptr
  rep	movsb		      ;move data
  mov	[edx+token.end],edi   ;set new ending
  lea	esi,[ebx+token.host#] ;get ptr to flags+
  lea	edi,[edx+token.host#]
  mov	ecx,2
  rep	movsb		      ;move flags
  clc
  jmp	short copy_token_exit
copy_token_error:
  mov	al,25
  call	report_error
copy_token_exit:
  pop	esi
  ret
;
;----------------------------------------------------------------
;save_token - move token data and flags to new token
;inputs: ebx =  from token block ptr
;        edx =  to token block ptr
;
save_token:
  push	esi
  push	edi
  mov	esi,ebx
  mov	edi,edx
  mov	ecx,16
  rep	movsb
  pop	edi
  pop	esi
  ret

;
;----------------------------------------------------------------
;report_error - set error exit info, and show message
;inputs: esi=parse point, or zero if not parse error
;        al = error number
;output:
report_error_pre:
  xor	esi,esi		;no line number display
  jmp	short report_error_entry

report_error:
  mov	esi,[cmd_buf_ptr]
report_error_entry:
  or	[domac_status],byte 80h	;set error exit
  mov	[domac_err#],al
  or	esi,esi
  jz	re_skip1	;jmp if no line number report
;look up current line#
  mov	ebx,esi
  mov	esi,[cmd_buf_top_ptr]
  xor	ecx,ecx		;init line#
re_line_lp1:
  inc	ecx		;bump line#
re_line_lp2:
  cmp	esi,[cmd_buf_end_ptr]
  jae	re_skip1	;jmp if line not found
  cmp	esi,ebx
  jae	re_got_line
  lodsb
  cmp	al,0ah
  jbe	re_line_lp1	;jmp if new line
  jmp	short re_line_lp2
;show line message
re_got_line:
  mov	eax,ecx
  mov	edi,line_stuff
  call	dword_to_ascii
  mov	ecx,line_msg
  call	crt_str
re_skip1:  
  mov	eax,[domac_err#]
  shl	eax,2		;convert to dword ptr
  add	eax,error_ptrs-4
  mov	ecx,[eax]	;get error ptr
  call	crt_str
  ret
;------
  [section .data]
line_msg: db 0ah
  db 'domac Error while processng command line# '
line_stuff:
  db '              ',0

error_ptrs:
  dd err1
  dd err2
  dd err3
  dd err4
  dd err5
  dd err6
  dd err7
  dd err8
  dd err9
  dd err10
  dd err11
  dd err12
  dd err13
  dd err14
  dd err15
  dd err16
  dd err17
  dd err18
  dd err19
  dd err20
  dd err21
  dd err22
  dd err23
  dd err24
  dd err25
  dd err26
  dd err27

err1: db 0ah
 db 'usage: domac <cmd_file> <infile> <outdir>',0ah,0
err2: db 0ah
 db 'error reading command file',0ah,0
err3: db 0ah
 db 'error reading data file',0ah,0
err4: db 0ah
 db 'error, no output file',0ah,0
err5: db 0ah
 db 'error, can not create output dir',0ah,0
err6: db 0ah
 db 'error in ifeq parameter',0ah,0
err7: db 0ah
 db 'error, compare string too long',0ah,0
err8: db 0ah
 db 'error, in ifne parameter',0ah,0
err9: db 0ah
 db 'error in ifne string length',0ah,0
err10 db 0ah
 db '^endif nesting error',0ah,0
err11 db 0ah
 db 'error with ^find parameter',0ah,0
err12 db 0ah
 db '^copy parameter error',0ah,0
err13: db 0ah
 db '^copy file not found',0ah,0
err14: db 0ah
 db '^copy file too large',0ah,0
err15: db 0ah
 db '^shrink/expand parameter error',0ah,0
err16: db 0ah
 db 'search character not found',0ah,0
err17: db 0ah
 db 'operation requires $findptr',0ah,0
err18: db 0ah
 db '^expand moving too far',0ah,0
err19: db 0ah
 db 'expecting #till parameter',0ah,0
err20: db 0ah
 db '^replace needs token or string parameter',0ah,0
err21: db 0ah
 db '^replace, illegal use of $findptr',0ah,0
err22: db 0ah
 db '^dolist already active, nesting not allowed',0ah,0
err23: db 0ah
 db '^dolist parameter error',0ah,0
err24: db 0ah
 db '^show needs valid token or string',0ah,0
err25: db 0ah
 db 'insert operation overflowed buffer',0ah,0
err26: db 0ah
 db 'can not search empty string',0ah,0
err27: db 0ah
 db 'file to file copy not supported',0ah,0
  
;----------------------------------------------------------------
;data
;----------------------------------------------------------------

domac_status	dd 0	;01h = normal exit
;                       ;02h = if ignore active
;                       ;04h = parsing string
;                       ;08h = do line active
;                       ;80h=error exit
domac_err#	dd 0	;

cmd_filename_ptr	dd 0
cmd_buf_length:		dd 0
cmd_buf_top_ptr:	dd 0
cmd_buf_ptr:		dd 0	;processing position
cmd_buf_end_ptr:	dd 0

infile_length:		dd 0	;initial length (do not use)
infile_buf_size:	dd 0	;buffer is bigger than token

;these are initial parse values, restored for each recursion to token
infile_path_ptr	dd 0
infile_mask_ptr dd 0
outdir		dd 0


;----
; commands
;----
commands:
 db '^ifeq',0		;if
 db '^ifne',0		;if
 db '^endif',0
;the above commands must be first for "if" logic test
 db '^find',0		;search and set $findptr
 db '^copy',0		;token copy
 db '^expand',0	;inc token start ptr
 db '^shrink',0	;sub token start ptr
 db '^replace',0	;search and replace
 db '^dolist',0		;do action for each line
 db '^shell',0
 db '^enddo',0
 db '^stop',0
 db '^show',0
 db 0

cmd_process_list:
 dd _ifeq		;if
 dd _ifne
 dd _endif
 dd _find		;search and set $findptr
 dd _copy		;token copy
 dd _expand_string	;add to token start ptr
 dd _shrink_string	;sub token start ptr
 dd _replace	;search and replace
 dd _dolist	;do action for each line
 dd _shell
 dd _enddo
 dd _stop
 dd _show

;-----
; keywords
;-----
keywords:
 db 'front',0	;0
 db 'back',0	;1
 db 'till',0	;2
 db 0	;end of list

list_block:
 dd	list_buf     ;list buf top
 dd	list_buf_end ;list buf end
 dd	4	     ;list entry size
 dd	list_buf     ;list start ptr
 dd	list_buf     ;list tail ptr

list_buf	times 8 dd 0
list_buf_end:

;-----------------------------------------------------------------------
  [section .bss]

shell_buf	resb 200
infilemaskbuf	resb 200 	;initial parameter, used by dir_walk

