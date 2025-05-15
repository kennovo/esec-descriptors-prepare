#!/bin/sh
if [ $# -ne 1 ] ; then
  echo "Usage: `basename $0` <skip>"
  exit 1
 fi
for i in * ; do
  [ -s "$i/md_1_1.xtc" -a -s "$i/${i}.prop" ] || continue
  echo 2 | gmx trjconv -f "$i/md_1_1.xtc" -s "$i/md_1_1.tpr" -o "$i/$i.gro" -pbc whole
  awk -v n=`wc -l <"$i/${i}.prop"` -v skip="$1" 'BEGIN{done=-32000;i=-1;init()}
    (NF==6){if(f>=skip)printf("%7.3f %7.3f %7.3f\n",$4,$5,$6);
      i++;next}
    (NF==3){f++;init();next}
    {print "ERROR: unexpected line!">"/dev/stderr";err=1;exit 1}
    END{if(err!=done){
        if(err)exit err;
        print "ERROR: unexpected end of file!">"/dev/stderr";exit 2} }
    function init(){if(! getline){err=done; exit 0};
      if(NF!=7){print "ERROR: expected 7 fields!">"/dev/stderr";err=1;exit 1};
      getline;
      if(NF!=1){print "ERROR: expected 1 field!">"/dev/stderr";err=1;exit 1};
      if($1!=n || (i!=-1 && i!=n)){print "ERROR: wrong number of atoms!">"/dev/stderr";err=1;exit 1};
      i=0}' "$i/$i.gro" >"$i/$i.traj.xyz"
done
