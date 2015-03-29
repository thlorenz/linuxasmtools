;--------------------------------------------------------------
;>1 syscall
; sys_setreuid32 - kernel function                          
;
;    INPUTS 
;     see AsmRef function -> sys_setreuid32                                      
;
;    Note: functon call consists of four instructions
;          
;          sys_setreuid32:                                   
;              mov  eax,203    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_setreuid32
sys_setreuid32:
	mov	eax,203
	int	byte 80h
	or	eax,eax
	ret