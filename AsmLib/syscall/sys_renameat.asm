;--------------------------------------------------------------
;>1 syscall
; sys_renameat - kernel function                            
;
;    INPUTS 
;     see AsmRef function -> sys_renameat                                        
;
;    Note: functon call consists of four instructions
;          
;          sys_renameat:                                     
;              mov  eax,302    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_renameat
sys_renameat:
	mov	eax,302
	int	byte 80h
	or	eax,eax
	ret