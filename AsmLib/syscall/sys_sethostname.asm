;--------------------------------------------------------------
;>1 syscall
; sys_sethostname - kernel function                         
;
;    INPUTS 
;     see AsmRef function -> sys_sethostname                                     
;
;    Note: functon call consists of four instructions
;          
;          sys_sethostname:                                  
;              mov  eax,74     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_sethostname
sys_sethostname:
	mov	eax,74
	int	byte 80h
	or	eax,eax
	ret