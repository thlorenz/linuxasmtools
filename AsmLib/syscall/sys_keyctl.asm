;--------------------------------------------------------------
;>1 syscall
; sys_keyctl - kernel function                              
;
;    INPUTS 
;     see AsmRef function -> sys_keyctl                                          
;
;    Note: functon call consists of four instructions
;          
;          sys_keyctl:                                       
;              mov  eax,288    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_keyctl
sys_keyctl:
	mov	eax,288
	int	byte 80h
	or	eax,eax
	ret