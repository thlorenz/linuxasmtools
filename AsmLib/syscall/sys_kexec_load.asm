;--------------------------------------------------------------
;>1 syscall
; sys_kexec_load - kernel function                          
;
;    INPUTS 
;     see AsmRef function -> sys_kexec_load                                      
;
;    Note: functon call consists of four instructions
;          
;          sys_kexec_load:                                   
;              mov  eax,283    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_kexec_load
sys_kexec_load:
	mov	eax,283
	int	byte 80h
	or	eax,eax
	ret