;--------------------------------------------------------------
;>1 syscall
; sys_lock - kernel function                                
;
;    INPUTS 
;     see AsmRef function -> sys_lock                                            
;
;    Note: functon call consists of four instructions
;          
;          sys_lock:                                         
;              mov  eax,53     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_lock
sys_lock:
	mov	eax,53
	int	byte 80h
	or	eax,eax
	ret