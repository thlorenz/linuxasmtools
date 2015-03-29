;--------------------------------------------------------------
;>1 syscall
; sys_statfs - kernel function                              
;
;    INPUTS 
;     see AsmRef function -> sys_statfs                                          
;
;    Note: functon call consists of four instructions
;          
;          sys_statfs:                                       
;              mov  eax,99     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_statfs
sys_statfs:
	mov	eax,99
	int	byte 80h
	or	eax,eax
	ret