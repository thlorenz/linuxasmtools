;--------------------------------------------------------------
;>1 syscall
; sys_getppid - kernel function                             
;
;    INPUTS 
;     see AsmRef function -> sys_getppid                                         
;
;    Note: functon call consists of four instructions
;          
;          sys_getppid:                                      
;              mov  eax,64     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_getppid
sys_getppid:
	mov	eax,64
	int	byte 80h
	or	eax,eax
	ret