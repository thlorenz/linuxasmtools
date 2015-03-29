;--------------------------------------------------------------
;>1 syscall
; sys_munlock - kernel function                             
;
;    INPUTS 
;     see AsmRef function -> sys_munlock                                         
;
;    Note: functon call consists of four instructions
;          
;          sys_munlock:                                      
;              mov  eax,151    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_munlock
sys_munlock:
	mov	eax,151
	int	byte 80h
	or	eax,eax
	ret