;--------------------------------------------------------------
;>1 syscall
; sys_mount - kernel function                               
;
;    INPUTS 
;     see AsmRef function -> sys_mount                                           
;
;    Note: functon call consists of four instructions
;          
;          sys_mount:                                        
;              mov  eax,21     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_mount
sys_mount:
	mov	eax,21
	int	byte 80h
	or	eax,eax
	ret