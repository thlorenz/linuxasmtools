;---------------------------------------------------
;>1 vt
;vt_in - feed input data to vt
; INPUT
;   ecx = ptr to input data
;   edx = length of input data
; OUTPUT
;   
; NOTE
;   Normally we read data from stdin and feed our
;   vt world by using vt_in.  It is also possible
;   to feed arbatrary commands to vt programs.
;<
;---------------------------------------------------
  [section .text align=1]

  extern ptty_fd
  extern sys_write
  extern vt_top_row
  extern vt_top_left_col

  global vt_in
vt_in:
;handle mouse clicks
; mouse click report = <esc> [m 2x 2r 2c  x=button r=row c=col
; cursor report = <esc> [xx;yyR is handled elsewhere.
;
  cmp	[ecx],byte 1bh	;possible lead in
  jne	send_key
  cmp	[ecx+1],byte '['
  jne	send_key
  cmp	[ecx+2],byte 'M'
  je	mouse_fix
send_key:
  mov	ebx,[ptty_fd]
;  mov	edx,eax		;size of key read
;  mov	ecx,work_buf
  call	sys_write
  ret

mouse_fix:
  mov	bl,[vt_top_row]
  sub	[ecx+5],bl
  mov	bl,[vt_top_left_col]
  sub	[ecx+4],bl
  jmp	short send_key


