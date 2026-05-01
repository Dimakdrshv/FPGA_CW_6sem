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
set SIM_DIR [file join $ROOT_DIR "files" "simulations"]
set UCF_DIR [file join $ROOT_DIR "files" "constraints"]

set PROJECT_DIR [file join $ROOT_DIR $PROJECT_NAME]

puts "ROOT_DIR    = $ROOT_DIR"
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
set PROJECT_SIM_DIR [file join $PROJECT_DIR "simulations"]
set PROJECT_UCF_DIR [file join $PROJECT_DIR "constraints"]

file mkdir $PROJECT_SRC_DIR
file mkdir $PROJECT_SIM_DIR
file mkdir $PROJECT_UCF_DIR

# -------------------------
# ADD SOURCE FILES (.v)
# -------------------------
foreach src_file [glob -nocomplain -directory $SRC_DIR *.v] {
    set dst_file [file join $PROJECT_SRC_DIR [file tail $src_file]]
    file copy -force $src_file $dst_file

    puts "Add source: $dst_file"
    xfile add $dst_file
}

# -------------------------
# ADD MEMORY FILES (.mem)
# -------------------------
foreach mem_file [glob -nocomplain -directory $SRC_DIR *.mem] {
    set dst_file [file join $PROJECT_SRC_DIR [file tail $mem_file]]
    file copy -force $mem_file $dst_file

    puts "Add memory: $dst_file"
    xfile add $dst_file
}

# -------------------------
# ADD SIMULATION FILES (.v)
# -------------------------
foreach sim_file [glob -nocomplain -directory $SIM_DIR *.v] {
    set dst_file [file join $PROJECT_SIM_DIR [file tail $sim_file]]
    file copy -force $sim_file $dst_file

    puts "Add simulation: $dst_file"
    xfile add $dst_file
}

# -------------------------
# ADD CONSTRAINTS (.ucf)
# -------------------------
foreach ucf_file [glob -nocomplain -directory $UCF_DIR *.ucf] {
    set dst_file [file join $PROJECT_UCF_DIR [file tail $ucf_file]]
    file copy -force $ucf_file $dst_file

    puts "Add constraint: $dst_file"
    xfile add $dst_file
}

project set top $TOP_MODULE

process run "Synthesize - XST"
process run "Implement Design"
process run "Generate Programming File"

project save
project close

puts "ISE project created successfully."