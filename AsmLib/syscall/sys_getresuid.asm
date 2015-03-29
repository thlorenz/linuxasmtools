;--------------------------------------------------------------
;>1 syscall
; sys_getresuid - kernel function                           
;
;    INPUTS 
;     see AsmRef function -> sys_getresuid                                       
;
;    Note: functon call consists of four instructions
;          
;          sys_getresuid:                                    
;              mov  eax,165    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_getresuid
sys_getresuid:
	mov	eax,165
	int	byte 80h
	or	eax,eax
	ret