file mkdir "../profiling"
file mkdir "../outputs"

set all_files [glob -nocomplain ../*.v ../*.sv]
set core_files [lsort [glob -nocomplain ../cores/*.v ../cores/*.sv]]

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

proc get_top_module {hdl_file} {
    set file_handle [open $hdl_file r]

    while {[gets $file_handle line] >= 0} {
        if {[regexp {^\s*module\s+([A-Za-z_][A-Za-z0-9_$]*)} $line -> module_name]} {
            close $file_handle
            return $module_name
        }
    }

    close $file_handle
    error "No module declaration found in $hdl_file"
}

set synthesis_targets [list \
    [list arm32_core $filtered_files ../arm32_core.sdc] \
    [list regfile $filtered_files ../regfile.sdc] \
]

foreach core_file $core_files {
    set top_module [get_top_module $core_file]
    lappend synthesis_targets [list $top_module [list $core_file] ../arm32_core.sdc]
}

puts "Synthesis targets:"
foreach target $synthesis_targets {
    lassign $target top_module source_files sdc_file
    puts "$top_module:"
    puts "  RTL: [join $source_files {, }]"
    puts "  SDC: $sdc_file"
}

set_db library /vol/ece303/genus_tutorial/NangateOpenCellLibrary_typical.lib
set_db lef_library /vol/ece303/genus_tutorial/NangateOpenCellLibrary.lef

foreach target $synthesis_targets {
    lassign $target top_module source_files sdc_file

    read_hdl -sv $source_files
    elaborate $top_module
    current_design $top_module

    read_sdc $sdc_file

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
