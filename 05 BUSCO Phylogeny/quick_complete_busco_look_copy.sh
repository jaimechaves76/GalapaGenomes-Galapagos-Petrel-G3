 #!/bin/bash

main() {
   get_args $@
   grep_completes | reorder_fields | $cmd
}

function grep_completes {
    grep "Complete" $result_dir/*/$fin_file |
    sed "s/:/\t/" |
    sort -k2,2V -k1,1 |
    sed "s|$result_dir/||" |
    sed "s|/[^/]*_odb.*/full_table_busco_format.tsv||" |
    sed "s|_cpa1_[^[:blank:]]*||"
}

function reorder_fields {
   cawk -t '
      NR==1 {last_busco = $2; id = 0}
      $2 != last_busco { last_busco = $2; id =0; print "" }

      { print ++id, $2, $1, fldcat(3,NF) }
   '
}

function list_buscos_shared_by_all {
   awk -v num_genomes="$num_genomes" '
      { busco_counts[$2]++ }
      END {
         for (busco in busco_counts) {
            if (busco_counts[busco] == num_genomes) {
               print busco
            }
         }
      }
   ' | sort -V
}

function count_buscos_all {
   # echo $(grep "^${num_genomes}\s" -c) shared BUSCOs in $num_genomes genomes
   awk -v num_genomes=$num_genomes '
      NF > 2 { counts[$1]++ }
      END {
         PROCINFO["sorted_in"] = "@ind_num_desc"
         for (c in counts) {
            if (c < int((num_genomes+1)/2)) break
            printf("%d shared Complete BUSCOs in %d (%.2f%%) of %d genomes\n", counts[c], c, 100*c/num_genomes, num_genomes)
         }
      }
   '
}

function view {
   cat -
}

function pull_buscos_shared_by_all {
   shared_buscos=$(cat - | list_buscos_shared_by_all)
   [ -z "$shared_buscos" ] && msg No shared BUSCOs found && return

   pushd $result_dir >/dev/null

   for d in *; do
      [ ! -d $d ] && continue
      pull_shared_buscos_from_one_genome $d
   done |
   sort_tab_delim_buscos |
   awk '{print ">"$1 " " $3; print $2 }'

   popd > /dev/null
}

function sort_tab_delim_buscos {
   if [ -z $sort_by_genome_then_busco ]; then
      sort -k1,1V
   else # genome name is in field 3 as output by pull_shared_buscos_from_one_genome
      sort -k3,3 -k1,1n
   fi
}

function pull_shared_buscos_from_one_genome {
   local d=$1
   local genome_name=$(echo $d | sed "s|_cpa1_[^[:blank:]]*||" | sed "s/_compleasm//")
   local buscos=$(find "$d" -type f -name "$busco_file")

   bawk -v genome_name=$genome_name '
      FILENUM==1 {
         busco_ar[$name]++
         next
      }

      # gene_marker.fasta file
      { name_prefix = $name; sub("_.*", "_", name_prefix) }

      # print in tab delimited flattened format so we can sort these together with other genome BUSCOs
      name_prefix in busco_ar {
         print name_prefix genome_name, $seq, genome_name
      }
   ' <(prep__shared) $buscos
}

function prep__shared {
   for s in $shared_buscos; do
      echo ">"$s"_"
   done
}

function write_faa_files_for_buscos_shared_by_all {
   # split_pulled_faa.sh script to do the work
   pull_buscos_shared_by_all | ./split_pulled_faa_fixed.sh -
}

function test_cmd {
   # echo $(grep "^${num_genomes}\s" -c) shared BUSCOs in $num_genomes genomes
   awk -v num_genomes=$num_genomes '
      NF > 2 { counts[$1]++ }
      END {
         PROCINFO["sorted_in"] = "@ind_num_desc"
         for (c in counts) {
            if (c < int((num_genomes+1)/2)) break
            printf("%d shared Complete BUSCOs in %d (%.2f%%) of %d genomes\n", counts[c], c, 100*c/num_genomes, num_genomes)
         }
      }
   '
}

# dir can be first or second arg and other arg is command
function get_args {
   [ -z $1 ] && usage

   [ -d $1 ] && compleasm_dirs=$1 && shift

   unset sort_by_genome_then_busco

   if [[ "$1" == "view" ]]; then
      cmd=view
   elif [[ "$1" == "count" ]]; then
      cmd=count_buscos_all
   elif [[ "$1" == "list" ]]; then
      cmd=list_buscos_shared_by_all
   elif [[ "$1" == "pull" ]]; then
      cmd=pull_buscos_shared_by_all
   elif [[ "$1" == "sort" ]]; then
      cmd=pull_buscos_shared_by_all
      sort_by_genome_then_busco=sort_by_genome_then_busco
   elif [[ "$1" == "faa" ]]; then
      cmd=write_faa_files_for_buscos_shared_by_all
   elif [[ "$1" == "test" ]]; then
      cmd=test_cmd
   else
      usage
   fi

   [ -z $compleasm_dirs ] && [ -d $2 ] && compleasm_dirs=$2
   [ -z $compleasm_dirs ] && usage

   set_vars  # uses $compleasm_dirs

}

function set_vars {
   result_dir=$compleasm_dirs
   fin_file=*_odb*/full_table_busco_format.tsv
   busco_file=gene_marker.fasta

   output_dir=shared_busco_faa  # for writing individual faa files for each BUSCO

   num_genomes=$(ls -1 $result_dir/*/$fin_file | wc -l)
}

function usage {
   local script=$(basename $0)
   msg "
    usage $script <dir with compleasm dirs> [ view | count | list | pull | faa ]

    view  -- Shows the Complete BUSCOs from each of the genomes sorted by BUSCO and numbered by genome count
    count -- counts the number of BUSCOs shared by all the genomes
    list  -- lists the BUSCO ID for those shared by all the genomes
    pull  -- pull the fasta records for each shared BUSCO from each genome gene_marker.fasta file and sorts by BUSCO id and genome name
    faa   -- pulls as above but writes individual faa files for each shared BUSCO in a $output_dir direcdtory
"
   exit 1
}

function msg { echo -e "$@" >/dev/stderr; }

main $@
