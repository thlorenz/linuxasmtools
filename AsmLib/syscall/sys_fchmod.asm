;--------------------------------------------------------------
;>1 syscall
; sys_fchmod - kernel function                              
;
;    INPUTS 
;     see AsmRef function -> sys_fchmod                                          
;
;    Note: functon call consists of four instructions
;          
;          sys_fchmod:                                       
;              mov  eax,94     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_fchmod
sys_fchmod:
	mov	eax,94
	int	byte 80h
	or	eax,eax
	ret