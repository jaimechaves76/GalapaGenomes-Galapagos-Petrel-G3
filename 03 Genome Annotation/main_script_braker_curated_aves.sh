#!/bin/bash

: BRAKER3 run with BRAKER2 mode -- no rnaseq -- with compleasm BUSCO completion of Galapagos Petee curated_aves repeats softmasked assembly

num_threads=96

asm=input/GalPetrel_ref_scaff_v3.softmasked.fasta
species=PteroPhaeo
lineage=aves

braker2_on_vert.sh $asm $species $lineage $num_threads
