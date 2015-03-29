;--------------------------------------------------------------
;>1 syscall
; sys_getitimer - kernel function                           
;
;    INPUTS 
;     see AsmRef function -> sys_getitimer                                       
;
;    Note: functon call consists of four instructions
;          
;          sys_getitimer:                                    
;              mov  eax,105    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_getitimer
sys_getitimer:
	mov	eax,105
	int	byte 80h
	or	eax,eax
	ret