;--------------------------------------------------------------
;>1 syscall
; sys_acct - kernel function                                
;
;    INPUTS 
;     see AsmRef function -> sys_acct                                            
;
;    Note: functon call consists of four instructions
;          
;          sys_acct:                                         
;              mov  eax,51     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_acct
sys_acct:
	mov	eax,51
	int	byte 80h
	or	eax,eax
	ret