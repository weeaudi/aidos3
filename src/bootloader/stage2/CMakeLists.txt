
file(GLOB_RECURSE STAGE2_SRC "*.asm" "*.cpp")

set(STAGE2_LINK ${CMAKE_CURRENT_SOURCE_DIR}/linker.ld)

add_executable(stage2 ${STAGE2_SRC})

set_target_properties(stage2 PROPERTIES OUTPUT_NAME "stage2.elf")

set(CRTBEGIN_OBJ ${64PREFIX_DIR}/lib/gcc/x86_64-elf/13.2.0/crtbegin.o)
set(CRTEND_OBJ ${64PREFIX_DIR}/lib/gcc/x86_64-elf/13.2.0/crtend.o)

target_link_options(stage2 PRIVATE 
    -Wl,-T ${STAGE2_LINK}               # Use linker script
    -Wl,--no-warn-rwx-segment           # Suppress warnings
    -nostdlib                           # Avoid linking standard libraries
    -Wl,-Map=${CMAKE_BINARY_DIR}/src/bootloader/stage2/stage2.map  # Generate map file
    ${CRTBEGIN_OBJ}  
    ${CRTEND_OBJ}
)

add_custom_command( 
    OUTPUT ${CMAKE_BINARY_DIR}/out/debug/stage2.elf
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_BINARY_DIR}/src/bootloader/stage2/stage2.elf ${CMAKE_BINARY_DIR}/out/debug/stage2.elf
    DEPENDS stage2
)

add_custom_target(stage2_debug_output ALL DEPENDS ${CMAKE_BINARY_DIR}/out/debug/stage2.elf)