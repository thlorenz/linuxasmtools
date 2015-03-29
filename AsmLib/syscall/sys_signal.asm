;--------------------------------------------------------------
;>1 syscall
; sys_signal - kernel function                              
;
;    INPUTS 
;     see AsmRef function -> sys_signal                                          
;
;    Note: functon call consists of four instructions
;          
;          sys_signal:                                       
;              mov  eax,48     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_signal
sys_signal:
	mov	eax,48
	int	byte 80h
	or	eax,eax
	ret