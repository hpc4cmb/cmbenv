
if [ module-info mode load ] {
  if [ is-loaded PrgEnv-gnu ] {
  } else {
    if [ is-loaded PrgEnv-cray ] {
      module swap PrgEnv-cray PrgEnv-gnu
    }
    if [ is-loaded PrgEnv-intel ] {
      module swap PrgEnv-intel PrgEnv-gnu
    }
  }
  # altd may cause random job hangs
  if [ is-loaded altd ] {
    module unload altd
  }
  # darshan may cause overhead
  if [ is-loaded darshan ] {
    module unload darshan
  }
  module swap cray-mpich cray-mpich/7.7.6
  module swap gcc gcc/8.2.0
  module load git
  setenv CRAYPE_LINK_TYPE dynamic
}
