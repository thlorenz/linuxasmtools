;--------------------------------------------------------------
;>1 syscall
; sys_signalfd - kernel function                            
;
;    INPUTS 
;     see AsmRef function -> sys_signalfd                                        
;
;    Note: functon call consists of four instructions
;          
;          sys_signalfd:                                     
;              mov  eax,321    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_signalfd
sys_signalfd:
	mov	eax,321
	int	byte 80h
	or	eax,eax
	ret