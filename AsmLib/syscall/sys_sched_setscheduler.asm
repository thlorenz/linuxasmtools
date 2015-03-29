;--------------------------------------------------------------
;>1 syscall
; sys_sched_setscheduler - kernel function                  
;
;    INPUTS 
;     see AsmRef function -> sys_sched_setscheduler                              
;
;    Note: functon call consists of four instructions
;          
;          sys_sched_setscheduler:                           
;              mov  eax,156    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_sched_setscheduler
sys_sched_setscheduler:
	mov	eax,156
	int	byte 80h
	or	eax,eax
	ret