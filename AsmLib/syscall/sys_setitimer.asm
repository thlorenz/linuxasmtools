;--------------------------------------------------------------
;>1 syscall
; sys_setitimer - kernel function                           
;
;    INPUTS 
;     see AsmRef function -> sys_setitimer                                       
;
;    Note: functon call consists of four instructions
;          
;          sys_setitimer:                                    
;              mov  eax,104    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_setitimer
sys_setitimer:
	mov	eax,104
	int	byte 80h
	or	eax,eax
	ret