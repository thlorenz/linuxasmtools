;--------------------------------------------------------------
;>1 syscall
; sys_chroot - kernel function                              
;
;    INPUTS 
;     see AsmRef function -> sys_chroot                                          
;
;    Note: functon call consists of four instructions
;          
;          sys_chroot:                                       
;              mov  eax,61     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_chroot
sys_chroot:
	mov	eax,61
	int	byte 80h
	or	eax,eax
	ret