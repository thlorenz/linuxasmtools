;--------------------------------------------------------------
;>1 syscall
; sys_utimes - kernel function                              
;
;    INPUTS 
;     see AsmRef function -> sys_utimes                                          
;
;    Note: functon call consists of four instructions
;          
;          sys_utimes:                                       
;              mov  eax,271    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_utimes
sys_utimes:
	mov	eax,271
	int	byte 80h
	or	eax,eax
	ret