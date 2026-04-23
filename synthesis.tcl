file mkdir "../profiling"
file mkdir "../outputs"

set all_files [glob -nocomplain ../*.v]
set filtered_files [lsearch -all -inline -not $all_files "core_tb.v"]

read_hdl -sv $all_files
set_db library /vol/ece303/genus_tutorial/NangateOpenCellLibrary_typical.lib
set_db lef_library /vol/ece303/genus_tutorial/NangateOpenCellLibrary.lef

foreach top_module {arm32_core regfile} {
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
}
exit
