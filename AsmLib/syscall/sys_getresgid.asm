;--------------------------------------------------------------
;>1 syscall
; sys_getresgid - kernel function                           
;
;    INPUTS 
;     see AsmRef function -> sys_getresgid                                       
;
;    Note: functon call consists of four instructions
;          
;          sys_getresgid:                                    
;              mov  eax,171    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_getresgid
sys_getresgid:
	mov	eax,171
	int	byte 80h
	or	eax,eax
	ret