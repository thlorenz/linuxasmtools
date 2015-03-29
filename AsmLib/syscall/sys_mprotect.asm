;--------------------------------------------------------------
;>1 syscall
; sys_mprotect - kernel function                            
;
;    INPUTS 
;     see AsmRef function -> sys_mprotect                                        
;
;    Note: functon call consists of four instructions
;          
;          sys_mprotect:                                     
;              mov  eax,125    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_mprotect
sys_mprotect:
	mov	eax,125
	int	byte 80h
	or	eax,eax
	ret