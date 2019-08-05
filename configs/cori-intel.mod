
if [ module-info mode load ] {
  if [ is-loaded PrgEnv-intel ] {
  } else {
    if [ is-loaded PrgEnv-cray ] {
      module swap PrgEnv-cray PrgEnv-intel
    }
    if [ is-loaded PrgEnv-gnu ] {
      module swap PrgEnv-gnu PrgEnv-intel
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
  module unload craype-hugepages2M
  module load gcc
  setenv CRAYPE_LINK_TYPE dynamic
}
