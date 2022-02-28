
if [ module-info mode load ] {
  if [ is-loaded PrgEnv-nvidia ] {
  } else {
    if [ is-loaded PrgEnv-cray ] {
      module swap PrgEnv-cray PrgEnv-nvidia
    }
    if [ is-loaded PrgEnv-gnu ] {
      module swap PrgEnv-gnu PrgEnv-nvidia
    }
  }
  module swap nvidia nvidia/22.2
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
