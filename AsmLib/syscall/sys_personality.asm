;--------------------------------------------------------------
;>1 syscall
; sys_personality - kernel function                         
;
;    INPUTS 
;     see AsmRef function -> sys_personality                                     
;
;    Note: functon call consists of four instructions
;          
;          sys_personality:                                  
;              mov  eax,136    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_personality
sys_personality:
	mov	eax,136
	int	byte 80h
	or	eax,eax
	ret