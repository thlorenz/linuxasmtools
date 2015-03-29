;--------------------------------------------------------------
;>1 syscall
; sys_utime - kernel function                               
;
;    INPUTS 
;     see AsmRef function -> sys_utime                                           
;
;    Note: functon call consists of four instructions
;          
;          sys_utime:                                        
;              mov  eax,30     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_utime
sys_utime:
	mov	eax,30
	int	byte 80h
	or	eax,eax
	ret