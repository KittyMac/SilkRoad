cmake_minimum_required(VERSION 3.4.1)

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall -Werror -Wno-unused-function")

add_library(silkroad SHARED
            silkroad.c)

# Include libraries needed for silkroad lib
target_link_libraries(silkroad
                      android
                      jnigraphics
                      log
                      m)
