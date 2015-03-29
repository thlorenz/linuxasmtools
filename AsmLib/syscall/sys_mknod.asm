;--------------------------------------------------------------
;>1 syscall
; sys_mknod - kernel function                               
;
;    INPUTS 
;     see AsmRef function -> sys_mknod                                           
;
;    Note: functon call consists of four instructions
;          
;          sys_mknod:                                        
;              mov  eax,14     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_mknod
sys_mknod:
	mov	eax,14
	int	byte 80h
	or	eax,eax
	ret