;--------------------------------------------------------------
;>1 syscall
; sys_ssetmask - kernel function                            
;
;    INPUTS 
;     see AsmRef function -> sys_ssetmask                                        
;
;    Note: functon call consists of four instructions
;          
;          sys_ssetmask:                                     
;              mov  eax,69     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_ssetmask
sys_ssetmask:
	mov	eax,69
	int	byte 80h
	or	eax,eax
	ret