;--------------------------------------------------------------
;>1 syscall
; sys_bdflush - kernel function                             
;
;    INPUTS 
;     see AsmRef function -> sys_bdflush                                         
;
;    Note: functon call consists of four instructions
;          
;          sys_bdflush:                                      
;              mov  eax,134    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_bdflush
sys_bdflush:
	mov	eax,134
	int	byte 80h
	or	eax,eax
	ret