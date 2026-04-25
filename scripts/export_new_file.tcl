# scripts/export_new_file.tcl
#
# Load in Vivado Tcl Console:
# source scripts/export_new_file.tcl
#
# Commands:
# export_src    CW_ALU.v
# export_sim    TB_CW_ALU.v
# export_constr Nexys-A7.xdc
# export_mem    ROM.mem

set PROJECT_NAME "FPGA_CW_6sem"

set ROOT_DIR  [file normalize [file join [file dirname [info script]] ".."]]
set BUILD_DIR [file join $ROOT_DIR "build" $PROJECT_NAME]

proc export_file {TYPE FILE_NAME} {
    global PROJECT_NAME ROOT_DIR BUILD_DIR

    switch -- $TYPE {
        source {
            set FILE_PATH [file join $BUILD_DIR "${PROJECT_NAME}.srcs" "sources_1" "new" $FILE_NAME]
            set DEST_DIR  [file join $ROOT_DIR "files" "sources"]
        }

        sim {
            set FILE_PATH [file join $BUILD_DIR "${PROJECT_NAME}.srcs" "sim_1" "new" $FILE_NAME]
            set DEST_DIR  [file join $ROOT_DIR "files" "simulations"]
        }

        constr {
            set FILE_PATH [file join $BUILD_DIR "${PROJECT_NAME}.srcs" "constrs_1" "new" $FILE_NAME]
            set DEST_DIR  [file join $ROOT_DIR "files" "constraints"]
        }

        mem {
            set FILE_PATH [file join $BUILD_DIR "${PROJECT_NAME}.srcs" "sources_1" "new" $FILE_NAME]
            set DEST_DIR  [file join $ROOT_DIR "files" "sources"]
        }

        default {
            puts "ERROR: unknown type '$TYPE'"
            puts "Allowed types: source, sim, constr, mem"
            return
        }
    }

    set FILE_PATH [file normalize $FILE_PATH]

    if {![file exists $FILE_PATH]} {
        puts "ERROR: file not found:"
        puts "$FILE_PATH"
        puts ""
        puts "Check that the file exists in Vivado .srcs/*/new directory."
        return
    }

    file mkdir $DEST_DIR

    set DEST_FILE [file join $DEST_DIR $FILE_NAME]

    puts ""
    puts "Source:"
    puts "$FILE_PATH"

    if {[file exists $DEST_FILE]} {
        puts "Replacing existing file:"
    } else {
        puts "Creating new file:"
    }

    puts "$DEST_FILE"

    file copy -force $FILE_PATH $DEST_FILE

    puts "Done."
    puts ""
}

proc export_src {FILE_NAME} {
    export_file source $FILE_NAME
}

proc export_sim {FILE_NAME} {
    export_file sim $FILE_NAME
}

proc export_constr {FILE_NAME} {
    export_file constr $FILE_NAME
}

proc export_mem {FILE_NAME} {
    export_file mem $FILE_NAME
}

puts ""
puts "Export helper loaded."
puts "Available commands:"
puts "  export_src    <file.v/.sv/.vhd>"
puts "  export_sim    <testbench.v/.sv/.vhd>"
puts "  export_constr <file.xdc>"
puts "  export_mem    <file.mem/.coe/.hex>"
puts ""