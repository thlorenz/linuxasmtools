
  [section .text]
;***********   type04 ****************
;
;  input:  ebp = current opcode ptr
;          edi = stuff ptr
;          edx = ptr to decode_table entry
;              db zxyyyyyy  where z=??
;                                 x=??
;                                 y=process index
;              db ?
;              dw name      index to opcode text (name)
;          ebx = decode_table entry
;ebx=[optxt ndx]  bh=modcol   bl= [process id]
;    [ 16 bits ]  [8bits  ]   [8 bits]
;                
;  output: al = legal prefix's (prefix_flag) if done high bit is set
;------------------------------------------------------------------


;------------------------------------------------------------------
;type s04

; opcode  prefix                prefix 66     prefix 66       modcol
;         legal                 inactive*     active          code
; ------  ------  ----------    -----------   -------------   -------
;   b0      -     mov al,imm8                                    1
;   b1      -     mov cl,imm8                                    1
;   b2      -     mov dl,imm8                                    1
;   b3      -     mov bl,imm8                                    1
;   b4      -     mov ah,imm8                                    1
;   b5      -     mov ch,imm8                                    1
;   b6      -     mov dh,imm8                                    1
;   b7      -     mov bh,imm8                                    1
;   b8      p                    mov eax,imm32  mov ax,imm16     2
;   b9      p                    mov ecx,imm32  mov cx,imm16     2
;   ba      p                    mov edx,imm32  mov dx,imm16     2
;   bb      p                    mov ebx,imm32  mov bx,imm16     2
;   bc      p                    mov ebp,imm32  mov bp,imm16     2
;   bd      p                    mov esp,imm32  mov sp,imm16     2
;   be      p                    mov esi,imm32  mov si,imm16     2
;   bf      p                    mov edi,imm32  mov di,imm16     2
;   90      p                    nop            xchg ax,ax       3
;   91      p                    xchg eax,ecx   xchg ax,cx       3
;   92      p                    xchg eax,edx   xchg ax,dx       3
;   93      p                    xchg eax,ebx   xchg ax,bx       3
;   94      p                    xchg eax,ebp   xchg ax,bp       3
;   95      p                    xchg eax,esp   xchg ax,sp       3
;   96      p                    xchg eax,esi   xchg ax,si       3
;   97      p                    xchg eax,edi   xchg ax,di       3
;   98      p                    cwde           cbw              4
;   99      p                    cdq            cwd              5
;

type_s04:
  mov	dl,[state_flag]	;get current prefix state
  dec	bh
  jz	t04_10		;jmp if code 1
  dec	bh
  jz	t04_20		;jmp if code 2
  dec	bh
  jz	t04_30		;jmp if code 3
  dec	bh
  jnz	t04_05
  jmp	t04_40		;jmp if code 4
;modcol code =5, this must be a cdq or cwd instruction
t04_05:
  test	dl,10h			;is prefix flag set (state_flag)
  jnz	t04_06
  jmp	t04_83			;jmp if default name ok
t04_06:
  sub	edi,byte 4		;reset stuff ptr
  mov	ecx,__cwd
  call	stuff_op
  jmp	short t04_83

;modcol code =1, this is a "mov reg,imm8"
t04_10:
  mov	bl,[ebp]	;get opcode
  and	bl,07h		;isolate low order bits
  mov	bh,-3		;move to byte regs
  xor	ecx,ecx
  mov	cl,[ebp+1]	;get hex value
  call	stuff_reg_hex
  add	ebp,byte 2	;move past opcode and immediate value
  mov	al,80h		;signal done
  ret

;modcol code =2, this is a "mov eax,immx" 
t04_20:
  xor	ecx,ecx
  mov	bl,[ebp]	;get opcode
  and	bl,07h		;isolate low order bits
  mov	bh,-1		;preload dword state
  test	dl,10h		;prefix 66h active (dl=state_flag)
  jz	t04_24		;jmp if no prefix active
  mov	bh,-2		;set word state
  mov	cx,[ebp+1]
  add	ebp,byte 3
  jmp	short t04_26
t04_24:
  call	stuff_reg
  mov	ebx,[ebp+1]
  mov	al,','
  stosb
  mov	al,20h
  call	process_operand_address
  mov	al,0ah
  stosb
  add	ebp,byte 5
  jmp	short t04_84

t04_26:
  call	stuff_reg_hex
  jmp	short t04_84

;modcol code =3, this is a "xchg eax,xxx"
t04_30:
  xor	ecx,ecx		;select register eax
  mov	bl,[ebp]	;get opcode
  and	bl,07h		;isolate low order bits
  mov	bh,-1
  test	dl,10h		;prefix 66h active (dl=state_flag)
  jz	t04_34		;jmp if no prefix active
  mov	bh,-2
t04_34:
  call	stuff_reg_reg
  jmp	short t04_82	;exit

;modcol code =4, this is a "cwde or cbw"
t04_40:
  test	dl,10h			;is prefix flag set (dl=state_flag)
  jz	t04_83			;jmp if default name ok
  sub	edi,byte 5		;reset stuff ptr for new op text
  mov	ecx,__cbw
t04_80:
  call	stuff_op
t04_83:
  mov	al,0ah
  stosb				;terminate string
t04_82:
  inc	ebp			;move to next instruction byte
t04_84:
  mov	al,80h +10h		;done code + prefix 66h
  ret    
  
;------------------------------------------------------------------
