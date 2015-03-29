;--------------------------------------------------------------
;>1 syscall
; sys_select - kernel function                              
;
;    INPUTS 
;     see AsmRef function -> sys_select                                          
;
;    Note: functon call consists of four instructions
;          
;          sys_select:                                       
;              mov  eax,82     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_select
sys_select:
	mov	eax,82
	int	byte 80h
	or	eax,eax
	ret