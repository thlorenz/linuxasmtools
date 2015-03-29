;--------------------------------------------------------------
;>1 syscall
; sys_swapon - kernel function                              
;
;    INPUTS 
;     see AsmRef function -> sys_swapon                                          
;
;    Note: functon call consists of four instructions
;          
;          sys_swapon:                                       
;              mov  eax,87     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_swapon
sys_swapon:
	mov	eax,87
	int	byte 80h
	or	eax,eax
	ret