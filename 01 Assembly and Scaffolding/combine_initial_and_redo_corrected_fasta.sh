#!/bin/bash

main() {
   get_args $@
   combine_fastas
   combine_qscore_tsvs
}

function combine_fastas {
   [ -s $combined_fasta ] && msg $combined_fasta already made. delete to recreate. && return

   bawk '
      { slen = length($seq) }
      slen < 1000 { next }  # skip the small ones

      { print ">" $name "\n" $seq }
   ' $init_fasta $redo_fasta  > $combined_fasta
}

function combine_qscore_tsvs {
   awk '
      $3 >= 100
   ' $init_qscore_tsv $redo_qscore_tsv > $combined_qscore_tsv
}


function get_args {
   init_fasta=input/petrel_pass_porechop_abi_corrected.fasta
   init_qscore_tsv=input/petrel_pass_porechop_abi_corrected.qscore_len_tsv

   redo_fasta=input/petrel_ont_redo_abi_corrected.fasta
   redo_qscore_tsv=input/petrel_ont_redo_abi_corrected.qscore_len_tsv

   combined_fasta=petrel_both_runs_abi_corrected.fasta
   combined_qscore_tsv=$(replace_ext.sh $combined_fasta qscore_len_tsv)
}
function msg { echo -e "$@" > /dev/stderr; }


main $@
