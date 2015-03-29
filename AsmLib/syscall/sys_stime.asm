;--------------------------------------------------------------
;>1 syscall
; sys_stime - kernel function                               
;
;    INPUTS 
;     see AsmRef function -> sys_stime                                           
;
;    Note: functon call consists of four instructions
;          
;          sys_stime:                                        
;              mov  eax,25     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_stime
sys_stime:
	mov	eax,25
	int	byte 80h
	or	eax,eax
	ret