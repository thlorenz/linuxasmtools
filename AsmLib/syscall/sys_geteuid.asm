;--------------------------------------------------------------
;>1 syscall
; sys_geteuid - kernel function                             
;
;    INPUTS 
;     see AsmRef function -> sys_geteuid                                         
;
;    Note: functon call consists of four instructions
;          
;          sys_geteuid:                                      
;              mov  eax,49     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_geteuid
sys_geteuid:
	mov	eax,49
	int	byte 80h
	or	eax,eax
	ret