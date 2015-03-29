;--------------------------------------------------------------
;>1 syscall
; sys_setfsgid - kernel function                            
;
;    INPUTS 
;     see AsmRef function -> sys_setfsgid                                        
;
;    Note: functon call consists of four instructions
;          
;          sys_setfsgid:                                     
;              mov  eax,139    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_setfsgid
sys_setfsgid:
	mov	eax,139
	int	byte 80h
	or	eax,eax
	ret