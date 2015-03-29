;--------------------------------------------------------------
;>1 syscall
; sys_getrusage - kernel function                           
;
;    INPUTS 
;     see AsmRef function -> sys_getrusage                                       
;
;    Note: functon call consists of four instructions
;          
;          sys_getrusage:                                    
;              mov  eax,77     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_getrusage
sys_getrusage:
	mov	eax,77
	int	byte 80h
	or	eax,eax
	ret