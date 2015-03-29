  [section .text]
;*********** type23 ****************
;
;inputs:
; [edx] = decode_table entry ptr
; [ebp]= ptr to opcode d8 -> df
;   [ebp+1] mod/rm   xx,yyy,zzz
;          xx=mod yyy=opcode extension  zzz=register eax+
;          if mod/rm > bf then special cases
; edi = stuff ptr

;output: al 80h = done flag
;        al 7fh = legal prefixs 
;------------------------------------------------------------------

;type s23 (s0d)
;
;         0-bf
; opcode  mod/rm
;         nnn bits
; ------  ------
;   d9    000       fld  
;   d9    001       -   (dummy entry must be here for multiple inst. decode)
;   d9    010       fst 
;   d9    011       fstp 
;   d9    100       fldenv
;   d9    101       fldcw
;   d9    110       fstenv
;   d9    111       fstcw
;
;         c0-ff
;         mod/rm
;         ------
;   d9    c0-c7     fld  st0-st7
;   d9    c8-cf     fxch st0-st7
;   d9       d0     fnop
;   d9       e0     fchs
;   d9       e1     fabs
;   d9       e4     ftst
;   d9       e5     fxam
;   d9       e8     fld1
;   d9       e9     fldl2t
;   d9       ea     fldl2e
;   d9       eb     fldpi
;   d9       ec     fldlg2
;   d9       ed     fldln2
;   d9       ee     fldz
;   d9       f0     f2xm1
;   d9       f1     fyl2x
;   d9       f2     fptan
;   d9       f3     fpatan
;   d9       f4     fxtract
;   d9       f5     fprem1
;   d9       f6     fdecstp
;   d9       f7     fincstp
;   d9       f8     fprem
;   d9       f9     fyl2xp1
;   d9       fa     fsqrt
;   d9       fb     fsincos
;   d9       fc     frndint
;   d9       fd     fscale
;   d9       fe     fsin
;   d9       ff     fcos


type_s23:		;( s0d)
  mov	bl,byte [ebp+1]		;get mod/rm byte
  cmp	bl,0c0h			;check mod/rm value
  jae	t13_special		;jmp if special processing
;handle all opcode with mod/rm in range 0-bf
  test  byte [edx+1],10h	;is this fldenv,fldcw,fnstenv,fnstcw?
  jz	t13_10			;jmp if not fldenv...
  mov	byte [skip_size_flag],1 ;turn off stuff of "dword"
t13_10:
  call	decode_rm		;go decode mod rm
  mov	byte [skip_size_flag],0	;enable stuff of size in decode_rm
  jmp	t13_done
;handle opcodes with mod/rm in range c0-ff
t13_special:
  mov	edi,inst+1		;;; this fails if lock prefix is present
  cmp	bl,0d0h
  jae	t13_singles		;jmp if single instructions
;handle "fld stx"  and  "fxch stx"
  cmp	bl,0d8h			;check if fld
  jae	t13_fxch		;jmp if fxch
;handle "fld"
  mov	esi,_fld
  call	str_move
  mov	al,9
  stosb				;put tab after name

  mov	ax,'st'
  stosw				;store part of reg
  and	bl,7			;isolate register
  or	bl,'0'			;convert to ascii
  mov	al,bl
  stosb				;complete register code
  add	ebp,2			;instruction size = 2
  jmp	t13_done
;handle "fxch"
t13_fxch:
  mov	eax,'fxch'
  stosd
  mov	al,9
  stosb
  add	ebp,2
  jmp	t13_done
;handle opcode with mod/rm in range d0-ff
t13_singles:
  mov	esi,t13_table
t13_lp:
  mov	bh,byte [esi]		;get table's mod/rm
  or	bh,bh
  jz	t13_error		;jmp if no match in table
  cmp	bh,bl
  je	t13_match		;jmp if match found
  add	esi,5
  jmp	short t13_lp
t13_error:
  or	byte [error_flag],1
  inc	ebp  
  jmp	t13_done
t13_match:
  inc	esi
  mov	esi,[esi]		;get name
  call	str_move
  add	ebp,2  

t13_done:
  mov	al,0ah
  stosb
  mov	al,80h			;get done code
  ret  

t13_table:
   db       0d0h		;mod/rm byte
   dd	_fnop			;instrucion opcode name

   db       0e0h
   dd	_fchs

   db       0e1h
   dd	_fabs

   db       0e4h
   dd	_ftst

   db       0e5h
   dd	_fxam

   db       0e8h
   dd	_fld1

   db       0e9h
   dd	_fldl2t

   db       0eah
   dd	_fldl2e

   db       0ebh
   dd	_fldpi

   db       0ech
   dd	_fldlg2

   db       0edh
   dd	_fldln2

   db       0eeh
   dd	_fldz

   db       0f0h
   dd	_f2xm1

   db       0f1h
   dd	_fyl2x

   db       0f2h
   dd	_fptan

   db       0f3h
   dd	_fpatan

   db       0f4h
   dd	_fxtract

   db       0f5h
   dd	_fprem1

   db       0f6h
   dd	_fdecstp

   db       0f7h
   dd	_fincstp

   db       0f8h
   dd	_fprem

   db       0f9h
   dd	_fyl2xp1

   db       0fah
   dd	_fsqrt

   db       0fbh
   dd	_fsincos

   db       0fch
   dd	_frndint

   db       0fdh
   dd	_fscale

   db       0feh
   dd	_fsin

   db       0ffh
   dd	_fcos
   db  0 ;end of table
