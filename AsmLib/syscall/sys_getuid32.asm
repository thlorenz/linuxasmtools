;--------------------------------------------------------------
;>1 syscall
; sys_getuid32 - kernel function                            
;
;    INPUTS 
;     see AsmRef function -> sys_getuid32                                        
;
;    Note: functon call consists of four instructions
;          
;          sys_getuid32:                                     
;              mov  eax,199    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_getuid32
sys_getuid32:
	mov	eax,199
	int	byte 80h
	or	eax,eax
	ret