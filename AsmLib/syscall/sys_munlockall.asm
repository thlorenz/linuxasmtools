;--------------------------------------------------------------
;>1 syscall
; sys_munlockall - kernel function                          
;
;    INPUTS 
;     see AsmRef function -> sys_munlockall                                      
;
;    Note: functon call consists of four instructions
;          
;          sys_munlockall:                                   
;              mov  eax,153    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_munlockall
sys_munlockall:
	mov	eax,153
	int	byte 80h
	or	eax,eax
	ret