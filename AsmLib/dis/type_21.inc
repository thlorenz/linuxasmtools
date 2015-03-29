  [section .text]
;*********** type21  ****************
; file type_process.inc
;
;  input:  ebp = current opcode ptr
;          edx = ptr to database entry
;           [edx+0]= [sx-xxxxxx] [opcode-cnt-xx]
;           [edx+1]= [tag] [p] [modcol-xxxx] [operand_cnt-xx] 
;           [edx+2]=byte name index for last_prefix_name
;           [edx+4]=oper byte to store in state_flag
;          edi = stuff ptr
;  output: all registers can be modified
;------------------------------------------------------------------


;------------------------------------------------------------------
;type s21

; opcode                prefix 
;                       flag   
; ------                ------ 
; a0 mov al,[adr]        -        s11,1
; a1 mov ax/eax,[adr]    p        s11,1
;
; a2 mov [adr],al        -        s11,2
; a3 mov [adr],ax/eax    p        s11,2
; 
type_s21:
  mov	byte [t11_exit_code],80h	;preload no prefix code

  mov	ebx,[ebp+1]		;get operand
  mov	[operand],ebx
;
;decode flag field
  mov	al,[edx+1]	;get flag field
  test	al,1
  jnz	t11_50		;jmp if type1
;must be type 2 (mov [adr],reg)
;
; check if this instruction can have prefix flag
  push	eax
;check if symbol table entry
  mov	al,'['
  stosb
  mov	al,20h			;tell process it is a jump (lie)
;the following call is redundant in most areas execpt for the
;symbol table lookup.  We could look up symbols here, but it is
;nice to have it in one one place.
  call	process_operand_address
  mov	al,']'
  stosb
  pop	eax
  test	al,40h	;p bit set
  jz	t11_10			;jmp if "mov [adr],al
  or	byte [t11_exit_code],10h ;enable prefix
  test	byte [state_flag],10h	;check prefix 66h state
  jnz	t11_20			;jmp if "mov [adr],ax
;must be "mov [adr],eax
  or	byte [operand_type],10h ;dword adr
  mov	eax,',eax'
  stosd
  jmp	short t11_80

t11_10:		;mov [adr],al
  or	byte [operand_type],4h  ;byte adr
  mov	eax,',al '
  stosd
  jmp	short t11_80

t11_20:		;mov [adr],ax
  or	byte [operand_type],8h  ;word adr
  mov	eax,',ax '
  stosd
  jmp	t11_80


t11_50:		;type mov reg,[adr]
  test	al,40h	;p bit set
  jz	t11_60			;jmp if "mov al,[adr]
  or	byte [t11_exit_code],10h ;enable prefix
  test	byte [state_flag],10h	;check prefix 66h state
  jnz	t11_70			;jmp if "mov ax,[adr]
;must be "mov eax,[adr]
  or	byte [operand_type],10h ;dword adr
  mov	eax,'eax,'
  stosd
  jmp	short t11_75

t11_60:		;mov al,[adr]
  or	byte [operand_type],4h  ;byte adr
  mov	eax,' al,'
  stosd
  jmp	short t11_75

t11_70:		;mov ax,[adr]
  or	byte [operand_type],8h  ;word adr
  mov	eax,' ax,'
  stosd
t11_75:
  mov	eax,ebx			;get [adr]
;  call	stuff_adr
;check if symbol table entry
  mov	al,'['
  stosb
  mov	al,20h			;tell process it is a jump (lie)
  call	process_operand_address
  mov	al,']'
  stosb

t11_80:
  mov	al,0ah
  stosb				;put eol at end of line
  add	ebp,5			;move to next instruction
  mov	al,[t11_exit_code]
  ret
;-------------
  [section .data]
t11_exit_code:	db	0
  [section .text]

