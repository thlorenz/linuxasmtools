;--------------------------------------------------------------
;>1 syscall
; sys_modify_ldt - kernel function                          
;
;    INPUTS 
;     see AsmRef function -> sys_modify_ldt                                      
;
;    Note: functon call consists of four instructions
;          
;          sys_modify_ldt:                                   
;              mov  eax,123    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_modify_ldt
sys_modify_ldt:
	mov	eax,123
	int	byte 80h
	or	eax,eax
	ret