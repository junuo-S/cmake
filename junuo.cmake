function(assign_source_group source)
    get_filename_component(source_path "${source}" PATH)
    source_group("${source_path}" FILES "${source}")
endfunction(assign_source_group)

function(junuo_add_executable)
    foreach(source ${ARGN})
        assign_source_group(${source})
    endforeach()
    add_executable(${ARGV})
endfunction(junuo_add_executable)

function(junuo_need_Qt target)
    if(NOT target)
        message(FATAL_ERROR "Missing 'TARGET' argument in junuo_need_Qt function.")
    endif()
    foreach(arg ${ARGN})
        find_package(Qt5 COMPONENTS REQUIRED ${arg})
        target_link_libraries(${target} PRIVATE Qt5::${arg})
    endforeach(arg)
endfunction(junuo_need_Qt)

function(junuo_target_sources_generate target)
    target_sources(${target} PRIVATE ${GenerateFile})
    source_group("Generate Files" FILES ${GenerateFile})
endfunction(junuo_target_sources_generate)


# 定义一个函数，用于生成automoc2_0_0.cpp文件
macro(junuo_auto_moc MOC_FILE)
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
    set(${MOC_FILE} ${CMAKE_CURRENT_BINARY_DIR}/moc/automoc2_0_0.cpp)
    add_custom_command(
        OUTPUT ${${MOC_FILE}}
        COMMAND ${CMAKE_COMMAND} -E cat ${auto_moc_MOC_SOURCES} > ${${MOC_FILE}}
        # COMMAND ${CMAKE_COMMAND} -E remove ${auto_moc_MOC_SOURCES}
        DEPENDS ${auto_moc_MOC_SOURCES}
    )
endmacro(junuo_auto_moc)

macro(junuo_auto_uic UIC_FILE)
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
        endif()
    endforeach()
endmacro(junuo_auto_uic)

macro(junuo_auto_rcc RCC_FILE)
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
            list(APPEND ${RCC_FILE} ${rcc_output})
        endif()
    endforeach()
endmacro(junuo_auto_rcc)


