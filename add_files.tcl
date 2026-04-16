# add_files.tcl
# Добавляет файлы в существующий проект Vivado

set project_name "FPGA_CW_6sem"
set project_dir  "."

# Открыть проект (если не открыт)
open_project "$project_dir/$project_name.xpr"

# Пути к каталогам
set src_dir     "$project_dir/${project_name}.srcs/sources_1"
set sim_dir     "$project_dir/${project_name}.srcs/sim_1"
set constr_dir  "$project_dir/${project_name}.srcs/constrs_1"

# -----------------------------
# Sources (sources_1)
# -----------------------------
if {[file exists $src_dir]} {
    set src_files [concat \
        [glob -nocomplain -directory $src_dir -types f *.v] \
        [glob -nocomplain -directory $src_dir -types f *.sv] \
        [glob -nocomplain -directory $src_dir -types f *.vhd] \
        [glob -nocomplain -directory $src_dir -types f *.vhdl] \
    ]

    if {[llength $src_files] > 0} {
        add_files -fileset sources_1 $src_files
        puts "Added source files"
    }
}

# -----------------------------
# Simulation (sim_1)
# -----------------------------
if {[file exists $sim_dir]} {
    set sim_files [concat \
        [glob -nocomplain -directory $sim_dir -types f *.v] \
        [glob -nocomplain -directory $sim_dir -types f *.sv] \
        [glob -nocomplain -directory $sim_dir -types f *.vhd] \
        [glob -nocomplain -directory $sim_dir -types f *.vhdl] \
    ]

    if {[llength $sim_files] > 0} {
        add_files -fileset sim_1 $sim_files
        puts "Added simulation files"
    }
}

# -----------------------------
# Constraints (constrs_1)
# -----------------------------
if {[file exists $constr_dir]} {
    set constr_files [glob -nocomplain -directory $constr_dir -types f *.xdc]

    if {[llength $constr_files] > 0} {
        add_files -fileset constrs_1 $constr_files
        puts "Added constraints"
    }
}

# Обновить порядок компиляции
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

# Сохранить проект
save_project

puts "Files successfully added to filesets"