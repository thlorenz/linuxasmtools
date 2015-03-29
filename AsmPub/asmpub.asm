
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
  extern env_stack
  extern ascii_to_dword
  extern file_open
  extern file_read_all
  extern file_write
  extern blk_find
  extern file_close
  extern file_simple_read
  extern sort_selection
  extern dword_to_ascii
  extern file_delete
  extern compare_mask
  extern dir_walk
;%include "dir_walk.inc"
;%include "file_dir.inc" ;fix include in dir_walk ;;
  extern lib_buf
  extern str_move
  extern crt_str
  extern file_status_name

 [section .text]
;--------------------------------------------------------------
;>1
; AsmPub - build documents from comments in assembler programs.
;
;    usage: asmpub <switches> -o <name> target
;
;           where: <switches> can be:
;                  -c(n) - comment character used in source files
;                      example:  -c; for ";" character
;                                -c# for "#" character
;                     Note: no spaces can separate a -x flag and
;                        associated value.  thus, -r 2 is illegal.
;                        Shells assume some characters have special
;                        meaning and need to be told to ignore them.
;                        Thus, the -c; parameter must be quoted as '-c;'
;                     Note: The -c switch can be used twice on a command
;                        line.  This allows two different comment
;                        characters to be processed.
;                  -f1 = format 1 (normal)
;                  -f2 = format 2 (library) (see below)
;                  -i  = write index file, uses -o switch to get path
;                        and appends extension of .index
;                  -k  = show sort key in index
;                  -n  = number sections in index and title lines
;                  -r(n) = recurse to  depth (n)
;                      where:  default=current dir (-r1)
;                              -r = recurse all directories
;                              -r2 = recurse to a depth of 2
;                  -s  = sort sections
;           where:
;                  -o(name) = base name for index and output files:
;                  Note: output file is stored in current directory
;                        if full path is not provided.  No space
;                        between -o and (name).
;           where: target can be:
;                  path to start search with optional file mask.
;                  example:  /home/sam/project/  <- scan all files
;                                                   at /project
;                            /home/sam/project/*.asm <- scan all
;                                                   files ending with
;                                                   ".asm" at /project
;                            /home/sam/mak*  <- scan all files starting
;                                               with "mak"
;                  Note: A full target path must be provided.  Examples:
;                            $HOME/source/'*.asm'
;                            /home/sam/source
;                            /home/sam/source/'*.asm'
;                        Shells treat "*" as a special character and
;                        must be told to ignore it.  Thus, it must be
;                        quoted.  Example -o*.asm  --> '-o*.asm'
;
;    operation:
;    ----------
;          AsmPub extracts each block of text and removes the
;          leading comment character.  If the sort flag flag
;          is enabled the blocks are sorted.  Next, numbering
;          is applied if enabled.  The index is then written
;          if enabled.  Finally, the comment blocks are written
;          and formatting applied.  
;
;    format of comment block in source file
;    --------------------------------------
;
;    The following assumes the comment character is ";"
;    
;    Each comment block begins with line: ";>1" followed by optional
;    sort keys:   The end of the block is specified by ";<1"
;    Contiuation block can start with ";>2" and end with ";<1".
;    The continuation block are appended to preceeding block and
;    sorted with it.  All comment block lines must begin at left
;    edge as follows:
;      summary:  ;>1  <-- begins comment block & has sort strings
;                ;>2  <-- begins continuation block, sorted with parent
;                ;<1  <-- ends comment or continuation block
;                ;    <-- normal text within comment block
;
;    The block beginning can have a sort key following the ";>1" string.
;    The sort string can be any string and can be preceeded by a space.
;    Example:  ;>1 key1-key2
;    The sort string can appear as headers in index file if switch -k
;    is used.
;
;    f1 format - The comment blocks are written as found. (the
;                leading comment character removed)  If numbering
;                is enabled it will be insert at front of first line
;                after the ";>" header line.  The ";>" header line
;                and other control lines will be removed.
;
;    f2 format - The f2 format is for libraries and works like f1
;                format with the following additions:  A blank line
;                is added at start of each block.  this is followed
;                by a line of dashes, then the first comment line.
;                Next, another line of dashes is inserted.  This
;                is followed by the remaining data from comment section.
;<
;-------------------------------------------------------------------------             
 global main,_start

main:
_start:
  call	env_stack
  call	parse
  jns	pub_02			;jmp if parse ok
pub_errj:
  jmp	pub_err			;exit if parse error
;open temp file to write comment blocks
pub_02:
  mov	ebx,temp_file
  mov	ecx,1102q		;open   read/write,  truncate
  mov	edx,644q		;permissions
  call	file_open
  js	pub_errj		;exit if error
  mov	[temp_file_fd],eax	;save handle
;setup to walk directories
pub_03:
  mov	eax,45
  xor	ebx,ebx			;request mem allocation adr
  int	byte 80h		;returns memory allocation adr in eax

  mov	esi,search_path
  xor	ebx,ebx			;preload no file mask
  cmp	byte [file_mask],0
  je	pub_05			;jmp if no mask
  mov	ebx,file_mask
pub_05:
  mov	ch,2			;return only files
  mov	cl,99			;max depth
  mov	edx,write_blocks	;our process
  call	dir_walk
  cmp	byte [comment_switch_fnd],0
  je	pub_07			;jmp if secondary comment char not found
  mov	al,[comment_switch_fnd]
  mov	[comment_char1],al
  mov	[comment_char2],al
  mov	byte [comment_switch_fnd],0
  jmp	pub_03			;go do it again with different comment char	
pub_07:	
  mov	ebx,[temp_file_fd]
  call	file_close		;close temp file
  mov	ebx,temp_file
  mov	edx,max
  mov	ecx,buf
  call	file_simple_read	;read temp file
  js	pub_err
  add	eax,buf
  mov	[temp_file_end_ptr],eax
  call	build_sort_pointers
  cmp	byte [sort_flag],0	;sort wanted?
  je	pub_10			;jmp if no sort
  mov	ebp,sort_pointers
  mov	edx,0			;do not shift column
  mov	ecx,30			;sort 30 characters
  call	sort_selection
pub_10:
  cmp	byte [index_flag],0	;index wanted?
  je	pub_20			;jmp if no index
  call	build_index
pub_20:
  call	write_document
;delete temp file
  mov	ebx,temp_file
  call	file_delete
  jmp	short pub_exit

pub_err:
  mov	ebx,eax
  jmp	short pub_exit2
pub_exit:
  xor	ebx,ebx
pub_exit2:
  mov	eax,1
  int	80h

;------------------------------------------------------------------
write_document:
  mov	ebx,output_data_file
  mov	ecx,1102q		;open   read/write,  create, truncate
  mov	edx,644q		;permissions
  call	file_open
  jns	wd_05			;jmp if good read
  jmp	wd_exit			;error exit
wd_05:
  mov	[data_file_fd],eax	;save handle
  mov	byte [show_key_flag],0	;disable saving key
  mov	ebp,sort_pointers
wd_loop:
  mov	esi,[ebp]		;get ptr to block
  or	esi,esi
  jnz	wd_07			;jmp if another pointer exists
  jmp	wd_done			;exit if at end of pointer list
wd_07:
  cmp	byte [format_flag],2	;is this a library format
  jne	wd_10			;jmp if not library format
;library format, write blank line and dash line
  push	esi
  mov	edx,dash_line1_length	;length of write
  mov	ecx,dash_line1		;get data to write
  mov	ebx,[data_file_fd]
  call	file_write		;write dashes
  pop	esi
;write header line
wd_10:
  mov	edi,lib_buf
  call	build_header_line
  mov	edx,edi			;end of stuff --> edx
  mov	ecx,lib_buf		;get buffer to write
  sub	edx,ecx			;compute length of write
  mov	ebx,[data_file_fd]
  call	file_write		;write header
;if this is library format, add a dash line after header
  cmp	byte [format_flag],2
  jne	wd_20			;jmp if not library format
  mov	edx,dash_line2_length	;length of write
  mov	ecx,dash_line2		;get data to write
  mov	ebx,[data_file_fd]
  call	file_write		;write dashes
wd_20:
;write body of comment block
  mov	esi,[ebp]		;get ptr to block
wd_lp1:
  lodsb
  cmp	al,0ah
  jne	wd_lp1			;loop till end of top sort-key line
wd_continuation_block:
wd_lp2:
  lodsb
  cmp	al,0ah
  jne	wd_lp2			;loop till end of header line
  push	esi			;save write starting point
wd_lp3:
  lodsb
  cmp	al,'<'
  jne	wd_lp3
  cmp	byte [esi -2],0ah
  jne	wd_lp3			;loop till end of comment block
  dec	esi
;esi = end of block, stack=start
  mov	edx,esi			;end of stuff --> edx
  pop	ecx			;get start of write block
  sub	edx,ecx			;compute length of write
  mov	ebx,[data_file_fd]
  call	file_write		;write header
;check if next block is continuation block
  mov	ecx,8			;max search count
wd_lp4:
  lodsb
  dec	ecx
  jecxz	wd_50			;jmp if next block not found
  cmp	al,'>'			;find start of next block
  jne	wd_lp4			;loop if not next block
  cmp	byte [esi],'2'		;continuation block?
  je	wd_continuation_block	;append next block
;move to next block
wd_50:
  add	ebp,4
  jmp	wd_loop

wd_done:
  mov	ebx,[data_file_fd]
  call	file_close		;close temp file
wd_exit:
  ret
;--------------
  [section .data]
data_file_fd:  dd	0
dash_line1: db 0ah
dash_line2: db '-----------------------------------------------------------------------'
	   db 0ah
dash_line1_length equ $ - dash_line1
dash_line2_length equ $ - dash_line2

  [section .text]
;------------------------------------------------------------------
; build_index - write index file
;  input:  sort_pointers
;          output_index_file - path for index file
;
build_index:
  mov	ebx,output_index_file
  mov	ecx,1102q		;open   read/write,  create, truncate
  mov	edx,644q		;permissions
  call	file_open
  jns	bi_10
bi_exitj:
  jmp	bi_exit			;exit if error
bi_10:
  mov	[index_file_fd],eax	;save handle
  mov	ebp,sort_pointers
bi_lp:
  cmp	dword [ebp],0		;end of sort pointers?
  je	bi_exitj  
  mov	edi,lib_buf		;get storage location for data
  cmp	byte [show_key_flag],0	;do we include sort keys?
  je	bi_40			;jmp if no sort keys needed
;check if current sort key is unique

  mov	esi,[ebp]		;get sort key ptr
  push	edi
  mov	edi,last_sort_key	;get previous sort key
  cmp	byte [esi],0ah		;check if null key
  je	bi_30			;jmp if no sort key avail
;check if this is a new sort key, we need to display new sort keys
bi_lp1:
  cmpsb
  je	bi_lp1
  dec	esi			;go back to mismatch
  cmp	byte [esi],0ah		;at eol
  je	bi_30			;if at eol assume this is same sort key,
;put spaces infront of sort-key in output buffer
  pop	edi			;get stuff ptr
  mov	al,0ah	;;
  stosb		;;
  mov	al,' '
  stosb
  mov	al,'-'	;;
  stosb
  stosb
  mov	al,' '	;;
  stosb		;;
; save new sort key in output and to last_sort_key
  mov	esi,[ebp]
  mov	ebx,last_sort_key
bi_lp2:
  lodsb				;get next sort key char
  cmp	al,0ah
  jne	bi_28			;jmp if not end of key
  mov	al,' '	;;
  stosb		;;
  mov	al,'-'	;;
  stosb		;;
  stosb		;;
  mov	al,' '	;;
  stosb		;;
  mov	al,0ah	;;
  stosb				;store 0ah in output buffer (end of key)
  mov	al,0
  mov	byte [ebx],al		;terminate local copy of sort key
  jmp	short bi_40	
bi_28:
  stosb				;store next output char of key
  mov	byte [ebx],al		;store next local copy of key
  inc	ebx
  jmp	short bi_lp2		;loop till strings moved
;this key does not exist or is the same as previous key, ignore it
bi_30:
  pop	edi			;restore stuff ptr
;store header line in buffer
bi_40:
  mov	esi,[ebp]		;get ptr to comment block
  call	build_header_line
bi_42:
;edi=end of write data
  mov	edx,edi
  mov	ecx,lib_buf		;get buffer to write
  sub	edx,ecx			;compute length of write
  mov	ebx,[index_file_fd]
  call	file_write
  add	ebp,4
  jmp	bi_lp

bi_exit:
  mov	ebx,[index_file_fd]
  call	file_close		;close temp file
  mov	dword [block_number],0
  ret

;-----------------
  [section .data]
index_file_fd	dd	0
last_sort_key:  times 40 db 0
  [section .text]
;------------------------------------------------------------------
; build_header_line - use sort pointer to build header line
;  input:  esi = pointer to comment block (sort_pointer)
;                [esi] --> sort key or eol
;          edi = location to build header line
;          [numbering_flag] - 0=no numbering
;  output:
;          esi = ptr to comment block, (beginning of next line)
;          eax = ptr to start of built index line (output line)
;          edi = ptr to end of built index line (output line)      
;
build_header_line:
  lodsb			;get next char
  cmp	al,0ah		;eol
  jne	build_header_line
;we are now at start of header line
  push	edi		;save store pointer
  cmp	byte [numbering_flag],0
  je	bhl_10		;jmp if no numbering
  inc	dword [block_number]
  mov	eax,[block_number]
  call	dword_to_ascii
  mov	al,' '
  stosb			;put space after number
bhl_10:
  lodsb			;get header line data
  stosb
  cmp	al,0ah		;end of line
  jne	bhl_10		;loop till end of line
  pop	eax		;get line start
  ret  

;---------------
  [section .data]
block_number:  dd	0
  [section .text]
;------------------------------------------------------------------
; build_sort_pointers - create pointer list
;  inputs: [buf] = comment blocks with >1  >2  < control lines
;          [sort_pointers] - buffer to store sort pointers
;  output: sort_pointers are built and terminated by a zero
;
build_sort_pointers:
  mov	edi,sort_pointers
  mov	esi,buf
  inc	esi			;move past '>'
  jmp	stuff_ptr
bsp_lp1:
  mov	ax,[block_begin]
bsp_lp2:  
  inc	esi
  cmp	esi,[temp_file_end_ptr]
  jae	bsp_done		;jmp if end of file
  cmp	[esi],ax
  jne	bsp_lp2			;loop till match found
  cmp	byte [esi+2],'1'
  jne	bsp_lp2			;loop if not >1
  add	esi,2			;move past 0ah,>
stuff_ptr:
  inc	esi			;skip over "1"
  cmp	byte [esi],' '		;space?
  je	stuff_ptr		;loop if space to strip off
  mov	[edi],esi		;save this pointer to sort key or eol
  add	edi,4
  jmp	bsp_lp1			;go do next pointer
  
bsp_done:
  xor	eax,eax
  stosd
  ret
;----------------
  [section .data]
block_begin:  db  0ah,'>'	;0ah,'>'
  [section .text]
                      
;------------------------------------------------------------------
; write_blocks - called to read files and write each comment block
;   inputs:  [temp_file_fd] - open write file descriptor
;            eax = ptr to full path of file to search
;            buf = buffer to use for reads
;            [comment_char1,comment_char2,comment_char3]
;
write_blocks:
  mov	ebp,eax		;ebp = path to read
  mov	edx,max		;buffer size
  mov	ecx,buf		;buffer ptr
  mov	[search_loc],ecx ; save for later
  mov	al,0		;flags
  call	file_read_all
  or	eax,eax
  js	wb_exit		;exit if error
  mov	[file_length],eax
  add	eax,buf
  mov	[file_end_ptr],eax
;setup to do search for matches
wb_srch_lp:
  mov	ebp,[file_end_ptr]
  mov	esi,comment_char1	;search string
  mov	edi,[search_loc]	;search start point
  mov	edx,1			;search forward
  mov	ch,0ffh			;match case
  call	blk_find
  jc	wb_exit			;jmp if no matches
; ebx = ptr to match
  inc	ebx
  mov	[search_loc],ebx	;save new search point
  cmp	byte [ebx-2],0ah	;at start of line?
  jne	wb_srch_lp		;loop back if not valid match
;we have found a block to write
  mov	esi,ebx
  call	write_one_line		;write the top line
  lodsb				;skip over comment char
;skip forward on header line to remove spaces
wb_lpx:
  cmp	byte [esi],' '
  jne	wb_lp0			;go write header
  inc	esi
  jmp	short wb_lpx
wb_lp0:
  call	write_one_line		;in-esi=line to write    out-esi=next line
  cmp	byte [loop_end_flag],0
  jne	wb_10			;jmp if comment block written
  lodsb				;skip over comment char
  cmp	byte [esi],'<'		;end of block?
  jne	wb_lp0			;go write next line
;we are at end of comment block
  mov	byte [loop_end_flag],1
  jmp	wb_lp0
;this comment block has been written
wb_10:
  mov	byte [loop_end_flag],0	;restart loop flag
  mov	[search_loc],esi	;store new search point
  jmp	wb_srch_lp		;go look for more blocks
;
wb_exit:
  xor	eax,eax			;signal continue to walk_dir
  ret  

;------------
  [section .data]
file_end_ptr: dd 0
file_length:  dd 0
search_loc:   dd 0	;current search location
loop_end_flag db 0
  [section .text]    
;------------------------------------------------
; input: esi = ptr to start of line
; output: esi = ptr to next line
write_one_line:
  mov	ebx,esi			;save line start --> ebx
wb_lp1:
  lodsb
  cmp	al,0ah			;end of line?
  jne	wb_lp1			;find end of line
  push	esi			;save end of write area
;append this line to end of file
  mov	edx,esi			;get end of write
  sub	edx,ebx			;compute length of write -> edx
  mov	ecx,ebx			;ecx = ptr to write data
  mov	ebx,[temp_file_fd]
  call	file_write
  pop	esi			;get start of next line
  ret
;------------------------------------------------------------------
parse:
  mov	esi,esp			;get stack pointer
  lodsd				;get return address
  lodsd				;get parameter count
  cmp	eax,3
  ja	p_05		;jmp if cound ok
  jmp	parse_error	;exit if too few  parameters entered
p_05:
  lodsd			;get name
parse_loop:
  lodsd			;get parameter
  or	eax,eax		;end of parameters?
  jnz	p_07		;jmp if more data
  jmp	parse_check	;exit if done
p_07:
  push	esi		;save stack pointer
;eax points at parameter, begin decode
  cmp	byte [eax],'-'	;switch?
  je	p_20		;jmp if switch found
;non-switch, assume this is target path
  mov	esi,eax
  mov	edi,search_path
  call	str_move	;store search path
;check if mask on end of search path
p_lp1:
  dec	edi
  cmp	byte [edi],'*'
  je	p_mask		;jmp if mask on end
  cmp	byte [edi],'/'
  jne	p_lp1		;keep looking
;found a '/' which means no mask was specified
  mov	byte [file_mask],0	;turn off mask
  jmp	short p_10		;continue parse
p_mask:
  dec	edi
  cmp	byte [edi],'/'
  jne	p_mask		;find start of mask
  mov	byte [edi],0	;truncate search path
  inc	edi
  mov	esi,edi
  mov	edi,file_mask
  call	str_move  
p_10:
  jmp	p_next
;decode the switch, eax = ptr to data
p_20:
  inc	eax		;move past '-'
  mov	bl,[eax]	;get next char
  cmp	bl,'f'		;format flag?
  jne	p_30		;jmp if not format
  inc	eax
  mov	bl,[eax]	;get format codes "1" or "2"
  and	bl,3		;isolate code
  mov	[format_flag],bl
  jmp	p_next
;check for "n" numbered sections flag
p_30:
  cmp	bl,'n'
  jne	p_40		;jmp if not numbered section parameter
  mov	byte [numbering_flag],1
  jmp	p_next
;check for "s" sort
p_40:
  cmp	bl,'s'
  jne	p_50		;jmp if not sort parameter
  mov	byte [sort_flag],1 ;enable sort
  jmp	p_next
;check for "r" recursion
p_50:
  cmp	bl,'r'
  jne	p_60		;jmp if not recursion parameter
  inc	eax		;move to next char
  mov	esi,eax
  call	ascii_to_dword	;convert string
  mov	[depth_flag],cl	;store recursion depth
  jmp	p_next
;check for output file name
p_60:
  cmp	bl,'i'
  jne	p_70		;jmp if not index parameter
  mov	byte [index_flag],1 ;enable index file
  jmp	p_next
;check if comment character
p_70:
  cmp	bl,'c'
  jne	p_75		;jmp if not comment char
  inc	eax
  mov	bl,[eax]	;get comment char
  cmp	byte [comment_switch_fnd],0 ;is this the first -c found
  je	p_73		;jmp if this is first -c found
  mov	byte [comment_switch_fnd],bl
  jmp	p_next
p_73:
  mov	[comment_char1],bl 
  mov	[comment_char2],bl
  mov	[comment_switch_fnd],bl	;set flag saying we were here 
  jmp	p_next
;checi if show sort key flag  -k
p_75:
  cmp	bl,'k'
  jne	p_80		;jmp if not -k flag
  mov	byte [show_key_flag],1
  jmp	p_next
;check if output file name
p_80:
  cmp	bl,'o'
  je	p_82		;jmp if "o" parameter found
  jmp	parse_error	;?? parameter
;build file names
p_82:
  inc	eax
  cmp	byte [eax],'/'	;was full path provided?
  je	p_90		;jmp if full path provided
;get current working directory
  push	eax
  mov	eax,183		;kernel call for getcwd
  mov	ebx,output_data_file
  mov	ecx,300		;max size
  int	80h
;scan to end of path
  mov	esi,ebx		;ebx points at output_data_file
p_lp2:
  lodsb
  or	al,al
  jnz	p_lp2		;loop to end
  dec	esi
  mov	byte [esi],'/'
  inc	esi
  mov	edi,esi		;edi = storage point for name
  pop	esi		;restore ptr to output file name
  call	str_move	;move string
;output_data_file now has full pointer to file, edi points to end of path
  jmp	p_92
;full path provided at [eax]
p_90:
  mov	esi,eax
  mov	edi,output_data_file
  call	str_move
;output_data_file now has full path, edi points to end, build other paths
p_92:
  mov	esi,text_extension
  call	str_move	;convert name to name.txt
;build index file path
  mov	esi,output_data_file
  mov	edi,output_index_file
  call	str_move
;remove the .txt extension
p_lp3:
  dec	edi
  cmp	byte [edi],'.'
  jne	p_lp3
  mov	esi,index_extension
  call	str_move
;build the temp file path
  mov	esi,output_data_file
  mov	edi,temp_file
  call	str_move
;remove the .txt extension
p_lp4:
  dec	edi
  cmp	byte [edi],'.'
  jne	p_lp4
  mov	esi,tmp_extension
  call	str_move
  
p_next:
  pop	esi		;restore stack ptr for parse
  jmp	parse_loop	;go look for next parameter
;check for errors
parse_check:
  mov	ebx,search_path
  call	file_status_name	;can we access this path
  jns	parse_exit
;show errror message
  mov	ecx,parse_msg
  call	crt_str
parse_error:
  mov	eax,-1
parse_exit:
  or	eax,eax			;set flags
  ret

parse_msg: db 0ah
 db 'AsmPub can not access files, parameter error?',0ah,0
;------------------------------------------------------------------
;%include "walk.inc"
;------------------------------------------------------------------
  [section .data]
format_flag:		db 1	;1=normal 2=library
numbering_flag:		db 0	;0=no numbering 1=numbering
sort_flag:		db 0	;0=no sort 1=sort
depth_flag:		db 1	;recursion depth for directories
index_flag:		db 0	;0=no index 1=write index
show_key_flag:		db 0    ;0=no show, 1=show sort key in index
output_data_file:  times 300 db 0
output_index_file: times 300 db 0
search_path:	   times 300 db 0
file_mask:	   times 20 db 0
temp_file_end_ptr:	dd	0	;end of temp file
temp_file_fd		dd	0	;file descriptor for temp file

comment_switch_fnd	db 0	;set to 1 if comment char previously parsed
                                ;set to secondary comment char if found
				;set to zero if secondary comment char processed
comment_char1:		db ';'	;comment character from parse
block_begin_char:	db '>',0

comment_char2:		db ';'
			db '<',0

text_extension:		db '.txt',0
index_extension:	db '.index',0
tmp_extension:		db '.tmp',0
;-------------------------------
  [section .bss]
temp_file:	resb 400	;temp file, overwritten by sort_pointers
max	equ 600000		;main buffer size, largest source file
buf	resb max
sort_pointers resd 6000
bss_base: resb 1