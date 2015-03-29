;--------------------------------------------------------------
;>1 syscall
; sys_setgroups32 - kernel function                         
;
;    INPUTS 
;     see AsmRef function -> sys_setgroups32                                     
;
;    Note: functon call consists of four instructions
;          
;          sys_setgroups32:                                  
;              mov  eax,206    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_setgroups32
sys_setgroups32:
	mov	eax,206
	int	byte 80h
	or	eax,eax
	ret