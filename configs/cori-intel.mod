
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
  # altd is evil and causes random job hangs
  if [ is-loaded altd ] {
    module unload altd
  }
  # darshan is useless at best and may cause overhead
  if [ is-loaded darshan ] {
    module unload darshan
  }
  module load gcc
  module load git
  setenv CRAYPE_LINK_TYPE dynamic
}
