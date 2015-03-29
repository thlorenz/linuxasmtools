;--------------------------------------------------------------
;>1 syscall
; sys_timer_create - kernel function                        
;
;    INPUTS 
;     see AsmRef function -> sys_timer_create                                    
;
;    Note: functon call consists of four instructions
;          
;          sys_timer_create:                                 
;              mov  eax,259    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_timer_create
sys_timer_create:
	mov	eax,259
	int	byte 80h
	or	eax,eax
	ret