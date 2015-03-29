;--------------------------------------------------------------
;>1 syscall
; sys_lseek - kernel function                               
;
;    INPUTS 
;     see AsmRef function -> sys_lseek                                           
;
;    Note: functon call consists of four instructions
;          
;          sys_lseek:                                        
;              mov  eax,19     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_lseek
sys_lseek:
	mov	eax,19
	int	byte 80h
	or	eax,eax
	ret