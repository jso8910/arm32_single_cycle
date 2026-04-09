set all_files [glob -nocomplain ../*.v]
set filtered_files [lsearch -all -inline -not $all_files "core_tb.v"]

read_hdl -sv $all_files
set_db library /vol/ece303/genus_tutorial/NangateOpenCellLibrary_typical.lib
set_db lef_library /vol/ece303/genus_tutorial/NangateOpenCellLibrary.lef

elaborate arm32_core
current_design arm32_core

read_sdc ../arm32_core.sdc

syn_generic
syn_map
syn_opt

report_timing > timing.rpt
report_area > area.rpt
report_power > power.rpt
report_qor > qor.rpt

write_hdl > arm32_core_syn.v
write_sdc > constraints_output.sdc
exit
