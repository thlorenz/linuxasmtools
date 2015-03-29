;--------------------------------------------------------------
;>1 syscall
; sys_uselib - kernel function                              
;
;    INPUTS 
;     see AsmRef function -> sys_uselib                                          
;
;    Note: functon call consists of four instructions
;          
;          sys_uselib:                                       
;              mov  eax,86     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_uselib
sys_uselib:
	mov	eax,86
	int	byte 80h
	or	eax,eax
	ret