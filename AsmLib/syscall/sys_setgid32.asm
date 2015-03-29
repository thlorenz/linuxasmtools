;--------------------------------------------------------------
;>1 syscall
; sys_setgid32 - kernel function                            
;
;    INPUTS 
;     see AsmRef function -> sys_setgid32                                        
;
;    Note: functon call consists of four instructions
;          
;          sys_setgid32:                                     
;              mov  eax,214    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_setgid32
sys_setgid32:
	mov	eax,214
	int	byte 80h
	or	eax,eax
	ret