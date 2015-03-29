;--------------------------------------------------------------
;>1 syscall
; sys_times - kernel function                               
;
;    INPUTS 
;     see AsmRef function -> sys_times                                           
;
;    Note: functon call consists of four instructions
;          
;          sys_times:                                        
;              mov  eax,43     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_times
sys_times:
	mov	eax,43
	int	byte 80h
	or	eax,eax
	ret