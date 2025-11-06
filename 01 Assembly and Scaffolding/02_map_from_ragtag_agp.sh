#!/bin/bash

agp=ragtag_CalBor_hap1/ragtag.scaffold.agp
map=GalPet_hf_asm_to_CalBor.map

awk '
   $5 != "W" { next }

   $1 != lst {
      if (NR > 1) printf("\n")
      lst = $1
      printf("%s", $1)
   }

   $(NF-1) > 10000 {
      suff = ($NF == "-") ? "_rc" : ""
      printf(" %s%s", $6, suff)
   }
   END { printf("\n") }
' $agp |
awk 'NF > 1{sub("_RagTag","",$1); print}' |
sort -V > $map
