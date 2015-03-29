;--------------------------------------------------------------
;>1 syscall
; sys_setpgid - kernel function                             
;
;    INPUTS 
;     see AsmRef function -> sys_setpgid                                         
;
;    Note: functon call consists of four instructions
;          
;          sys_setpgid:                                      
;              mov  eax,57     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_setpgid
sys_setpgid:
	mov	eax,57
	int	byte 80h
	or	eax,eax
	ret