#!/bin/bash

main() {
   get_args $@
   [ -s concatenated.fasta ] && echo concatenated.fasta already exists, delete it and partitions.txt to rerun && exit

   run_mafft_on_each  # runs mafft and trimal on each of the BUSCO faa files in the arg provided directory
   concat_faas  # creates concatenated.fasta and partitions.txt needed for iqtree or RaxML
}

function run_mafft_on_each {
   mkdir -p faa_aln

   for busco_faa in $(ls -v $faa_dir/*at*.faa); do

      if (( num_processes >= max_processes )); then
         wait -n  # wait for the next one to finish, whichever it is
         (( num_processes-- ))
      fi

      (( num_processes++ ))

      run_mafft_on_one $busco_faa &
   done
   wait
}

function run_mafft_on_one {
   local busco_faa=$1
   if [[ -z $busco_faa || ! -s $busco_faa ]]; then
      echo No input faa or empty one \"$busco_faa\"
   else
      aln=$(basename $busco_faa)
      aln=faa_aln/$(replace_ext.sh $aln aln)
      trimmed=$(replace_ext.sh $aln trimal.fasta)
      [ -s $trimmed ] && echo $trimmed already created && return

      mafft --auto $busco_faa > $aln
      [ -s $aln ] && trimal -in $aln -out $trimmed -keepseqs -keepheader -gappyout
   fi
}

function concat_faas {
   if [ ! -s concatenated.fasta ]; then
      echo -e "\nconcatenating the files using AMAS.py concat -i faa_aln/*.trimal.fasta -f fasta -d aa -p partitions.txt -t concatenated.fasta"
      AMAS.py concat -i $(ls -v faa_aln/*.trimal.fasta) -f fasta -d aa -p partitions.txt -t concatenated.fasta

      # AMAS does not add the prefix we need for iqtree so we do it manually
      grep "^PROT," partitions.txt >/dev/null || sed -i 's/^/PROT, /' partitions.txt

      # make a phylip file too for RaxML
      echo creating a phylip file using fasta2phylip.py -i concatenated.fasta -o concatenated.phylip
      fasta2phylip.py -i concatenated.fasta -o concatenated.phylip

      echo -e "\nto run iqtree with 32 threads: iqtree2 -s concatenated.fasta -p partitions.txt -m MFP-R -bb 1000 -nt 32 -o <outgroup species>"
   else
      echo concatenated.fasta already exists
   fi
}

function get_args {
   [[ -z $1 || ! -d $1 ]] && usage

   faa_dir=$1 && shift

   num_processes=0  # number of mafft processes currently running
   max_processes=10 # max to run at a time

   threads=$(get_int_val.sh $1)
   [ ! -z $threads ] && max_processes=$threads
}

function usage {
   local script=$(basename $0)

   echo -e "
   usage $script <dir with BUSCO faa files> [<number of maffts to run at a time, default 10>]

   - can use split_pulled_faa.sh to split the pulled BUSCOs created by quick_complete_busco_look.sh script
   - also runs trimal with -keepseqs -keepheader -gappyout to create trimal.fasta file
   - mafft output .aln files are kept but can be removed if you do not want to take a look at them
" >/dev/stderr

   exit 1
}


main $@
