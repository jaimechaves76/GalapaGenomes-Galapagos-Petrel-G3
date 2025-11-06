#!/bin/bash

threads=64
fasta=input/petrel_both_runs_abi_corrected.fasta

GeneScope_run.sh $fasta -t $threads 21 25 27
