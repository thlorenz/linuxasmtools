

  [section .text align=1]



  [section .text]



extern x_connect
extern root_win_id
extern env_stack
extern sys_exit
extern x_query_pointer
 extern x_get_input_focus
extern delay
 extern word_to_ascii
 extern stdout_str

global _start
_start:
  call	env_stack
  call	x_connect

query_loop:
  call	x_get_input_focus
  js	use_root
  mov	eax,[ecx+8]
  jmp	short do_query
use_root:
  mov	eax,[root_win_id]
do_query:
  mov	ecx,query_pkt
  call	x_query_pointer
  js	error
  mov	esi,ecx
  mov	edi,query_pkt
  mov	ecx,query_pkt_size
  rep	movsb

  test	word [event],100h + 400h
  jnz	got_click
no_event:
  mov	eax,4000
  call	delay
  jmp	query_loop
;we have got a click
got_click:
  mov	eax,'    '
  mov	[rootx],eax
  mov	[rooty],eax

  mov	eax,[root_x]
  cmp	eax,[rootx_save]
  je	no_event		;ignore if no movement
  mov	[rootx_save],eax
  mov	edi,rootx
  call	word_to_ascii

  mov	eax,[root_y]
  mov	edi,rooty
  call	word_to_ascii


  mov	ecx,log_txt
  call	stdout_str

  test	word [event],400h
  jnz	error		;exit if right click
  jmp	query_loop
  
error:
  call	sys_exit

;-----------
  [section .data]
rootx_save	dd 0

query_pkt:
  db 0 ;reply 1=success 0=fail
  db 0 ;-
  dw 0 ;sequence#
  dd 0 ;reply length (zero)
root_window_id:
  dd 0 ;root window id
child_window_id:
  dd 0 ;child window id (0=no child)
root_x:
  dw 0 ;root x position (pixel column)
root_y:
  dw 0 ;root y position (pixel row)
child_x:
  dw 0 ;child x position (pixel column)
child_y:
  dw 0 ;child y position (pixel row)
event:
  dw 0 ;event mask
;         SETofKEYBUTMASK
;          #x0001	 Shift
;          #x0002	 Lock
;          #x0004	 Control
;          #x0008	 Mod1
;          #x0010	 Mod2
;          #x0020	 Mod3
;          #x0040	 Mod4
;          #x0080	 Mod5
;          #x0100	 Button1
;          #x0200	 Button2
;          #x0400	 Button3
;          #x0800	 Button4
;          #x1000	 Button5
;          #xE000	 unused but must be zero
;              
overflog times 8 db 0
query_pkt_size equ $ - query_pkt

log_txt: db 0ah
  db 'rootx='
rootx:
  db '0000 '
  db 'rooty='
rooty:
  db '0000 '
  db 0

  [section .text]

