;--------------------------------------------------------------
;>1 syscall
; sys_lchown - kernel function                              
;
;    INPUTS 
;     see AsmRef function -> sys_lchown                                          
;
;    Note: functon call consists of four instructions
;          
;          sys_lchown:                                       
;              mov  eax,16     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_lchown
sys_lchown:
	mov	eax,16
	int	byte 80h
	or	eax,eax
	ret