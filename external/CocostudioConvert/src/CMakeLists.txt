include_directories(${PROJECT_SOURCE_DIR}/TouchJSON/Source)
set(APP_SRC main.m)
set(EXECUTABLE_OUTPUT_PATH ${PROJECT_SOURCE_DIR}/bin)
add_executable(CocostudioConvert ${APP_SRC})
target_link_libraries(CocostudioConvert TouchJSON)