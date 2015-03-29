;--------------------------------------------------------------
;>1 syscall
; sys_getcwd - kernel function                              
;
;    INPUTS 
;     see AsmRef function -> sys_getcwd                                          
;
;    Note: functon call consists of four instructions
;          
;          sys_getcwd:                                       
;              mov  eax,183    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_getcwd
sys_getcwd:
	mov	eax,183
	int	byte 80h
	or	eax,eax
	ret