;--------------------------------------------------------------
;>1 syscall
; sys_sgetmask - kernel function                            
;
;    INPUTS 
;     see AsmRef function -> sys_sgetmask                                        
;
;    Note: functon call consists of four instructions
;          
;          sys_sgetmask:                                     
;              mov  eax,68     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_sgetmask
sys_sgetmask:
	mov	eax,68
	int	byte 80h
	or	eax,eax
	ret