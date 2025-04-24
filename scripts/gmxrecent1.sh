#!/bin/sh
if [ $# -ne 1 ] ; then
  echo "Usage: `basename $0` <skip>"
  exit 1
 fi
for i in * ; do
  [ -s $i/md_1_1.xtc -a -s $i/${i}_prop.xyz ] || continue
  echo 2 | gmx trjconv -f $i/md_1_1.xtc -s $i/md_1_1.tpr -o $i/$i.gro -pbc whole
  awk -v prop="$i/${i}_prop.xyz" -v skip="$1" 'BEGIN{done=-32000;
      while(getline<prop){m=$1;mtot+=m;mas[++n]=m;cha[n]=$2};
      mmt=-mtot;i=-1;init()}
    (NF==6){m=mas[++i];
      x[i]=xi=$4;y[i]=yi=$5;z[i]=zi=$6;
      cmx+=xi*m;cmy+=yi*m;cmz+=zi*m;next}
    (NF==3){
      if(++f>skip){cmx/=mmt;cmy/=mmt;cmz/=mmt;
        for(j=1;j<=n;j++){printf("%9.5f %9.5f %9.5f\n",x[j]+cmx,y[j]+cmy,z[j]+cmz)};
        cmv2=cmx*cmx+cmy*cmy+cmz*cmz;if(cmv2>maxv2)maxv2=cmv2};
      init();next}
    {print "ERROR: unexpected line!">"/dev/stderr";err=1;exit 1}
    END{if(err!=done){
        if(err)exit err;
        print "ERROR: unexpected end of file!">"/dev/stderr";exit 2};
      print "Maximum center of mass offset =",sqrt(maxv2)>"/dev/stderr"}
    function init(){if(! getline){err=done; exit 0};
      if(NF!=7){print "ERROR: expected 7 fields!">"/dev/stderr";err=1;exit 1};
      getline;
      if(NF!=1){print "ERROR: expected 1 field!">"/dev/stderr";err=1;exit 1};
      if($1!=n || (i!=-1 && i!=n)){print "ERROR: wrong number of atoms!">"/dev/stderr";err=1;exit 1};
      i=0;cmx=0;cmy=0;cmz=0}' $i/$i.gro >$i/$i.recenter.xyz
done
