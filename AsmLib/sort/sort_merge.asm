
;   Copyright (C) 2007 Jeff Owens
;
;   This program is free software: you can redistribute it and/or modify
;   it under the terms of the GNU General Public License as published by
;   the Free Software Foundation, either version 3 of the License, or
;   (at your option) any later version.
;
;   This program is distributed in the hope that it will be useful,
;   but WITHOUT ANY WARRANTY; without even the implied warranty of
;   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;   GNU General Public License for more details.
;
;   You should have received a copy of the GNU General Public License
;   along with this program.  If not, see <http://www.gnu.org/licenses/>.


  [section .text align=1]
;%define DEBUG

%ifdef DEBUG

 [section .text]
 global _start
 global main
_start:
main:    ;080487B4
  mov	ebp,index
  mov	ebx,10		;length of sort key
  mov	ecx,11		;number of records
  mov	edx,0		;column of sort key
  call	sort_merge

  mov	eax,1
  int	80h

  [section .data]

index:	dd	rec1
	dd	rec2
	dd	rec3
	dd	rec4
	dd	rec5
	dd	rec6
	dd	rec7
	dd	rec8
	dd	rec9
	dd	reca
	dd	recb
	dd	0
 times 15 dd 0

rec1 db '999'
rec2 db '888'
rec3 db '777'
rec4 db '666'
rec5 db '555'
rec6 db '444'
rec7 db '333'
rec8 db '222'
rec9 db 'aaa'
reca db 'ccc'
recb db '111'

 times 6 db 0

  [section .text]
%endif

;------------------------------------------------------
;>1 sort
;sort_merge - merge sort buffer using index
; inputs:    ebp = address of dword ptr list (index) 
;                  pointing at records in a buffer.  The
;                  pointer list must be writable and have
;                  extra space at end.  The size of index
;                  and extra space is:
;                   ((8 * number-of-records) + 16)
;                  The extra area is used by sort_merge.
;            ebx = length of sort key (how many bytes in record
;                  to compare)
;            ecx = number of records in buffer
;            edx = starting column for sort, 0=first 1=second
;                  note: tabs are not expanded, so column is
;                        byte index into record.
; 
; output:
;            all registers are destroyed
;            The index has been reordered in acending sort
;            order.
; NOTES:
;            merge sort is very fast but uses more memory
;            than the bubble or selection sorts.  Generally
;            large sorting jobs should use the merge sort,
;            and small (2-100 records) can use the other
;            sorts.
;            This is a binary sort and does not recognize
;            end of line characters.  This can cause problems
;            with variable length records, beware.  
;            memory usage is about 200 bytes of code and a
;            buffer of (record_count * 8) bytes
;<
;-----------------------------------------------------------------


  global sort_merge
sort_merge:
	cld
	mov	[sort_column],edx
	mov	[sort_field_len],ebx
	mov	[index1_top],ebp
	mov	[record_count],ecx	
	mov	[delta],dword 4
	mov	[toggle],dword 0
;compute index2 locaton
	shl	ecx,2			;convert ecx to byte count
	mov	[index_length],ecx	;save length of index in bytes
	add	ebp,ecx			;add index1 start
	mov	[ebp],dword 0		;put zero at end
	mov	[index1_end],ebp	;save end of index1
	add	ebp,4			;move past zero
	mov	[index2_top],ebp	;save index2 start
	add	ebp,ecx			;compute index2 end
	mov	[index2_end],ebp	;save index2 end
	mov	[ebp],dword 0		;put zero at end of index2
lp1:
	mov	eax,[delta]		;check if done
	cmp	eax,[index_length]
	jb	onward
	jmp	sm_done
onward:
	xor	dword [toggle],1		;switch states
	jnz	build_index2
;setup for build in index1 buf
	mov	eax,[index1_top]
	mov	[move_ptr],eax
	mov	eax,[index2_end]
	mov	[buf_end],eax
	mov	ebp,[index2_top]
	mov	ebx,ebp
	add	ebp,[delta]
	jmp	short lp2
;setup for build in index2 buf
build_index2:
	mov	eax,[index2_top]
	mov	[move_ptr],eax
	mov	eax,[index1_end]
	mov	[buf_end],eax
	mov	ebp,[index1_top]
	mov	ebx,ebp
	add	ebp,[delta]
lp2:
	cmp	ebp,[buf_end]
	jae	lp2_tail		;jmp if on pass complete
; merge, ebx=lista  ebp=listb	
	call	merge
	add	ebx,[delta]
	add	ebp,[delta]
	jmp	short lp2	
lp2_tail:
	cmp	ebx,[buf_end]
	jae	lp2_done
;move indexes at [ebp]
	mov	esi,ebx	
	mov	edi,[move_ptr]
tail_lp:
	lodsd
	stosd
	or	eax,eax
	jnz	tail_lp
	mov	[move_ptr],edi	;; needed?
lp2_done:
	shl	dword [delta],1
	jmp	lp1

sm_done:
	test	byte [toggle],1
	jz	sm_done2		;jmp if index1 has current pointers
	mov	esi,[index2_top]
	mov	edi,[index1_top]
	mov	ecx,[record_count]
	rep	movsd
sm_done2:
	ret

;------------------------
  [section .data]

record_count	dd	0
index_length	dd	0 ;bytes (record_count * 4)
index1_top:	dd	0 ;top of initial input index
index2_top:	dd	0 ;top of work buf
index1_end:	dd	0
index2_end:	dd	0
toggle:		dd	0 ;index active 0=index1 1=index2
buf_end:	dd	0 ;end of current merge list in ebp

  [section .text]

;--------------------------------------------------------------------
; MERGE - combine two sorted lists
;   inputs:   ebx = list1 index top (short list's terminated by 0)
;             ebp = list2 index top, (short list's terminated by 0)
;             delta = length of each list, 4=one entry (dword)
;             sort_field_len = length of sort key (compare string)
;             sort_column = column of sort key (compare string)
;             move_ptr - destination for sorted index
;
;  output: ebx,ebp updated to end of field
;          edi = [move_ptr] = stuff ptr for next index
merge:
	mov	eax,[delta]		;get list1 length
	mov	edx,eax			;list2 length

;registers eax=list1 len    ebx=list1 ptr
;          edx=list2 len    ebp=list2 ptr
m_lp:	mov	edi,[ebp]		;get list2 record ptr
	mov	esi,[ebx]		;get list1 record ptr
;check if list1 has pointers
        cmp	eax,4			;check list1 length
	js	sort2_only		;jmp if list1 out of data
	or	esi,esi			;check if list1 has record
	je	sort2_only		;jmp if list1 out of data
;check if list2 has pointers
	cmp	edx,4			;check list2 length
	js	move1			;jmp if list2 empty
	or	edi,edi			;check if list2 has record
	je	move1			;jmp if list2 empty
; list1 & list2 have data, setup for compare
	mov	ecx,[sort_column]
	add	esi,ecx		;move to sort point
	add	edi,ecx		;move to sort point
; both lists have valid records, do compare
	mov	ecx,[sort_field_len]
	repe	cmpsb
	jbe	move1			;jmp if list1 record smaller
; list2 has smaller record data, move it
move2:	mov	esi,ebp			;get list2 ptr
	sub	edx,4			;dec length
	add	ebp,4			;move to next list1 entry
	jmp	short do_move
; list1 has smaller record data, move it
move1:	mov	esi,ebx			;get list1 ptr
	sub	eax,4			;dec length
	add	ebx,4			;move to next list2 entry
do_move:
	mov	edi,[move_ptr]
	movsd
	mov	[move_ptr],edi
	jmp	short m_lp
; list1 is empty, check list2
sort2_only:
	cmp	edx,4			;check list2 length
	js	merge_done1		;jmp if end of both lists
	or	edi,edi			;check if record available
	jnz	move2			;jmp if list record avail
merge_done1:
	ret
;-----------------------------------------------
  [section .data]

sort_field_len dd	0	;word  value of above
sort_column	dd	0	;index to sort field
delta		dd	0
move_ptr	dd	0	;current store posn in work_seg
  [section .text]

