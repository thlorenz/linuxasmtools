  [section .text]

;****f* sort/sort_selection *
; NAME
;>1 sort
;  sort_dword_array3 - use selection sort with ptr list
;    This routine expects to find a dword sort key in data
; INPUTS
;    ebp - pointer to pointers for each record
;          last pointer equals zero
;    edx = column in data with dword sort key
;          0=first column
; OUTPUT
;    pointers ordered by decending  records 
; NOTES
;   source file: sort_dword_array3.asm
;   The index must have at least one entry.
;<
; * ----------------------------------------------
;*******
;
  global sort_dword_array3
sort_dword_array3:
  cmp	dword [ebp],0			;check if nothing to sort
  jz	ss_done
ss_lp1:
  mov	ebx,ebp
  add	ebx,4
  cmp	dword [ebx],0			;check if sort done
  je	ss_done
; do compare
ss_lp2:
  mov	esi,[ebp]			;get current selection
  mov	edi,[ebx]			;get challenger
  add	esi,edx				;move to selected column
  add	edi,edx				;move to selected column
  cmpsd					;compare dword
;  repe	cmpsb				;compare
  jbe	next_challenger			;jmp if not smaller
; we have found a smaller entry
  mov	eax,[ebp]	;get old lowest
  xchg	eax,[ebx]	;put at challenger's space
  mov	[ebp],eax	;put challenger at top
next_challenger:
  add	ebx,4		;move to next challenger
  cmp	dword [ebx],0	;at end of this pass?
  jne	ss_lp2		;loop till done
; move past current small and start again
  add	ebp,4
  jmp	ss_lp1	
ss_done:
  ret
;-----------
