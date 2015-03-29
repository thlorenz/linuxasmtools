;--------------------------------------------------------------
;>1 syscall
; sys_umask - kernel function                               
;
;    INPUTS 
;     see AsmRef function -> sys_umask                                           
;
;    Note: functon call consists of four instructions
;          
;          sys_umask:                                        
;              mov  eax,60     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_umask
sys_umask:
	mov	eax,60
	int	byte 80h
	or	eax,eax
	ret