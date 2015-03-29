;--------------------------------------------------------------
;>1 syscall
; sys_getpgid - kernel function                             
;
;    INPUTS 
;     see AsmRef function -> sys_getpgid                                         
;
;    Note: functon call consists of four instructions
;          
;          sys_getpgid:                                      
;              mov  eax,132    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_getpgid
sys_getpgid:
	mov	eax,132
	int	byte 80h
	or	eax,eax
	ret