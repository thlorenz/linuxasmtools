;--------------------------------------------------------------
;>1 syscall
; sys_oldstat - kernel function                             
;
;    INPUTS 
;     see AsmRef function -> sys_oldstat                                         
;
;    Note: functon call consists of four instructions
;          
;          sys_oldstat:                                      
;              mov  eax,18     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_oldstat
sys_oldstat:
	mov	eax,18
	int	byte 80h
	or	eax,eax
	ret