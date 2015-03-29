;--------------------------------------------------------------
;>1 syscall
; sys_alarm - kernel function                               
;
;    INPUTS 
;     see AsmRef function -> sys_alarm                                           
;
;    Note: functon call consists of four instructions
;          
;          sys_alarm:                                        
;              mov  eax,27     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_alarm
sys_alarm:
	mov	eax,27
	int	byte 80h
	or	eax,eax
	ret