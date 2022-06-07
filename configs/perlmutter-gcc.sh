loadedgnu=$(module -t list 2>&1 | grep PrgEnv-gnu)
loadednvidia=$(module -t list 2>&1 | grep PrgEnv-nvidia)
loadedcray=$(module -t list 2>&1 | grep PrgEnv-cray)
loadeddarshan=$(module -t list 2>&1 | grep darshan)
loadedaltd=$(module -t list 2>&1 | grep altd)
if [ "x${loadedgnu}" = x ]; then
    if [ "x${loadedcray}" != x ]; then
      module swap PrgEnv-cray PrgEnv-gnu
    fi
    if [ "x${loadednvidia}" != x ]; then
      module swap PrgEnv-nvidia PrgEnv-gnu
    fi
fi
# altd may cause random job hangs
if [ "x${loadedaltd}" != x ]; then
  module unload altd
fi
# darshan may cause overhead
if [ "x${loadeddarshan}" != x ]; then
  module unload darshan
fi
module unload cray-libsci
export CRAYPE_LINK_TYPE=dynamic
