cmake_minimum_required(VERSION 3.18.5)

project(GFCC VERSION 0.1)

# specify the C++ standard
# set(CMAKE_CXX_STANDARD 11)
# set(CMAKE_CXX_STANDARD_REQUIRED True)

# add executable
add_executable(lexer ${CMAKE_CURRENT_SOURCE_DIR}/src/lex.yy.c)
target_link_libraries(lexer PUBLIC fl)

# generate lexical analyser
add_custom_command(
  OUTPUT ${CMAKE_CURRENT_SOURCE_DIR}/src/lex.yy.c
  COMMAND flex --outfile=${CMAKE_CURRENT_SOURCE_DIR}/src/lex.yy.c ${CMAKE_CURRENT_SOURCE_DIR}/src/lexer.l
  DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/src/lexer.l
  )

target_include_directories(lexer PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/src/include)

# get headers
file(GLOB DEFAULT_HEARDERS "${CMAKE_CURRENT_SOURCE_DIR}/src/include/*.h")

#install
install(TARGETS lexer DESTINATION bin)
# install(FILES ${DEFAULT_HEARDERS} DESTINATION include)
