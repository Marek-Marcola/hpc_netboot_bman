#!/bin/bash

VERSION_BIN="260605"

SN="${0##*/}"
ID="[$SN]"

DEBUG=0

os_dist=""
os_ver=""
os_maj=""
os_date=""
os_out=""
os_tar=""
os_cfg=""

INSTALL_RSYNC=0
INSTALL_ANPB=0
INSTALL_ANPB_HP="bman"
VERSION=0
STAGE_LIST=0
BACKUP=0
BACKUP_LIST=0
UNPACK=0
CONFIG=0
EXEC=0
ACTIVATE=0
REMOVE=0
LIST=0
HELP=0
QUIET=0

DDIR=/var/backup/bman

s=0

: ${COMM:=$(readlink -f ${BASH_SOURCE})}

while [ $# -gt 0 ]
do
  case $1 in
    --vers*|-vers*)
      VERSION=1
      shift
      ;;
    --inst*|-inst*)
      INSTALL_RSYNC=1
      shift
      ;;
    --anpb|-anpb)
      INSTALL_ANPB=1
      [[ -n "$2" && ${2:0:1} != "-" ]] && INSTALL_ANPB_HP="$2" && shift
      shift
      ;;
    --stage|-stage)
      STAGE_LIST=1
      shift
      ;;
    -B)
      BACKUP=1
      BACKUP_LIST=1
      shift
      ;;
    -Bl)
      BACKUP_LIST=1
      shift
      ;;
    -uca)
      UNPACK=1
      CONFIG=1
      EXEC=1
      ACTIVATE=1
      LIST=1
      shift
      ;;
    -u)
      UNPACK=1
      shift
      ;;
    -c)
      CONFIG=1
      shift
      ;;
    -x)
      EXEC=1
      shift
      ;;
    -a)
      ACTIVATE=1
      shift
      ;;
    -rm)
      REMOVE=1
      shift
      ;;
    -l)
      LIST=1
      QUIET=1
      shift
      ;;
    -lb)
      LIST=2
      QUIET=1
      shift
      ;;
    -lc)
      LIST=3
      QUIET=1
      shift
      ;;
    -D)
      os_dist="$2"
      shift; shift
      ;;
    -V)
      os_ver="$2"
      shift; shift
      ;;
    -d)
      os_date="$2"
      shift; shift
      ;;
    -T)
      os_tar="$2"
      shift; shift
      ;;
    -h|-help|--help)
      HELP=1
      shift
      ;;
    -q)
      QUIET=1
      shift
      ;;
    *)
      ARGS1+=("$1")
      shift
      ;;
  esac
done

#
# stage: HELP
#
if [ $HELP -eq 1 ]; then
  echo "$SN -version                       # version"
  echo "$SN -install                       # install with rsync"
  echo "$SN -anpb [host_pattern] [-x]      # install with ansible"
  echo "$SN -stage                         # stage list"
  echo ""
  echo "$SN -B                             # backup"
  echo "$SN -Bl                            # backup list"
  echo "$SN -u                             # unpack"
  echo "$SN -c [-x]                        # config show,exec"
  echo "$SN -a                             # activate"
  echo "$SN -rm [-x]                       # remove"
  echo "$SN -lc                            # list: configs"
  echo "$SN -lb                            # list: netboot"
  echo "$SN -l                             # list: netroot"
  echo "$SN                                # info"
  echo ""
  echo "common options:"
  echo "  -D dist"
  echo "  -V ver"
  echo "  -d date"
  echo "  -T archive (tar)"
  echo ""
  echo "aliases:"
  echo "  -uca = -u -c -x -a -l"
  echo ""
  echo "env files: \$HOME/.bman.env .bman.env \$BMANENV /usr/local/etc/bman.env"
  echo ""
  echo "notes:"
  echo " bm -l"
  echo " bm -d YYYYMMDDHHMM -uca"
  echo " bm -d YYYYMMDDHHMM -rm -x -l"
  exit 0
fi

#
# stage: CONFIG
#
for f in $HOME/.bman.env .bman.env $BMANENV /usr/local/etc/bman.env; do
  if [ -e $f ]; then
    [[ "$EFILE" != "" ]] && EFILE="$EFILE $f" || EFILE="$f"
    . $f
  fi
done

: ${NETROOT:=/netroot}
: ${NETBOOT:=/netboot}

if [ "$os_date" = "" ]; then
  os_date=$(readlink $NETROOT/$os_dist-$os_ver|awk -F- '{print $3}')
fi

: ${os_out:=$NETROOT/$os_dist-$os_ver-$os_date}
: ${os_tar:=$NETROOT/$os_dist-$os_ver-$os_date.tar}
: ${os_maj:=$(echo $os_ver|awk -F. '{print $1}')}

#
# stage: VERSION
#
if [ $VERSION -eq 1 ]; then
  echo "${0##*/}  $VERSION_BIN"
  [[ "$VERSION_ENV" != "" ]] && echo "bman.env $VERSION_ENV"
  exit 0
fi

#
# stage: INSTALL-RSYNC
#
if [ $INSTALL_RSYNC -eq 1 ]; then
  if [ -f bman.env ]; then
    for d in /usr/local/etc /pub/pkb/kb/data/999204-bman/999204-000020_bman_script /pub/pkb/pb/playbooks/999204-bman/files; do
      if [ -d $d ]; then
        set -ex
        rsync -ai bman.env $d
        { set +ex; } 2>/dev/null
      fi
    done
  fi
  if [ -f bman.sh ]; then
    for d in /usr/local/bin /pub/pkb/kb/data/999204-bman/999204-000020_bman_script /pub/pkb/pb/playbooks/999204-bman/files; do
      if [ -d $d ]; then
        set -ex
        rsync -ai bman.sh $d
        { set +ex; } 2>/dev/null
      fi
    done
  fi
  exit 0
fi

#
# stage: INSTALL-ANPB
#
if [ $INSTALL_ANPB -eq 1 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: INSTALL-ANPB (EVAL=$EVAL)"

  if [ ! $(type -t anpb) ]; then
    echo "$ID: error: command not found: anpb"
    exit 1
  fi

  [[ $EVAL -ne 1 ]] && EVAL_OPT="--check --diff" || EVAL_OPT=""

  set -ex
  anpb bman_install.yml -e h=$INSTALL_ANPB_HP $EVAL_OPT
  { set +ex; } 2>/dev/null

  exit 0
fi

#
# stage: STAGE-LIST
#
if [ $STAGE_LIST -eq 1 ]; then
  cat $COMM | grep '^#' | grep 'stage:'
  exit 0
fi

#
# stage: INFO
#
if [ $QUIET -eq 0 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: INFO"

  [[ -n $INFO ]] && echo "info    = ${INFO}"
  echo "cwd     = $(pwd -P)"
  echo "efile   = ${EFILE:-[none]}"
  echo "os_cid  = ${os_cid:-[none]}"
  echo "os_sid  = ${os_sid:-[none]}"
  echo "os_Dist = ${os_dist:-[none]}"
  echo "os_Ver  = ${os_ver:-[none]}"
  echo "os_maj  = ${os_maj:-[none]}"
  echo "os_date = ${os_date:-[none]}"
  echo "os_out  = ${os_out}"
  echo "os_Tar  = ${os_tar}"
  echo "os_cfg  = ${os_cfg}"

  if [ "$DOCS" != "" ]; then
    echo -n "docs    = "
    echo "$DOCS" | sed 's/\!/\n/g' | sed '2,$ s/^/         /'
  fi
fi

#
# stage: UNPACK
#
if [ $UNPACK -eq 1 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: UNPACK"

  if [ "$os_dist" = "" -o "$os_ver" = "" ]; then
    echo "$ID: error: require dist,ver"
    exit 1
  fi
  if [ -d $os_out ]; then
    echo "$ID: error: directory already exists: $os_out"
    exit 1
  fi
  if [ ! -f $os_tar ]; then
    echo "$ID: error: archive does not exists: $os_tar"
    exit 1
  fi

  set -ex
  mkdir -v $os_out
  tar xf $os_tar -C $os_out
  { set +ex; } 2>/dev/null
fi

#
# stage: CONFIG
#
if [ $CONFIG -eq 1 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: CONFIG (EXEC=$EXEC)"

  if [ "$os_dist" = "" -o "$os_ver" = "" ]; then
    echo "$ID: error: require dist,ver"
    exit 1
  fi
  if [ ! -d $os_out ]; then
    echo "$ID: error: directory does not exists: $os_out"
    exit 1
  fi

  if [ ! -d $os_out/version.d ]; then
    echo "$ID: error: version directory does not exists: $os_out/version.d"
    exit 1
  else
    echo "$ID: version directory: $os_out/version.d"
  fi

  OPTS="-i -a --no-times"
  if [ $EXEC -eq 0 ]; then
    OPTS="--dry-run $OPTS"
  fi

  n=0

  for cid in $(echo $os_cfg|sed 's/,/ /g'); do
    cdir=/usr/local/etc/bman.d/config-$cid
    if [ -d $cdir/files-add ]; then
      (( $n != 0 )) && echo; ((++n))
      set -ex
      rsync $OPTS $cdir/files-add/ $os_out
      { set +ex; } 2>/dev/null
    fi

    if [ -f $cdir/files-del ]; then
      (( $n != 0 )) && echo; ((++n))
      cat $cdir/files-del | \
      while read f; do
        if [ -e $os_out/$f ]; then
          if [ $EXEC -eq 0 ]; then
            echo rm -vd $os_out/$f
          else
            set -ex
            rm -vd $os_out/$f
            { set +ex; } 2>/dev/null
          fi
        else
          echo "# rm -vd $os_out/$f"
        fi
      done
    fi

    if [ -f $cdir/files-bin ]; then
      (( $n != 0 )) && echo; ((++n))
      cat $cdir/files-bin | \
      while read f; do
        if [ -x $cdir/bin/$f ]; then
          if [ $EXEC -eq 0 ]; then
            echo $cdir/bin/$f $os_out $os_dist $os_ver $os_date
          else
            set -ex
            $cdir/bin/$f $os_out $os_dist $os_ver $os_date
            { set +ex; } 2>/dev/null
          fi
        else
          echo "# $cdir/bin/$f $os_out"
        fi
      done
    fi
  done

  if [ $EXEC -ne 0 ]; then
    (( $n != 0 )) && echo; ((++n))
    set -ex
    VF=$os_out/version.d/version-$os_dist-$os_ver-config.txt
    echo info.date = $(date +%Y-%m-%d_%H:%M:%S) > $VF
    echo info.name = $os_dist-$os_ver-config >> $VF
    echo info.from = $os_cfg >> $VF
    { set +ex; } 2>/dev/null
  fi
fi

#
# stage: ACTIVATE
#
if [ $ACTIVATE -eq 1 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: ACTIVATE"

  if [ "$os_dist" = "" -o "$os_ver" = "" ]; then
    echo "$ID: error: require dist,ver"
    exit 1
  fi
  if [ ! -d $os_out ]; then
    echo "$ID: error: directory does not exists: $os_out"
    exit 1
  fi

  set -ex
  cd $NETROOT
  ln -snfv $os_dist-$os_ver-$os_date $os_dist-$os_ver
  { set +ex; } 2>/dev/null
fi

#
# stage: REMOVE
#
if [ $REMOVE -eq 1 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: REMOVE (EXEC=$EXEC)"

  if [ -d $os_out/version.d ]; then
    echo "$ID: version directory: $os_out/version.d"
    if [ $EXEC -eq 0 ]; then
      echo rm -rf $os_out
    else
      set -ex
      rm -rf $os_out
      { set +ex; } 2>/dev/null
    fi
  else
    echo "no os_out: $os_out/version.d"
  fi
  if [ -f $os_tar ]; then
    if [ $EXEC -eq 0 ]; then
      echo rm -f $os_tar
    else
      set -ex
      rm -f $os_tar
      { set +ex; } 2>/dev/null
    fi
  else
    echo "no os_tar: $os_tar"
  fi
fi

#
# stage: LIST
#
if [ $LIST -ne 0 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: LIST"

  if [ $LIST -eq 1 ]; then
    set -ex
    tree --noreport -F -h -C -L 1 $NETROOT/
    { set +ex; } 2>/dev/null
    echo
    set -ex
    df -h $NETROOT/
    { set +ex; } 2>/dev/null
  elif [ $LIST -eq 2 ]; then
    set -ex
    tree --noreport -F -h -C -I syslinux $NETBOOT/
    { set +ex; } 2>/dev/null
  else
    n=0
    for cid in $(echo $os_cfg|sed 's/,/ /g'); do
      cdir=/usr/local/etc/bman.d/config-$cid
      (( $n != 0 )) && echo; ((++n))
      echo "config: ${cid}"
      if [ -d $cdir/files-add ]; then
        set -ex
        tree --noreport -F -h -C -a -f -i $cdir/files-add
        { set +ex; } 2>/dev/null
      fi
      if [ -f $cdir/files-del ]; then
        set -ex
        cat $cdir/files-del
        { set +ex; } 2>/dev/null
      fi
    done
  fi
fi

#
# stage: BACKUP
#
if [ $BACKUP -ne 0 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: BACKUP"

  if [ ! -d $DDIR ]; then
    set -x
    mkdir -pv $DDIR
    { set +x; } 2>/dev/null
  fi

  F=${DDIR}/bman-${os_cid}${os_cid:+-}$(date "+%Y%m%d%H%M").tar

  set -x
  cd /usr/local
  tar cf $F etc/bman* bin/bman*
  gzip -f $F
  { set +x; } 2>/dev/null
fi

#
# stage: BACKUP-LIST
#
if [ $BACKUP_LIST -ne 0 ]; then
  (( $s != 0 )) && echo; ((++s))
  echo "$ID: stage: BACKUP-LIST"

  set -x
  tree --noreport -F -h -C -L 1 ${DDIR}
  { set +x; } 2>/dev/null
fi
