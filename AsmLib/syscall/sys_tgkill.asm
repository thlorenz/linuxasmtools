;--------------------------------------------------------------
;>1 syscall
; sys_tgkill - kernel function                              
;
;    INPUTS 
;     see AsmRef function -> sys_tgkill                                          
;
;    Note: functon call consists of four instructions
;          
;          sys_tgkill:                                       
;              mov  eax,270    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_tgkill
sys_tgkill:
	mov	eax,270
	int	byte 80h
	or	eax,eax
	ret