  extern popup_menu
  extern crt_set_color

;-------- tools.inc ------------
;
tools_popup:
  mov	esi,tp_msg
  mov	eax,tp_list
  call	show_menu
  ret

tp_list:
 dd t_reference
 dd t_color
 dd t_dis
 dd t_src
 dd t_timer
 dd t_plan
 dd t_key_echo
 dd t_exit
;
t_reference:
  mov	ebx,asmref
  jmp	short launch_it
t_color:
  mov	ebx,asmcolor
  jmp	short launch_it
t_dis:
  mov	ebx,asmdis
  jmp	short launch_it
t_src:
  mov	ebx,asmsrc
  jmp	short launch_it
t_timer:
  mov	ebx,asmtimer
  jmp	short launch_it
t_plan:
  mov	ebx,asmplan
  jmp	short launch_it
t_key_echo:
  mov	ebx,key_echo
  jmp	short launch_it
t_exit:
  ret

launch_it:
  mov	eax,ebx
  mov	ebx,f3_key_table
  call	launch
tp_exit:
  ret

;
tp_msg: db 1,0ah
 db ' ',2,'Reference',1,0ah,0ah
 db ' ',2,'Colors',1,0ah,0ah
 db ' ',2,'Disassembler',1,0ah,0ah
 db ' ',2,'Source generator',1,0ah,0ah
 db ' ',2,'Program timer',1,0ah,0ah
 db ' ',2,'Planner',1,0ah,0ah
 db ' ',2,'keyboard echo',1,0ah,0ah
 db ' ',2,'-cancel-',1,0ah,0ah,0

asmcolor: db 'asmcolor',0
asmref:   db 'asmref',0
asmsrc:   db 'asmsrc',0
asmdis:   db 'asmdis',0
asmtimer: db 'asmtimer',0
asmplan:  db 'asmplan',0
key_echo: db 'key_echo',0
;---------------------------------------------------------------
; input:  esi = ptr to text
;         eax = ptr to processes, process returns al=-1 continue al=0 exit
; output: eax = zero if no selection/ESC
show_menu:
  push	esi
  push	eax
  mov	[menu_block],esi
  mov	[process_ptrs],eax
sm_loop:
  mov	ebp,menu_block
  call	popup_menu
  or	eax,eax
  jz	sm_exit		;exit if no selection was made
  add	ecx,[process_ptrs]
  call	[ecx]
  cmp	al,-1
  jne	sm_exit1
  pop	eax
  pop	esi
  jmp	short show_menu
sm_exit1:
  xor	eax,eax
sm_exit:
  push	eax
  mov	eax,[menu_colors]
  call	crt_set_color
  call	crt_clear
  pop	eax
  pop	esi		;clear stack
  pop	esi		;clear stack
  ret  
;------
  [section .data]

process_ptrs dd 0	;ptr to process list

menu_block:
  dd 0		;text
  db 40		;total columns
  db 18		;total rows
  db 9		;starting column
  db 1		;starting row
menu_colors:
  dd	30003436h	;normal color
  dd	30003634h	;button color
  dd	31003037h	;select bar color
  

  [section .text]

;---------------------------------------------------------------
