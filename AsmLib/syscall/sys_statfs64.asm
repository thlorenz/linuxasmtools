;--------------------------------------------------------------
;>1 syscall
; sys_statfs64 - kernel function                            
;
;    INPUTS 
;     see AsmRef function -> sys_statfs64                                        
;
;    Note: functon call consists of four instructions
;          
;          sys_statfs64:                                     
;              mov  eax,268    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_statfs64
sys_statfs64:
	mov	eax,268
	int	byte 80h
	or	eax,eax
	ret