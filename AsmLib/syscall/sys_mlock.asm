;--------------------------------------------------------------
;>1 syscall
; sys_mlock - kernel function                               
;
;    INPUTS 
;     see AsmRef function -> sys_mlock                                           
;
;    Note: functon call consists of four instructions
;          
;          sys_mlock:                                        
;              mov  eax,150    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_mlock
sys_mlock:
	mov	eax,150
	int	byte 80h
	or	eax,eax
	ret