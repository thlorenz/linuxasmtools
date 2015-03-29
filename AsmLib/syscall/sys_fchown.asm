;--------------------------------------------------------------
;>1 syscall
; sys_fchown - kernel function                              
;
;    INPUTS 
;     see AsmRef function -> sys_fchown                                          
;
;    Note: functon call consists of four instructions
;          
;          sys_fchown:                                       
;              mov  eax,95     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_fchown
sys_fchown:
	mov	eax,95
	int	byte 80h
	or	eax,eax
	ret