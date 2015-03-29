;--------------------------------------------------------------
;>1 syscall
; sys_remap_file_pages - kernel function                    
;
;    INPUTS 
;     see AsmRef function -> sys_remap_file_pages                                
;
;    Note: functon call consists of four instructions
;          
;          sys_remap_file_pages:                             
;              mov  eax,257    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_remap_file_pages
sys_remap_file_pages:
	mov	eax,257
	int	byte 80h
	or	eax,eax
	ret