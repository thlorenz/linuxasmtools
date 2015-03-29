;--------------------------------------------------------------
;>1 syscall
; sys_vhangup - kernel function                             
;
;    INPUTS 
;     see AsmRef function -> sys_vhangup                                         
;
;    Note: functon call consists of four instructions
;          
;          sys_vhangup:                                      
;              mov  eax,111    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_vhangup
sys_vhangup:
	mov	eax,111
	int	byte 80h
	or	eax,eax
	ret