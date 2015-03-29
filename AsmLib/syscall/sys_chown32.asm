;--------------------------------------------------------------
;>1 syscall
; sys_chown32 - kernel function                             
;
;    INPUTS 
;     see AsmRef function -> sys_chown32                                         
;
;    Note: functon call consists of four instructions
;          
;          sys_chown32:                                      
;              mov  eax,212    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_chown32
sys_chown32:
	mov	eax,212
	int	byte 80h
	or	eax,eax
	ret