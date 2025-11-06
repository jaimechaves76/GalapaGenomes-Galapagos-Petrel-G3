#!/bin/bash

threads=64

asm=input/GalPetrel_ref_scaff_v2.fa
reads=input/hifiasm.asm.ec.fa

quartet_gapfiller.py -d $asm -g $reads -t $threads |& tee gapfill.log



#############################

: "
usage: quartet_gapfiller.py [-h] -d DRAFT_GENOME -g GAPCLOSER_CONTIG [GAPCLOSER_CONTIG ...] [-f FLANKING_LEN] [-l MIN_ALIGNMENT_LENGTH] [-i MIN_ALIGNMENT_IDENTITY] [-m MAX_FILLING_LEN] [-p>
                            [--joinonly] [--overwrite] [--minimapoption MINIMAPOPTION] [--noplot]
quartet_gapfiller.py: error: the following arguments are required: -d, -g
"
