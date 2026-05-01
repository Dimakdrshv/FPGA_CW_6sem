# scripts/create_project.tcl

set PROJECT_NAME "FPGA_CW_6sem"
set PART_NAME "xc7a100tcsg324-1"

set ROOT_DIR    [file normalize [file join [file dirname [info script]] ".."]]
set BUILD_DIR   [file join $ROOT_DIR "build"]
set PROJECT_DIR [file join $BUILD_DIR $PROJECT_NAME]

set SRC_DIR [file join $ROOT_DIR "files" "sources"]
set SIM_DIR [file join $ROOT_DIR "files" "simulations"]
set XDC_DIR [file join $ROOT_DIR "files" "constraints"]

puts "ROOT_DIR    = $ROOT_DIR"
puts "PROJECT_DIR = $PROJECT_DIR"

# Clean old build
if {[file exists $BUILD_DIR]} {
    puts "Removing old build directory..."
    file delete -force $BUILD_DIR
}

file mkdir $BUILD_DIR

# Create project
create_project $PROJECT_NAME $PROJECT_DIR -part $PART_NAME

# ---------------- Sources ----------------
set src_files [glob -nocomplain \
    [file join $SRC_DIR "*.v"] \
    [file join $SRC_DIR "*.sv"] \
    [file join $SRC_DIR "*.vhd"] \
    [file join $SRC_DIR "*.vhdl"] \
]

if {[llength $src_files] > 0} {
    add_files -fileset sources_1 $src_files
    import_files -fileset sources_1 -force
}

# ---------------- Memory files ----------------
set mem_files [glob -nocomplain \
    [file join $SRC_DIR "*.mem"] \
    [file join $SRC_DIR "*.coe"] \
    [file join $SRC_DIR "*.hex"] \
]

if {[llength $mem_files] > 0} {
    add_files -fileset sources_1 $mem_files
    import_files -fileset sources_1 -force
}

# ---------------- Constraints ----------------
set ucf_files [glob -nocomplain [file join $XDC_DIR "*.ucf"]]

set tmp_xdc_dir [file join $PROJECT_DIR "tmp_constraints"]
file mkdir $tmp_xdc_dir

set xdc_files {}

foreach ucf_file $ucf_files {
    set xdc_file [file join $tmp_xdc_dir "[file rootname [file tail $ucf_file]].xdc"]

    puts "Converting constraint file:"
    puts "  $ucf_file"
    puts "  -> $xdc_file"

    file copy -force $ucf_file $xdc_file

    lappend xdc_files $xdc_file
}

if {[llength $xdc_files] > 0} {
    add_files -fileset constrs_1 $xdc_files
    import_files -fileset constrs_1 -force
}

# ---------------- Simulations ----------------
set sim_files [glob -nocomplain \
    [file join $SIM_DIR "*.v"] \
    [file join $SIM_DIR "*.sv"] \
    [file join $SIM_DIR "*.vhd"] \
    [file join $SIM_DIR "*.vhdl"] \
]

if {[llength $sim_files] > 0} {
    add_files -fileset sim_1 $sim_files
    import_files -fileset sim_1 -force
}

# ---------------- Project settings ----------------
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts ""
puts "Project recreated successfully:"
puts "$PROJECT_DIR/$PROJECT_NAME.xpr"
puts ""