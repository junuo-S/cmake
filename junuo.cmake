function(assign_source_group source)
    get_filename_component(source_path "${source}" PATH)
    source_group("${source_path}" FILES "${source}")
endfunction(assign_source_group)

function(junuo_add_executable target_name)
    foreach(source ${ARGN})
        assign_source_group(${source})
    endforeach()
    add_executable(${ARGV})
endfunction(junuo_add_executable)

function(junuo_add_library target_name)
    foreach(source ${ARGN})
        assign_source_group(${source})
    endforeach()
    add_library(${ARGV})
    set_target_properties(${target_name} PROPERTIES WINDOWS_EXPORT_ALL_SYMBOLS true)
endfunction(junuo_add_library)

function(junuo_use_Qt target)
    if(NOT target)
        message(FATAL_ERROR "Missing 'TARGET' argument in junuo_need_Qt function.")
    endif()
    find_package(${Qt_version} COMPONENTS REQUIRED ${ARGN})
    foreach(arg ${ARGN})
        target_link_libraries(${target} PRIVATE ${Qt_version}::${arg})
    endforeach(arg)
endfunction(junuo_use_Qt)

function(junuo_use_Python3 target)
    if(NOT target)
        message(FATAL_ERROR "Missing 'TARGET' argument in junuo_use_Python3 function.")
    endif()
    find_package(Python3 COMPONENTS Interpreter Development REQUIRED)
    target_include_directories(${target} PRIVATE ${Python3_INCLUDE_DIRS})
    target_link_libraries(${target} PRIVATE ${Python3_LIBRARY})
    target_link_directories(${target} PRIVATE ${Python3_LIBRARY_DIRS})
endfunction(junuo_use_Python3)

function(junuo_use_OpenSSL target)
    if(NOT target)
        message(FATAL_ERROR "Missing 'TARGET' argument in junuo_use_OpenSSL function.")
    endif()
    find_package(OpenSSL REQUIRED)
    target_link_libraries(${target} PRIVATE OpenSSL::SSL OpenSSL::Crypto)
endfunction(junuo_use_OpenSSL)

function(junuo_use_lz4 target)
    if(NOT target)
        message(FATAL_ERROR "Missing 'TARGET' argument in junuo_use_lz4 function.")
    endif()
    find_package(lz4 CONFIG REQUIRED)
    target_link_libraries(${target} PRIVATE lz4::lz4)
endfunction(junuo_use_lz4)

function(junuo_use_protobuf target)
    if(NOT target)
        message(FATAL_ERROR "Missing 'TARGET' argument in junuo_use_protobuf function.")
    endif()
    find_package(Protobuf CONFIG REQUIRED)
    target_link_libraries(${target} PRIVATE protobuf::libprotoc protobuf::libprotobuf protobuf::libprotobuf-lite)
endfunction(junuo_use_protobuf)

function(junuo_add_generate_sources target GenerateFile)
    target_sources(${target} PRIVATE ${GenerateFile})
    source_group("Generate Files" FILES ${GenerateFile})
endfunction(junuo_add_generate_sources)

function(junuo_auto_moc target_name)
    set(auto_moc_MOC_SOURCES)
    # 为每个头文件调用 MOC 并生成对应的源文件
    foreach(header ${ARGN})
        get_filename_component(file_extension ${header} EXT)
        if(${file_extension} STREQUAL ".h")
            get_filename_component(header_name ${header} NAME_WE)
            set(moc_output "${CMAKE_CURRENT_BINARY_DIR}/moc/moc_${header_name}.cpp")
            add_custom_command(
                OUTPUT ${moc_output}
                COMMAND ${Qt_version}::moc ${CMAKE_CURRENT_SOURCE_DIR}/${header} -o ${moc_output}
                DEPENDS ${header}
            )
            list(APPEND auto_moc_MOC_SOURCES ${moc_output})
        endif()
    endforeach()
    # 将所有的MOC文件合并成一个文件
    set(ret_file ${CMAKE_CURRENT_BINARY_DIR}/moc/automoc2_0_0.cpp)
    add_custom_command(
        OUTPUT ${ret_file}
        COMMAND ${CMAKE_COMMAND} -E cat ${auto_moc_MOC_SOURCES} > ${ret_file}
        DEPENDS ${auto_moc_MOC_SOURCES}
    )
    target_sources(${target_name} PRIVATE ${ret_file})
    source_group("Generate Files" FILES ${ret_file})
endfunction(junuo_auto_moc)

function(junuo_auto_uic target_name)
    foreach(ui_file ${ARGN})
        get_filename_component(file_extension ${ui_file} EXT)
        if(${file_extension} STREQUAL ".ui")
            # 获取.ui文件的文件名（不包含扩展名）
            get_filename_component(ui_name ${ui_file} NAME_WE)
            # 设置输出的头文件路径，通常将它们放在一个单独的目录中，如"ui_headers"
            set(output_header "${CMAKE_CURRENT_BINARY_DIR}/uic/ui_${ui_name}.h")
            # 将输出头文件添加到UI_HEADERS列表中，用于后续处理
            list(APPEND ${UIC_FILE} ${output_header})
            # 执行uic命令来处理.ui文件并生成头文件
            add_custom_command(
                OUTPUT ${output_header}
                COMMAND ${Qt_version}::uic ${CMAKE_CURRENT_SOURCE_DIR}/${ui_file} -o ${output_header}
                DEPENDS ${ui_file}
            )
            target_sources(${target_name} PRIVATE ${output_header})
            source_group("Generate Files" FILES ${output_header})
        endif()
    endforeach()
endfunction(junuo_auto_uic)

function(junuo_auto_rcc target_name qrcfile)
    get_filename_component(file_extension ${qrcfile} EXT)
    if(${file_extension} STREQUAL ".qrc")
        get_filename_component(header_name ${qrcfile} NAME_WE)
        set(rcc_output "${CMAKE_CURRENT_BINARY_DIR}/rcc/rcc_${header_name}.cpp")
        add_custom_command(
            OUTPUT ${rcc_output}
            COMMAND ${Qt_version}::rcc ${CMAKE_CURRENT_SOURCE_DIR}/${qrcfile} -o ${rcc_output}
            DEPENDS ${qrcfile} ${ARGN}
        )
        target_sources(${target_name} PRIVATE ${rcc_output})
        source_group("Generate Files" FILES ${rcc_output})
    endif()
endfunction(junuo_auto_rcc)

function(junuo_include_directories target_name)
    target_include_directories(${target_name} PRIVATE ${ARGN})
endfunction(junuo_include_directories)

function(junuo_link_libraries target_name)
    target_link_libraries(${target_name} PRIVATE ${ARGN})
endfunction(junuo_link_libraries)

function(junuo_compile_definitions target_name)
    target_compile_definitions(${target_name} PRIVATE ${ARGN})
endfunction(junuo_compile_definitions)

function(junuo_add_translation target_name)
    find_package(${Qt_version} COMPONENTS LinguistTools REQUIRED)
    foreach(ts_file ${ARGN})
        get_filename_component(file_extension ${ts_file} EXT)
        if(${file_extension} STREQUAL ".ts")
            get_filename_component(header_name ${ts_file} NAME_WE)
            add_custom_command(
                TARGET ${target_name} POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/translation
                COMMAND ${Qt_version}::lrelease ${CMAKE_CURRENT_SOURCE_DIR}/${ts_file} -qm ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/translation/${header_name}.qm
                DEPENDS ${ARGN}
            )
        endif()
    endforeach()
endfunction(junuo_add_translation)

function(junuo_generate_protobuf_files target_name)
    set(proto_gen_path ${CMAKE_CURRENT_BINARY_DIR}/gen-cpp)
    file(MAKE_DIRECTORY ${proto_gen_path})
    # 初始化输出列表
    set(proto_headers)
    set(proto_sources)

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
    target_sources(${target_name} PRIVATE ${proto_headers} ${proto_sources})
    source_group("Generate Files" FILES ${proto_headers} ${proto_sources})
endfunction(junuo_generate_protobuf_files)

