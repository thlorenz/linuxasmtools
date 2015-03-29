;--------------------------------------------------------------
;>1 syscall
; sys_writev - kernel function                              
;
;    INPUTS 
;     see AsmRef function -> sys_writev                                          
;
;    Note: functon call consists of four instructions
;          
;          sys_writev:                                       
;              mov  eax,146    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_writev
sys_writev:
	mov	eax,146
	int	byte 80h
	or	eax,eax
	ret