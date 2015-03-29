;--------------------------------------------------------------
;>1 syscall
; sys_setdomainname - kernel function                       
;
;    INPUTS 
;     see AsmRef function -> sys_setdomainname                                   
;
;    Note: functon call consists of four instructions
;          
;          sys_setdomainname:                                
;              mov  eax,121    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_setdomainname
sys_setdomainname:
	mov	eax,121
	int	byte 80h
	or	eax,eax
	ret