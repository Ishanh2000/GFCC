cmake_minimum_required(VERSION 3.10.2)

project(GFCC VERSION 0.1)

# specify the C++ standard
# set(CMAKE_CXX_STANDARD 11)
# set(CMAKE_CXX_STANDARD_REQUIRED True)

# add executable
add_executable(lexer ${CMAKE_CURRENT_SOURCE_DIR}/src/generated/lex.yy.c)
target_link_libraries(lexer PUBLIC fl)

# generate lexical analyser using flex
add_custom_command(
  OUTPUT ${CMAKE_CURRENT_SOURCE_DIR}/src/generated/lex.yy.c
  COMMAND flex --outfile=${CMAKE_CURRENT_SOURCE_DIR}/src/generated/lex.yy.c
          ${CMAKE_CURRENT_SOURCE_DIR}/src/lexer.l
  DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/src/lexer.l
          ${CMAKE_CURRENT_SOURCE_DIR}/src/include/generated/y.tab.h
  )

# generate parser using bison
add_custom_command(
  OUTPUT  ${CMAKE_CURRENT_SOURCE_DIR}/src/include/generated/y.tab.h ${CMAKE_CURRENT_SOURCE_DIR}/src/generated/y.tab.c
  COMMAND bison --defines=${CMAKE_CURRENT_SOURCE_DIR}/src/include/generated/y.tab.h
                --output=${CMAKE_CURRENT_SOURCE_DIR}/src/generated/y.tab.c
                ${CMAKE_CURRENT_SOURCE_DIR}/src/parser.y
  DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/src/parser.y
  )

target_include_directories(lexer PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/src/include)
target_include_directories(lexer PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/src/include/generated)

# get headers
file(GLOB DEFAULT_HEARDERS "${CMAKE_CURRENT_SOURCE_DIR}/src/include/*.h")

#install
install(TARGETS lexer DESTINATION bin)
# install(FILES ${DEFAULT_HEARDERS} DESTINATION include)
