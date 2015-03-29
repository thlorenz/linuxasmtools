
data_here:
  mov	esi,msg_block2
  call	show_box
  _mov	eax,3
  ret

;-------------------
  [section .data]
msg_block2:
  dd  30003436h	;color
  dd  data_menu	;message
  dd  data_menu_end
  dd  0		;scroll
  db  20	;columns inside box
  db  8		;rows inside box
  db  4		;starting row
  db  8		;starting column
  dd  30003634h	;outline color

data_menu:
  db " Key  Action ",0ah
  db " ---  ------ ",0ah
  db "  4   type=db",0ah
  db "  5   type=dw",0ah
  db "  6   type=dd",0ah
  db "  7   type=str",0ah
  db "  8   type=data ptr",0ah
  db "  9   type=code ptr",0ah
data_menu_end:

  [section .text]

