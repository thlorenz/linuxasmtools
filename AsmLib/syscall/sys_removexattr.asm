;--------------------------------------------------------------
;>1 syscall
; sys_removexattr - kernel function                         
;
;    INPUTS 
;     see AsmRef function -> sys_removexattr                                     
;
;    Note: functon call consists of four instructions
;          
;          sys_removexattr:                                  
;              mov  eax,235    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_removexattr
sys_removexattr:
	mov	eax,235
	int	byte 80h
	or	eax,eax
	ret