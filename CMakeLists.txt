cmake_minimum_required(VERSION 3.10.2)

project(GFCC VERSION 0.1)

configure_file(
  ${CMAKE_CURRENT_SOURCE_DIR}/src/include/gfcc_meta.h.in
  ${CMAKE_CURRENT_SOURCE_DIR}/src/include/generated/gfcc_meta.h
)


# specify the C++ standard
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED True)

# add executable
add_executable(parser
  ${CMAKE_CURRENT_SOURCE_DIR}/src/consts.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/src/main.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/src/meta.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/src/typo.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/src/symtab.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/src/tree.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/src/generated/lex.yy.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/src/generated/parser.tab.cpp
)
target_link_libraries(parser PUBLIC fl)

# generate lexical analyser using flex
add_custom_command(
  OUTPUT ${CMAKE_CURRENT_SOURCE_DIR}/src/generated/lex.yy.cpp
  COMMAND flex --outfile=${CMAKE_CURRENT_SOURCE_DIR}/src/generated/lex.yy.cpp
          ${CMAKE_CURRENT_SOURCE_DIR}/src/lexer.l
  DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/src/lexer.l
          ${CMAKE_CURRENT_SOURCE_DIR}/src/include/generated/parser.tab.h
)

# generate parser using bison
add_custom_command(
  OUTPUT  ${CMAKE_CURRENT_SOURCE_DIR}/src/include/generated/parser.tab.h ${CMAKE_CURRENT_SOURCE_DIR}/src/generated/parser.tab.cpp
  COMMAND bison --defines=${CMAKE_CURRENT_SOURCE_DIR}/src/include/generated/parser.tab.h
                --output=${CMAKE_CURRENT_SOURCE_DIR}/src/generated/parser.tab.cpp
                ${CMAKE_CURRENT_SOURCE_DIR}/src/parser.y
  DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/src/parser.y
)

target_include_directories(parser PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/src/include)
target_include_directories(parser PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/src/include/generated)

# get headers
file(GLOB DEFAULT_HEARDERS "${CMAKE_CURRENT_SOURCE_DIR}/src/include/*.h")

#install
install(TARGETS parser DESTINATION bin)
# install(FILES ${DEFAULT_HEARDERS} DESTINATION include)
