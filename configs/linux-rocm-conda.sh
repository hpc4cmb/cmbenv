loadedrocm=`modulecmd sh -t list 2>&1 | grep rocm`
if [ "x${loadedrocm}" = x ]; then
    module load rocm
fi
