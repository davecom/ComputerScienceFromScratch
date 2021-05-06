#!/usr/bin/make -f
#
# Makefile for Thwaite
# Copyright 2011 Damian Yerrick
#
# Copying and distribution of this file, with or without
# modification, are permitted in any medium without royalty
# provided the copyright notice and this notice are preserved.
# This file is offered as-is, without any warranty.
#
version = 0.03
objlist = main random levels smoke bg missiles explosion scurry \
          title practice cutscene cutscripts tips \
          math bcd unpkb pads mouse kinematics \
          paldetect sound music musicseq ntscPeriods

CC65 = /usr/local/bin
AS65 = ca65
LD65 = ld65
#EMU := "/C/Program Files/nintendulator/Nintendulator.exe"
EMU := mednafen -nes.pal 0 -nes.input.port1 gamepad -nes.input.port2 gamepad
CC = gcc
ifdef COMSPEC
DOTEXE=.exe
else
DOTEXE=
endif
CFLAGS = -std=gnu99 -Wall -DNDEBUG -O
CFLAGS65 = 
objdir = obj/nes
srcdir = src
imgdir = tilesets

# -f while debugging code; -r while adding shuffle markup;
# neither once a module has stabilized
shufflemode = -r

objlistntsc = $(foreach o,$(objlist),$(objdir)/$(o).o)

.PHONY: run dist zip

run: thwaite.nes
	$(EMU) $<

# Actually this depends on every single file in zip.in, but currently
# we use changes to thwaite.nes, makefile, and README as a heuristic
# for when something was changed.  Limitation: it won't see changes
# to docs or tools.
dist: zip
zip: thwaite-$(version).zip
thwaite-$(version).zip: zip.in thwaite.nes README.html $(objdir)/index.txt
	zip -9 -u $@ -@ < $<

# Some unzip tools won't create empty folders, so put a file there.
$(objdir)/index.txt: makefile CHANGES.txt
	echo Files produced by build tools go here, but caulk goes where? > $@

$(objdir)/%.o: $(srcdir)/%.s $(srcdir)/nes.h $(srcdir)/ram.h
	$(AS65) $(CFLAGS65) $< -o $@

$(objdir)/%.o: $(objdir)/%.s
	$(AS65) $(CFLAGS65) $< -o $@

# incbins

$(objdir)/title.o: todo.txt src/title.pkb
$(objdir)/cutscene.o: src/cutscene.pkb
$(objdir)/practice.o: src/practice.txt

$(objdir)/ntscPeriods.s: tools/mktables.py
	$< period $@

map.txt thwaite.prg: nes.ini $(objlistntsc)
	$(LD65) -C $^ -m map.txt -o thwaite.prg

$(objdir)/%.chr: $(imgdir)/%.png
	tools/pilbmp2nes.py $< $@

%.nes: %.prg %.chr
	cat $^ > $@

thwaite.chr: $(objdir)/maingfx.chr $(objdir)/cuthouses.chr
	cat $^ > $@

