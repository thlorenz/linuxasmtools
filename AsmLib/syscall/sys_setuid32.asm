;--------------------------------------------------------------
;>1 syscall
; sys_setuid32 - kernel function                            
;
;    INPUTS 
;     see AsmRef function -> sys_setuid32                                        
;
;    Note: functon call consists of four instructions
;          
;          sys_setuid32:                                     
;              mov  eax,213    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_setuid32
sys_setuid32:
	mov	eax,213
	int	byte 80h
	or	eax,eax
	ret