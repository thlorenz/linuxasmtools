;--------------------------------------------------------------
;>1 syscall
; sys_setresgid - kernel function                           
;
;    INPUTS 
;     see AsmRef function -> sys_setresgid                                       
;
;    Note: functon call consists of four instructions
;          
;          sys_setresgid:                                    
;              mov  eax,170    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_setresgid
sys_setresgid:
	mov	eax,170
	int	byte 80h
	or	eax,eax
	ret