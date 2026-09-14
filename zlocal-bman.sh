bm() {
  local desc="@@netboot management (via bman.sh)@@"
  bman.sh $@
}

cdbm() {
  local desc="@@change working directory to bman $EDIR@@"
  local D="/usr/local/etc/bman.d"
  cd $D
  pwd
}
