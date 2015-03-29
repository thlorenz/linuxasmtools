
  [section .text]
;***********   type_05 ****************
;
;  input:  ebp = current opcode ptr
;          edi = stuff ptr
;          edx = ptr to decode_table entry
;              db zxyyyyyy  where z=??
;                                 x=??
;                                 y=process index
;              db prefix_flag setting        
;              dw name      index to opcode text (name)
;          ebx = decode_table entry
;                
;  output: al = legal prefix's (prefix_flag) if done high bit is set
;
;------------------------------------------------------------------

;------------------------------------------------------------------
;type s05  rep/repne  string instructions
;
; opcode        prefix                prefix 66     prefix 66   prefix
;               flag                  inactive*     active      flag
; ------        ------  ----------    -----------   ----------  -------
; [f3] 6c         -     [rep] insb                              84h done + rep 
; [f3] [66] 6d    p                   [rep] insw    [rep] insd  94h done + 66h + rep 
; [f3] a4         -     [rep] movsb                             84h done + rep 
; [f3] [66] a5    p                   [rep] movsw   [rep] movsd 94h done + 66h + rep 
; [f3] ac         -     [rep] lodsb                             84h done + rep 
; [f3] [66] ad    p                   [rep] lodsw   [rep] lodsd 94h done + 66h + rep 
; [f3] 6e         -     [rep] outsb                             84h done + rep 
; [f3] [66] 6f    p                   [rep] outsw   [rep] outsd 94h done + 66h + rep 
; [f3] aa         -     [rep] stosb                             84h done + rep 
; [f3] [66] ab    p                   [rep] stosw   [rep] stosd 94h done + 66h + rep 
; [f2] [f3] a6    -     rep/repne cmpsb                         86h done+rep+repne
;[f2] [f3] [66] a7  p                 rep/ne cmpsw rep/ne cmpsd 96h done+66h+rep+repne
; [f2] [f3] ae    -     rep/repne scasb                         86h done+rep+repne
;[f2] [f3] [66] af  p                 rep/ne scasw rep/ne scasd 96h done+66h+rep+repne
;
type_s05:
  test	bl,80h		;is P bit set
  jz	t05_15		;jmp if no opcode name adjust
;adjust name if prefix 66h active
  sub	edi,byte 2	;move back to end of opcode text
  mov	al,'d'		;preload movsd end char
  test	byte [state_flag],10h
  jz	t05_10		;jmp if no adjustment needed
  mov	al,'w'		;adjust
t05_10:
  stosb			;store end char
t05_15:
  mov	al,0ah
  stosb			;terminate name
;set instruction_type flag for "ins" and "outs"
  cmp	byte [ebp],6fh	;is this a ins or outs opcode
  ja	t05_25		;jmp if not ins or outs
  mov	byte [instruction_type],4
t05_25:
;set prefix flag
  mov	al,bh		;get prefix setting
  inc	ebp
  ret
;------------------------------------------------------------------
