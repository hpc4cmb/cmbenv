loadedgnu=`${MODULESHOME}/bin/modulecmd sh -t list 2>&1 | grep PrgEnv-gnu`
loadedintel=`${MODULESHOME}/bin/modulecmd sh -t list 2>&1 | grep PrgEnv-intel`
loadedcray=`${MODULESHOME}/bin/modulecmd sh -t list 2>&1 | grep PrgEnv-cray`
loadeddarshan=`${MODULESHOME}/bin/modulecmd sh -t list 2>&1 | grep darshan`
loadedaltd=`${MODULESHOME}/bin/modulecmd sh -t list 2>&1 | grep altd`
if [ "x${loadedintel}" = x ]; then
    if [ "x${loadedcray}" != x ]; then
      module swap PrgEnv-cray PrgEnv-intel
    fi
    if [ "x${loadedgnu}" != x ]; then
      module swap PrgEnv-gnu PrgEnv-intel
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
module load gcc
module load git
export CRAYPE_LINK_TYPE=dynamic
