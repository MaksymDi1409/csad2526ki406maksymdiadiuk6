cmake_minimum_required(VERSION 3.15)

# Автоматично ім'я проєкту за назвою папки
get_filename_component(PROJECT_NAME ${CMAKE_CURRENT_SOURCE_DIR} NAME)
project(${PROJECT_NAME} VERSION 0.1.0 LANGUAGES CXX)

# Налаштування стандарту C++
set(CMAKE_CXX_STANDARD 17 CACHE STRING "C++ standard to use")
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Опції
option(BUILD_TESTING "Enable building tests" ON)

# Директорії для заголовків (помістіть ваші заголовки у include/)
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/include")
    include_directories("${CMAKE_CURRENT_SOURCE_DIR}/include")
endif()

# Збірка бібліотеки з усіх cpp-файлів у src/ (якщо є)
file(GLOB_RECURSE PROJECT_SOURCES CONFIGURE_DEPENDS
         "${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp"
         "${CMAKE_CURRENT_SOURCE_DIR}/src/*.cc"
         "${CMAKE_CURRENT_SOURCE_DIR}/src/*.cxx")

if(PROJECT_SOURCES)
    add_library(${PROJECT_NAME}_lib STATIC ${PROJECT_SOURCES})
    target_include_directories(${PROJECT_NAME}_lib PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    )
    # Встановіть проперті для спрощення підключення
    set_target_properties(${PROJECT_NAME}_lib PROPERTIES POSITION_INDEPENDENT_CODE ON)
endif()

# Створення виконуваних файлів з app/*.cpp (наприклад app/main.cpp)
file(GLOB APP_SOURCES CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/app/*.cpp")
if(APP_SOURCES)
    # Якщо є кілька файлів у app/, створимо один виконуваний з усіх них
    add_executable(${PROJECT_NAME}_app ${APP_SOURCES})
    if(TARGET ${PROJECT_NAME}_lib)
        target_link_libraries(${PROJECT_NAME}_app PRIVATE ${PROJECT_NAME}_lib)
    endif()
    target_include_directories(${PROJECT_NAME}_app PRIVATE
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    )
endif()

# Тести (опціонально)
if(BUILD_TESTING)
    include(CTest)
    enable_testing()
    # Якщо у вас є тести в tests/, підключіть їх тут.
    # Приклад: автоматичне створення одного виконуваного для tests/*.cpp
    file(GLOB TEST_SOURCES CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/tests/*.cpp")
    if(TEST_SOURCES)
        add_executable(${PROJECT_NAME}_tests ${TEST_SOURCES})
        if(TARGET ${PROJECT_NAME}_lib)
            target_link_libraries(${PROJECT_NAME}_tests PRIVATE ${PROJECT_NAME}_lib)
        endif()
        target_include_directories(${PROJECT_NAME}_tests PRIVATE
            $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        )
        add_test(NAME run_tests COMMAND ${PROJECT_NAME}_tests)
    endif()
endif()

# Зручніці для інсталяції (необов'язково)
install(CODE "message(STATUS \"Project ${PROJECT_NAME} configured.\")")