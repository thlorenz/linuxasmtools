;--------------------------------------------------------------
;>1 syscall
; sys_write - kernel function                               
;
;    INPUTS 
;     see AsmRef function -> sys_write                                           
;
;    Note: functon call consists of four instructions
;          
;          sys_write:                                        
;              mov  eax,4      
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_write
sys_write:
	mov	eax,4
	int	byte 80h
	or	eax,eax
	ret