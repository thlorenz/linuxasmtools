;--------------------------------------------------------------
;>1 syscall
; sys_sched_getparam - kernel function                      
;
;    INPUTS 
;     see AsmRef function -> sys_sched_getparam                                  
;
;    Note: functon call consists of four instructions
;          
;          sys_sched_getparam:                               
;              mov  eax,155    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_sched_getparam
sys_sched_getparam:
	mov	eax,155
	int	byte 80h
	or	eax,eax
	ret