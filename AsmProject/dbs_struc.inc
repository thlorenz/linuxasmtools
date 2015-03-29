struc	dbs
.db_records	resd	1	;pointer to record area
.db_index	resd	1	;pointer to index area
.db_index_end	resd	1	;pointer to zero at end of index
;                                can expand to db_append
.db_append	resd	1	;pointer to appended record area
.db_append_end  resd	1	;pointer to start of free space.
.db_path	resb	200	;copy of file path
.db_separation	resb	4	;copy of record separator codes,
;                                first byte is length of codes.
.db_rec_start	resb	1	;.db_records points here
endstruc

