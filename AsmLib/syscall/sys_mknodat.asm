;--------------------------------------------------------------
;>1 syscall
; sys_mknodat - kernel function                             
;
;    INPUTS 
;     see AsmRef function -> sys_mknodat                                         
;
;    Note: functon call consists of four instructions
;          
;          sys_mknodat:                                      
;              mov  eax,297    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_mknodat
sys_mknodat:
	mov	eax,297
	int	byte 80h
	or	eax,eax
	ret