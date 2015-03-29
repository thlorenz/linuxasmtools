
  extern x_check_event
  extern x_read_socket
  extern x_key_translate

  extern x_key_decode
;%include "x_key_decode.inc"
  extern x_mouse_decode
;%include "x_mouse_decode.inc"


struc mouse_pkt
.code	resb 1		;code = 4(press) 5(release) 6(MotionNotify)
.but	resb 1		;evemt window code
.seq	resw 1		;pkt sequence#
.time	resd 1		;time of event
.root	resd 1		;root win id
.ewinn	resd 1		;event win id
.cwin	resd 1		;child win (0=none)
.rootx	resw 1		;root pix column
.rooty	resw 1		;root pix row
.eventx resw 1		;event pix column
.eventy resw 1		;event pix row
.mask	resw 1		;event bits
.same	resb 1		;same screen bool
	resb 1		;unused
;mask bits are:
; 10-numlock 08-alt 04-ctrl 02-caplock 01-shift
endstruc

;--------------------------------------------------
;output; eax=process or zero
check_socket:
  call	x_check_event
;   eax = -1 "js" error
;          0 "jz" no socket pkts, no pending replies
;          1  socket pkt avail.
;          2  expecting reply
;          3  socket pkt avail. & expecting reply
  js	ce_error
  jz	ce_exit2
  cmp	al,2		;reply expected
  je	ce_error	;jmp no events, and reply expected (future timeout?)
;read event
  mov	ecx,lib_buf
  mov	edx,700
  call	x_read_socket
  js	ce_error
%ifdef TRACE
  call	socket_trace
%endif
  mov	al,[ecx]		;get packet opcode
  cmp	al,2			;key event?
  jne	cs_15			;jmp if not key event
  call	key_decode
  jmp	short ce_exit
cs_15:
  cmp	al,4
  jne	cs_25
  call	mouse_decode
  jmp	short ce_exit
cs_25:
  cmp	al,12
  jne	ce_35			;jmp if not expose
  or	[win_bit_map],byte 1fh	;enable redisplay
  mov	[window_delay_count],word 1000
  jmp	short ce_exit2
ce_35:
;setup to display event message  
  call	x_wait_event
  jmp	ce_exit3
ce_error:
%ifdef TRACE
  call	error_trace
%endif
;setup to show socket error msg  
ce_exit3:
  or	[event_mode],byte 1	;set exit
ce_exit2:
  xor	eax,eax		;clear returned event
ce_exit:
  ret

key_decode:
  call	x_key_translate
  mov	ebx,eax
  mov	esi,key_decode_table
  call	x_key_decode
  ret

mouse_decode:
  movzx eax,word [ecx+mouse_pkt.eventy]	;get pixel row
  xor	edx,edx
  div	word [ebp+win.s_char_height]	;compute click row

  cmp	al,11				;check if in code window
  jae	md_20				;jmp if in code win

  movzx	eax,word [ecx+mouse_pkt.eventx]	;get pixel column
  xor	edx,edx
  div	word [ebp+win.s_char_width]

  cmp	al,24
  jae	md_40				;jmp if mem window
  cmp	al,14
  jae	md_30				;jmp if break window
;assume this is reg window click
  mov	esi,mouse_reg_decode
  jmp	short md_80
md_20:
  mov	esi,mouse_code_decode
  jmp	short md_80
md_30:
  mov	esi,mouse_break_decode
  jmp	short md_80
md_40:
  mov	esi,mouse_mem_decode
md_80:
  call	x_mouse_decode
  ret

  [section .data]
;------------------------------------------------------------
key_decode_table:

 dw 40beh
 dd key_f1	;f1=freg popup

 dw 813fh
 dd key_?
;----
 dw 8061h
 dd brk_add

 dw 807ah
 dd brk_zap
;----

 dw 8063h		;c
 dd calc_help

 dw 8062h
 dd mem_db

 dw 8077h
 dd mem_dw

 dw 8064h
 dd mem_dd

 dw 813ch		;'<'
 dd mem_history_bak

 dw 4051h
 dd mem_history_bak

 dw 4096h
 dd mem_history_bak

 dw 813eh		;'>'
 dd mem_history_fwd

 dw 4053h
 dd mem_history_fwd

 dw 4098h
 dd mem_history_fwd

 dw 806ch		;'l'
 dd mem_string

 dw 4452h	;control-up
 dd mem_up

 dw 4454h
 dd mem_down

 dw 4455h
 dd mem_pgup

 dw 4456h
 dd mem_pgdn

 dw 4497h	;control-up
 dd mem_up

 dw 4499h
 dd mem_down

 dw 449ah
 dd mem_pgup

 dw 449bh
 dd mem_pgdn

 dw 400dh
search_stuf:	;current search routine
 dd mem_search_continue
;----
 dw 8067h
 dd code_go

 dw 8073h
 dd code_step

 dw 8020h
 dd code_step

 dw 806fh
 dd code_stepo

 dw 8070h
 dd code_prep

 dw 8066h
 dd code_find

 dw 8071h
 dd code_quit

 dw 4052h	;control-up
 dd code_up

 dw 4054h
 dd code_down

 dw 4055h
 dd code_pgup

 dw 4056h
 dd code_pgdn

 dw 4097h	;control-up
 dd code_up

 dw 4099h
 dd code_down

 dw 409ah
 dd code_pgup

 dw 409bh
 dd code_pgdn

 dw 806bh	;k
 dd kill_app1

 dd 0	;end of table

;--------------------------------------------------

;-------------------- start row=0  next window row = 11
; 01234567890123  <- window start column 0
; _EAX=xxxxxxxx_     next window at column 14
;--------------------
mouse_reg_decode:
;;
 db 01 ;start col
  db 03 ;end col
  db 00 ;start row
  db 00 ;end row
  dd reg_mouse_?
;;
 db 01 ;start col
  db 03 ;end col
  db 01 ;start row
  db 10 ;end row
  dd reg_name_click
;;
 db 04 ;start col
  db 13 ;end col
  db 01 ;start row
  db 10 ;end row
  dd reg_value_click

  dd 0		;end of table
;--------------------------------------
mouse_break_decode:
;;
 db 14 ;start col
  db 14 ;end col
  db 00 ;start row
  db 00 ;end row
  dd brk_?
;;
 db 16 ;start col
  db 18 ;end col
  db 00 ;start row
  db 00 ;end row
  dd brk_add
;;
 db 20 ;start col
  db 22 ;end col
  db 00 ;start row
  db 00 ;end row
  dd brk_zap
;; toggle or menu
 db 14 ;start col
  db 24 ;end col
  db 01 ;start row
  db 10 ;end row
  dd brk_pop_up

  dd 0		;end of table
;---------------------------------------
mouse_mem_decode:
;;
 db 25 ;start col
  db 27 ;end col
  db 00 ;start row
  db 00 ;end row
  dd mem_mouse_?
;;
 db 29 ;start col
  db 30 ;end col
  db 00 ;start row
  db 00 ;end row
  dd mem_db
;;
 db 32 ;start col
  db 33 ;end col
  db 00 ;start row
  db 00 ;end row
  dd mem_dw
;;
 db 35 ;start col
  db 36 ;end col
  db 00 ;start row
  db 00 ;end row
  dd mem_dd
;;
 db 38 ;start col
  db 38 ;end col
  db 00 ;start row
  db 00 ;end row
  dd mem_history_bak
;;
 db 40 ;start col
  db 63 ;end col
  db 00 ;start row
  db 00 ;end row
  dd mem_string
;; scroll bar decode
 db 63 ;start col
  db 64 ;end col
  db 01 ;start row
  db 01 ;end row
  dd mem_up
;;
 db 63 ;start col
  db 64 ;end col
  db 02 ;start row
  db 04 ;end row
  dd mem_pgup
;;
 db 63 ;start col
  db 64 ;end col
  db 10 ;start row
  db 10 ;end row
  dd mem_down
;;
 db 63 ;start col
  db 64 ;end col
  db 07 ;start row
  db 09 ;end row
  dd mem_pgdn
;
 db 24 ;start col
  db 64 ;end col
  db 01 ;start row
  db 11 ;end row
  dd mem_pop_up

  dd 0			;end of table

;------------------------------
mouse_code_decode:
;;
 db 01 ;start col
  db 03 ;end col
  db 11 ;start row
  db 11 ;end row
  dd code_mouse_?
;;
 db 05 ;start col
  db 06 ;end col
  db 11 ;start row
  db 11 ;end row
  dd code_go
;;
 db 08 ;start col
  db 11 ;end col
  db 11 ;start row
  db 11 ;end row
  dd code_step
;;
 db 13 ;start col
  db 17 ;end col
  db 11 ;start row
  db 11 ;end row
  dd code_stepo
;;
 db 19 ;start col
  db 22 ;end col
  db 11 ;start row
  db 11 ;end row
  dd code_prep
;;
 db 24 ;start col
  db 54 ;end col
  db 11 ;start row
  db 11 ;end row
  dd code_find
;;
 db 59 ;start col
  db 63 ;end col
  db 11 ;start row
  db 11 ;end row
  dd code_quit
;;
;scroll bar actions
;;
 db 63 ;start col
  db 64 ;end col
scroll_up:
  db 00 ;start row
  db 00 ;end row
  dd code_up
;;
 db 63 ;start col
  db 64 ;end col
scroll_pgup:
  db 00 ;start row
  db 00 ;end row
  dd code_pgup
;;
 db 63 ;start col
  db 64 ;end col
scroll_down:
  db 00 ;start row
  db 00 ;end row
  dd code_down
;;
 db 63 ;start col
  db 64 ;end col
scroll_pgdn:
  db 00 ;start row
  db 00 ;end row
  dd code_pgdn

 db 00	;start col
 db 09	;end col
 db 11  ;start row
 db 99	;end row (all rows)
 dd code_popup_adr

 db 12	;start col
 db 62	;end col
 db 11	;start row
 db 99	;end row (all rows)
 dd code_popup_operand

  dd 0		;end of table



  [section .text]
;--------------------------------------------------
