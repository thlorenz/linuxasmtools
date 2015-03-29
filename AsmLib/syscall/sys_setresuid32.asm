;--------------------------------------------------------------
;>1 syscall
; sys_setresuid32 - kernel function                         
;
;    INPUTS 
;     see AsmRef function -> sys_setresuid32                                     
;
;    Note: functon call consists of four instructions
;          
;          sys_setresuid32:                                  
;              mov  eax,208    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_setresuid32
sys_setresuid32:
	mov	eax,208
	int	byte 80h
	or	eax,eax
	ret