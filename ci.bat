@echo off
REM === Continuous Integration Build Script for Windows ===
if not exist build mkdir build
cd build

cmake ..
cmake --build . --config Release

ctest --output-on-failure

cd ..
echo === Build and tests finished successfully ===
pause