  [section .text]
;*********** type30 ****************
;
;inputs:
; [edx] = ptr to decode_table entry
; [ebp]= ptr to opcode d8 -> df
;   [ebp+1] mod/rm   xx,yyy,zzz
;          xx=mod yyy=opcode extension  zzz=register eax+
;          if mod/rm > bf then special cases
; edi = stuff ptr

;output: al 80h = done flag
;        al 7fh = legal prefixs 
;------------------------------------------------------------------

;------------------------------------------------------------------

;type s30 
;
; opcode  mod/rm
; ------  --------------
; 8e      11 (seg) (reg)   mov seg,reg
; 8c      11 (seg) (reg)   mov reg,seg

type_s30:
  mov	bl,byte [ebp+1]		;get mod/rm byte
  test	byte [ebp],02h		;check opcode
  jz	t30_10			;jmp if reg,seg (opcode 8c)
;this is mov seg,reg (opcode 8e)
  shr	bl,3
  and	bl,7			;isolate set
  mov	bh,-4			;set type = es,cs,
  call	stuff_reg
  mov	al,','
  stosb
  mov	bl,byte [ebp+1]
  and	bl,7
  mov	bh,-2			;type = ax,cx,..
  call	stuff_reg
  jmp	short t30_90
;this is a mov reg,seg (opcode 8c)
t30_10:
  and	bl,7
  mov	bh,-2			;type = ax,cx,..
;the following is a nasm kludge.  the prefix 66h is generated if just ax is used
  test	[state_flag],byte 10h	;was 66h prefix found
  jnz	t30_15			;jmp if no prefix
  mov	bh,-1
t30_15:
  call	stuff_reg
  mov	al,','
  stosb
  mov	bl,byte [ebp+1]
  shr	bl,3
  and	bl,7			;isolate reg
  mov	bh,-4			;set type = es,cs
  call	stuff_reg

t30_90:
  add	ebp,byte 2
  mov	al,0ah			;put 0ah at end of string
  stosb
  mov	al,90h			;get done code + prefix 66h ok
  ret  


;------------------------------------------------------------------

