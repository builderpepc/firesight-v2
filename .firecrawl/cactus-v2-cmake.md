cmake\_minimum\_required(VERSION 3.10)
project(CactusEngine LANGUAGES CXX)

set(CMAKE\_CXX\_STANDARD 20)
set(CMAKE\_CXX\_STANDARD\_REQUIRED True)

if(NOT CMAKE\_BUILD\_TYPE)
 set(CMAKE\_BUILD\_TYPE Release)
endif()

if(APPLE)
 set(CMAKE\_OSX\_ARCHITECTURES "arm64")
 set(CMAKE\_CXX\_FLAGS "${CMAKE\_CXX\_FLAGS} -arch arm64 -march=armv8.2-a+fp16+simd+dotprod+i8mm -pthread -Wall -Wextra -pedantic -O3 -Wno-missing-field-initializers")
 add\_compile\_definitions(
 \_\_ARM\_NEON=1
 \_\_ARM\_FEATURE\_FP16\_VECTOR\_ARITHMETIC=1
 \_\_ARM\_FEATURE\_DOTPROD=1
 \_\_ARM\_FEATURE\_MATMUL\_INT8=1
 ACCELERATE\_NEW\_LAPACK
 )
else()
 set(CMAKE\_CXX\_FLAGS "${CMAKE\_CXX\_FLAGS} -march=armv8.2-a+fp16+simd+dotprod+i8mm -pthread -Wall -Wextra -pedantic -O3 -Wno-missing-field-initializers")
 add\_compile\_definitions(
 \_\_ARM\_NEON=1
 \_\_ARM\_FEATURE\_FP16\_VECTOR\_ARITHMETIC=1
 \_\_ARM\_FEATURE\_DOTPROD=1
 \_\_ARM\_FEATURE\_MATMUL\_INT8=1
 )
endif()

\# --- Depend on cactus-graph (which depends on cactus-kernels) ---
set(CACTUS\_GRAPH\_DIR "${CMAKE\_CURRENT\_SOURCE\_DIR}/../cactus-graph")
if(NOT TARGET cactus\_graph)
 add\_subdirectory(${CACTUS\_GRAPH\_DIR} ${CMAKE\_CURRENT\_BINARY\_DIR}/cactus-graph)
endif()

\# --- libcurl ---
set(CACTUS\_CURL\_ROOT "${CMAKE\_CURRENT\_SOURCE\_DIR}/libs/curl" CACHE PATH "Path to vendored libcurl")

if(APPLE)
 set(CACTUS\_CURL\_INCLUDE\_DIR "${CACTUS\_CURL\_ROOT}/include")
 set(CACTUS\_CURL\_LIBRARY\_MACOS "${CACTUS\_CURL\_ROOT}/macos/libcurl.a")
 if(EXISTS "${CACTUS\_CURL\_INCLUDE\_DIR}/curl/curl.h" AND EXISTS "${CACTUS\_CURL\_LIBRARY\_MACOS}")
 set(CACTUS\_HAS\_CURL TRUE)
 else()
 set(CACTUS\_HAS\_CURL FALSE)
 message(WARNING "Vendored libcurl not found at ${CACTUS\_CURL\_ROOT}; cloud features disabled")
 endif()
else()
 find\_package(CURL QUIET)
 set(CACTUS\_HAS\_CURL ${CURL\_FOUND})
endif()

\# --- Engine sources ---
set(ENGINE\_SOURCES
 src/bpe.cpp
 src/sp.cpp
 src/constraints.cpp
 src/model.cpp
 src/engine\_image.cpp
 src/index.cpp
 src/index\_ffi.cpp
 src/log.cpp
 src/graph\_ffi.cpp
 src/rag.cpp
 src/telemetry.cpp
 src/telemetry\_impl.cpp
 src/cloud.cpp
 src/init.cpp
 src/embed.cpp
 src/complete.cpp
 src/transcribe.cpp
 src/tokenizer.cpp
 src/npu.cpp
)

set(MODEL\_SOURCES
 models/model\_lfm2.cpp
 models/model\_lfm2vl.cpp
 models/model\_qwen.cpp
 models/model\_siglip2.cpp
 models/gemma4/model\_gemma4.cpp
 models/gemma4/model\_gemma4\_mm.cpp
 models/gemma4/model\_gemma4\_audio.cpp
 models/gemma4/model\_gemma4\_vision.cpp
)

if(APPLE)
 enable\_language(OBJCXX)
 list(APPEND ENGINE\_SOURCES src/npu\_ane.mm)
 set\_source\_files\_properties(src/npu\_ane.mm PROPERTIES COMPILE\_FLAGS "-fobjc-arc")
endif()

add\_library(cactus\_engine STATIC ${ENGINE\_SOURCES} ${MODEL\_SOURCES})
set(CACTUS\_KERNELS\_DIR "${CMAKE\_CURRENT\_SOURCE\_DIR}/../cactus-kernels")
target\_include\_directories(cactus\_engine
 PUBLIC ${CMAKE\_CURRENT\_SOURCE\_DIR}
 PRIVATE ${CMAKE\_CURRENT\_SOURCE\_DIR}/src
 ${CMAKE\_CURRENT\_SOURCE\_DIR}/models
 ${CACTUS\_KERNELS\_DIR}/src
 ${CACTUS\_KERNELS\_DIR}/libs
)
target\_link\_libraries(cactus\_engine PUBLIC cactus\_graph)
set\_target\_properties(cactus\_engine PROPERTIES POSITION\_INDEPENDENT\_CODE ON)

\# curl
if(CACTUS\_HAS\_CURL)
 if(APPLE)
 target\_link\_libraries(cactus\_engine PUBLIC ${CACTUS\_CURL\_LIBRARY\_MACOS})
 target\_include\_directories(cactus\_engine PUBLIC ${CACTUS\_CURL\_INCLUDE\_DIR})
 else()
 target\_link\_libraries(cactus\_engine PUBLIC ${CURL\_LIBRARIES})
 target\_include\_directories(cactus\_engine PRIVATE ${CURL\_INCLUDE\_DIRS})
 endif()
 target\_compile\_definitions(cactus\_engine PRIVATE CACTUS\_USE\_CURL=1)
endif()

\# Apple frameworks
if(APPLE)
 find\_library(COREML\_FRAMEWORK CoreML REQUIRED)
 find\_library(FOUNDATION\_FRAMEWORK Foundation REQUIRED)
 find\_library(SECURITY\_FRAMEWORK Security REQUIRED)
 find\_library(SYSTEMCONFIGURATION\_FRAMEWORK SystemConfiguration REQUIRED)
 find\_library(CFNETWORK\_FRAMEWORK CFNetwork REQUIRED)
 target\_link\_libraries(cactus\_engine PUBLIC
 ${COREML\_FRAMEWORK}
 ${FOUNDATION\_FRAMEWORK}
 ${SECURITY\_FRAMEWORK}
 ${SYSTEMCONFIGURATION\_FRAMEWORK}
 ${CFNETWORK\_FRAMEWORK}
 )
endif()

\# Version
set(\_CACTUS\_VERSION\_FILE "${CMAKE\_CURRENT\_SOURCE\_DIR}/../CACTUS\_VERSION")
if(EXISTS "${\_CACTUS\_VERSION\_FILE}")
 file(READ "${\_CACTUS\_VERSION\_FILE}" \_CACTUS\_VERSION\_CONTENT)
 string(STRIP "${\_CACTUS\_VERSION\_CONTENT}" CACTUS\_VERSION\_STR)
 target\_compile\_definitions(cactus\_engine PRIVATE CACTUS\_COMPILE\_TIME\_VERSION="${CACTUS\_VERSION\_STR}")
endif()

if(CMAKE\_CXX\_COMPILER\_ID STREQUAL "AppleClang" OR CMAKE\_CXX\_COMPILER\_ID STREQUAL "Clang")
 target\_compile\_options(cactus\_engine PRIVATE -Wno-c99-extensions)
elseif(CMAKE\_CXX\_COMPILER\_ID STREQUAL "GNU")
 target\_compile\_options(cactus\_engine PRIVATE -Wno-pedantic)
endif()