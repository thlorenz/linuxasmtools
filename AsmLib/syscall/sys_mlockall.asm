;--------------------------------------------------------------
;>1 syscall
; sys_mlockall - kernel function                            
;
;    INPUTS 
;     see AsmRef function -> sys_mlockall                                        
;
;    Note: functon call consists of four instructions
;          
;          sys_mlockall:                                     
;              mov  eax,152    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_mlockall
sys_mlockall:
	mov	eax,152
	int	byte 80h
	or	eax,eax
	ret