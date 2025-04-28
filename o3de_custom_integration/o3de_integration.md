To use this copy of Assimp locally in your o3de build do the following:

- Replace FindAssimp.cmake inside your ~/.o3de/3rdParty/packages/assimp-5.4.3-rev3-linux with the copy from this directory
- Build and install assimp:
    `cmake --build build --target assimp -j 18`
    `cmake --install build --prefix ~/tools/my_assimp_install`
- Rebuild your o3de project
