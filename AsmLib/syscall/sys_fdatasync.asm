;--------------------------------------------------------------
;>1 syscall
; sys_fdatasync - kernel function                           
;
;    INPUTS 
;     see AsmRef function -> sys_fdatasync                                       
;
;    Note: functon call consists of four instructions
;          
;          sys_fdatasync:                                    
;              mov  eax,148    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_fdatasync
sys_fdatasync:
	mov	eax,148
	int	byte 80h
	or	eax,eax
	ret