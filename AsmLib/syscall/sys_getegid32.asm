;--------------------------------------------------------------
;>1 syscall
; sys_getegid32 - kernel function                           
;
;    INPUTS 
;     see AsmRef function -> sys_getegid32                                       
;
;    Note: functon call consists of four instructions
;          
;          sys_getegid32:                                    
;              mov  eax,202    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_getegid32
sys_getegid32:
	mov	eax,202
	int	byte 80h
	or	eax,eax
	ret