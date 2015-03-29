;--------------------------------------------------------------
;>1 syscall
; sys_rmdir - kernel function                               
;
;    INPUTS 
;     see AsmRef function -> sys_rmdir                                           
;
;    Note: functon call consists of four instructions
;          
;          sys_rmdir:                                        
;              mov  eax,40     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_rmdir
sys_rmdir:
	mov	eax,40
	int	byte 80h
	or	eax,eax
	ret