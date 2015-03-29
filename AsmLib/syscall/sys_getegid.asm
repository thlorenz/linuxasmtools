;--------------------------------------------------------------
;>1 syscall
; sys_getegid - kernel function                             
;
;    INPUTS 
;     see AsmRef function -> sys_getegid                                         
;
;    Note: functon call consists of four instructions
;          
;          sys_getegid:                                      
;              mov  eax,50     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_getegid
sys_getegid:
	mov	eax,50
	int	byte 80h
	or	eax,eax
	ret