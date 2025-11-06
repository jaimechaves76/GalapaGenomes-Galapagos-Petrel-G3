#!/bin/bash

# ragtag.sh scaffold <reference.fa> <query.fa>

threads=32
output_dir=ragtag_CalBor_hap1

ref=input/bCalBor7.hap1_asm.fasta
query=input/GalPetrel_hf_01.fasta

ragtag.sh scaffold -t $threads $ref $query -o $output_dir
