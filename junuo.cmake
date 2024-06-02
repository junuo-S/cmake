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
    find_package(Qt5 COMPONENTS REQUIRED ${ARGN})
    foreach(arg ${ARGN})
        target_link_libraries(${target} PRIVATE Qt5::${arg})
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
        message(FATAL_ERROR "Missing 'TARGET' argument in junuo_use_Python3 function.")
    endif()
    find_package(OpenSSL REQUIRED)
    target_link_libraries(${target} PRIVATE OpenSSL::SSL OpenSSL::Crypto)
endfunction(junuo_use_OpenSSL)



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
                COMMAND Qt5::moc ${CMAKE_CURRENT_SOURCE_DIR}/${header} -o ${moc_output}
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
                COMMAND Qt5::uic ${CMAKE_CURRENT_SOURCE_DIR}/${ui_file} -o ${output_header}
                DEPENDS ${ui_file}
            )
            target_sources(${target_name} PRIVATE ${output_header})
            source_group("Generate Files" FILES ${output_header})
        endif()
    endforeach()
endfunction(junuo_auto_uic)

function(junuo_auto_rcc target_name)
    foreach(qrcfile ${ARGN})
        get_filename_component(file_extension ${qrcfile} EXT)
        if(${file_extension} STREQUAL ".qrc")
            get_filename_component(header_name ${qrcfile} NAME_WE)
            set(rcc_output "${CMAKE_CURRENT_BINARY_DIR}/rcc/rcc_${header_name}.cpp")
            add_custom_command(
                OUTPUT ${rcc_output}
                COMMAND Qt5::rcc ${CMAKE_CURRENT_SOURCE_DIR}/${qrcfile} -o ${rcc_output}
                DEPENDS ${qrcfile}
            )
            target_sources(${target_name} PRIVATE ${rcc_output})
            source_group("Generate Files" FILES ${rcc_output})
        endif()
    endforeach()
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
    find_package(Qt5 COMPONENTS LinguistTools REQUIRED)
    foreach(ts_file ${ARGN})
        get_filename_component(file_extension ${ts_file} EXT)
        if(${file_extension} STREQUAL ".ts")
            get_filename_component(header_name ${ts_file} NAME_WE)
            add_custom_command(
                TARGET ${target_name} POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/translation
                COMMAND Qt5::lrelease ${CMAKE_CURRENT_SOURCE_DIR}/${ts_file} -qm ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/translation/${header_name}.qm
                DEPENDS ${ARGN}
            )
        endif()
    endforeach()
endfunction(junuo_add_translation)

