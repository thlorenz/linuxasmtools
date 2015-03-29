;--------------------------------------------------------------
;>1 syscall
; sys_umount - kernel function                              
;
;    INPUTS 
;     see AsmRef function -> sys_umount                                          
;
;    Note: functon call consists of four instructions
;          
;          sys_umount:                                       
;              mov  eax,22     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_umount
sys_umount:
	mov	eax,22
	int	byte 80h
	or	eax,eax
	ret