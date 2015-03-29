;--------------------------------------------------------------
;>1 syscall
; sys_tee - kernel function                                 
;
;    INPUTS 
;     see AsmRef function -> sys_tee                                             
;
;    Note: functon call consists of four instructions
;          
;          sys_tee:                                          
;              mov  eax,315    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_tee
sys_tee:
	mov	eax,315
	int	byte 80h
	or	eax,eax
	ret