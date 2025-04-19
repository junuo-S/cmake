function(assign_source_group source)
    get_filename_component(source_path "${source}" PATH)
    source_group("${source_path}" FILES "${source}")
endfunction(assign_source_group)

macro(junuo_package package_name package_type)
    set(junuo_current_package_name ${package_name})
    if (${package_type} STREQUAL "EXECUTABLE")
        if (OS_WIN)
            add_executable(${junuo_current_package_name} WIN32)
        elseif (OS_DARWIN)
            add_executable(${junuo_current_package_name} MACOSX_BUNDLE)
        else()
            add_executable(${junuo_current_package_name})
        endif()
    elseif (${package_type} STREQUAL "CONSOLE")
        add_executable(${junuo_current_package_name})
    elseif (${package_type} STREQUAL "STATIC")
        add_library(${junuo_current_package_name} STATIC)
    elseif (${package_type} STREQUAL "SHARED")
        add_library(${junuo_current_package_name} SHARED)
    else()
        message(FATAL_ERROR "not support package type: ${package_type}")
    endif()
endmacro(junuo_package)

function(junuo_link_packages)
    target_link_libraries(${junuo_current_package_name} PRIVATE ${ARGN})
endfunction(junuo_link_packages)

function(junuo_use_packages)
    foreach(arg ${ARGN})
        if (${arg} MATCHES "Qt")
            set(regex "^(Qt[0-9]+)([A-Za-z]+)$")
            string(REGEX MATCH "${regex}" _ "${arg}")
            set(Qt_part "${CMAKE_MATCH_1}")
            set(component_part "${CMAKE_MATCH_2}")
            if (NOT ${Qt_part} STREQUAL "Qt${QT_VERSION_MAJOR}")
                message(FATAL_ERROR "Qt version is ambiguous")
            else()
                junuo_use_Qt(${component_part})
            endif()
        else()
            string(REPLACE "-" "_" func_name "junuo_use_${arg}")
            if(COMMAND ${func_name})
                cmake_language(CALL ${func_name})
            else()
                message(FATAL_ERROR "Function ${func_name} is not defined.")
            endif()
        endif()
    endforeach()
endfunction(junuo_use_packages)

function(junuo_use_Qt)
    find_package("Qt${QT_VERSION_MAJOR}" COMPONENTS REQUIRED ${ARGN})
    foreach(arg ${ARGN})
        target_link_libraries(${junuo_current_package_name} PRIVATE Qt${QT_VERSION_MAJOR}::${arg})
    endforeach(arg)
endfunction(junuo_use_Qt)

function(junuo_use_python3)
    find_package(Python3 COMPONENTS Interpreter Development REQUIRED)
    target_include_directories(${junuo_current_package_name} PRIVATE ${Python3_INCLUDE_DIRS})
    target_link_libraries(${junuo_current_package_name} PRIVATE ${Python3_LIBRARY})
    target_link_directories(${junuo_current_package_name} PRIVATE ${Python3_LIBRARY_DIRS})
endfunction(junuo_use_python3)

function(junuo_use_openssl)
    find_package(OpenSSL REQUIRED)
    target_link_libraries(${junuo_current_package_name} PRIVATE OpenSSL::SSL OpenSSL::Crypto)
endfunction(junuo_use_openssl)

function(junuo_use_lz4)
    find_package(lz4 CONFIG REQUIRED)
    target_link_libraries(${junuo_current_package_name} PRIVATE lz4::lz4)
endfunction(junuo_use_lz4)

function(junuo_use_protobuf)
    find_package(Protobuf CONFIG REQUIRED)
    target_link_libraries(${junuo_current_package_name} PRIVATE protobuf::libprotoc protobuf::libprotobuf protobuf::libprotobuf-lite)
endfunction(junuo_use_protobuf)

function(junuo_sources)
    set(source_file_list)
    set(ui_file_list)
    set(qrc_file_list)
    set(proto_file_list)
    set(ts_file_list)
    foreach(_file ${ARGN})
        get_filename_component(file_extension ${_file} EXT)
        if (NOT file_extension)
            continue()
        endif()
        if (".h;.cpp;.hpp;.cc" MATCHES ${file_extension})
            list(APPEND source_file_list ${_file})
        elseif (${file_extension} STREQUAL ".ui")
            list(APPEND ui_file_list ${_file})
        elseif (${file_extension} STREQUAL ".qrc")
            list(APPEND qrc_file_list ${_file})
        elseif (${file_extension} STREQUAL ".proto")
            list(APPEND proto_file_list ${_file})
        elseif (${file_extension} STREQUAL ".ts")
            list(APPEND ts_file_list ${_file})
        endif()
        target_sources(${junuo_current_package_name} PRIVATE ${_file})
        assign_source_group(${_file})
    endforeach()
    junuo_deal_ui_files(${ui_file_list})
    if("junuo_moc" IN_LIST ARGN)
        junuo_deal_moc_files(${source_file_list})
    endif()
    junuo_deal_qrc_files(${qrc_file_list})
    junuo_deal_protobuf_files(${proto_file_list})
    junuo_add_translation(${ts_file_list})
endfunction(junuo_sources)

function(junuo_deal_protobuf_files)
    list(LENGTH ARGN argn_count)
    if (argn_count LESS 0 OR argn_count EQUAL 0)
        return()
    endif()
    set(proto_gen_path ${CMAKE_CURRENT_BINARY_DIR}/gen-cpp)
    file(MAKE_DIRECTORY ${proto_gen_path})
    # 初始化输出列表
    set(proto_headers)
    set(proto_sources)
    find_package(Protobuf CONFIG REQUIRED)
    # 遍历传入的 proto 文件列表
    foreach(proto_file ${ARGN})
        # 获取 proto 文件名（不带扩展名）
        get_filename_component(file_name_no_suffix ${proto_file} NAME_WE)
        set(proto_header ${proto_gen_path}/${file_name_no_suffix}.pb.cc)
        set(proto_source ${proto_gen_path}/${file_name_no_suffix}.pb.h)
        # 提取路径部分
        get_filename_component(part_path "${proto_file}" DIRECTORY)
        # 提取文件名部分
        get_filename_component(part_name "${proto_file}" NAME)

        # 添加自定义命令生成 .cc 和 .h 文件，并指定依赖项
        add_custom_command(
            OUTPUT ${proto_header} ${proto_source}
            COMMAND ${Protobuf_PROTOC_EXECUTABLE}
            ARGS --cpp_out=${proto_gen_path} -I ${CMAKE_CURRENT_SOURCE_DIR}/${part_path} ${part_name}
            DEPENDS ${proto_file}  # 依赖于 .proto 文件
            COMMENT "Generating C++ source and header from ${proto_file}"
        )

        # 将生成的 .cc 和 .h 文件加入列表
        list(APPEND proto_headers ${proto_header})
        list(APPEND proto_sources ${proto_source})
    endforeach()
    junuo_add_generate_sources(${proto_headers} ${proto_sources})
endfunction(junuo_deal_protobuf_files)

function(junuo_deal_ui_files)
    set(output_dir ${CMAKE_CURRENT_BINARY_DIR}/uic)
    foreach(ui_file ${ARGN})
        get_filename_component(file_extension ${ui_file} EXT)
        if(${file_extension} STREQUAL ".ui")
            # 获取.ui文件的文件名（不包含扩展名）
            get_filename_component(ui_name ${ui_file} NAME_WE)
            set(output_header "${output_dir}/ui_${ui_name}.h")
            # 执行uic命令来处理.ui文件并生成头文件
            add_custom_command(
                OUTPUT ${output_header}
                COMMAND ${CMAKE_COMMAND} -E make_directory ${output_dir}
                COMMAND Qt${QT_VERSION_MAJOR}::uic ${CMAKE_CURRENT_SOURCE_DIR}/${ui_file} -o ${output_header}
                DEPENDS ${ui_file}
            )
            junuo_add_generate_sources(${output_header})
        endif()
    endforeach()
endfunction(junuo_deal_ui_files)

function(junuo_deal_moc_files)
    list(LENGTH ARGN argn_count)
    if (argn_count LESS 0 OR argn_count EQUAL 0)
        return()
    endif()
    set(moc_file_base_name junuo_moc_01.cpp)
    set(generate_moc_file ${CMAKE_CURRENT_BINARY_DIR}/moc/${moc_file_base_name})
    set_source_files_properties(${generate_moc_file} PROPERTIES GENERATED TRUE)
    junuo_add_generate_sources(${generate_moc_file})
    find_program(qmake_executable NAMES qmake-qt${QT_VERSION_MAJOR} qmake)
    if (NOT qmake_executable)
        return()
    endif()
    get_filename_component(Qt_bin_dir ${qmake_executable} DIRECTORY)
    add_custom_command(
        OUTPUT ${generate_moc_file}
        COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_CURRENT_BINARY_DIR}/moc
        COMMAND ${Python3_EXECUTABLE} ${PROJECT_SOURCE_DIR}/cmake/script/junuo_cmake_help.py moc --compile "${ARGN}" --source-dir ${CMAKE_CURRENT_SOURCE_DIR} --output-dir ${CMAKE_CURRENT_BINARY_DIR} --qt-bin-dir ${Qt_bin_dir} --output-file ${moc_file_base_name}
        COMMENT "parallel moc ing..."
        DEPENDS ${LINES}
    )
endfunction(junuo_deal_moc_files)

function(junuo_deal_qrc_files)
    list(LENGTH ARGN argn_count)
    if (argn_count LESS 0 OR argn_count EQUAL 0)
        return()
    endif()
    set(output_dir ${CMAKE_CURRENT_BINARY_DIR}/rcc)
    foreach(qrc_file ${ARGN})
        execute_process(
            COMMAND ${Python3_EXECUTABLE} ${PROJECT_SOURCE_DIR}/cmake/script/junuo_cmake_help.py rcc --check ${qrc_file} --source-dir ${CMAKE_CURRENT_SOURCE_DIR}
            OUTPUT_VARIABLE check_result
            RESULT_VARIABLE result_value
        )
        if (NOT result_value EQUAL 0)
            message(FATAL_ERROR "failed to execute python script. return code: ${result_value}")        
        endif()
        string(REPLACE "\n" ";" LINES ${check_result})
        get_filename_component(file_name ${qrc_file} NAME_WE)
        set(generate_rcc_file ${output_dir}/rcc_${file_name}.cpp)
        junuo_sources(${LINES})
        junuo_add_generate_sources(${generate_rcc_file})
        add_custom_command(
            OUTPUT ${generate_rcc_file}
            COMMAND ${CMAKE_COMMAND} -E make_directory ${output_dir}
            COMMAND Qt${QT_VERSION_MAJOR}::rcc ${CMAKE_CURRENT_SOURCE_DIR}/${qrc_file} -o ${generate_rcc_file}
            DEPENDS ${qrc_file} ${LINES}
        )
    endforeach()
endfunction(junuo_deal_qrc_files)

function(junuo_add_translation)
    find_package(Qt${QT_VERSION_MAJOR} COMPONENTS LinguistTools REQUIRED)
    foreach(ts_file ${ARGN})
        get_filename_component(file_extension ${ts_file} EXT)
        if(${file_extension} STREQUAL ".ts")
            get_filename_component(header_name ${ts_file} NAME_WE)
            add_custom_command(
                TARGET ${junuo_current_package_name} POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/translation
                COMMAND Qt${QT_VERSION_MAJOR}::lrelease ${CMAKE_CURRENT_SOURCE_DIR}/${ts_file} -qm ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/translation/${header_name}.qm
                DEPENDS ${ts_file}
            )
        endif()
    endforeach()
endfunction(junuo_add_translation)

function(junuo_add_generate_sources)
    list(LENGTH ARGN argn_count)
    if (argn_count LESS 0 OR argn_count EQUAL 0)
        return()
    endif()
    target_sources(${junuo_current_package_name} PRIVATE ${ARGN})
    source_group("Generate Files" FILES ${ARGN})
endfunction(junuo_add_generate_sources)

function(junuo_include_directories)
    target_include_directories(${junuo_current_package_name} PRIVATE ${ARGN})
endfunction(junuo_include_directories)

function(junuo_compile_definitions)
    target_compile_definitions(${junuo_current_package_name} PRIVATE ${ARGN})
endfunction(junuo_compile_definitions)
