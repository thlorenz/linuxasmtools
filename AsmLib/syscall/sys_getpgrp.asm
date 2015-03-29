;--------------------------------------------------------------
;>1 syscall
; sys_getpgrp - kernel function                             
;
;    INPUTS 
;     see AsmRef function -> sys_getpgrp                                         
;
;    Note: functon call consists of four instructions
;          
;          sys_getpgrp:                                      
;              mov  eax,65     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_getpgrp
sys_getpgrp:
	mov	eax,65
	int	byte 80h
	or	eax,eax
	ret