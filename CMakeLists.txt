cmake_minimum_required(VERSION 3.16)
project(hello LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

find_package(PkgConfig REQUIRED)
pkg_check_modules(LIBXMLXX REQUIRED IMPORTED_TARGET libxml++-2.6)

add_library(hello_lib src/hello.cpp)
target_include_directories(hello_lib PUBLIC src)
target_link_libraries(hello_lib PUBLIC PkgConfig::LIBXMLXX)

add_executable(hello src/main.cpp)
target_link_libraries(hello PRIVATE hello_lib)
