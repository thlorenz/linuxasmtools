;--------------------------------------------------------------
;>1 syscall
; sys_setresgid32 - kernel function                         
;
;    INPUTS 
;     see AsmRef function -> sys_setresgid32                                     
;
;    Note: functon call consists of four instructions
;          
;          sys_setresgid32:                                  
;              mov  eax,210    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_setresgid32
sys_setresgid32:
	mov	eax,210
	int	byte 80h
	or	eax,eax
	ret