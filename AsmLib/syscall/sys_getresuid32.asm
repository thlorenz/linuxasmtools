;--------------------------------------------------------------
;>1 syscall
; sys_getresuid32 - kernel function                         
;
;    INPUTS 
;     see AsmRef function -> sys_getresuid32                                     
;
;    Note: functon call consists of four instructions
;          
;          sys_getresuid32:                                  
;              mov  eax,209    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_getresuid32
sys_getresuid32:
	mov	eax,209
	int	byte 80h
	or	eax,eax
	ret