;--------------------------------------------------------------
;>1 syscall
; sys_sched_setaffinity - kernel function                   
;
;    INPUTS 
;     see AsmRef function -> sys_sched_setaffinity                               
;
;    Note: functon call consists of four instructions
;          
;          sys_sched_setaffinity:                            
;              mov  eax,241    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_sched_setaffinity
sys_sched_setaffinity:
	mov	eax,241
	int	byte 80h
	or	eax,eax
	ret