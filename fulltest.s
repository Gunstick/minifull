
; synchon fullscreen by ULM 1989 and 2020 
; this code is based on one of the first fullscreen routines done
; and has now been evolved to add the first line and the 2 last
; lines for 276 maximum lines of pixels

; Based on troed's idea in https://www.youtube.com/watch?v=F4WJYyoF1Lk
; you do not need to switch back to 50hz after opening the left border
; you can do that later. But there are 2 regions.
; in the top region, you need to switch back early, typical after
; the right border stabilizer. See overloop1
; The second part has the switch back to 60hz even later, after the left
; boder opening. This basically opens the lower border on every line.
; So this opens for old and new pal glue, as well as the 2 bonus lines at
; the very bottom givin a total of 276 lines. See overloop2
; you cannot use overloop2 for the top part as then the 60Hz close the
; the border early at the position where a classic 60hz screen ends.

; as this is an ULM product, the right stabilizer is using middle
; resolution instead of high, but you can change that here
; you will not see a difference in hatari but only on a real machine
RS set 1   ; 1=MID 2=HI

; you can adjust the number of lines here:
overscanlines set 276  ; how many lines to overscan (1-276)

; switch vertical pixel graphic bars on/off
drawgraphics set 0   ; 0=fill screen 1=thin lines 2=nothing

; switch bgcolors on/off to show where the switches are
bgcolors set 0   ; 0=with colors 1=no bg color toggles

; this flag I used to adjust the top opening including the first line left border
topborder1stlooptest set 1    ; 0 = test if initial top opens correctly 1 = normal operation



; macro to fill time
NOPS:	Macro 
     ifne \1
	REPT \1
	nop
	ENDR
     endc
	EndM

; macro to show colors or not
; is always 4 NOPs long. If oyu need time
; remove the calls to BGCOLOR
BGCOLOR: Macro \1
   ifeq bgcolors
     ifc \1,"NOT"  ; Conditionally assemble the following lines if <string1> matches <string2>.
	not $ffff8240.w
     else
       move.w \1,$ffff8240.w
     endc
     ifc \1,d3
       nop
     endc
     ifc \1,d4
       nop
     endc
   else
     NOPS 4
   endc
	EndM

;please leave all section indications unchanged...
;simple loader to get into supervisor-mode
;this part can be removed when started from bootsector
x:
	pea	start
	move.w	#38,-(sp)
	trap	#14
	addq.l	#6,sp

	clr.w	-(sp)
	trap	#1
	
start:
	move	sr,in_oldsr
	move	#$2700,sr

	move.b	$ffff8260.w,in_oldres
	bsr	waitvbl_o
	move.b	#0,$ffff8260.w

;	movem.l $ffff8240.w,d0-d7
;	movem.l d0-d7,in_oldpal
;	movem.l zeroes,d0-d7
;	movem.l d0-d7,$ffff8240.w

	lea	$ffff8201.w,a0
	movep.w 0(a0),d0
	move.w	d0,in_screenad

	move.b	#18,$fffffc02.w
	bsr	waitvbl_o
	move.b	#26,$fffffc02.w

;	bsr	in_psginit

	move.l	$0604.w,in_old604
	move.l	sp,$0604.w
	move	usp,a0
	move.l	a0,in_oldusp
	move.l	sp,in_oldsp
	move.l	$0600.w,in_old600
	move.l	#back,$0600.w
;here we go... to the real screen...
	jmp	screen
back:
	move.l	in_old600,$0600.w
	move.l	in_old604,$0604.w
	movea.l in_oldusp,a0
	move	a0,usp
	movea.l in_oldsp,sp

;	movem.l zeroes,d0-d7
;	movem.l d0-d7,$ffff8240.w

	move.b	#2,$ffff820a.w
	bsr	waitvbl_o
	move.b	#0,$ffff820a.w
	bsr	waitvbl_o
	move.b	#2,$ffff820a.w

;	movem.l in_oldpal,d0-d7
;	movem.l d0-d7,$ffff8240.w

	move.b	in_oldres,$ffff8260.w
	lea	$ffff8201.w,a0
	move.w	in_screenad,d0
	movep.w d0,0(a0)

;	bsr.s	in_psginit

;	move.b	#20,$fffffc02.w
;	bsr	waitvbl_o
;	move.b	#8,$fffffc02.w

;	move	in_oldsr,sr

	rts

in_psginit:
	lea	in_psginittab,a0
in_nextinit:
	move.b	(a0)+,d0
	cmp.b	#$ff,d0
	beq.s	in_initend
	move.b	(a0)+,d1
	move.b	d0,$ffff8800.w
	move.b	d1,$ffff8802.w
	bra.s	in_nextinit
in_initend:
	rts

in_psginittab:
	dc.b	0,$ff,1,$ff,2,$ff,3,$ff,4,$ff,5,$ff,6,0
	dc.b	7,$7f,8,7,9,7,10,7,$ff,0
	even

in_screenad:	ds.w	1
in_oldpal:	ds.l	16
in_oldres:	ds.w	1
in_old600:	ds.l	1
in_old604:	ds.l	1
in_oldsr:	ds.w	1
in_oldsp:	ds.l	1
in_oldusp:	ds.l	1

;THIS COMMENT IS FROM 1989, SO PROBABLY NOT ACCURATE
; systemadresses: $600.w = return address (see exit)
;		  $604.w = stackpointer (copy to sp if needed
;					  ex. move.l $604.w,sp)
;
; from here on, no stackpointer is present, if you need one, just
; get the address of space for stack in $604.w (see also sys. $604.w)
;
; you can use all registers, even usp (move an,usp or move usp,an)
;
; sr is set to $2700 and must (!!!!) be $2700 when returning to main menu
;
; waitvbl_o can be used to wait for the end of the displayed(!!!!) screen
;	normal mode and overscan (with opened lowr border...)
; waitvbl_o uses d0-d1/a0
;

;this part is the real screen...


screen:
	lea	bss_start,a0
	lea	bss_end,a1
	movem.l zeroes,d1-d7/a2-a6
clear_loop:
	movem.l d1-d7/a2-a6,(a0)
	movem.l d1-d7/a2-a6,12*4(a0)
	movem.l d1-d7/a2-a6,24*4(a0)
	lea	36*4(a0),a0
	cmpa.l	a0,a1
	bpl.s	clear_loop

	move.l	#screenmem,d0
	add.l	#255,d0
	and.l	#$ffff00,d0
	move.l	d0,screenad1
	ror.l	#8,d0
	lea	$ffff8201.w,a0
	movep.w d0,0(a0)

	lea	graphic,a6
   ifeq drawgraphics
	lea	graphic_2,a6
   endc
	movem.l (a6),d1-d2
	movem.l (a6),d3-d4
	movem.l (a6),d5-d6
	movem.l (a6),d7-a0
	movem.l (a6),a1-a2
	movea.l screenad1,a6
	move.w	#299+100,d0
   ifne drawgraphics-2
graphiccop:
	movem.l d1-a2,0(a6)
	movem.l d1-a2,40(a6)
	movem.l d1-a2,80(a6)
	movem.l d1-a2,120(a6)
	movem.l d1-a2,160(a6)
	movem.l d1-d6,200(a6)
	lea	230(a6),a6
	dbra	d0,graphiccop
   endc
	movem.l pal,d0-d7
	movem.l	d0-d7,$ffff8240.w

	movea.l $0604.w,sp


nonoverscanlines set 276-overscanlines
toplines set 222   ; this is a bit longer than aclassic 60hz screen size and position
	; can be between 200 and 228
overscanlines set overscanlines-toplines
     ifle overscanlines
toplines set toplines+overscanlines
     endc

	jsr	waitvbl_o   ; wait until inside vbl, this is quite precise
	moveq	#7,d7
	lea	$ffff8209.w,a0
	moveq	#0,d3
	moveq	#20,d2
sync2:
	move.b	(a0),d3   ; wait until screen counter is running (normal screen)
	beq.s	sync2
	sub.w	d3,d2
	lsl.l	d2,d2	  ; sync up
test2:
	bsr	waitvbl_o   ; now the vbl wait is synched (modulo E clock jitter sometimes)


mainscreenloop:
	; this is the placeholder for the vbl
	; about 4500 NOPs worth of... synched code
	; or fiddle around with e clock and HBL IRQ to get a 
	; variable VBL time
	move.w	#1500,d3
wait_border:
	dbf	d3,wait_border
	BGCOLOR #$700
	NOPS 8+2+1+4+2
	BGCOLOR #$400
	NOPS	196-30-30-2; here adjust the 1st top border opening

	BGCOLOR #$7
	BGCOLOR #0
	move.b #0,$ffff820a.w  ; 60Hz open top
	NOPS	12 		 ; 
	move.b	#RS,$ffff8260.w   ;  stabilizer (not actually useful here)
	move.b	#0,$ffff8260.w   ; LO
	NOPS	9 
	move.b	#2,$ffff8260.w   ; HI open left (this makes left overscan on 1st top border line)
	move.b	#0,$ffff8260.w   ; LO
	move.b	#2,$ffff820a.w   ; 50 Hz go back to 50 after top is open
	BGCOLOR NOT
	BGCOLOR #$70
	NOPS	36-16-2*5-9
	btst	#6,$fffffa0d.w	; keyboard (this is sync)
	bne	back		; 
   ifeq topborder1stlooptest
	  NOPS 57 
	  BGCOLOR #$7
	  BGCOLOR #$70
	  move.b	#0,$ffff820a.w   ; 60Hz open right
	  NOPS	12		 ; troed says: it's not switches
	  move.b	#RS,$ffff8260.w   ;  stabilizer
	  move.b	#0,$ffff8260.w   ; 
	  move.b	#2,$ffff820a.w   ; 50Hz
	  NOPS	5
	  move.b	#2,$ffff8260.w   ; HI open left
	  move.b	#0,$ffff8260.w   ; LO
	  NOPS 36-4-4-5-4-4-12
	
	  REPT 42
	    NOPS 128-36-8-8
	    BGCOLOR #$7
	    BGCOLOR #$70
	    move.b	#0,$ffff820a.w   ; 60Hz open right
	    NOPS	12		 ; troed says: it's not switches
	    move.b	#RS,$ffff8260.w   ;  stabilizer
	    move.b	#0,$ffff8260.w   ; 
	    move.b	#2,$ffff820a.w   ; 50Hz
	    NOPS	5
	    move.b	#2,$ffff8260.w   ; HI open left
    	    move.b	#0,$ffff8260.w   ; LO
	    NOPS 36-12-4-4-5-4-4
	  ENDR  

.waitendscreen:
	  move.b $ffff8209,d0
	  NOPS 40
	  cmp.b $ffff8209,d0
	  bne.s .waitendscreen

	  NOPS 18           ; adjust here if e-clock jitter
	  bra test2
   endc ; topborder1stlooptest


firstlineright set 1   ; adjust the top border right hand opening
	NOPS	64-8+firstlineright
	BGCOLOR #$700
	BGCOLOR #$70
	move.b	#0,$ffff820a.w   ; 60Hz open right
	move.b	#2,$ffff820a.w   ; 50Hz
	NOPS 29-8-firstlineright
   	move.w #toplines-2,d3 ; we have already 1 line done above
   ifgt overscanlines
	moveq #overscanlines-1,d4 
   else
	moveq #-1,d4
   endc
overloop1:
	NOPS	2
	move.b	#2,$ffff8260.w   ; HI open left
	move.b	#0,$ffff8260.w   ; LO

	NOPS 4
	BGCOLOR NOT
	NOPS	87-8-4-4
	BGCOLOR d3
	BGCOLOR #$171
	move.b	#0,$ffff820a.w   ; 60Hz open right

	NOPS	12		 ; troed says: it's not switches
	move.b	#RS,$ffff8260.w   ;  stabilizer
	move.b	#0,$ffff8260.w   ; 
	move.b	#2,$ffff820a.w   ; 50Hz

	dbf	d3,overloop1 ; ~3 taken, ~4 not taken
   ifle overscanlines
	NOPS 2
   else
	NOPS 1
overloop2:

	move.b	#2,$ffff8260.w   ; HI open left
	move.b	#0,$ffff8260.w   ; LO

	move.b	#2,$ffff820a.w   ; 50 Hz
	BGCOLOR NOT
	BGCOLOR NOT
	NOPS	87-8-4-2*4

	BGCOLOR d4
	BGCOLOR #$272
	move.b	#0,$ffff820a.w   ; 60Hz open right (and bottom for old STs)
	NOPS	12		 ; open bottom is: delay 50hz until left border
	move.b	#RS,$ffff8260.w   ;  stabilizer
	move.b	#0,$ffff8260.w   ; LO

	NOPS	9-3
	dbf	d4,overloop2 ; ~3 taken, ~4 not taken
    endc
	
	move.b	#2,$ffff820a.w   ; 50 Hz  now bottom is open
    ifle nonoverscanlines
	NOPS 23
    else
	BGCOLOR #$7
	move.w #nonoverscanlines-1,d0   ; wait lines
.ll:
        move.w #(512/4-4-4-4)/(3),d1 ; one line = 512 cycles
.l:
	dbf d1,.l
	BGCOLOR NOT
	NOPS 1
	dbf d0,.ll	
	BGCOLOR #$3
	NOPS 12
     endc
	bra mainscreenloop

waitvbl_o:
	move.b	$ffff8203.w,d0
	lsl.w	#8,d0
	lea	$ffff8207.w,a0
no_vbl:
	movep.w 0(a0),d1
	cmp.w	d0,d1
	bne.s	no_vbl
	rts

;here starts the data section

zeroes:
		dc.l	0,0,0,0,0,0,0,0
		dc.l	0,0,0,0,0,0,0,0
graphic:

		dc.w	%1011
		dc.w    %1011
		dc.w	%1011
        	dc.w	%1011
graphic_2:
		dc.w	%0101010101010101
		dc.w    %0011001100110011
		dc.w	%0000111100001111
        	dc.w	%1111111111111111
pal:
		dc.w	$0070,$0221,$0332,$0443,$0554,$0665,$0776,$20
		dc.w	$0700,$0711,$0712,$0723,$0724,$0735,$0736,$0747

;end of data section

		section	bss
bss_start:			;here starts the bss

stack:		ds.l	1
screenad1:	ds.l	1


screenmem:	ds.l	230*300/4
bss_end:			;here ends the bss
	end

