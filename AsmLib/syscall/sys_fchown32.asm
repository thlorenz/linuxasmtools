;--------------------------------------------------------------
;>1 syscall
; sys_fchown32 - kernel function                            
;
;    INPUTS 
;     see AsmRef function -> sys_fchown32                                        
;
;    Note: functon call consists of four instructions
;          
;          sys_fchown32:                                     
;              mov  eax,207    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_fchown32
sys_fchown32:
	mov	eax,207
	int	byte 80h
	or	eax,eax
	ret