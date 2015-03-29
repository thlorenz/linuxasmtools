;--------------------------------------------------------------
;>1 syscall
; sys_capget - kernel function                              
;
;    INPUTS 
;     see AsmRef function -> sys_capget                                          
;
;    Note: functon call consists of four instructions
;          
;          sys_capget:                                       
;              mov  eax,184    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_capget
sys_capget:
	mov	eax,184
	int	byte 80h
	or	eax,eax
	ret