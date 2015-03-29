;--------------------------------------------------------------
;>1 syscall
; sys_ustat - kernel function                               
;
;    INPUTS 
;     see AsmRef function -> sys_ustat                                           
;
;    Note: functon call consists of four instructions
;          
;          sys_ustat:                                        
;              mov  eax,62     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_ustat
sys_ustat:
	mov	eax,62
	int	byte 80h
	or	eax,eax
	ret