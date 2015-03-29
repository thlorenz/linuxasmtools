;--------------------------------------------------------------
;>1 syscall
; sys_umount2 - kernel function                             
;
;    INPUTS 
;     see AsmRef function -> sys_umount2                                         
;
;    Note: functon call consists of four instructions
;          
;          sys_umount2:                                      
;              mov  eax,52     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_umount2
sys_umount2:
	mov	eax,52
	int	byte 80h
	or	eax,eax
	ret