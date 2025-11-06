#!/bin/bash

threads=64
asm=input/GalPetrel_ref_scaff_v3.fa
repeatlib=input/denovo_and_curated_aves_repeats.fa

repeatmasker_run.sh $asm $repeatlib $threads
