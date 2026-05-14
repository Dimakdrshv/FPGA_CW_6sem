# create_ise_project.tcl

set PROJECT_NAME "FPGA_CW_6sem"

set FAMILY  "Spartan3E"
set DEVICE  "xc3s500e"
set PACKAGE "pq208"
set SPEED   "-4"

set TOP_MODULE "CW_TOP"

# This script must be placed near files/
set ROOT_DIR [file normalize [file dirname [info script]]]

set SRC_DIR [file join $ROOT_DIR "files" "sources"]
set UCF_DIR [file join $ROOT_DIR "files" "constraints"]

set PROJECT_DIR [file join $ROOT_DIR $PROJECT_NAME]

puts "ROOT_DIR    = $ROOT_DIR"
puts "SRC_DIR     = $SRC_DIR"
puts "UCF_DIR     = $UCF_DIR"
puts "PROJECT_DIR = $PROJECT_DIR"

if {[file exists $PROJECT_DIR]} {
    puts "Removing old project directory..."
    file delete -force $PROJECT_DIR
}

file mkdir $PROJECT_DIR
cd $PROJECT_DIR

project new "$PROJECT_NAME.xise"

project set family  $FAMILY
project set device  $DEVICE
project set package $PACKAGE
project set speed   $SPEED

# folders inside ISE project
set PROJECT_SRC_DIR [file join $PROJECT_DIR "sources"]
set PROJECT_UCF_DIR [file join $PROJECT_DIR "constraints"]

file mkdir $PROJECT_SRC_DIR
file mkdir $PROJECT_UCF_DIR

# -------------------------
# ADD VERILOG SOURCE FILES
# -------------------------

set verilog_files [lsort [glob -nocomplain -directory $SRC_DIR *.v]]

foreach src_file $verilog_files {
    set dst_file [file join $PROJECT_SRC_DIR [file tail $src_file]]
    file copy -force $src_file $dst_file

    puts "Add Verilog source: $dst_file"
    xfile add $dst_file
}

# -------------------------
# ADD MEMORY FILES
# -------------------------

set mem_files [lsort [glob -nocomplain -directory $SRC_DIR *.mem]]

foreach mem_file $mem_files {
    set dst_file [file join $PROJECT_SRC_DIR [file tail $mem_file]]
    file copy -force $mem_file $dst_file

    puts "Copy memory file only: $dst_file"
}

# -------------------------
# ADD CONSTRAINT FILES
# -------------------------

set ucf_files [lsort [glob -nocomplain -directory $UCF_DIR *.ucf]]

foreach ucf_file $ucf_files {
    set dst_file [file join $PROJECT_UCF_DIR [file tail $ucf_file]]
    file copy -force $ucf_file $dst_file

    puts "Add constraint file: $dst_file"
    xfile add $dst_file
}

# -------------------------
# SET TOP MODULE
# -------------------------

puts "Set top module: $TOP_MODULE"

project set top $TOP_MODULE
project set "Implementation Top" $TOP_MODULE
project set "Implementation Top Instance Path" "/$TOP_MODULE"

# -------------------------
# SAVE PROJECT
# -------------------------

project save
project close

puts "ISE project created successfully."