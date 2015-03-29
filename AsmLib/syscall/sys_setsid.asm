;--------------------------------------------------------------
;>1 syscall
; sys_setsid - kernel function                              
;
;    INPUTS 
;     see AsmRef function -> sys_setsid                                          
;
;    Note: functon call consists of four instructions
;          
;          sys_setsid:                                       
;              mov  eax,66     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_setsid
sys_setsid:
	mov	eax,66
	int	byte 80h
	or	eax,eax
	ret