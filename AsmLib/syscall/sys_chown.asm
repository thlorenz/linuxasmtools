;--------------------------------------------------------------
;>1 syscall
; sys_chown - kernel function                               
;
;    INPUTS 
;     see AsmRef function -> sys_chown                                           
;
;    Note: functon call consists of four instructions
;          
;          sys_chown:                                        
;              mov  eax,182    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_chown
sys_chown:
	mov	eax,182
	int	byte 80h
	or	eax,eax
	ret