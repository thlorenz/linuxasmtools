;--------------------------------------------------------------
;>1 syscall
; sys_migrate_pages - kernel function                       
;
;    INPUTS 
;     see AsmRef function -> sys_migrate_pages                                   
;
;    Note: functon call consists of four instructions
;          
;          sys_migrate_pages:                                
;              mov  eax,294    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_migrate_pages
sys_migrate_pages:
	mov	eax,294
	int	byte 80h
	or	eax,eax
	ret