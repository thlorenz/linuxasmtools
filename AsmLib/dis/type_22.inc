  [section .text]
;*********** type22 ****************
;
;inputs:
; [edx] = decode_table entry
; [ebp]= ptr to opcode d8 -> df
;   [ebp+1] mod/rm   xx,yyy,zzz
;          xx=mod yyy=opcode extension  zzz=register eax+
;          if mod/rm > bf then special cases
; edi = stuff ptr

;output: al 80h = done flag
;        al 7fh = legal prefixs 
;------------------------------------------------------------------

;type s22
;         0-bf
; opcode  mod/rm
;         nnn bits
; ------  ------
;   d8    000       fadd (mod/rm)
;   d8    001       fmul
;   d8    010       fcom
;   d8    011       fcomp
;   d8    100       fsub
;   d8    101       fsubr
;   d8    110       fdiv
;   d8    111       fdivr
;
;         c0-ff
;         mod/rm
;         ------
;   d8    11,000,000 -> 11,000,111 (c0-c7)     fadd st0-st7
;   d8    11,001,000 -> 11,001,111 (c8-cf)     fmul st0-st7
;   d8    11,010,000 -> 11,010,111 (d0-d7)     fcom st0-st7
;   d8    11,011,000 -> 11,011,111 (d8-df)     fcomp st0-st7
;   d8    11,100,000 -> 11,100,111 (e0-e7)     fsub st0-st7
;   d8    11,101,000 -> 11,101,111 (e8-ef)     fsubr st0-st7
;   d8    11,110,000 -> 11,110,111 (f0-f7)     fdiv st0-st7
;   d8    11,111,000 -> 11,111,111 (f8-ff)     fdivr st0-st7


type_s22:		;( s0c)
  mov	bl,byte [ebp+1]		;get mod/rm byte
  cmp	bl,0c0h			;check mod/rm value
  jae	t12_special		;jmp if special processing
  call	decode_rm		;go decode mod rm
  jmp	short t12_done
t12_special:
  mov	ax,'st'
  stosw				;store part of reg
  and	bl,7			;isolate register
  or	bl,'0'			;convert to ascii
  mov	al,bl
  stosb				;complete register code
  add	ebp,2			;instruction size = 2
t12_done:
  mov	al,0ah
  stosb
  mov	al,80h			;get done code
  ret  
  

