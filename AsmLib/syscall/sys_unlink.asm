;--------------------------------------------------------------
;>1 syscall
; sys_unlink - kernel function                              
;
;    INPUTS 
;     see AsmRef function -> sys_unlink                                          
;
;    Note: functon call consists of four instructions
;          
;          sys_unlink:                                       
;              mov  eax,10     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_unlink
sys_unlink:
	mov	eax,10
	int	byte 80h
	or	eax,eax
	ret