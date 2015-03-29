;--------------------------------------------------------------
;>1 syscall
; sys_chdir - kernel function                               
;
;    INPUTS 
;     see AsmRef function -> sys_chdir                                           
;
;    Note: functon call consists of four instructions
;          
;          sys_chdir:                                        
;              mov  eax,12     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_chdir
sys_chdir:
	mov	eax,12
	int	byte 80h
	or	eax,eax
	ret