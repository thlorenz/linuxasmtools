;--------------------------------------------------------------
;>1 syscall
; sys_truncate - kernel function                            
;
;    INPUTS 
;     see AsmRef function -> sys_truncate                                        
;
;    Note: functon call consists of four instructions
;          
;          sys_truncate:                                     
;              mov  eax,92     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_truncate
sys_truncate:
	mov	eax,92
	int	byte 80h
	or	eax,eax
	ret