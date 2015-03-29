;--------------------------------------------------------------
;>1 syscall
; sys_splice - kernel function                              
;
;    INPUTS 
;     see AsmRef function -> sys_splice                                          
;
;    Note: functon call consists of four instructions
;          
;          sys_splice:                                       
;              mov  eax,313    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_splice
sys_splice:
	mov	eax,313
	int	byte 80h
	or	eax,eax
	ret