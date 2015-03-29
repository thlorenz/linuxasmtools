;-------------------------
; file hash_struc.inc
;-------------------------

struc hash
.entries_ptr      resd	1	;offset when written to disk
.avail_entry_ptr  resd	1	;offset when written to disk
.field		  resd  1       ;index into record to scan for end of entry
.mask		  resb  1	;
                  resb  3	;filler to preserve dword boundry
.hash_chain_tbl   resd	1	;start of hash chain table, length set from hash mask
;hash entries follow chain_tbl
endstruc

; hash chain_table size
;  mask=1h  chain_table=0008 bytes or 2 pointers
;       3h              0016          4
;       7h              0032          8
;      0fh              0064         16
;      1fh              0128         32
;      3fh              0256         64
;      7fh              0512        128
;     0ffh              1024        256

; note: global variables used with above are:
;       hash_table_ptr - pointer to hash.entries_ptr
;       hash_buffer_end - pointer to end of buffer
;