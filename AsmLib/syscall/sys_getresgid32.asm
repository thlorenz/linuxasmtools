;--------------------------------------------------------------
;>1 syscall
; sys_getresgid32 - kernel function                         
;
;    INPUTS 
;     see AsmRef function -> sys_getresgid32                                     
;
;    Note: functon call consists of four instructions
;          
;          sys_getresgid32:                                  
;              mov  eax,211    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_getresgid32
sys_getresgid32:
	mov	eax,211
	int	byte 80h
	or	eax,eax
	ret