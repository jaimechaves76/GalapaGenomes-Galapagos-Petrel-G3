#!/bin/bash

#  use hifiasm_ng -> hifiasm_0.24.0-r702

telo=CCCTAA  # lex lower of TTAGGG vert telo motif
ont_input=input/petrel_both_trimmed_runs.fastq

export HIFIASM_PGM=hifiasm_ng

hifiasm.sh -t 96 --telo-m $telo --ont $ont_input
