;--------------------------------------------------------------
;>1 syscall
; sys_flock - kernel function                               
;
;    INPUTS 
;     see AsmRef function -> sys_flock                                           
;
;    Note: functon call consists of four instructions
;          
;          sys_flock:                                        
;              mov  eax,143    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_flock
sys_flock:
	mov	eax,143
	int	byte 80h
	or	eax,eax
	ret