  extern window_id_color
  extern window_clear_area
  extern trace_regsget

;------------ register window -----------------------
;
; colors: 
;     regMenuForButton=skyblue
;     regMenuBButton=blue
;     regBColor=blue
;     regFColor=white
;     regChangeBColor=blue
;     regChangeFColor=green
;
; window size and loction
;     upper left corner = 0,0
;     width = 14
;     height = 11
;
; ---- menu line ----
; -eax=
; -ebx=
; -ecx=
; -edx=
; -esi
; -edi
; -ebp
; -esp
; -eip
;  ODITSZAPC
;  oditszapc

;------------------------------------------------------------------
reg_win_setup:
  mov	byte [win_bit_map],3fh	;enable all windows and outlines
  ret

;----------------------------------------------------------------
register_menu:
;display fixed window areas
  mov	ebx,[regFColor]
  mov	ecx,[regBColor]
  call	window_id_color
 
  xor	eax,eax			;x location (col)
  xor	ebx,ebx			;y locatin (row)
  mov	ecx,14			;width
  mov	edx,11			;height
  mov	esi,1			;use current color
  call	window_clear_area
  mov	ebx,[regMenuForButton]
  mov	ecx,[regMenuBButton]
  call	window_id_color
rm_50:
  mov	esi,reg_menu_block
  call	window_write_table

  mov	ebx,[regFColor]
  mov	ecx,[regBColor]
  call	window_id_color

  mov	esi,reg_block
  call	window_write_table
rm_exit:
  ret
;-----------------------------------------------------------------
show_regs:
  test	byte [win_bit_map],1
  jz	sr_10			;jmp if menu in place
  call	register_menu
;display register values
sr_10:
sr_12:
  mov	esi,reg_tbl
  mov	[reg_row],byte 1
sr_lp:
  lodsd			;get regs_1 ptr
  or	eax,eax
  jz	sr_50		;jmp if done
  mov	ebx,eax
  lodsd			;get regs_2 ptr
  push	esi
  mov	ebx,[ebx]	;get regs_1 value
  push	ebx
  cmp	ebx,[eax]	;has register changed  
  jne	sr_changed
  mov	ebx,[regFColor]
  mov	ecx,[regBColor]
  jmp	short sr_20
sr_changed:
  mov	ebx,[regChangeFColor]
  mov	ecx,[regChangeBColor]
sr_20:
  call	window_id_color
;display register value
  pop	eax		;get register value
  mov	edi,reg_build
  call	dwordto_hexascii

  mov	ecx,5		;column
  mov	edx,[reg_row]	;row
  mov	esi,reg_build
  mov	edi,8		;string length
  call	window_write_line
  pop	esi
  inc	dword [reg_row]
  jmp	short sr_lp
;display flags
sr_50:
  mov	ebx,[regFColor]
  mov	ecx,[regBColor]
  call	window_id_color

  mov	esi,flag_letters	;upper case letters
  mov	edi,flag_build
  mov	ebx,[r1_flags]
  shl	ebx,20			;position flag start
  mov	ecx,12			;loop counter
sr_60:
  lodsb			;get next letter
  rol	ebx,1
  jc	sr_70
  or	al,20h		;unset (to lower case)
sr_70:
  cmp	al,20h
  je	sr_80		;skip unused flag positions
  stosb
sr_80:
  loop	sr_60
;write flag data
  mov	ecx,4		;column
  mov	edx,10		;row
  mov	esi,flag_build
  mov	edi,10		;length of flags  
  call	window_write_line
sr_exit:
  ret


;---------------
  [section .data]
 align 4

reg_row: dd 0	;current display row

reg_tbl:
  dd r1_eax,r2_eax
  dd r1_ebx,r2_ebx
  dd r1_ecx,r2_ecx
  dd r1_edx,r2_edx
  dd r1_esi,r2_esi
  dd r1_edi,r2_edi
  dd r1_ebp,r2_ebp
  dd r1_esp,r2_esp
  dd r1_eip,r2_eip
  dd 0

regs_1:
r1_ebx	dd 0
r1_ecx	dd 0
r1_edx	dd 0
r1_esi	dd 0
r1_edi	dd 0
r1_ebp	dd 0
r1_eax	dd 0
r1_ds 	dd 0
r1_es 	dd 0
r1_fs 	dd 0
r1_gs 	dd 0
r1_old_eax dd 0
r1_eip	dd 0
r1_cs 	dd 0
r1_flags dd 0
r1_esp	dd 0
r1_ss 	dd 0

regs_2:
r2_ebx	dd 0
r2_ecx	dd 0
r2_edx	dd 0
r2_esi	dd 0
r2_edi	dd 0
r2_ebp	dd 0
r2_eax	dd 0
r2_ds 	dd 0
r2_es 	dd 0
r2_fs 	dd 0
r2_gs 	dd 0
r2_old_eax dd 0
r2_eip	dd 0
r2_cs 	dd 0
r2_flags dd 0
r2_esp	dd 0
r2_ss 	dd 0

reg_build: times 8 db 0

flag_letters: db 'ODITSZ A P C'
flag_build:   db '            '
reg_menu_block:
  db 12
  dw 1		;column
  dw 0		;row
  db 3		;length
  db ' ? '

;  db 12
;  dw 5		;column
;  dw 0		;row
;  db 4		;length
;  db 'Menu'

  db 0

reg_block:
  db 12		;write line
  dw 1		;column
  dw 1		;row
  db 4		;length of string
eax_txt:
  db 'EAX='

  db 12		;write line
  dw 1		;column
  dw 2		;row
  db 4		;length of string
ebx_txt:
  db 'EBX='

  db 12		;write line
  dw 1		;column
  dw 3		;row
  db 4		;length of string
ecx_txt:
  db 'ECX='

  db 12		;write line
  dw 1		;column
  dw 4		;row
  db 4		;length of string
edx_txt:
  db 'EDX='

  db 12		;write line
  dw 1		;column
  dw 5		;row
  db 4		;length of string
esi_txt:
  db 'ESI='

  db 12		;write line
  dw 1		;column
  dw 6		;row
  db 4		;length of string
edi_txt:
  db 'EDI='

  db 12		;write line
  dw 1		;column
  dw 7		;row
  db 4		;length of string
ebp_txt:
  db 'EBP='

  db 12		;write line
  dw 1		;column
  dw 8		;row
  db 4		;length of string
esp_txt:
  db 'ESP='

  db 12		;write line
  dw 1		;column
  dw 9		;row
  db 4		;length of string
eip_txt:
  db 'EIP='

  db 12		;write line
  dw 1		;column
  dw 10		;row
  db 3		;length of string
  db 'FL='

  db 0		;end of table

  [section .text]
