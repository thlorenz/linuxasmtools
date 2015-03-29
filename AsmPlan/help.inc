  extern message_box

;-----------   help.asm -------------------

help:
  mov	esi,help_table
  call	message_box
  ret

;---------------
  [section .data]

help_table:
  dd	30003437h		;window color
  dd	help_msg		;text pointer
  dd	help_msg_end
  dd	0			;scroll
ht_col db 70			;columns in box
ht_row db 27			;rows in box
ht_top_row   db 2		;top row
ht_left_con  db 3		;left column
  dd	30003734h		;box color

help_msg:
 db ' KEYBOARD COMMANDS         MOUSE COMMAND',0ah
 db ' -----------------    -----------------------------------',0ah
 db '  a - add todo        In xterm all buttons can be clicked',0ah
 db '  b - page (up)',0ah   
 db '  d - del proj        To edit todo click on body',0ah
 db '  e,x - exit          To complete todo left click date',0ah
 db '  f - page (down)     To delete todo right click date',0ah
 db '  h - help',0ah
 db '  n - new proj',0ah
 db '  o - open proj              In edit window all highlights',0ah
 db '  s - search                 can be clicked to select',0ah
 db ' down - move selector down   Keyboard commands us lower',0ah
 db '  up  - move selector up     case to increment value and',0ah
 db ' space - complete            upper case to decrement',0ah
 db ' del - delete todo',0ah
 db ' enter - edit todo',0ah
help_msg_end:


  [section .text]
