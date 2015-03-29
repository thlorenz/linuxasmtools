
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
  [section .noteGNU-stack]

  [section .text]

  extern memory_init
;%define DEBUG
%undef DEBUG


struc packet
.bak_ptr: resd 1   ;zero if first packet
.length:  resd 1   ;memory allocation size including pkt header,
                   ;set negative if available
.checksum: resd 1  ;sum of all above
.memory:	   ;start of allocated memory block
endstruc

;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;>1 memory
;  m_allocate - provide memory to caller
;             This function may be called after calling
;             the m_setup function
;  INPUTS     eax = size of allocation request in bytes
;
;  OUTPUT     eax = positive memory address if successful
;             eax = negative error code as following:
;                   -1 can not allocate memory
;                   -2 memory corrupted by caller.  This is
;                      usually a memory leak that clobbered
;                      the memory manager data area.
;                 sign flag set for "js" or "jns"
;  DESIGN     Each allocated area of memory requires overhead
;             of 12 bytes for record keeping.  This data is
;             placed in a header infront of each allocated
;             memory block.  It can be accessed by programs
;             but should not be modified.
;
;             Memory managers are often blamed for program bugs
;             and become corrupted if thier record keeping is hit
;             my memory leaks.  To avoid these problems all headers
;             are checksumed and if any corruption occurs the
;             memory manager returns an error.
;
;             This design favors reliability and security over
;             speed, but is moderatly fast and frees the programmer
;             from buffer management and overlap/fragmentation
;             problems.
;
;             The format of the header is:  struc header
;                                           .prev_block_ptr  resd 1
;                                           .block_size      resd 1
;                                           .checksum        resd 1
;                                           .memory ; (memory block start)
;                                           endstruc
;
;  NOTE       source file is memory.asm
;
;<
;  * ----------------------------------------------


allocate_first_pkt:
  mov	[first_time_flag],ecx ;disable first time path
  push	eax		;save request
  push	ebx		;save pkt start
  add	ebx,eax		;compute end of allocation
  mov	edx,ebx		;save allocation end
  add	ebx,16		;allocate extra for end of chain marker
  mov	eax,45		;allocate memory
  int	80h
  pop	ebx		;get top of block ptr
  pop	ecx		;get allocation size
  or	eax,eax		;check if error
  js	m_error1j
;fill in the packet
  xor	eax,eax
  mov	[ebx+packet.bak_ptr],eax ;first=zero
  mov	[ebx+packet.length],ecx
;create a dummey end of chain packet
  mov	[edx+packet.bak_ptr],ebx  ;insert bak_ptr
  mov	[edx+packet.length],eax   ;set length=0 (end of chain)
;checksum the allecated memory packet
  add	eax,ecx		;compute checksum
  mov	[ebx+packet.checksum],eax
  lea	eax,[ebx+packet.memory] ;get allocatation address for caller
  jmp	m_exit
m_error1j:
  jmp	m_error1
;---------------------------------
  global m_allocate
m_allocate:
  add	eax,15		;add packet size +
  and	eax,~3		;force to dword boundry
  mov	ebx,[chain_top]	;
  xor	ecx,ecx
  cmp	dword [first_time_flag],ecx	;ecx=0
  jne	allocate_first_pkt
;scan through existing packets looking for free memory
; edx=request  ebx=pkt ptr  edi=current best fit
;                           ecx=size of current best fit
  mov	edx,eax		;request size to edx
  not	ecx		;set ecx=-1
;  mov	ecx,-1		;size of best current free packet to request
pkt_srch_loop:
  mov	esi,[ebx+packet.length]	;get length
  or	esi,esi
  jz	end_of_chain	;jmp if end of chain reached
  mov	eax,[ebx]	;get bak_ptr from pkt
  add	eax,esi		;checksum= bak_ptr - length
  cmp	eax,[ebx+packet.checksum]
  jne	m_error2	;jmp if checksum failed
;check if this packets memory is in use
  or	esi,esi
  jns	skip_pkt	;jmp if packet in use
  neg	esi		;set length positive
;check if this packet has room to allocate memory
  cmp	esi,edx
  je	got_pkt		;use if exact size
  ja	got_possible
;this packet does not have room, check if more packets
skip_pkt:
  add	ebx,esi		;move to next packet
  jmp	short pkt_srch_loop

;we have found a free packet with room, check if better fit
; edx=request  ebx=pkt ptr  edi=current best fit
;                           ecx=size of current best fit
got_possible:
  cmp	esi,ecx		;check if new packet smaller
  ja	skip_pkt	;jmp if old packet was smaller
  mov	ecx,esi		;set new best size
  mov	edi,ebx		;set ptr to new best pkt
  jmp	short skip_pkt	;continue
;this packet is an exact fit, use it
; ebx=pkt pointer
got_pkt:
  mov	eax,[ebx+packet.length]
  neg	eax
  mov	[ebx+packet.length],eax		;set in use
  add	eax,[ebx+packet.bak_ptr]		;compute new checksum
  mov	[ebx+packet.checksum],eax
  lea	eax,[ebx+packet.memory]
  jmp	m_exit		;return to caller

;we are at the end of pkt chain, check if any possibles found
end_of_chain:
  or	ecx,ecx		;any packets with room found
  jns	split_packet	;jmp if packet found
;we need to allocate more memory, no packets were found
;check if last packet is free,
  mov	esi,[ebx+packet.bak_ptr]
  or	esi,esi		;is this also the top pkt
  jnz	m_end2		;jmp if end pkt is not top pkt also
  mov	esi,ebx		;only one pkt in chain, setup for allocate_end_pkt
m_end2:
  mov	eax,[esi+packet.length]
  or	eax,eax
  js	expand_last_pkt ;jmp if last packet has free memory
;last packet is in use, allocate new memory
  jmp	allocate_end_pkt

m_error2:
  mov	eax,-2
  jmp	m_exit
;
; split packet
; edx=request   edi=current best fit
;               ecx=size of current best fit
split_packet:
  mov	ebx,edi		;setup for got_pkt jump
  mov	eax,edx
  add	eax,16		;compute minimum split threshold
  cmp	eax,ecx		;check if this pkt has enough memory
  ja	got_pkt		;reuse if not big enough to split
;put our new packet at end of split packet
;compute reduced size of origional packet
;return top packet memory to caller
;edx=request size (including overhead) edi=split pkt  ecx=split pkt size
  sub	ecx,edx		;set ecx=size of remaining split pkt
  mov	esi,edi		;compute
  add	esi,ecx		;  remaining pkt address
;fill in remaining split pkt, at top of origional split pkt
;edi=split ptr   esi=new pkt ptr
;ecx=split size  edx=new pkt size
  neg	ecx		;set remaining size to avail (negative
  mov	[edi+packet.length],ecx
  mov	eax,[edi+packet.bak_ptr] ;compute
  add	eax,ecx			  ;  checksum
  mov	[edi+packet.checksum],eax
;build new pkt
  mov	[esi+packet.bak_ptr],edi  ;insert bak_ptr
  mov	[esi+packet.length],edx	  ;insert length
  mov	eax,edi			  ;get split pkt ptr (bak_ptr) for new
  add	eax,edx			  ;compute checksum
  mov	[esi+packet.checksum],eax ;insert checksum
;adjust fwd packet bak_ptr and checksum
;first, verify fwd packet is ok
  mov	ebx,esi			  ;get new pkt ptr
  add	ebx,edx			  ;compute fwd pkt address (edi)
;verify fwd packet is ok (checksum)
  mov	eax,[ebx+packet.length]	  ;compute checksum
  or	eax,eax			  ;is this end of chain
  jz	build_fwd_pkt
  add	eax,[ebx+packet.bak_ptr]  ;get bak_ptr (new packet)
  cmp	eax,[ebx+packet.checksum]
  jne	m_error2
;fwd packet is ok, build new bak_ptr and checksum
build_fwd_pkt:
  mov	[ebx+packet.bak_ptr],esi
  mov	eax,esi			;get bak ptr
  add	eax,[ebx+packet.length]	;compute checksum
  mov	[ebx+packet.checksum],eax ;store new checksum

  lea	eax,[esi+packet.memory]	;get callers memory address 
  jmp	short m_exit
;last packet has free memory, use it and allocate more
; ebx=last pkt ptr
; eax=last pkt size (negative)
; esi=last pkt bak_ptr
; edx=request size
expand_last_pkt:
  mov	ebx,esi			;move from dummy pkt at end to last pkt
  mov	esi,[ebx]		;get bak ptr from last pkt
  mov	[ebx+packet.length],edx	;insert new size in last pkt
  add	esi,edx			;checksum = bak_ptr - length
  mov	[ebx+packet.checksum],esi
;allocate memory
  mov	edi,ebx			;save packet ptr
  add	ebx,edx			;compute new memory end
  mov	eax,45		;allocate memory
  int	80h
  or	eax,eax
  js	m_error1
  lea   eax,[edi+packet.memory]
  jmp   short m_exit  
m_error1:
  mov	eax,-1
m_exit:
  or	eax,eax
  ret  

;we need to allocate memory and add new pkt at end
; esi=last pkt ptr   edx=request size
allocate_end_pkt:
  mov	ebp,[esi+packet.length] ;get length
  add	ebp,esi		;compute next packet ptr
;compute new end of memory
  mov	ebx,ebp
  add	ebx,edx		;add request size
  add	ebx,12		;add extra room for dummy end pkt  
  mov	eax,45		;allocate memory
  int	80h		;ebx=new end of address space
  or	eax,eax		;check if error
  js	m_error1
;fill in the packet
  mov	[ebp+packet.bak_ptr],esi ;point to previous chain end
  mov	[ebp+packet.length],edx
;create a dummey end of chain packet
  mov	ecx,ebp			  ;compute
  add	ecx,edx			  ;   dummy end pkt location
  mov	[ecx+packet.bak_ptr],ebp  ;insert bak_ptr
  xor	eax,eax
  mov	[ecx+packet.length],eax   ;set length=0 (end of chain)
;checksum the allecated memory packet
  add	esi,edx		;compute checksum
  mov	[ebp+packet.checksum],esi
  lea	eax,[ebp+packet.memory] ;get allocatation address for caller
  jmp	m_exit
;-------------------------------------------------------
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;>1 memory
;  m_release - release previously allocated memory
;             This function may be called after calling
;             the m_setup, and mem_allocate functions.
;  INPUTS     eax = pointer to memory for release
;
;  OUTPUT     eax = 0 if success
;             eax = negative error code as following:
;                   -1 can not release memory or
;                      memory not found, this can be
;                      caused by a bad input pointer (eax)
;                      or by a memory leak that modified
;                      a header used by memory manager.
;                      See mem_allocate for a discusson
;                      of headers.
;                   -2 memory block already released and
;                      available
;             flags set for "js" or "jns"
;
;  NOTE       source file is memory.asm
;
;<
;  * ----------------------------------------------
  global m_release
m_release:
  sub	eax,12		;move to top of packet
  xor	ecx,ecx		;clear flag
  mov	edi,eax		;edi=free pkt ptr
;checksum free packet
  mov	eax,[edi+packet.bak_ptr]
  mov	esi,eax			;save bak_ptr
  add	eax,[edi+packet.length]	;compute checksum
  cmp	eax,[edi+packet.checksum]
  jne	m_r_err1
  or	esi,esi		;check if bak packet combine
  jz	no_bak_combine
;checksum bak packet
  mov	eax,[esi+packet.bak_ptr]
  mov	ebx,[esi+packet.length] ;get bak pkt length
  add	eax,ebx		;compute bak pkt checksum
  cmp	[esi+packet.checksum],eax
  jne	m_r_err1	;jmp if bad checksum
  or	ebx,ebx
  js	fwd_check
no_bak_combine:
  or	cl,1		;set no bak combine flag  
;bak packet has free memory
; edi=free pkt  esi=bak pkt
;               ebx=bak pkt size(negative)
;check if fwd1 packet has free memory
fwd_check:
  mov	ebp,edi		;get free pkt ptr
  add	ebp,[edi+packet.length] ;compute fwd pkt ptr
;checksum fwd packet
  mov	ebx,[ebp+packet.bak_ptr]
  mov	eax,[ebp+packet.length] ;check if fwd pkt exists
  or	eax,eax
  jz	no_fwd_combine	;jmp if no fwd pkt
  add	ebx,eax		;compute checksum
  cmp	ebx,[ebp+packet.checksum]
  jne	m_r_err1	;jmp if error
  or	eax,eax
  js	decode		;jmp if fwd pkt available
no_fwd_combine:
  or	cl,2		;set fwd combine flag
; esi=bak ptr  edi=free ptr  ebp=fwd1 ptr
;                            eax= size fwd1 pkt
decode:
  shl	ecx,2
  add	ecx,jtable
  call	[ecx]
  jmp	short exit1
m_r_err1:
  mov	eax,-1		;checksum error
exit1:
  or	eax,eax
  ret
;-----------------
  [section .data]
jtable:
	dd	bak_fwd_combine	;ecx=0
	dd	fwd_combine	;ecx=1
	dd	bak_combine	;ecx=2
	dd	no_combine	;ecx=3
  [section .text]
;-----------------

;---------
; esi=bak ptr  edi=free ptr  ebp=fwd1 ptr
;                            eax= size fwd1 pkt
no_combine:
  mov	eax,[edi+packet.length]
  neg	eax			;set pkt to available
  mov	[edi+packet.length],eax
;checksum free pkt
  mov	ebx,[edi+packet.bak_ptr]
  add	ebx,eax			;compute checksum
  mov	[edi+packet.checksum],ebx
  xor	eax,eax			;set success return
  ret
;---------
; esi=bak ptr  edi=free ptr  ebp=fwd1 ptr
;                            eax= size fwd1 pkt
bak_combine:
  mov	eax,[edi+packet.length] ;get free pkt length (positive)
  mov	ebx,[esi+packet.length] ;get bak pkt length (negative)
  sub	ebx,eax			;compute new length
  mov	[esi+packet.length],ebx	;store new length
;compute checksum for bak pkt
  mov	eax,[esi+packet.bak_ptr]
  add	eax,ebx			;compute checksum
  mov	[esi+packet.checksum],eax
;fix ptr in fwd pkt to point at bak pkt
  mov	[ebp+packet.bak_ptr],esi
;checksum fwd pkt
  add	esi,[ebp+packet.length] ;compute checksum
  mov	[ebp+packet.checksum],esi
  xor	eax,eax			;signal success
  ret

; esi=bak ptr  edi=free ptr  ebp=fwd1 ptr
;                            eax= size fwd1 pkt (negative)
fwd_combine:
  mov	ebx,[edi+packet.length] ;get free pkt size
  neg	ebx			;set negative (free)
  add	eax,ebx			;compute new free pkt size
  mov	[edi+packet.length],eax ;store new size for free pkt
;checksum free pkt
  add	esi,eax
  mov	[edi+packet.checksum],esi
;fix fwd2 to point at free pkt
  mov	edx,[ebp+packet.length] ;get length of fwd1 pkt
  neg	edx			;make positive
  add	edx,ebp			;get ptr to fwd2 pkt
  mov	[edx+packet.bak_ptr],edi;point fwd2 to free pkt
;checksum fwd2 pkt
  mov	eax,[edx+packet.length]	;get fwd pkt length
  or	eax,eax
  jz	fwd_combine_exit	;jmp if end pkt (no cksum wanted)
  add	edi,eax			;compute checksum
  mov	[edx+packet.checksum],edi
  xor	eax,eax			;set success flag
fwd_combine_exit:
  ret

; esi=bak ptr  edi=free ptr  ebp=fwd1 ptr
;                            eax= size fwd1 pkt
bak_fwd_combine:
  mov	eax,[esi+packet.length]	;get bak pkt length (negative)
  sub	eax,[edi+packet.length] ;add free pkt length (positive)
  add	eax,[ebp+packet.length]	;add fwd pkt length (negative value)
  mov	[esi+packet.length],eax ;set new bak pkt length
;checksum bak pkt
  mov	ebx,[esi+packet.bak_ptr]
  add	ebx,eax			;compute checksum
  mov	[esi+packet.checksum],ebx
;fix fwd2 to point at bak pkt
  mov	edx,[ebp+packet.length] ;get length of fwd1 pkt
  neg	edx			;make positive
  add	edx,ebp			;get ptr to fwd2 pkt
  mov	[edx+packet.bak_ptr],esi;point fwd2 to bak pkt
;checksum fwd2 packet
  add	esi,[edx+packet.length]	;compute checksum
  mov	[edx+packet.checksum],esi
  xor	eax,eax			;set success flag
  ret
;------------
;  %include "m_setup.inc"
;------------
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;>1 memory
;  m_setup  - setup for memory manager use
;             This function must be called before using
;             any memory manager functions
;  INPUTS     none 
;
;  OUTPUT     none
;
;  NOTE       source file is memory.asm
;             calls memory_init to find start of memory
;<
;  * ----------------------------------------------
  
  global m_setup
m_setup:
  call	memory_init
  or	ebx,ebx
  jz	m_setup_set		;jmp if first call
  mov	eax,ebx			;get origional start from ebx
m_setup_set:
  add	eax,3
  and	eax,~3			;adjust to dword boundry
  mov	[chain_top],eax
  mov	[first_time_flag],eax
  ret

;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;>1 memory
;  m_close - release memory and disable memory manager
;             This function also occurs if a program exits
;             with a kernel exit function.
;  INPUTS     eax = none
;
;  OUTPUT     none
;
;  NOTE       source file is memory.asm
;
;<
;  * ----------------------------------------------

  global m_close
m_close:
  mov	ebx,[chain_top]
  mov	eax,45
  int	80h
  xor	ebx,ebx
  mov	[chain_top],ebx	;just incase we are restarted
  ret

;------------
  [section .data]
  global chain_top
chain_top:
  dd 0
first_time_flag:	;set to non-zero if first time
  dd 0			;normaly=0 (not first time)
  [section .text]
;-----------------------------------------------------------
; test program to exercise the memory manager.
; This code is enabled if the DEBUG flag is defined
;-
; the three equates at top determine test parameters
; Blocks of memory are allocated and put into an array.
; The array is then accessed randomly and if memory is
; found it is released, if no memory is found it  is
; allocated.
;-----------------------------------------------------------
%ifdef DEBUG

allocation_size	equ	12	;size of memory block to allocate
array_size	equ	8	;size of array (power of 2, 2,4,8,16)
test_loop_size	equ	2222	;number of allocations/releases

 global _start
 global main
_start:
main:
  mov	eax,bss_start
  call	m_setup

  mov	[down_counter],dword test_loop_size

  mov	ecx,array_size		;must be 2,4,8,16,32,64
  mov	edi,array
  xor	eax,eax
  mov	[up_counter],eax
  cld
clear_loop:
  stosd
  loop	clear_loop

test_loop:
  mov	eax,[up_counter]
  cmp	eax,17h		;break locaton
  jne	continue
  nop
continue:
  call	random
  mov	ebx,array_size
  dec	ebx		;form mask for random number
  and	eax,ebx		;mod
;index into array
  shl	eax,2
  add	eax,array	;index into array
  mov   [array_ptr],eax
  mov	ebx,[eax]	;get array contents
  or	ebx,ebx
  jnz	do_release
;this area not allocated, allocate it
  mov	eax,allocation_size
  call	m_allocate
  or	eax,eax
  js	test_err1
  mov	esi,[array_ptr]
  mov	[esi],eax	;save allocation in array
;clear our new memory area
  mov	ecx,allocation_size
  mov	edi,eax		;memory address
  cld
  xor	eax,eax
  rep	stosb
  jmp	loop_end
;this area is allocated, release it
do_release:
  mov	eax,ebx		;get memory address
  call	m_release
  js	test_err2
  mov	esi,[array_ptr]
  xor	eax,eax
  mov	[esi],eax
loop_end:
  inc	dword [up_counter]
  dec	dword [down_counter]
  jz	loop_done
  jmp	test_loop
loop_done:
  call	check_counters

;----
  mov	esi,[chain_top]
  mov	eax,[total_allocated]
  mov	ebx,[total_released]
;----
  mov	eax,1
  int	80h
;--------------
test_err1:
  nop
test_err2:
  jmp	loop_done
;----------------------------
check_counters:
  mov	esi,[chain_top]
cc_loop:
  mov	eax,[esi+packet.length]
  or	eax,eax
  jz	cc_done
  jns	cc_allocated		;jmp if alloated mem
  neg	eax
  add	[total_released],eax
  jmp	short cc_end
cc_allocated:
  add	[total_allocated],eax
cc_end:
  add	esi,eax			;move to next link
  jmp	short cc_loop
cc_done:
  ret
;
;--------------
random:
  mov	eax,[seed]
  mul	dword [factor]
  inc	eax
  mov	[seed],eax
  ret
 [section .data]
seed: dd 13047934h
factor: dd 8088405h
;--------------
total_allocated dd	0
total_released  dd	0
  [section .bss]
array: resd array_size		;alloated address's
up_counter  resd 1
down_counter resd 1
array_ptr  resd 1

bss_start:
 resb	1
%endif

