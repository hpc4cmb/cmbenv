
if [ module-info mode load ] {
  if [ is-loaded PrgEnv-gnu ] {
  } else {
    if [ is-loaded PrgEnv-cray ] {
      module swap PrgEnv-cray PrgEnv-gnu
    }
    if [ is-loaded PrgEnv-nvidia ] {
      module swap PrgEnv-nvidia PrgEnv-gnu
    }
  }
  module load cuda
  # altd may cause random job hangs
  if [ is-loaded altd ] {
    module unload altd
  }
  # darshan may cause overhead
  if [ is-loaded darshan ] {
    module unload darshan
  }
  module unload cray-libsci
  setenv CRAYPE_LINK_TYPE dynamic
}
