;--------------------------------------------------------------
;>1 syscall
; sys_symlink - kernel function                             
;
;    INPUTS 
;     see AsmRef function -> sys_symlink                                         
;
;    Note: functon call consists of four instructions
;          
;          sys_symlink:                                      
;              mov  eax,83     
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_symlink
sys_symlink:
	mov	eax,83
	int	byte 80h
	or	eax,eax
	ret