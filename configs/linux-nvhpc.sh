loadednvhpc=`modulecmd sh -t list 2>&1 | grep nvhpc`
if [ "x${loadednvhpc}" = x ]; then
  module load nvhpc-nompi/23.1
fi
