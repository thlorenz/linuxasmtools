;--------------------------------------------------------------
;>1 syscall
; sys_afs_syscall - kernel function                         
;
;    INPUTS 
;     see AsmRef function -> sys_afs_syscall                                     
;
;    Note: functon call consists of four instructions
;          
;          sys_afs_syscall:                                  
;              mov  eax,137    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_afs_syscall
sys_afs_syscall:
	mov	eax,137
	int	byte 80h
	or	eax,eax
	ret