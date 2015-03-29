;--------------------------------------------------------------
;>1 syscall
; sys_kill - kernel function                                
;
;    INPUTS 
;     see AsmRef function -> sys_kill                                            
;
;    Note: functon call consists of four instructions
;          
;          sys_kill:                                         
;              mov  eax,37     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_kill
sys_kill:
	mov	eax,37
	int	byte 80h
	or	eax,eax
	ret