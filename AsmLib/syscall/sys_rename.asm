;--------------------------------------------------------------
;>1 syscall
; sys_rename - kernel function                              
;
;    INPUTS 
;     see AsmRef function -> sys_rename                                          
;
;    Note: functon call consists of four instructions
;          
;          sys_rename:                                       
;              mov  eax,38     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_rename
sys_rename:
	mov	eax,38
	int	byte 80h
	or	eax,eax
	ret