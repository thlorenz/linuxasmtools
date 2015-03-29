  extern window_write_lines

;------------------------------------------------------
;general help
key_?:
;set box color
  mov	ebx,[popButFColor]
  mov	ecx,[popBColor]
  call	window_id_color
;clear box
   mov	eax,14	;left column
   mov	ebx,0	;top row
   mov	ecx,44  ;  ecx = width (chars)
   mov	edx,16  ;  edx = height (chars)
   mov	esi,1   ;  esi = flag 1=current color
  call	window_clear_area
;show text
  mov	edx,gen_txt_block
  call	window_write_lines
  call	x_wait_event
  mov	[win_bit_map],byte 1fh
  ret


;-----------------
  [section .data]

gen_txt_block:
  dd 14		;number of rows
  dd 42		;number of columns
  dd 1		;starting row
  dd 15		;starting column
  dd gen_help_txt

gen_help_txt:
 db 'AsmBug - assembly debugger',0ah
 db '       - by jeff owens',0ah
 db 'queries to:',0ah
 db ' DesktopLinuxAsm@yahoogroups.com',0ah 
 db 'features: left click on any adr',0ah
 db '          sets break',0ah
 db '        : right click pops menu',0ah
 db '        : settngs remembered',0ah
 db '        : calculator ',0ah   
 db '        : talks to x xerver',0ah 
 db 0ah
 db ' ** any key to exit **',0ah
 db 0 ;end of message

  [section .text]
;---------------------------------------------------------


  ret

;------------------------------------------------------
reg_help:
;set box color
  mov	ebx,[popButFColor]
  mov	ecx,[popBColor]
  call	window_id_color
;clear box
   mov	eax,14	;left column
   mov	ebx,0	;top row
   mov	ecx,44  ;  ecx = width (chars)
   mov	edx,18  ;  edx = height (chars)
   mov	esi,1   ;  esi = flag 1=current color
  call	window_clear_area
;show text
  mov	edx,reg_txt_block
  call	window_write_lines
  call	x_wait_event
  mov	[win_bit_map],byte 1fh
  ret


;-----------------
  [section .data]

reg_txt_block:
  dd 16		;number of rows
  dd 42		;number of columns
  dd 1		;starting row
  dd 16		;starting column
  dd reg_help_txt

reg_help_txt:
 db 'left click on value  = edit reg',0ah
 db 'right click value    = menu',0ah
 db 'left click reg name  = mem win tracking',0ah
 db 'right click reg name = menu',0ah
 db 'f1 key show extended registers',0ah
 db 0ah
 db 'flag info, upper case letter means set ',0ah
 db 'flags are: O - overflow',0ah
 db '           D - direction',0ah
 db '           I - interupt',0ah
 db '           T - trap',0ah
 db '           S - sign',0ah
 db '           Z - zero',0ah
 db '           A - auxiliary',0ah
 db '           P - parity',0ah
 db '           C - carry',0ah
 db 0ah
 db 0 ;end of message

  [section .text]
;---------------------------------------------------------
break_help:
;set box color
  mov	ebx,[popButFColor]
  mov	ecx,[popBColor]
  call	window_id_color
;clear box
   mov	eax,25	;left column
   mov	ebx,0	;top row
   mov	ecx,34  ;  ecx = width (chars)
   mov	edx,15  ;  edx = height (chars)
   mov	esi,1   ;  esi = flag 1=current color
  call	window_clear_area
;show text
  mov	edx,brk_txt_block
  call	window_write_lines
  call	x_wait_event
  mov	[win_bit_map],byte 1fh
  ret



;----------------
  [section .data]

brk_txt_block:
  dd 14		;number of rows
  dd 34		;number of columns
  dd 1		;starting row
  dd 26		;starting column
  dd break_help_txt

break_help_txt:
 db 'buttons:',0ah
 db '  Add = add break',0ah
 db '  Zap = clear all breaks',0ah
 db 'Keys:',0ah
 db '  a = add',0ah
 db '  z = zap',0ah
 db 'Mouse:',0ah
 db '  left click on address',0ah
 db '    = toggle break state',0ah
 db '  right click on address',0ah
 db '    = pop up menu',0ah
 db 0ah
 db ' ** any key to exit **',0ah
 db 0 ;end of message
;---------------------------------------------------------
  [section .text]
mem_help:
;set box color
  mov	ebx,[popButFColor]
  mov	ecx,[popBColor]
  call	window_id_color
;clear box
   mov	eax,0	;left column
   mov	ebx,0	;top row
   mov	ecx,26  ;  ecx = width (chars)
   mov	edx,26  ;  edx = height (chars)
   mov	esi,1   ;  esi = flag 1=current color
  call	window_clear_area
;show text
  mov	edx,mem_txt_block
  call	window_write_lines
  call	x_wait_event
  mov	[win_bit_map],byte 1fh
  ret



;----------------
  [section .data]

mem_txt_block:
  dd 27		;number of rows
  dd 26		;number of columns
  dd 0		;starting row
  dd 1		;starting column
  dd mem_help_txt

mem_help_txt:
 db 'buttons:',0ah
 db ' dB = byte display',0ah
 db ' dW = word display',0ah
 db ' dD = dword display',0ah
 db '  < = prior selection',0ah
 db ' (adr) = see string entry',0ah
 db ' (scroll bar) = up,dn,etc',0ah
 db 'Keys:',0ah
 db ' b = byte display',0ah
 db ' w = word display',0ah
 db ' d = dword display',0ah
 db ' < = prior selections',0ah
 db ' > = next selection',0ah
 db ' l = string entry (below)',0ah
 db ' enter = repeat search',0ah  
 db 'Pop ups:',0ah
 db ' lclick on address=menu',0ah
 db ' lclick on value = edit',0ah
 db ' rclick on value = menu',0ah
 db 'String entry:',0ah
 db ' * hex address 0x...',0ah
 db ' * register name',0ah
 db ' * label (search str)',0ah
 db ' * operation  +-*/',0ah
 db ' * calc (c=calc help)',0ah
 db 0ah
 db ' ** any key to exit **'
 db 0 ;end of message


;---------------------------------------------------------
  [section .text]
calc_help:
;set box color
  mov	ebx,[popButFColor]
  mov	ecx,[popBColor]
  call	window_id_color
;clear box
   mov	eax,0	;left column
   mov	ebx,0	;top row
   mov	ecx,30  ;  ecx = width (chars)
   mov	edx,27  ;  edx = height (chars)
   mov	esi,1   ;  esi = flag 1=current color
  call	window_clear_area
;show text
  mov	edx,calc_txt_block
  call	window_write_lines
  call	x_wait_event
  mov	[win_bit_map],byte 1fh
  ret



;----------------
  [section .data]

calc_txt_block:
  dd 27		;number of rows
  dd 30		;number of columns
  dd 0		;starting row
  dd 1		;starting column
  dd calc_help_txt

calc_help_txt:
 db 'The MEMORY window address',0ah
 db 'and CODE window -find-',0ah
 db 'buttons can be used as a',0ah
 db 'calculator',0ah
 db 0ah
 db 'Start MEMORY win calc by',0ah
 db 'click or l key. Use f key',0ah
 db 'for CODE win calc.',0ah
 db 0ah
 db 'Operators are: + - * /',0ah
 db 'Hex values start with 0x',0ah
 db 'Labels and regs accepted',0ah
 db 'Single reg name sets',0ah
 db 'tracking mode in MEMORY',0ah
 db 'win.  ',0ah
 db 0ah
 db ' eax + ebx + label - 3',0ah
 db 0ah
 db 'If result is legal address',0ah
 db 'the window data is updated,',0ah
 db 'else hex and decimal entry',0ah
 db 'is shown.  To convert value',0ah
 db 'to hex, just enter decimal',0ah 
 db 0ah
 db ' ** any key to exit **',0ah
 db 0 ;end of message



;---------------------------------------------------------
  [section .text]
code_help:
;set box color
  mov	ebx,[popButFColor]
  mov	ecx,[popBColor]
  call	window_id_color
;clear box
   mov	eax,0	;left column
   mov	ebx,0	;top row
   mov	ecx,30  ;  ecx = width (chars)
   mov	edx,23  ;  edx = height (chars)
   mov	esi,1   ;  esi = flag 1=current color
  call	window_clear_area
;show text
  mov	edx,code_txt_block
  call	window_write_lines
  call	x_wait_event
  mov	[win_bit_map],byte 1fh
  ret
;----------------
  [section .data]

code_txt_block:
  dd 23		;number of rows
  dd 30		;number of columns
  dd 0		;starting row
  dd 1		;starting column
  dd code_help_txt

code_help_txt:
 db 'buttons:',0ah
 db ' Go = run',0ah
 db ' Step = byte display',0ah
 db ' stepO =  step over',0ah
 db ' Prep = setup',0ah
 db ' Find = calc,search',0ah
 db ' (scroll bar) = up,dn,etc',0ah
 db 'Keys:',0ah
 db ' g = run',0ah
 db ' s = step',0ah
 db ' o = step over',0ah
 db ' p = setup',0ah
 db ' f = calc/find',0ah
 db ' enter = repeat search',0ah  
 db 'Pop up Menu:',0ah
 db ' l click =brk toggle',0ah
 db ' r click =menu',0ah
 db ' f1 = extended regs',0ah
 db 'Find entry:',0ah
 db ' * hex address',0ah
 db ' * label (search str)',0ah
 db ' * calc (c=calc help)',0ah
 db ' ** any key to exit **'
 db 0 ;end of message


;----------------
  [section .text]

