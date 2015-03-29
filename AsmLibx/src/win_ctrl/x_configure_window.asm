
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
;---------- x_configure_window ------------------

  extern x_send_request

;---------------------
;>1 win_ctrl
;  x_configure_window - get list of windows
; INPUTS
;    eax = window id to move/resize
;    ebx = bit mask
;    esi = ptr to list of word values
;
;     bit mask bits and values possible are:
;      0000001h  ;new x pixel column (window position)
;      0000002h  ;new y pixel row (window position)
;      0000004h  ;new window width
;      0000008h  ;new window height
;      0000010h  ;new border width
;      0000020h  ;sibling
;      0000040h  ;stack-mode flag
;
;     values:
;       dw x pixel column adr
;       dw y pixel column adr
;       dw window pixel width
;       dw window pixel height
;       dw window border width
;       dd sibling
;       db stack mode 0=above
;                     1=below
;                     2=topIf
;                     3=bottomIf
;                     4=opposite
;
; OUTPUT:
;    flag set (jns) if success
;    flag set (js) if err, eax=error code
;              
; NOTES
;   source file: x_configure_window.asm
;<
; * ----------------------------------------------

  
  global x_configure_window
x_configure_window:
  mov	[xcw_win_id],eax	;save id
  mov	[xcw_mask],bx

  xor	eax,eax
  mov	edi,xcw_list
  test	bl,1
  jz	xcw_10
  movsw
  stosw
xcw_10:
  test	bl,2
  jz	xcw_20
  movsw
  stosw
xcw_20:
  test	bl,4
  jz	xcw_30
  movsw
  stosw
xcw_30:
  test	bl,8
  jz	xcw_40
  movsw
  stosw
xcw_40:
  test	bl,10h
  jz	xcw_50
  movsw
  stosw
xcw_50:
  test	bl,20h
  jz	xcw_60
  movsd
xcw_60:
  test	bl,40h
  jz	xcw_70
  movsb

xcw_70:
  sub	edi,xcw_pkt
  mov	edx,edi
xcw_80:
  test	dl,3
  jz	xcw_90			;jmp if dword boundry
  inc	edx
  jmp	short xcw_80
xcw_90:
  mov	ecx,edx			;edx=dword pkt length
  shr	ecx,2			;make dword count
  mov	[xcw_pkt_len],cx
; eax=win id  edx=pkt length
  mov	ecx,xcw_pkt
  call	x_send_request
  ret

;------------------------
  [section .data]
xcw_pkt:
  db 12		;configure window opcode
  db 0		;unused
xcw_pkt_len:
  dw 0		;request length
xcw_win_id:
  dd 0
xcw_mask:
  dw 0
  dw 0		;unused
xcw_list:
  times 6 dd 0

  [section .text]

