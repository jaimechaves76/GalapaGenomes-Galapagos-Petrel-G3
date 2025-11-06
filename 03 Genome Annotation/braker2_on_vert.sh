#!/bin/bash

: BRAKER3 run with BRAKER2 mode -- no rnaseq -- with compleasm BUSCO completion
: vert since we use the vert protein orthodb fasta file

main() {
   get_args $@
   braker2  # uses vars set in get_args
}

function braker2 {  # braker2 means no rnaseq data
   : BRAKER_run.sh puts Augustus and other dirs into the PATH and sets things up to call braker.pl and calls it with the given args
   : cores option was changed to threads with BRAKER3

   BRAKER_run.sh --genome=$asm            \
                 --species=$species       \
                 --prot_seq=$proteins     \
                 --workingdir=$outdir     \
                 --softmasking            \
                 --gff3                   \
                 --busco_lineage=$lineage \
                 --threads=$threads $addtl_args |&
   tee braker_run.log
}


function get_args {
   asm=$1
   species=$2
   lineage=$3
   threads=$4

   get_braker_version

   [ -z $1 ] && usage
   ! isfasta.sh $asm && usage $asm is not a fasta file

   [ -z $lineage ] && usage BUSCO lineage missing
   ! is_busco_lineage.sh $lineage && usage \"$lineage\" is not a valid BUSCO lineage

   if [ -z $threads ]; then
      threads=32 && msg threads defaulting to 32
   else
      chk=$(get_int_val.sh $threads)
      [ -z $chk ] && usage invalid thread number \"$threads\"
   fi

   if [ ! -z $5 ]; then  # BRAKER additional args
      shift; shift; shift; shift
      addtl_args="$@"
   fi

   # these two are hardwired. proteins is what makes this for verts
   proteins=/ccg/bin/orthodb_downloads/Vertebrata_OrthoDB_11.fa
   outdir="."  # output in current dir
}

function get_braker_version {
   # manually set in case we can not get perl script to tell us
   braker_version="braker.pl version 3.0.8."

   # use perl script result when possible
   local pl=/ccg/bin/BRAKER/scripts/braker.pl
   [ -x $pl ] && braker_version=$($pl --version)
}

function usage {
   local pgm_name=$(basename $0)

   [ ! -z "$1" ] && err_msg "\n    $@"  # error message passed in to show

   msg "
    usage: $pgm_name <assembly fasta> <species name for Augustus> <BUSCO lineage> [<num threads> <other BRAKER args>]

       eg: $pgm_name GalGal.GRCg7b.softmasked.fa GalGal aves 48

           species name can be whatever as long as does not already exist in Augustus dir

           it's braker2 not braker3 since it does not use RNAseq input.
           underlying version is $braker_version
"
   exit 1
}
function msg { echo -e "$@" > /dev/stderr; }
function err_msg { echo -e "\033[1;31m$@\033[0m" > /dev/stderr; }  # bold red


main $@
