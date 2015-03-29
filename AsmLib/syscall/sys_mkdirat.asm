;--------------------------------------------------------------
;>1 syscall
; sys_mkdirat - kernel function                             
;
;    INPUTS 
;     see AsmRef function -> sys_mkdirat                                         
;
;    Note: functon call consists of four instructions
;          
;          sys_mkdirat:                                      
;              mov  eax,296    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_mkdirat
sys_mkdirat:
	mov	eax,296
	int	byte 80h
	or	eax,eax
	ret