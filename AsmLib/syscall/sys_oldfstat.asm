;--------------------------------------------------------------
;>1 syscall
; sys_oldfstat - kernel function                            
;
;    INPUTS 
;     see AsmRef function -> sys_oldfstat                                        
;
;    Note: functon call consists of four instructions
;          
;          sys_oldfstat:                                     
;              mov  eax,28     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_oldfstat
sys_oldfstat:
	mov	eax,28
	int	byte 80h
	or	eax,eax
	ret