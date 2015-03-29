;--------------------------------------------------------------
;>1 syscall
; sys_setgroups - kernel function                           
;
;    INPUTS 
;     see AsmRef function -> sys_setgroups                                       
;
;    Note: functon call consists of four instructions
;          
;          sys_setgroups:                                    
;              mov  eax,81     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_setgroups
sys_setgroups:
	mov	eax,81
	int	byte 80h
	or	eax,eax
	ret