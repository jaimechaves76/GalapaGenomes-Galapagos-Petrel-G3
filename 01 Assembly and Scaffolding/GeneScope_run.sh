#!/bin/bash

main() {
   get_args $@
   run_GeneScope_on_kmers
   concat_summary_files $fastx
   clean_up
}

function run_GeneScope_on_kmers {
   check_for_R_package_dependecies

   local k
   for k in $kmers_to_check; do
      GeneScope $k
   done
}

function GeneScope { # depends on fastx, table_level and threads being set by get_args, kmer_size passed in
   kmer_size=$1
   [ -z $kmer_size ] && usage "kmer size not set"

   dir_prefix=GeneScope_K
   output_dir=${dir_prefix}${kmer_size}
   (( $table_level > 1 )) && output_dir=${output_dir}_t${table_level}

   FastK -v -T${threads} -t${table_level} -k${kmer_size} $fastx -NTable

   Histex -G Table |
   GeneScopeFK.R -o $output_dir -k ${kmer_size}

   msg ""
   write_txt_versions_of_hist
}


############################################################
#                    support functions                     #
############################################################

function check_for_R_package_dependecies {
   ! install_GeneScope_dependencies.sh && exit 1
}

function write_txt_versions_of_hist {
   Histex -G Table.hist > $output_dir/Table.txt
   [ -s $output_dir/Table.txt ] && graph_kmer_hist.sh $output_dir/Table.txt > $output_dir/Table.txt_graph

   mv Table.* $output_dir
}

function concat_summary_files {  # input file pssed in to add, since GeneScope has it blank
   local input_file=$1; local count

   function output_summary_files {
      for summ in $(ls -tr ${dir_prefix}*/summary.txt); do
         (( count++ )) && echo -e "------------------------------------------------------------------\n"
         awk -v input_file=$input_file '
            /^input file/ { $0 = $0 input_file".hist" }
            { print }
         ' $summ
      done
   }

   summ_file=GeneScope_summary_reports.txt

   output_summary_files > $summ_file
   msg $count summary.txt files concatenated into $summ_file
}

# leaves the kmer files it create which are prefixed with .Table.ktab.
function clean_up {
   rm .Table.ktab.*
}


############################################################
#                   arguments and usage                    #
############################################################

function get_args {  # for handling dash arguments as well as positional ones
   pgm_name=$(basename $0)  # for usage and version info
   kmers_to_check=""

   [ -z $2 ] && usage  # comment or delete if no args is OK

   while (( $# > 0 ));  do
      arg=$1; shift

      if [[ $arg != "-"* ]]; then  # positional arguments handled here
         [ -z $fastx ] && fastx=$arg && continue  # second positional is fasta filename

         int_val=$(get_int_val.sh $arg)  # any int is considered a kmer size to check
         [ ! -z $int_val ] && kmers_to_check="${kmers_to_check} $int_val" && continue
      else  # dash arguments, both alone and with a value handled here
         [[ $arg == "-h" || $arg == "--help" ]] && usage

         # handle dash args with value here, e.g. for threads, -t 32
         dash_arg_val=$1;  : important to shift with those that use this value as below

         [[ $arg == "-t" || $arg == "--threads" ]] && threads=$dash_arg_val && shift && continue
         [[ $arg == "--table"* ]] && table_level=$(get_int_val.sh $dash_arg_val) && shift && continue
      fi

      usage unrecognized argument '"'$arg'"'
   done

   # validate args here and set defaults
   ! is_fastx "$fastx" && usage "Need a fasta file"
   [ -z "$kmers_to_check" ] && usage "Need at least one kmer size argument."

   set_threads $threads
   [ -z $table_level ] && table_level=1
}

function usage {
   [ ! -z "$1" ] && err_msg "\n    $@"  # error message passed in to show

   # change this to match the arguments that your script expects
   msg "
    usage: $pgm_name  <fasta or fastq file>  <kmer_len>...  [ -t <num_threads> ]

           Gene Myers' command line rewrite of GenomeScope 2.0
           Creates the kmer histogram and runs the GenomeScope plotting

           Provide one or more kmer sizes to run for each
"
   exit 1
}

function set_threads {  # potential thread arg passed in as arg 1
   [ -z $1 ] && threads=32  # set thread default if not set on command line
   threads=$(get_int_val.sh $threads)
   [ -z $threads ] && usage "thread value is not a number"
}

function msg { echo -e "$@" > /dev/stderr; }
function err_msg { echo -e "\033[1;31m$@\033[0m" > /dev/stderr; }  # bold red
function is_fasta { get_file_first_char $1; [[ $first_char == ">" ]]; }
function is_fastq { get_file_first_char $1; [[ $first_char == "@" ]]; }
function is_fastx { get_file_first_char $1; [[ $first_char == "@" || $first_char == ">" ]]; }
function get_file_first_char { local file=$1; [ ! -s "$file" ] && first_char="X" && return;  first_char=$( zgrep -m 1 -o ^. $file); }


#############################################################
# call main to start things off, passing all the arguments. #
#############################################################

main $@
