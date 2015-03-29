;--------------------------------------------------------------
;>1 syscall
; sys_pwrite64 - kernel function                            
;
;    INPUTS 
;     see AsmRef function -> sys_pwrite64                                        
;
;    Note: functon call consists of four instructions
;          
;          sys_pwrite64:                                     
;              mov  eax,181    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_pwrite64
sys_pwrite64:
	mov	eax,181
	int	byte 80h
	or	eax,eax
	ret