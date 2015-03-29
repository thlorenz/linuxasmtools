
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
;---------- x_interatom ------------------

%ifndef DEBUG
  extern x_send_request
  extern x_wait_reply
%endif
  extern str_move

;---------------------
;>1 server
;  x_interatom - lookup atom code
; INPUTS
;    esi = ptr to atom name string
;
; OUTPUT:
;    flags set for jns-success  js-error
;    eax = atom code
;              
; NOTES
;   source file: x_interatom.asm
;<
; * ----------------------------------------------

  global x_interatom
x_interatom:
  mov	edi,atom_name
  call	str_move	;move sting
  sub	edi,atom_pkt    ;compute length of pkt
  mov	edx,edi		;length in edx
;compute string length
  sub	edi,8		;remove pkt top
  mov	eax,edi
  mov	[atom_name_len],ax

anc_00:
  test	dl,3		;dword boundry?
  je	anc_10		;jmp if on boundry
  inc	edx
  jmp	short anc_00
anc_10:
  mov	eax,edx
  shr	eax,2
  mov	[atom_req_len],ax

  mov	ecx,atom_pkt
;  mov	edx,atom_request_len
  neg	edx			;indicate reply
  call	x_send_request
  js	anc_exit
  call	x_wait_reply		;get response
  js	anc_exit
  mov	eax,[ecx+8]
anc_exit:
  or	eax,eax
  jnz	anc_exit2
  or	eax,byte -1
  jmp	short anc_exit
anc_exit2:
  ret

  [section .data]

atom_pkt:	db 10h		;interatom opcode
		db 0		;unused
atom_req_len:	dw 06		;request length
atom_name_len:	dw 16		;name lenght
		dw 0		;unused
atom_name:      times 16 db 0
		db 0		;keep this! str_move
;                                sets to zero
  [section .text]

%ifdef DEBUG

extern crt_str
extern x_send_request
extern env_stack
extern x_wait_reply
extern x_connect
extern root_win_id

global _start
_start:
  call	env_stack
  call	x_connect
  mov	esi,atomname
  call	x_interatom

  mov	eax,01
  int	byte 80h

;-----------
  [section .data]
atomname:	db '_NET_SUPPORTED'
  [section .text]

%endif
