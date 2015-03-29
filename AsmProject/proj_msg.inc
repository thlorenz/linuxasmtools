  extern crt_window

clear_screen:
  mov	eax,30003734h
  call	crt_clear
  ret

;------------------------------------------------
; input: esi = ptr to text strings
;  
show_text_right:
  mov	[str_msg],esi
;
; find zero at end of message
;
str_lp:
  lodsb
  or	al,al
  jnz	str_lp
  dec	esi
  mov	[str_end],esi

  cmp	byte [crt_rows],0
  jne	str_10
  call	read_window_size
str_10:
  mov	al,[crt_columns]
  shr	al,1			;start in mid window
  add	al,3			;convert to 1 based
  mov	[str1],al		;total win columns
  mov	[str4],al		;starting column

  mov	al,[crt_rows]
  mov	[str2],al		;set max rows
  mov	esi,str_table
  call	crt_window
  ret
;-----------------------
  [section .data]

str_table:
         dd	30003734h	;page color
str_msg: dd	0		;ptr to text
str_end: dd	0		;end of all data for display
         dd	0		;scroll
str1:	db	0		;total win columns
str2:	db	0		;total win rows
str3:   db	1		;startng row
str4:	db	0		;starting column

;-------------------------------------------------

menu1_msg:
  db 0ah
  db 'Project Setup Hints:',0ah
  db 0ah
  db ' To select a menu item use the',0ah
  db ' UP or DOWN arrow keys.  Then',0ah
  db ' press ENTER',0ah
  db 0ah
  db ' The mouse can be used in',0ah
  db ' x terminals.',0ah
  db 0

file_browse_msg:
  db 0ah
  db ' Select directory to hold projects.',0ah
  db ' A new project directory will be',0ah
  db ' created within this directory.',0ah
  db 0ah
  db ' You can change this selection later',0ah
  db ' if necessary.',0ah
  db 0ah
  db '------------------------------------',0ah
  db 0ah
  db ' the following keys are recognized:',0ah
  db 0ah
  db ' right arrow - move into directory',0ah
  db ' left arrow  - go back one directory',0ah
  db ' up arrow    - move file select bar up',0ah
  db ' down arrow  - move file select bar down',0ah
  db ' pgup/pgdn   - move page up or down',0ah
  db ' ESC         - exit without selecting',0ah
  db ' enter       - select direcory',0ah
  db 0ah
  db ' mouse clicks also select files',0ah
  db 0

file_edit_msg:
  db 0ah
  db ' Select project to edit',0ah
  db 0ah
  db ' To select a menu item use the',0ah
  db ' UP or DOWN arrow keys.  Then',0ah
  db ' press ENTER',0ah
  db 0ah
  db ' The mouse can be used in',0ah
  db ' x terminals.',0ah
  db 0

add_project_msg:
  db 0ah
  db ' Highlight the directory name of',0ah
  db ' an existing project.',0ah
  db ' Example:  if project resides at:',0ah
  db '           /home/sam/projects/test',0ah
  db '           The directory -test- ',0ah
  db '           is highlighted.',0ah
  db 0ah
  db ' You can change this selectior later',0ah
  db ' if necessary.',0ah
  db 0ah
  db '------------------------------------',0ah
  db 0ah
  db ' the following keys are recognized:',0ah
  db 0ah
  db ' right arrow - move into directory',0ah
  db ' left arrow  - go back one directory',0ah
  db ' up arrow    - move file select bar up',0ah
  db ' down arrow  - move file select bar down',0ah
  db ' pgup/pgdn   - move page up or down',0ah
  db ' ESC         - exit without selecting',0ah
  db ' enter       - select direcory',0ah
  db 0ah
  db ' mouse clicks also select files',0ah
  db 0

project_delete_msg:
  db 0ah
  db ' Select project to delete',0ah
  db ' Files in the project directory',0ah
  db ' will not be deleted, only',0ah
  db ' the project records are updated',0ah
  db 0ah
  db ' To select a menu item use the',0ah
  db ' UP or DOWN arrow keys.  Then',0ah
  db ' press ENTER',0ah
  db 0ah
  db ' The mouse can be used in',0ah
  db ' x terminals.',0ah
  db 0

  [section .text]
