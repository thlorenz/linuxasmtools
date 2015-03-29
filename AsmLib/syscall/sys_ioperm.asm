;--------------------------------------------------------------
;>1 syscall
; sys_ioperm - kernel function                              
;
;    INPUTS 
;     see AsmRef function -> sys_ioperm                                          
;
;    Note: functon call consists of four instructions
;          
;          sys_ioperm:                                       
;              mov  eax,101    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_ioperm
sys_ioperm:
	mov	eax,101
	int	byte 80h
	or	eax,eax
	ret