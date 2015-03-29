;--------------------------------------------------------------
;>1 syscall
; sys_sched_get_priority_min - kernel function              
;
;    INPUTS 
;     see AsmRef function -> sys_sched_get_priority_min                          
;
;    Note: functon call consists of four instructions
;          
;          sys_sched_get_priority_min:                       
;              mov  eax,160    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_sched_get_priority_min
sys_sched_get_priority_min:
	mov	eax,160
	int	byte 80h
	or	eax,eax
	ret