
  [section .text]
;***********   type_03  ****************
;
;  input:  ebp = current opcode ptr
;          edi = stuff ptr
;          edx = ptr to decode_table entry
;              db zxyyyyyy  where z=instruction has/hasn't operand
;                                 x=??  y=process index
;              db ?         warn bit, seg reg 3bits, type code 4 bits
;              dw name      index to opcode text (name)
;          ebx = decode_table entry
;ebx=[optxt ndx] bh=[warn ] [seg reg] [inst type] bl=[operand] [] [process id]
;    [ 16 bits ]    [ 1bit] [3bits  ] [ 4bits   ]    [1bit   ] [] [6 bits]
;                
;  output: al = legal prefix's (prefix_flag) if done high bit is set
;------------------------------------------------------------------

;------------------------------------------------------------------
;type s03 - single opcode

; opcode       segment operand warn  instrction    exit 
;              reg     flag    flag  type          prefix in al
; ------       ------  ------  ---   -----------   -------------
; 06 push es     0       1      4     0(normal)      80h  done
; 07 pop  es     0       1      4     0              80h
; 0e push cs     1       1      4     0              80h
; 16 push ss     2       1      4     0              80h
; 17 pop  ss     2       1      4     0              80h
; 1e push ds     3       1      4     0              80h
; 1f pop  ds     3       1      4     0              80h
; 27 daa         -       0      -     0              80h
; 2f das         -       0      -     0              80h
; 37 aaa         -       0      -     0              80h
; 3f aas         -       0      -     0              80h
; 60 pusha       -       0      -     0              80h
; 61 popa        -       0      -     0              80h
; 9e sahf        -       0      -     0              80h
; 9f lahf        -       0      -     0              80h
; c3 ret         -       0      -     8(jmp/ret)     80h
; c9 leave       -       0      -     0              80h
; cc int3        -       0      8     0              80h
; cb retf        -       0      8     8(jmp/ret)     80h
; ce into        -       0      8     4              80h
; cf iret        -       0      8     4(system)      80h
; d7 xlat        -       0      -     0              80h
; f4 hlt         -       0      8     8              80h
; f5 cmc         -       0      -     0              80h
; f8 clc         -       0      -     0              80h
; f9 stc         -       0      -     0              80h
; fa cli         -       0      -     0              80h
; fb sti         -       0      -     0              80h
; fc cld         -       0      -     0              80h
; fd std         -       0      -     0              80h
; 9c pushf       -       0      -     0              80h
; 9d popf        -       0      -     0              80h
; 9b wait        -       0      8     4              80h
;0f06 clts       -       0      -     4(system)      c0h done + esc
;0fa2 cpuid      -       0      -     0              c0h
;0fa1 pop  fs    4       1      4     0              c0h
;0fa9 pop  gs    5       1      4     0              c0h
;0fa0 push fs    4       1      4     0              c0h
;0fa8 push gs    5       1      4     0              c0h
;
;  f0 lock               0            0
;
; Note: "lock" can only apply to selected instructions and makes
;       it difficult to adjust "inst" text later.  For these reasons
;       it is treated as separate instruction.
;
type_s03:
  mov	al,bh		;get instruction type
  and	al,0fh		;isolate instruction type
  mov	[instruction_type],al

  test	bl,80h		;is operand present
  jz	s03_2		;jmp if no operand
;stuff segment operand
  or	byte [warn_flag],4 ;warn segment register usage
  shr	bh,4		;position seg reg
  and	bh,7		;isolate seg reg code
  mov	bl,bh		;put in  bl
  mov	bh,-4		;segment register indicator
  call	stuff_reg
  mov	al,0ah
  stosb			;terminate string
  jmp	short s03_4
;check if warn flag set
s03_2:
  test	bh,80h		;warn flag set
  jz	s03_4		;jmp if no warn flag
  or	byte [warn_flag],08h ;unusual instruction
;build exit code
s03_4:
  mov	al,80h		;done 
  test	byte [state_flag],40h ;does this inst. have esc prefix
  jz	s03_6		;jmp if no esc prefix
  or	al,40h
s03_6:
  inc	ebp		;move to next instruction
  ret  

;------------------------------------------------------------------
