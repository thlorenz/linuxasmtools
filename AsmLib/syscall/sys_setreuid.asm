;--------------------------------------------------------------
;>1 syscall
; sys_setreuid - kernel function                            
;
;    INPUTS 
;     see AsmRef function -> sys_setreuid                                        
;
;    Note: functon call consists of four instructions
;          
;          sys_setreuid:                                     
;              mov  eax,70     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_setreuid
sys_setreuid:
	mov	eax,70
	int	byte 80h
	or	eax,eax
	ret