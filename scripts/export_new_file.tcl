# scripts/export_new_file.tcl
#
# Load in Vivado Tcl Console:
# source scripts/export_new_file.tcl
#
# Commands:
# export_src    CW_ALU.v
# export_sim    TB_CW_ALU.v
# export_constr Nexys-A7.xdc
# export_mem_src ROM.mem
# export_mem_sim TB_ROM.mem
# export_mem     ROM.mem  ;# auto: searches sources_1 and sim_1

set PROJECT_NAME "FPGA_CW_6sem"

set ROOT_DIR  [file normalize [file join [file dirname [info script]] ".."]]
set BUILD_DIR [file join $ROOT_DIR "build" $PROJECT_NAME]

proc find_file_recursive {BASE_DIR FILE_NAME} {
    set result {}

    if {![file exists $BASE_DIR]} {
        return $result
    }

    set items [glob -nocomplain -directory $BASE_DIR *]

    foreach item $items {
        if {[file isdirectory $item]} {
            set sub_result [find_file_recursive $item $FILE_NAME]

            foreach found $sub_result {
                lappend result $found
            }
        } else {
            if {[file tail $item] eq $FILE_NAME} {
                lappend result [file normalize $item]
            }
        }
    }

    return $result
}

proc export_file {TYPE FILE_NAME} {
    global PROJECT_NAME ROOT_DIR BUILD_DIR

    switch -- $TYPE {
        source {
            set SEARCH_DIR [file join $BUILD_DIR "${PROJECT_NAME}.srcs" "sources_1"]
            set DEST_DIR   [file join $ROOT_DIR "files" "sources"]
        }

        sim {
            set SEARCH_DIR [file join $BUILD_DIR "${PROJECT_NAME}.srcs" "sim_1"]
            set DEST_DIR   [file join $ROOT_DIR "files" "simulations"]
        }

        constr {
            set SEARCH_DIR [file join $BUILD_DIR "${PROJECT_NAME}.srcs" "constrs_1"]
            set DEST_DIR   [file join $ROOT_DIR "files" "constraints"]
        }

        mem_src {
            set SEARCH_DIR [file join $BUILD_DIR "${PROJECT_NAME}.srcs" "sources_1"]
            set DEST_DIR   [file join $ROOT_DIR "files" "sources"]
        }

        mem_sim {
            set SEARCH_DIR [file join $BUILD_DIR "${PROJECT_NAME}.srcs" "sim_1"]
            set DEST_DIR   [file join $ROOT_DIR "files" "simulations"]
        }

        default {
            puts "ERROR: unknown type '$TYPE'"
            puts "Allowed types: source, sim, constr, mem_src, mem_sim"
            return
        }
    }

    set SEARCH_DIR [file normalize $SEARCH_DIR]

    set MATCHES [find_file_recursive $SEARCH_DIR $FILE_NAME]

    if {[llength $MATCHES] == 0} {
        puts ""
        puts "ERROR: file not found:"
        puts "$FILE_NAME"
        puts ""
        puts "Searched recursively in:"
        puts "$SEARCH_DIR"
        puts ""
        return
    }

    if {[llength $MATCHES] > 1} {
        puts ""
        puts "ERROR: multiple files found with name:"
        puts "$FILE_NAME"
        puts ""
        puts "Matches:"

        foreach match $MATCHES {
            puts "  $match"
        }

        puts ""
        puts "Rename one of the files or export manually."
        puts ""
        return
    }

    set FILE_PATH [lindex $MATCHES 0]

    file mkdir $DEST_DIR

    if {$TYPE eq "constr"} {
        set DEST_FILE [file join $DEST_DIR "[file rootname $FILE_NAME].ucf"]
    } else {
        set DEST_FILE [file join $DEST_DIR $FILE_NAME]
    }

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

proc export_mem_src {FILE_NAME} {
    export_file mem_src $FILE_NAME
}

proc export_mem_sim {FILE_NAME} {
    export_file mem_sim $FILE_NAME
}

proc export_mem {FILE_NAME} {
    global PROJECT_NAME ROOT_DIR BUILD_DIR

    set SRC_SEARCH_DIR [file normalize [file join $BUILD_DIR "${PROJECT_NAME}.srcs" "sources_1"]]
    set SIM_SEARCH_DIR [file normalize [file join $BUILD_DIR "${PROJECT_NAME}.srcs" "sim_1"]]

    set SRC_MATCHES [find_file_recursive $SRC_SEARCH_DIR $FILE_NAME]
    set SIM_MATCHES [find_file_recursive $SIM_SEARCH_DIR $FILE_NAME]

    set total_matches [expr {[llength $SRC_MATCHES] + [llength $SIM_MATCHES]}]

    if {$total_matches == 0} {
        puts ""
        puts "ERROR: memory file not found:"
        puts "$FILE_NAME"
        puts ""
        puts "Searched recursively in:"
        puts "  $SRC_SEARCH_DIR"
        puts "  $SIM_SEARCH_DIR"
        puts ""
        return
    }

    if {$total_matches > 1} {
        puts ""
        puts "ERROR: multiple memory files found with name:"
        puts "$FILE_NAME"
        puts ""
        puts "Source matches:"
        foreach match $SRC_MATCHES {
            puts "  $match"
        }
        puts "Simulation matches:"
        foreach match $SIM_MATCHES {
            puts "  $match"
        }
        puts ""
        puts "Use export_mem_src or export_mem_sim explicitly."
        puts ""
        return
    }

    if {[llength $SRC_MATCHES] == 1} {
        export_file mem_src $FILE_NAME
    } else {
        export_file mem_sim $FILE_NAME
    }
}

puts ""
puts "Export helper loaded."
puts "Available commands:"
puts "  export_src     <file.v/.sv/.vhd>"
puts "  export_sim     <testbench.v/.sv/.vhd>"
puts "  export_constr  <file.xdc>  -> exports as .ucf"
puts "  export_mem_src <file.mem/.coe/.hex>"
puts "  export_mem_sim <file.mem/.coe/.hex>"
puts "  export_mem     <file.mem/.coe/.hex>  ;# auto-detects sources_1 or sim_1"
puts ""