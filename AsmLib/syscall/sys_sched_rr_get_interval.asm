;--------------------------------------------------------------
;>1 syscall
; sys_sched_rr_get_interval - kernel function               
;
;    INPUTS 
;     see AsmRef function -> sys_sched_rr_get_interval                           
;
;    Note: functon call consists of four instructions
;          
;          sys_sched_rr_get_interval:                        
;              mov  eax,161    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_sched_rr_get_interval
sys_sched_rr_get_interval:
	mov	eax,161
	int	byte 80h
	or	eax,eax
	ret