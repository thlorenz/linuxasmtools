;--------------------------------------------------------------
;>1 syscall
; sys_linkat - kernel function                              
;
;    INPUTS 
;     see AsmRef function -> sys_linkat                                          
;
;    Note: functon call consists of four instructions
;          
;          sys_linkat:                                       
;              mov  eax,303    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_linkat
sys_linkat:
	mov	eax,303
	int	byte 80h
	or	eax,eax
	ret