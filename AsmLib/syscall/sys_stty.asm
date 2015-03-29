;--------------------------------------------------------------
;>1 syscall
; sys_stty - kernel function                                
;
;    INPUTS 
;     see AsmRef function -> sys_stty                                            
;
;    Note: functon call consists of four instructions
;          
;          sys_stty:                                         
;              mov  eax,31     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_stty
sys_stty:
	mov	eax,31
	int	byte 80h
	or	eax,eax
	ret