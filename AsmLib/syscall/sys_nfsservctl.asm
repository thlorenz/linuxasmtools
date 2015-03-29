;--------------------------------------------------------------
;>1 syscall
; sys_nfsservctl - kernel function                          
;
;    INPUTS 
;     see AsmRef function -> sys_nfsservctl                                      
;
;    Note: functon call consists of four instructions
;          
;          sys_nfsservctl:                                   
;              mov  eax,169    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_nfsservctl
sys_nfsservctl:
	mov	eax,169
	int	byte 80h
	or	eax,eax
	ret