;
; The collection of values associated with times and dates
;
struc time
.ct:		resd	1	; raw C time (seconds since the Epoch)
.at:		resd	1	; zone adjusted seconds since last Epoch
.zo:		resd	1	; time zone offset
.zi:		resb	6	; time zone identifier
.tz:		resb	10	; time zone name
; fields set by seconds2bins follow this comment. 
.dc:		resd	1	; days since last Epoch
.sc:		resd	1	; seconds
.mn:		resd	1	; minutes
.hr:		resd	1	; hours
.yr:		resd	1	; year
.mr:		resd	1	; meridian (0 for AM)
.wd:		resd	1	; day of the week (Sunday=0, Saturday=6)
.dy:		resd	1	; day of the month
.mo:		resd	1	; month (one-based)
endstruc
