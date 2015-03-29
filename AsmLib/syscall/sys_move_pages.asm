;--------------------------------------------------------------
;>1 syscall
; sys_move_pages - kernel function                          
;
;    INPUTS 
;     see AsmRef function -> sys_move_pages                                      
;
;    Note: functon call consists of four instructions
;          
;          sys_move_pages:                                   
;              mov  eax,317    
;              int  byte 80h
;              or   eax,eax
;              ret
;<;
;------------------------------------------------------------------
  [section .text align=1]

  global sys_move_pages
sys_move_pages:
	mov	eax,317
	int	byte 80h
	or	eax,eax
	ret