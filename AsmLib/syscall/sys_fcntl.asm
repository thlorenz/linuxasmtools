;--------------------------------------------------------------
;>1 syscall
; sys_fcntl - kernel function                               
;
;    INPUTS 
;     see AsmRef function -> sys_fcntl                                           
;
;    Note: functon call consists of four instructions
;          
;          sys_fcntl:                                        
;              mov  eax,55     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_fcntl
sys_fcntl:
	mov	eax,55
	int	byte 80h
	or	eax,eax
	ret