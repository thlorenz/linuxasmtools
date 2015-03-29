;--------------------------------------------------------------
;>1 syscall
; sys_rt_sigsuspend - kernel function                       
;
;    INPUTS 
;     see AsmRef function -> sys_rt_sigsuspend                                   
;
;    Note: functon call consists of four instructions
;          
;          sys_rt_sigsuspend:                                
;              mov  eax,179    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_rt_sigsuspend
sys_rt_sigsuspend:
	mov	eax,179
	int	byte 80h
	or	eax,eax
	ret