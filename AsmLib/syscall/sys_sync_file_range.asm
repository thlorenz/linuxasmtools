;--------------------------------------------------------------
;>1 syscall
; sys_sync_file_range - kernel function                     
;
;    INPUTS 
;     see AsmRef function -> sys_sync_file_range                                 
;
;    Note: functon call consists of four instructions
;          
;          sys_sync_file_range:                              
;              mov  eax,314    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_sync_file_range
sys_sync_file_range:
	mov	eax,314
	int	byte 80h
	or	eax,eax
	ret