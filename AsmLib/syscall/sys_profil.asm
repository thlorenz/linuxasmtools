;--------------------------------------------------------------
;>1 syscall
; sys_profil - kernel function                              
;
;    INPUTS 
;     see AsmRef function -> sys_profil                                          
;
;    Note: functon call consists of four instructions
;          
;          sys_profil:                                       
;              mov  eax,98     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_profil
sys_profil:
	mov	eax,98
	int	byte 80h
	or	eax,eax
	ret