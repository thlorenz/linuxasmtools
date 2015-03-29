;--------------------------------------------------------------
;>1 syscall
; sys_sigsuspend - kernel function                          
;
;    INPUTS 
;     see AsmRef function -> sys_sigsuspend                                      
;
;    Note: functon call consists of four instructions
;          
;          sys_sigsuspend:                                   
;              mov  eax,72     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_sigsuspend
sys_sigsuspend:
	mov	eax,72
	int	byte 80h
	or	eax,eax
	ret