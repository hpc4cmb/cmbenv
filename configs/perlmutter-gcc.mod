
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
  if [ is-loaded cpe-cuda ] {
  } else {
    module load cpe-cuda
  }   
  if [ is-loaded cuda ] {
  } else {
    module load cuda
  }
  # altd may cause random job hangs
  if [ is-loaded altd ] {
    module unload altd
  }
  # darshan may cause overhead
  if [ is-loaded darshan ] {
    module unload darshan
  }
  if [ is-loaded cray-libsci ] {
    module unload cray-libsci
  }
  setenv CRAYPE_LINK_TYPE dynamic
}
