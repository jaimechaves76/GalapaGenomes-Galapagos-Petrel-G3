#!/bin/bash

main() {
   set_vars

   if [ ! -s $output_scaffolded_asm ]; then
      scaffold_asm_from_map > $output_scaffolded_asm
   else
      msg $output_scaffolded_asm already created.
   fi

   create_stats
   run_busco
}

function set_vars {
   asm=input/GalPetrel_hf_01.fasta
   # map=GalPet_hf_asm_to_CalBor.map
   map=modified_GalPet_hf_asm_to_CalBor.map

   to_replace="Cbor"
   prefix="Pphae"

   output_scaffolded_asm=GalPetrel_ref_scaff_v2.fa
}

function scaffold_asm_from_map {
   bawk -v prefix=$prefix -v to_replace=$to_replace '

      FILENUM == 1 {  # map with contigs in $comment var
         sub("^ *", "", $comment); sub(" $", "", $comment)

         if (match($name, "^"to_replace)) {
            chrnum = $name
            sub(to_replace, "", chrnum)
            sub("_RagTag$", "", chrnum)
            chr_order[++order] = chrnum
            chr_ctgs[chrnum] = $comment
         } else {
            unloc_name[++u] = $comment
         }
      }
      FILENUM == 1 { next }

      # asm contig records to store
      # also store revcomp with _rc suffix as name since that might be what is in map
      {
         seqs[$name] = $seq

         rc_seq = $seq
         seqs[$name"_rc"] = revcomp(rc_seq)
      }

      END {
         for (i = 1; i <= order; i++) {
            scaff_seq = ""
            cnum = chr_order[i]
            ctg_list = chr_ctgs[cnum]

            n = split(ctg_list, ar, " ")
            for (p = 1; p <= n; p++) {
               nm = ar[p]
               if (p > 1) scaff_seq = scaff_seq "\n" Ns "\n"
               scaff_seq = scaff_seq seqs[nm]
            }

            print ">"prefix cnum " " length(scaff_seq) "  " ctg_list
            print scaff_seq
         }

         for (i = 1; i <= u; i++) {
            nm = unloc_name[i]
            print ">unloc" i " " length(seqs[nm]) " " nm
            print seqs[nm]
         }
      }

      BEGIN { for (n=1; n <= 100; n++) {Ns = Ns "N" } }  # make our separator of 100 Ns
   ' <(prefix_gt $map) $asm
}

function create_stats {
   [ ! -s $output_scaffolded_asm ] && return

   stats_file=$(replace_ext.sh $output_scaffolded_asm stats)
   [ ! -s $stats_file ] && asmstats.pl $output_scaffolded_asm > $stats_file

   scaflens_file=$(replace_ext.sh $output_scaffolded_asm scaflens)
   [ ! -s $scaflens_file ] && make_scaflens.sh $output_scaffolded_asm > $scaflens_file
}

function run_busco {
   dual_compleasm_busco.sh $output_scaffolded_asm 96
   make_scaflens.sh $output_scaffolded_asm > $scaflens_file
}

function msg { echo -e "$@" >/dev/stderr; }


main $@
