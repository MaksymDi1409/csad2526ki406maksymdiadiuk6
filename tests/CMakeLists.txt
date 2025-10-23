# Завантаження GoogleTest через FetchContent
include(FetchContent)

FetchContent_Declare(
  googletest
  URL https://github.com/google/googletest/archive/refs/heads/main.zip
)
# Для уникнення конфліктів з policy CMP0135
set(BUILD_GMOCK OFF CACHE BOOL "" FORCE)
set(INSTALL_GTEST OFF CACHE BOOL "" FORCE)
FetchContent_MakeAvailable(googletest)

# Створення тестового виконуваного файлу
file(GLOB TEST_SOURCES CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/*.cpp")

add_executable(${PROJECT_NAME}_tests ${TEST_SOURCES})
target_link_libraries(${PROJECT_NAME}_tests PRIVATE GTest::gtest_main)

# Якщо існує бібліотека з основного проекту — підключаємо її
if(TARGET ${PROJECT_NAME}_lib)
    target_link_libraries(${PROJECT_NAME}_tests PRIVATE ${PROJECT_NAME}_lib)
endif()

# Додаємо include-шляхи
target_include_directories(${PROJECT_NAME}_tests PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/..
)

# Автоматичне знаходження тестів
include(GoogleTest)
gtest_discover_tests(${PROJECT_NAME}_tests)