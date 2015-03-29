;--------------------------------------------------------------
;>1 syscall
; sys__sysctl - kernel function                             
;
;    INPUTS 
;     see AsmRef function -> sys__sysctl                                         
;
;    Note: functon call consists of four instructions
;          
;          sys__sysctl:                                      
;              mov  eax,149    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys__sysctl
sys__sysctl:
	mov	eax,149
	int	byte 80h
	or	eax,eax
	ret