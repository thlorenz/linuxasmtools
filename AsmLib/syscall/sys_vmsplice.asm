;--------------------------------------------------------------
;>1 syscall
; sys_vmsplice - kernel function                            
;
;    INPUTS 
;     see AsmRef function -> sys_vmsplice                                        
;
;    Note: functon call consists of four instructions
;          
;          sys_vmsplice:                                     
;              mov  eax,316    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_vmsplice
sys_vmsplice:
	mov	eax,316
	int	byte 80h
	or	eax,eax
	ret