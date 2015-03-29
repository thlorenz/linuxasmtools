;--------------------------------------------------------------
;>1 syscall
; sys_getgroups - kernel function                           
;
;    INPUTS 
;     see AsmRef function -> sys_getgroups                                       
;
;    Note: functon call consists of four instructions
;          
;          sys_getgroups:                                    
;              mov  eax,80     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_getgroups
sys_getgroups:
	mov	eax,80
	int	byte 80h
	or	eax,eax
	ret