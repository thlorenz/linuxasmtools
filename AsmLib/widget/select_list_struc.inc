
struc sl
.button_groups	resb	1	;number of groups (button columns) 0=calculate
.buttons_per_column resb 1	;number of buttons in each column 0=calculate
; window sizes are for contents, a one character frame is added 
.win_columns	resb	1	;size of our select window (columns) 0=use default
.win_rows	resb	1	;size of our select window (rows) 0=use default
.win_left_column resb	1	;starting column, 0=calculate
.win_top_row	resb	1	;starting row 0=calculate
.box_color	resd	1	;color of box, -1=no box 0=default
.win_color	resd	1	;color of select window, 0=default
.button_size_columns resb 1	;all buttons are same length 0=calculate
.button_size_rows    resb 1	;all buttons are same size 0=calculate
.button_separation_columns   resb 1 ;number of rows between buttons, 0=default of 0
.button_separation_rows   resb 1 ;number of rows between buttons, 0=default of 0
sl_struc_size:
endstruc

struc button
.button_group		resb 1	;1=button column #1
.button_color		resd 1	;button unselected color 0=default  
.button_selected_color  resd 1	;button selected color (if -1, can't select, 0=default)
.button_text		resb 1  ;variable length text goes here, multi line text has 0ah
button_struc_size:
endstruc
