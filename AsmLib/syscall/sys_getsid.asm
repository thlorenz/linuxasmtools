;--------------------------------------------------------------
;>1 syscall
; sys_getsid - kernel function                              
;
;    INPUTS 
;     see AsmRef function -> sys_getsid                                          
;
;    Note: functon call consists of four instructions
;          
;          sys_getsid:                                       
;              mov  eax,147    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_getsid
sys_getsid:
	mov	eax,147
	int	byte 80h
	or	eax,eax
	ret