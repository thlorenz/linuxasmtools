;--------------------------------------------------------------
;>1 syscall
; sys_getcpu - kernel function                              
;
;    INPUTS 
;     see AsmRef function -> sys_getcpu                                          
;
;    Note: functon call consists of four instructions
;          
;          sys_getcpu:                                       
;              mov  eax,318    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_getcpu
sys_getcpu:
	mov	eax,318
	int	byte 80h
	or	eax,eax
	ret