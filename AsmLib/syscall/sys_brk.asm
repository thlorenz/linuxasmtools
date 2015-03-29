;--------------------------------------------------------------
;>1 syscall
; sys_brk - kernel function                                 
;
;    INPUTS 
;     see AsmRef function -> sys_brk                                             
;
;    Note: functon call consists of four instructions
;          
;          sys_brk:                                          
;              mov  eax,45     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_brk
sys_brk:
	mov	eax,45
	int	byte 80h
	or	eax,eax
	ret