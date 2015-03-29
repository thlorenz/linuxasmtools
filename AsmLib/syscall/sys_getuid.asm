;--------------------------------------------------------------
;>1 syscall
; sys_getuid - kernel function                              
;
;    INPUTS 
;     see AsmRef function -> sys_getuid                                          
;
;    Note: functon call consists of four instructions
;          
;          sys_getuid:                                       
;              mov  eax,24     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_getuid
sys_getuid:
	mov	eax,24
	int	byte 80h
	or	eax,eax
	ret