file mkdir "../profiling"
file mkdir "../outputs"

set all_files [glob -nocomplain ../*.v ../*.sv]

set filtered_files {}
foreach file $all_files {
    set filename [file tail $file]

    if {$filename ni {
        arraysort_tb.v
        arraysum_tb.v
        binsearch_tb.v
        matmul_tb.v
        strcmp_tb.v
        NangateOpenCellLibrary.v
    }} {
        lappend filtered_files $file
    }
}

puts "RTL files being synthesized:"
puts [join $filtered_files "\n"]

set_db library /vol/ece303/genus_tutorial/NangateOpenCellLibrary_typical.lib
set_db lef_library /vol/ece303/genus_tutorial/NangateOpenCellLibrary.lef

foreach top_module {arm32_core regfile} {
    read_hdl -sv $filtered_files
    elaborate $top_module
    current_design $top_module

    read_sdc ../${top_module}.sdc

    syn_generic
    syn_map
    syn_opt

    report_timing > ../profiling/${top_module}_timing.rpt
    report_area > ../profiling/${top_module}_area.rpt
    report_power > ../profiling/${top_module}_power.rpt
    report_qor > ../profiling/${top_module}_qor.rpt

    write_hdl > ../outputs/${top_module}_syn.v
    write_sdc > ../outputs/${top_module}_constraints_output.sdc

    # Clear the design from memory so the next iteration starts fresh
    delete_obj [get_designs $top_module]
}
exit
