;--------------------------------------------------------------
;>1 syscall
; sys_wait4 - kernel function                               
;
;    INPUTS 
;     see AsmRef function -> sys_wait4                                           
;
;    Note: functon call consists of four instructions
;          
;          sys_wait4:                                        
;              mov  eax,114    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_wait4
sys_wait4:
	mov	eax,114
	int	byte 80h
	or	eax,eax
	ret