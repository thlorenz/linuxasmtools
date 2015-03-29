  [section .text]
;*********** type_06  ****************
;
;  input:  ebp = current opcode ptr
;          edi = stuff ptr
;          edx = ptr to decode_table entry
;              db zxyyyyyy  where z=??
;                                 x=??
;                                 y=process index
;              db flag 80h = byte
;                      40h = constant 1
;                      20h = op is immediate
;                      10h = special les,lds instruction
;              dw name      index to opcode text (name)
;          ebx = decode_table entry
;                
;  output: al = legal prefix's (prefix_flag) if done high bit is set
;
;------------------------------------------------------------------

;------------------------------------------------------------------
; opcode  prefix      operand                      prefix 66     prefix 66
;         flag   flag (see codes.h)                inactive*     active
; ------  ------ ---- --------------                -----   -------------
; 8f pop
; fe dec    -     1   t1_rm8_b (81h)  dec (rm8)
; fe inc    -     0   t1_rm8_b (81h)  inc (rm8)
; f6 div    -     6   t1_rm8_b (81h)  div (rm8)
; f6 idiv   -     7   t1_rm8_b (81h) idiv (rm8)
; f6 mul    -     4   t1_rm8_b (81h)  mul (rm8)
; f6 imul   -     5   t1_rm8_b (81h) imul (rm8)
; f6 neg    -     3   t1_rm8_b (81h)  neg (rm8)
; f6 not    -     2   t1_rm8_b (81h)  not (rm8)
;0f 97 seta -     -   t1_rm8_b (81h) seta (rm8)
;0f 92 sete -     -   t1_rm8_b (81h) sete (rm8)
;0f 94 sets -     -   t1_rm8_b (81h) sets (rm8)
;0f 9f setg -     -   t1_rm8_b (81h) setg (rm8)
;0f 9c setl -     -   t1_rm8_b (81h) setl (rm8)
;0f 96 setna-     -   t1_rm8_b (81h) setna(rm8)
;0f 93 setnc-     -   t1_rm8_b (81h) setnc(rm8)
;0f 95 setne-     -   t1_rm8_b (81h) setne(rm8)
;0f 9e setng-     -   t1_rm8_b (81h) setng(rm8)
;0f 9d setnl-     -   t1_rm8_b (81h) setnl(rm8)
;0f 99 setns-     -   t1_rm8_b (81h) setns(rm8)
;0f 9b setnp-     -   t1_rm8_b (81h) setnp(rm8)
;0f 90 seto -     -   t1_rm8_b (81h) seto (rm8)
;0f 9a setp -     -   t1_rm8_b (81h) setp (rm8)
;0f 98 sets -     -   t1_rm8_b (81h) sets (rm8)
;0f 91 setno-     -   t1_rm8_b (81h) setno(rm8)

;---------------------------------------------
;decode first operand
type_s06:
  cmp	byte [ebp],0ffh	;is this a dec or inc or push
  jne	t6_1_9		;jmp if not dec or inc or push
  mov	al,byte [ebp +1] ;get modrm byte
  and	al,0c0h
  cmp	al,0c0h
  jne	t6_1_6		;jmp if not register op
;check if dec,inc,push instructions
  mov	al,[ebp +1]	;get modrm byte again
  and	al,038h		;isolate flag (instruction type field)
  cmp	al,8
  jbe	t6_1_5		;jmp if dec or inc 
  cmp	al,030h
  jne	t6_1_6		;jmp if not "push"
t6_1_5:
  or	byte [warn_flag],1	;set db expansion flag
;check if jump instruction modrm-flag = 100 or 101
t6_1_6:
  mov	al,[ebp+1]
  and	al,038h
  cmp	al,20h
  je	t6_1_7		;jmp if jmp inst
  cmp	al,28h
  jne	t6_1_9		;jmp if not jmp inst
t6_1_7:
  or	byte [instruction_type],8	;set jmp type
t6_1_9:
  call	decode_rm
  mov	al,0ah		;get eol
  stosb			;terminate instruction_asciiz
  mov	al,[prefix_bits]
  ret
