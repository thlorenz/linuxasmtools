
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
;---------- window_find ------------------

  extern x_get_property
  extern root_win_id
  extern blk_find
  extern lib_buf
  extern x_wait_reply
  extern x_query_tree
  extern x_send_request
;---------------------
;>1 win_info
;  window_find - search for window
; INPUTS
;    al = flag 0=search x win titles,  1=search x win class
;              2=search win mgr titles 3=search win mgr class
;    ebx = ptr to asciiz search string
;          (Can be fragment or partial string
;           that occurs within title or class)
;    ecx = work buffer to hold windows.  Size
;          greater than: ( (max windows) * 4 ) + 30
;          Memory fault could occur if buffer too small
;    edx = buffer length
; OUTPUT:
;    flag set (jns) if success
;    flag set (js) if err, eax=error code
;
;    if success ecx -> buffer with:
;      window id's, end of list has
;      dword with zero.
;              
; NOTES
;   source file: window_find.asm
;   lib_buf is used as work buffer
;<
; * ----------------------------------------------

  global window_find
window_find:
  mov	[search_flag],eax
  mov	[search_str],ebx
  mov	[search_buf],ecx
;setup to collect all children
  test	al,2			;x or window mgr
  jz	wf_x
;get window list from window manager
  mov	ecx,atom_pkt
  mov	edx,atom_pkt_end - atom_pkt
  neg	edx		;indicate reply expected
  call	x_send_request
  call	x_wait_reply
  js	wf_error
  mov	esi,[ecx+8]	;get atom
  mov	edi,21h		;atom type
  mov	eax,[root_win_id] ;get root window id
  mov	ecx,lib_buf
  mov	edx,700		;buffer size
  call	x_get_property       
  js	wf_error
  lea	esi,[ecx+32]	;get list address
  mov	edi,[search_buf] ;get stuff buf
  mov	[get_id_ptr],edi
  mov	[stuff_id_ptr],edi
  mov	ecx,[ecx+16]	;get number of entries
  mov	[window_count],ecx
  rep	movsd		;move id's
  jmp	short wf_loop
;get window list from x server
wf_x:
  mov	eax,[root_win_id]
  mov	[ecx],eax		;put id in buffer
  mov	esi,ecx			;buffer start to esi
  mov	edi,ecx			;form
  add	edi,4			; buffer end ptr
  mov	[stuff_id_ptr],edi
  call	get_children		;returns esi,edi unchanged  
  js	wf_error
;setup to process all windows on list
; edi = ptr to end of list
; [search_buf] has list start
  mov	ecx,[search_buf]
  mov	[get_id_ptr],ecx	;save ptr to first id
  mov	edi,[stuff_id_ptr]
  sub	edi,esi		;compute length of buffer
  shr	edi,2		;convert to count
  mov	[window_count],edi ;save number of windows found
  mov	[stuff_id_ptr],ecx	;restart stuff ptr
;interrogate each window
wf_loop:
  cmp	[window_count],word 0
  jne	wf_get_attr		;jmp if more entries
  jmp	wf_done			;jmp if end of list
wf_get_attr:
;search setup
  mov	eax,[get_id_ptr]
  mov	eax,[eax]		;get window id
  mov	ecx,lib_buf		;buffer
  mov	edx,700			;buffer length
  test	[search_flag],byte 1	;title search
  jnz	wf_class_search		;jmp if class search
;title search - read window title property
  mov	esi,39			;atom = WM_NAME (27h)
  mov	edi,0			;atom type
  call	x_get_property
  jmp	short wf_srch		;go do search
wf_class_search:
  mov	esi,67			;atom = WM_CLASS (43h)    
  mov	edi,31			;atom type (1fh)
  call	x_get_property
wf_srch:
  js	wf_error
  lea	edi,[ecx+32]		;search start address
  xor	eax,eax
  mov	ax,[ecx+16]		;get size of search buf
  lea	ebp,[edi + eax*4]	;get search buffer end  
  mov	esi,[search_str]	;get search string
  cmp	[esi],byte 0		;if string=0 then match all
  jz	wf_match		;jmp if match all
  mov	edx,1			;forward search flag
  mov	ch,0ffh			;match case
  call	blk_find
  jc	wf_next			;jmp if not found
;we have found a match, save id
wf_match:
  mov	eax,[get_id_ptr]
  mov	eax,[eax]		;get window id
  mov	edi,[stuff_id_ptr]
  stosd				;store id
  mov	[stuff_id_ptr],edi
wf_next:
  add	[get_id_ptr],dword 4
  dec	dword [window_count]
  jmp	wf_loop
wf_done:
  mov	edi,[stuff_id_ptr]
  xor	eax,eax
  stosd				;terminate the list
wf_error:
  mov	ecx,[search_buf]
  ret
  
;------------
  [section .data]
search_flag:	dd 0
search_str:	dd 0
search_buf:	dd 0
get_id_ptr:	dd 0		;ptr to trail id
stuff_id_ptr:	dd 0		;success stuff ptr
window_count:	dd 0

atom_pkt:	db 10h		;interatom opcode
		db 0
		dw 06		;request length
		dw 16		;name lenght
		dw 0		;unused
		db '_NET_CLIENT_LIST'
atom_pkt_end:

  [section .text]
;------------------------------------------------
;recursive routine to get children
; input: esi = ptr to list of window id's
;        edi = ptr to end of window id's (beyond last valid id)
;        stuff_id_ptr = global pointer to children storage area
;
get_children:
  push	esi
  push	edi
;query tree for next window id
next_child:
  mov	eax,[esi]	;get next win id
  mov	ecx,[stuff_id_ptr] ;get buffer to use
  mov	edx,1000	;buffer length
  push	esi
  push	edi
  call	x_query_tree
  pop	edi
  pop	esi
  js	nc_abort	
  xor	ebx,ebx
  mov	bx,[ecx+16]		;get child count
  or	ebx,ebx
  jz	no_children
;add children to end of list
  push	esi
  push	edi
  lea	esi,[ecx+32]	;get ptr to first child
  mov	edi,[stuff_id_ptr]
gc_lp1:
  movsd
  dec	ebx
  jnz	gc_lp1		;loop till children stored
;setup for recursion
  mov	esi,[stuff_id_ptr]	;get start of list
  mov	[stuff_id_ptr],edi	;update stuff_id_ptr
  call	get_children        
  pop	edi
  pop	esi
  js	nc_abort
no_children:
  add	esi,4
  cmp	esi,edi
  jb	next_child
  pop	edi
  pop	esi
  xor	eax,eax		;set normal exit
nc_abort:
  ret


  [section .text]

%ifdef DEBUG

extern crt_str
extern x_send_request
extern env_stack
extern x_wait_big_reply
extern x_connect
extern root_win_id

global _start
_start:
  call	env_stack
  call	x_connect
  mov	eax,3		;flag, search window class
  mov	ebx,search_string
  mov	ecx,buffer
  mov	edx,buffer_len
  call	window_find
  mov	eax,[ecx]	;get window id
  mov	eax,01
  int	byte 80h

;-----------
  [section .data]
buffer_len equ 4000
buffer: times buffer_len db 0
search_string:	db 'xterm',0
  [section .text]

%endif
