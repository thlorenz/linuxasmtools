;--------------------------------------------------------------
;>1 syscall
; sys_read - kernel function                                
;
;    INPUTS 
;     see AsmRef function -> sys_read                                            
;
;    Note: functon call consists of four instructions
;          
;          sys_read:                                         
;              mov  eax,3      
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_read
sys_read:
	mov	eax,3
	int	byte 80h
	or	eax,eax
	ret