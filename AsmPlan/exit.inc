  extern ascii2days
  extern days2ascii
  extern ascii2regs
  extern days_in_month
  extern regs2days
  extern block_open_write
  extern block_close
  extern sort_selection

;5 exit *******************************************************************
;
; clear screen before exit
;
exit_program:
  cmp	byte [exit_program_flg],3
  je	exit              		;jmp if abort exit
  call	process_todos
  cmp	dword [file_end_ptr],fbuf
  je	skip_sort			;jmp if zero entries
  call	sort_todos
skip_sort:
  call	write_sorted_project
exit:
;  mov	eax,[exit_screen_color]
;  call	crt_clear
;  mov	ax,0101h
;  call	move_cursor
  call	reset_clear_terminal
  xor ebx,ebx
  mov eax,1
  int 80h

;-------------------------------------------------------------------
; delete all todo's with "D" at front
; reschedule all todo's with a "C" at front
;  inputs:  fbuf
;           [file_end_ptr]
;
process_todos:
  mov	esi,fbuf
pt_lp:
  cmp	esi,[file_end_ptr]		;check if done
  je	pt_end				;jmp if done
  cmp	byte [esi],'_'			;check if normal todo
  je	pt_10				;jmp if normal
  cmp	byte [esi],'D'
  jne	pt_20				;jmp if not delete
  call	cut_todo			;remove this todo
pt_10:
  call	next_todo
  jmp	pt_lp
pt_20:
  call	reschedule_todo
  jmp	pt_lp
pt_end:
  ret
;-------------------------------------------------------------------
; inputs:  esi = pointer to current todo
;          resched_table (see edit.inc)
; output:  esi = unchanged
;
reschedule_todo:
  mov	[active_todo_ptr],esi		;save pointer
  mov	ax,[esi + 1]			;get reschedule code

;nasm can't handle
;  and	ax,0ffdfh			;force upper case
  and	ax,-33

  mov	edi,resched_table
rt_lp:
  cmp	ax,[edi]
  je	rt_found
  add	edi,10
  cmp	byte [edi],0
  jne	rt_lp			;loop till resched found
rt_found:
  mov	eax,[edi + 6]		;get process address
  call	eax
  mov	esi,[active_todo_ptr]
  mov	byte [esi],'_'
  ret
  
;-------------------------------------------------------------------
resched_once:	;resched process
  call	cut_todo
  ret
;-------------------------------------------------------------------
resched_daily:	;resched process
  add	esi,year_field
  push	esi
  call	ascii2days		;sets eax=days since 1970
  inc	eax
  pop	edi			;storage point
  call	bin_to_date
  ret
;-------------------------------------------------------------------
resched_eom:	;resched process
  add	esi,year_field
  push	esi
  call	ascii2regs			;sets [year,month_number,day_of_month]
  inc	ah
  cmp	ah,12
  jbe	re_ok				;jmp if month ok
  mov	ah,1
  inc	edx				;move to next year
re_ok:
  push	eax
  mov	bl,ah				;get month
  call	days_in_month
  pop	eax
  mov	al,bl				;set days
  pop	edi				;get storage point
  call	regs_to_date
  ret  
;-------------------------------------------------------------------
resched_wk1:	;resched process
  add	esi,year_field
  push	esi
  call	ascii2days		;sets eax=days since 1970
  add	eax,7
  pop	edi			;storage point
  call	bin_to_date
  ret
;-------------------------------------------------------------------
resched_wk2:	;resched process
  add	esi,year_field
  push	esi
  call	ascii2days		;sets eax=days since 1970
  add	eax,14
  pop	edi			;storage point
  call	bin_to_date
  ret
;-------------------------------------------------------------------
resched_wk3:	;resched process
  add	esi,year_field
  push	esi
  call	ascii2days		;sets eax=days since 1970
  add	eax,21
  pop	edi			;storage point
  call	bin_to_date
  ret
;-------------------------------------------------------------------
resched_wk4:	;resched process
  add	esi,year_field
  push	esi
  call	ascii2days		;sets eax=days since 1970
  add	eax,28
  pop	edi			;storage point
  call	bin_to_date
  ret
;-------------------------------------------------------------------
resched_m1:		;resched process
  mov	bl,1
  call	bump_months
  ret  
;-------------------------------------------------------------------
resched_m2:		;resched process
  mov	bl,2
  call	bump_months
  ret
;-------------------------------------------------------------------
resched_m3:		;resched process
  mov	bl,3
  call	bump_months
  ret
;-------------------------------------------------------------------
resched_m4:		;resched process
  mov	bl,4
  call	bump_months
  ret
;-------------------------------------------------------------------
resched_m6:		;resched process
  mov	bl,6
  call	bump_months
  ret
;-------------------------------------------------------------------
resched_y1:		;resched process
  mov	bl,12
  call	bump_months
  ret
;-------------------------------------------------------------------
resched_y2:		;resched process
  mov	bl,24
  call	bump_months
  ret
;-------------------------------------------------------------------
resched_y3:		;resched process
  mov	bl,36
  call	bump_months
  ret
;
;-------------------------------------------------------------------
; inputs:  bl = number of months to bump
;          esi = ptr to todo
;          [year,month_number,day_of_month]
;
bump_months:
  add	esi,year_field			;point at date
  push	esi				;save ascii date ptr
  push	ebx				;save bump increment
  call	ascii2regs
  pop	ebx
  add	ah,bl				;bump months
bm_22:
  cmp	ah,12
  jbe	bm_30				;jmp if months ok
  inc	edx				;bump year
  sub	ah,12				;adjust months
  jmp	bm_22

bm_30:
  pop	edi				;get storage point
  call	regs_to_date
  ret
 
;-------------------------------------------------------------------
; input:  sort_index
;
write_sorted_project:
  mov	edi,lib_buf
  mov	esi,home_path
  call	str_move
  mov	esi,[project_ptr]	;get ptr to project name
  call	str_move
  
  mov	ebx,lib_buf
;;  mov ecx,O_WRONLY_CREAT_TRUNC
  xor	edx,edx			;default permissions
  call	block_open_write
  js wsp_error
;
; use index to find next todo
;
  mov	ebp,sort_index
wsp_lp1:
  mov	esi,[ebp]		;get todo ptr
  mov	ecx,esi			;save todo ptr
  or	esi,esi
  jz	wsp_done		;jmp if all todo's written
  sub	edx,edx
wsp_lp2:
  cmp	word [esi],0a0ah
  je	wsp_10			;jmp if end of todo found
  inc	esi			;move ptr
  inc	edx  			;bump count
  jmp	wsp_lp2
wsp_10:
  add	edx,2
;
; write to file
;  ebx = file descriptor
;  ecx = data pointer
;  edx = lenght of write
;
  mov	eax,4
  int	80h			;file write
  js	wsp_error
  add	ebp,4			;move to next record
  jmp	wsp_lp1
;
; error processing
;
wsp_error:
  call	err_msg
  jmp	wsp_done2  
;
; all data has been written, close file
;
wsp_done:
  call	block_close
  js	wsp_error
wsp_done2:
  ret

;------------------------------------------------------------

sort_todos:
  mov	esi,fbuf		;sort buffer
  mov	edi,sort_index		;index buffer
  call	make_index
  mov	ebp,sort_index
  xor	edx,edx			;sort from column 0
  mov	ecx,10			;length of sort
  call	sort_selection
  call	fix_index
  ret

;------------------------------------------
fix_index:
  mov	esi,sort_index
fi_lp:
  mov	eax,[esi]		;get index
  or	eax,eax
  jz	fi_done
  sub	eax,year_field
  mov	dword [esi],eax
  add	esi,4
  jmp	fi_lp
fi_done:
  ret
;------------------------------------------
; make index for sort
;  input:  esi = buffer to be sorted, each record ends with 0ah, zero = last
;          edi = index build area
;  output:  sorted index entries point at year field, adjust before
;           writing out data
;
make_index:
  add	esi,year_field
  mov	[edi],esi
  sub	esi,year_field
  add	edi,4
mi_lp:
  cmp	esi,[file_end_ptr] ;are we done?
  ja	mi_done		;jmp if done
  cmp	word [esi],0a0ah
  je	mi_20		;jmp if end of this todo
  inc	esi
  jmp	mi_lp
mi_20:
  add	esi,2
  cmp	esi,[file_end_ptr]
  jae	mi_done		;jmp if end of todos
  jmp	make_index
mi_done:
  mov	dword [edi],0	;terminate sort index
  ret

;-----------------------------------------------------------
;
; input: edi = store buf
;        eax = days
; output: yyyymmdd in ascii
;
bin_to_date:
  mov	ebx,edi
  mov	ebp,format2
  call	days2ascii
  ret

format2: db '012',0


;-----------------------------------------------------------
;
;  input:  al = day of month 1-31
;          ah = month number 1-12
;         edx = year
;         edi = storage location for ascii (year,month,day)
; output: ascii stored using ptr edi

regs_to_date:
  push	edi
  call	regs2days	;puts days in eax
  pop	edi
  call	bin_to_date
  ret