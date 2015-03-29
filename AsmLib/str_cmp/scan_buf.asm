
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
%undef DEBUG
;-------------------------------------------

  extern strlen1
  extern lib_buf


LARGENUM	equ 255
MAXPATLEN	equ 254


;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -( SEARCH  )
;>1 str_cmp
;  scan_buf_open - setup for scan buffer for string
;
;  INPUTS     esi = points at string to search for (max length 254)
;             dl = 0 for match case, 20h for match either case
;
;  OUTPUT     eax = 0 if sucessful
;             possible errors are: - string length too long or zero bytes.
;                                  - insufficient memory
;
;  Note:  The fast block scan functions need to be called as follows:
;            scan_buf_open  - allocate memory, initialize tables for scan
;            scan_buf       - actual scan operation, call repeatedly
;         The scan_buf uses Boyer-Moore for high speed scan
;
;<
;  * ----------------------------------------------
;* * * * * * * * * * * * * *

  global scan_buf_open
scan_buf_open:
 cld
 mov	[case_flag],dl
 not	byte [case_flag] ;;
;
; determine compare string length
;
 call	strlen1
 jecxz	md1_abort	;jmp if zero length compare string
 cmp	ecx,MAXPATLEN
 ja	md1_abort	;jmp if string too long
 mov	[iPatLen],ecx	;sav match string len
;
; fill delta_tbl table with length of compare string
;
 mov	al,cl	;fill
 mov	ah,cl   ;  eax
 mov	ecx,eax ;    with
 shl	eax,16  ;      length
 mov	ax,cx

 mov	ecx, 256/4
 mov	edi,delta_tbl
 rep	stosd

;For each character 'x' in the pattern string, set delta_tbl['x']
;with the distance that 'x' is away from the end of the pattern string.
;If 'x' occurs more than once, use the smallest distance (which
;  is already built in to the algorithm).
;If 'x' is the last character in the pattern string, use
;  LARGENUM instead of 0.
;For case insensitivity, delta_tbl['x'] = delta_tbl['X'].
;Example: if the pattern string is 'Kitty' and DL = 20h, then
;  delta_tbl['k'] = delta_tbl['K'] = 4
;  delta_tbl['i'] = delta_tbl['I'] = 3
;  delta_tbl['t'] = delta_tbl['T'] = 1 (the 2nd 't' overwrites 2)
;  delta_tbl['y'] = delta_tbl['Y'] = LARGENUM
;  all other entries (i.e. those entries of delta_tbl['x'] where
;  'x' in not in the pattern string) have a distance of 5

 mov	cl, al			;set cl = compare string length
 sub	ebx,ebx
md1_loop2:
 dec	al			;compare string length - 1
 jnz	md1_skip1		;jmp if length was 2+
 mov	al, LARGENUM		;if length was 1, store ff for all 
md1_skip1:
 mov	bl, [esi]		;get character
 inc	esi			;move to next char
 mov	[delta_tbl + ebx], al   ;insert length into table
;
; Note: the following code only set case on alpha characters, and
;       that screwed up the compare if last char was non-alphs.
;       Removing the alpha character check allow the match to occur
;       and adds the possibility we will match on control characters
;       that are not upper/lower case alternate.  It should be a rare
;       occurance in  text files and even in binary files.
; 
; mov	ah, bl
; or	ah, dl			;change char to alt case
; sub	ah, 'a'
; cmp	ah, 'z' - 'a' + 1
; jnc	md1_skip2
 xor	bl, dl				;dl=case flag 0=match 20=any case
 mov	[delta_tbl + ebx], al
md1_skip2:
 loop	md1_loop2

;Convert the pattern string into distances, using the delta_tbl
;  table (aiPatStart[i] = delta_tbl[pchPatStart[i]]).  This
;  speeds up the search routine later.

 mov	ecx, [iPatLen]			;get len of pattrn (match ssring)
 sub	esi,ecx				;set esi=pattern ptr
 mov	edi, aiPatStart			;get ptr to pattrn table
md1_loop3:
 mov	bl, [esi]			;get pattern char
 mov	bl, [delta_tbl + ebx]		;get aiDela1 entry for this char.
 mov	[edi], bl
 inc	edi
 inc	esi
 loop	md1_loop3
 mov	byte [edi], 00h				;?? this was "mov [esi]"

;Start at the beginning of the pattern string.

 mov	[piPatCurr], dword aiPatStart ;init skip table ptr
 sub	eax, eax		; return okay
md1_exit:
 ret

md1_abort:
 mov	al, 0001h	; return error
 jmp	short md1_exit

;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -( SEARCH  )
;>1 str_cmp
;  scan_buf - fast scan of sequential buffers for string
;
;  INPUT      esi = points at block of data to be scanned
;             ecx = block length (byte count)
;
;  output:    esi = points at remaining data to be scanned
;             edi = pointer to match in buffer
;             ecx = number of bytes remaining to be scanned
;             eax = 0 for match found (may be match split between two blocks)
;                   1 for end of block, no match.
;
;  note:  scan_buf can find multiple matches in a buffer, and
;         automatically sets up inputs to be re-entered.  Matches split
;         across two buffers (blocks) are also handled.
;
;         The scan_buf uses Boyer-Moore for high speed scan
;
;         scan_buf can be called repeatedly as long as the compare
;         string is not changed.  If the compare string changes, then
;         scan_buf_open should be called..
;
;         Some benchmarks from a DOS system shows how scan_buf compares
;         to other search methods:
;                            code size   time (small numbers best)
;                            ---------   -------------------------
;         SCAN_BLOCK_TINY1    46 bytes    2.36 (small is faster)
;         SCAN_BLOCK_TINY2    69 bytes   13.35 (matches ether case)
;         SCAN_BLOCK1         43 bytes    2.36
;         SCAN_BLOCK2        152 bytes    6.37 (matches either case)
;         scan_buf           466 bytes    1.42 
;
;
;  Example:     
;                mov   esi, offset pattern
;                mov   dl, 20h
;                call  scan_buf_open
;                test  ax, ax
;                jnz   error
;
;        read_loop:
;                 mov   esi, target
;                 (setup esi,ecx here for scan_buf call)
;                 (if last buffer then goto to done)
;        search_loop:
;                 call  scan_buf
;                 test  eax, eax
;                 jz    read_loop
;                 (process match found here, esi points at end of match)
;                 jecxz  read_loop
;                 jmp   search_loop
;
;          done:
;
; Credits:  This code origionally provided by Mike Levis and modified
;           by Jeff Owens
;<
;  * ----------------------------------------------
;* * * * * * * * * * * * * *

%define cx_iTrgLen ecx       ;buf len/remaining
%define dx_iPatLen1 edx      ;match len/remaining
%define dx_piSavePatCurr edx ;table ptr sav
%define si_pchTrgCurr esi    ;buf ptr
%define di_piPatCurr edi     ;table ptr
%define bp_pchTrgEnd ebp     ;ptr to end of match str


  global scan_buf
scan_buf:
 mov	ah,[case_flag]
 sub	ebx,ebx
 mov	di_piPatCurr,[piPatCurr] ;init ptr to match table

;get length of pattern string (may be partial match)

 mov	dx_iPatLen1, [iPatLen] ;init match count
 add	dx_iPatLen1, aiPatStart ;add ptr table of skip values
 sub	dx_iPatLen1, di_piPatCurr ;sub current ptr of match codes

;get address of target string end

 mov	bp_pchTrgEnd, si_pchTrgCurr ;get buffer ptr
 add	bp_pchTrgEnd, cx_iTrgLen ;init end of buffer ptr

; if ([iPatLen]1 > iTrgLen) then no possible match

 cmp	dx_iPatLen1, cx_iTrgLen ;buf siz > match size?
 ja	s_no_match ;jmp if buf too small for match
 mov	[pchTrgStart], si_pchTrgCurr ;init save buf start

;use brute force if partial match is in progress

 cmp	dx_iPatLen1, [iPatLen] ;match count = match str len?
 jne	s_slow ;jmp if match in progress

;Jump over characters in target string that are not in the
;  pattern string, and/or jump to the character in the target
;  string that is the same as the last chacter of the pattern
;  string.

s_fast:
 mov	bl, [si_pchTrgCurr]
 and	bl,ah			;[case_flag]			;;;
 mov	bl, [delta_tbl + ebx]
 cmp	bl, LARGENUM          
 je	s_fast_end            
 add	si_pchTrgCurr, ebx     
 jc	s_no_match            
 cmp	si_pchTrgCurr, bp_pchTrgEnd
 jb	s_fast                     
 jmp	short s_no_match                
s_fast_end:
 inc	si_pchTrgCurr             
 mov	[pchTrgSave], si_pchTrgCurr
 sub	si_pchTrgCurr, dx_iPatLen1

; if (pchTrgCurr < pchTrgStart) {pchTrgCurr += [iPatLen]1;   goto fast;}

 cmp	si_pchTrgCurr, [pchTrgStart]
 jnb	s_slow
 add	si_pchTrgCurr, dx_iPatLen1
 jmp	short s_fast

s_no_match:
 jcxz	s_null_string
 call	CheckTail
 sub	cx_iTrgLen, cx_iTrgLen
 mov	al, 0001h
 jmp	short s_exit

;Do a char-by-char comparison of the target string with the pattern string.

s_slow:
 mov	bl, [si_pchTrgCurr]
 mov	al, [delta_tbl + ebx]
 mov	bl, [di_piPatCurr]
 cmp	al, bl
 jne	s_skip1
 inc	si_pchTrgCurr
 inc	di_piPatCurr
 dec	dx_iPatLen1
 jnz	s_slow
 jmp	short s_match
s_skip1:

;Since the pattern has not been found in the target string yet,
;  adjust target string index to look for the next match
;  ("pchTrgSave + 2" is needed to avoid backsliding)

 add	si_pchTrgCurr, dx_iPatLen1
 cmp	al, LARGENUM
 je	s_skip2a
 cmp	si_pchTrgCurr, [pchTrgSave]
 jnb	s_skip2b
s_skip2a:
 mov	si_pchTrgCurr, [pchTrgSave]
 add	si_pchTrgCurr, 0002h
s_skip2b:

;Check to see if there are more characters in the target string

 cmp	si_pchTrgCurr, bp_pchTrgEnd
 jnbe	s_skip3
 mov	dx_iPatLen1, [iPatLen]
 mov	di_piPatCurr,dword  aiPatStart
 jmp	short s_fast
s_skip3:

s_null_string:
 mov	[piPatCurr], di_piPatCurr
 mov	al,1
 jmp	short s_exit

s_match:
 sub	cx_iTrgLen, si_pchTrgCurr
 add	cx_iTrgLen, [pchTrgStart]
 mov	[piPatCurr], dword aiPatStart
 mov	edi,esi				;set edi= end of match 
 sub	edi,[iPatLen]			;point edi at start of match in buffer
;; dec	edi
 sub	eax, eax

s_exit:
 ret
;====================================================================
;  CheckTail
;    Called only by Search to look for partial matches at the tail end
;    of the target string, using a brute force variation.
;    Essential, this routine scans the target string tail to get
;    characters that are in the pattern string, and then uses the brute
;    force method on them.

CheckTail:
 mov	eax, dx_iPatLen1 ;get match count
 mov	dx_piSavePatCurr, di_piPatCurr ;get table ptr
 dec	eax

; if (iTrgLen > [iPatLen]1 - 1)
;    iTrgLen = [iPatLen]1 - 1;
; iSaveTrgLen = iTrgLen;

 cmp	cx_iTrgLen, eax ;buf len > match count?
 jbe	ct_skip1 ;jmp if buf len < match len
 mov	cx_iTrgLen, eax ;set buf length
ct_skip1:
 mov	eax, [iPatLen] ;get match len
 mov	ah, cl

 lea	si_pchTrgCurr, [bp_pchTrgEnd - 1] ;

; while ([iPatLen] != delta_tbl[*pchTrgCurr] && iTrgLen --)  pchTrgCurr ++;

ct_loop1:
 mov	bl, [si_pchTrgCurr] ;current buf char
 mov	bl, [delta_tbl + ebx] ;index into table
 cmp	al, bl
 je	ct_skip2
 dec	si_pchTrgCurr ;move buf ptr
 loop	ct_loop1

; pchTrgCurr ++; if (pchTrgCurr == pchTrgEnd)
;    goto no_match;

ct_skip2:
 inc	si_pchTrgCurr ;move buf ptr
 cmp	si_pchTrgCurr, bp_pchTrgEnd ;end of buf
 jae	ct_no_match ;jmp if at end of buffer

; iTrgLen = iSaveTmpLen - iTrgLen;

 mov	al, ah ;get match str len
 neg	cx_iTrgLen
 sub	ah, ah
 add	cx_iTrgLen, eax ;compute partial match len
ct_loop2:
 mov	[iSaveTrgLen], cx_iTrgLen ;save partial match len
 mov	[pchSaveTrgCurr], si_pchTrgCurr ;sav match ptr

;    while (delta_tbl[*pchTrgCurr++] == *piPatCurr++ && iTrgLen--)
;    if (delta_tbl[*(pchTrgCurr - 1)] == *(piPatCurr - 1))
;       goto match

ct_loop3:
 mov	bl, [si_pchTrgCurr] ;get buf char
 mov	al, [delta_tbl + ebx] ;look up in table
 mov	bl, [di_piPatCurr] ;get match char
 inc	si_pchTrgCurr ;bump buf ptr
 inc	di_piPatCurr ;bump match ptr
 cmp	al, bl ;match
 loope	ct_loop3 ;loop if matching
 je	ct_match ;jmp if match found

;    piPatCurr = piSavePatCurr
;    pchTrgCurr = pchSaveTrgCurr + 1
;    iTrgLen = iSaveTrgLen
; } while (iTrgLen --);

 mov	di_piPatCurr, dx_piSavePatCurr ;restore match ptr
 mov	si_pchTrgCurr, [pchSaveTrgCurr] ;restore buf ptr
 mov	cx_iTrgLen, [iSaveTrgLen] ;restore match len
 inc	si_pchTrgCurr
 loop	ct_loop2 ;loop if more buf data
 
ct_no_match:
 mov	al, 001h
 mov	[piPatCurr], dword aiPatStart
 jmp	short ct_exit

ct_match:
 mov	[piPatCurr], di_piPatCurr
 cmp	si_pchTrgCurr, bp_pchTrgEnd
 sub	eax, eax
ct_exit:
 mov	si_pchTrgCurr, bp_pchTrgEnd
 ret


  [section .data align=4]
;----------------------------------------------------------------------------
; data needed by SCAN_BLOCK routines
;
;table with entry for each alpha char and distances in search string
delta_tbl   times 256 db 0

iPatLen		dd	0 ;match string length
;table of shift values (skip forward) for search string characters
aiPatStart times MAXPATLEN db 0
piPatCurr	dd 0 ;current table ptr
;
; variables used by Check_tail
;
pchSaveTrgCurr	dd	0 ;buf ptr save
iSaveTrgLen	dd	0 ;match str ptr save
;
; variables used by search
;
pchTrgSave	dd	0 ;buf ptr save
pchTrgStart	dd	0 ;match str ptr save
case_flag	db	0 ;0=match 20h=any case match
;---------------------------------------------------------------------

;---------------------------------------------------------------------

  [section .text]  

%ifdef DEBUG

 global _start
 global main
_start:
main:    ;080487B4
  cld

  mov	esi,search_string
  call	scan_buf_open
  mov	edi,search_buffer
  mov	ecx,search_buffer_end
  sub	ecx,edi			;compute length
  call	scan_buf

  mov	eax,1
  int	80h

search_string	db	'jeff',0
search_buffer	db	'can you find jeff in this buffer'
search_buffer_end:


%endif

