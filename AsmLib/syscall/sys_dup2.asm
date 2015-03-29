;--------------------------------------------------------------
;>1 syscall
; sys_dup2 - kernel function                                
;
;    INPUTS 
;     see AsmRef function -> sys_dup2                                            
;
;    Note: functon call consists of four instructions
;          
;          sys_dup2:                                         
;              mov  eax,63     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_dup2
sys_dup2:
	mov	eax,63
	int	byte 80h
	or	eax,eax
	ret