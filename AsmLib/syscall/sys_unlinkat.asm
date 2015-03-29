;--------------------------------------------------------------
;>1 syscall
; sys_unlinkat - kernel function                            
;
;    INPUTS 
;     see AsmRef function -> sys_unlinkat                                        
;
;    Note: functon call consists of four instructions
;          
;          sys_unlinkat:                                     
;              mov  eax,301    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_unlinkat
sys_unlinkat:
	mov	eax,301
	int	byte 80h
	or	eax,eax
	ret