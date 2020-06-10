#!/usr/bin/make -f
#


#	vasmm68k_mot -Ftos -pic -align -devpac -m68000 -showopt -nosym -o $@.tos $< 
.s:
	vasmm68k_mot -Ftos -align -devpac -m68000 -showopt -o $@.tos $< 
.S:
	vasmm68k_mot -Ftos -align -devpac -m68000 -showopt -o $@.tos $< 
#	./mktruerel.sh $@.tos 
.o:
	vlink $<

