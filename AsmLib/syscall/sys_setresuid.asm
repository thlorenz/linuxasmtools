;--------------------------------------------------------------
;>1 syscall
; sys_setresuid - kernel function                           
;
;    INPUTS 
;     see AsmRef function -> sys_setresuid                                       
;
;    Note: functon call consists of four instructions
;          
;          sys_setresuid:                                    
;              mov  eax,164    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_setresuid
sys_setresuid:
	mov	eax,164
	int	byte 80h
	or	eax,eax
	ret