To use this copy of Assimp locally in your o3de build do the following:

- Replace FindAssimp.cmake inside your ~/.o3de/3rdParty/packages/assimp-5.4.3-rev3-linux with the copy from this directory
- adjust CMAKE configuration, eg. with cmake-gui:
    - disable `BUILD_SHARED_LIBS`
    - enable `ASSIMP_BUILD_USD_IMPORTER`
- Build and install assimp:
    `cmake --build build --target assimp -j 18`
    `cmake --install build --prefix ~/tools/my_assimp_install`
- Rebuild your o3de project


Known issues:
- tools like usdcat might introduced nans into the PrimVar arrays. Tinyusdz won't be able to parse them
- Some assets have `int[] primvars:displayColor:indices` declarations without consecutive definition of the array or any other assignment. This silently breaks tinyusdz parsing
