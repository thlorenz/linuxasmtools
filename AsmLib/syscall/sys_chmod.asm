;--------------------------------------------------------------
;>1 syscall
; sys_chmod - kernel function                               
;
;    INPUTS 
;     see AsmRef function -> sys_chmod                                           
;
;    Note: functon call consists of four instructions
;          
;          sys_chmod:                                        
;              mov  eax,15     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_chmod
sys_chmod:
	mov	eax,15
	int	byte 80h
	or	eax,eax
	ret