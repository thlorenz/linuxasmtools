;--------------------------------------------------------------
;>1 syscall
; sys_nanosleep - kernel function                           
;
;    INPUTS 
;     see AsmRef function -> sys_nanosleep                                       
;
;    Note: functon call consists of four instructions
;          
;          sys_nanosleep:                                    
;              mov  eax,162    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_nanosleep
sys_nanosleep:
	mov	eax,162
	int	byte 80h
	or	eax,eax
	ret