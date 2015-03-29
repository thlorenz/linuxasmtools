;--------------------------------------------------------------
;>1 syscall
; sys_timerfd - kernel function                             
;
;    INPUTS 
;     see AsmRef function -> sys_timerfd                                         
;
;    Note: functon call consists of four instructions
;          
;          sys_timerfd:                                      
;              mov  eax,322    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_timerfd
sys_timerfd:
	mov	eax,322
	int	byte 80h
	or	eax,eax
	ret