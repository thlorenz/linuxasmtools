;--------------------------------------------------------------
;>1 syscall
; sys_ioctl - kernel function                               
;
;    INPUTS 
;     see AsmRef function -> sys_ioctl                                           
;
;    Note: functon call consists of four instructions
;          
;          sys_ioctl:                                        
;              mov  eax,54     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_ioctl
sys_ioctl:
	mov	eax,54
	int	byte 80h
	or	eax,eax
	ret