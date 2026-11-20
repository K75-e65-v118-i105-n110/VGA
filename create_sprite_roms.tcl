set project_dir [file dirname [file normalize [info script]]]
set project_file [file join $project_dir homework_4.xpr]
set coe_dir [file join $project_dir photo_process]
set ip_dir [file join $project_dir homework_4.srcs sources_1 ip]

open_project $project_file

foreach coe_file [lsort [glob -nocomplain -directory $coe_dir *.coe]] {
    set module_name [file rootname [file tail $coe_file]]
    set ip [get_ips -quiet $module_name]
    if {[llength $ip] == 0} {
        create_ip -name blk_mem_gen -vendor xilinx.com -library ip \
            -version 8.4 -module_name $module_name -dir $ip_dir

        set ip [get_ips $module_name]
        set_property -dict [list \
            CONFIG.Memory_Type {Single_Port_ROM} \
            CONFIG.Write_Width_A {12} \
            CONFIG.Write_Depth_A {400} \
            CONFIG.Read_Width_A {12} \
            CONFIG.Enable_A {Use_ENA_Pin} \
            CONFIG.Load_Init_File {true} \
            CONFIG.Coe_File $coe_file \
            CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
        ] $ip

        generate_target all $ip
        puts "Created ROM IP $module_name from [file tail $coe_file]"
    } else {
        puts "Found existing ROM IP $module_name"
    }

    if {[llength [get_filesets -quiet $module_name]] == 0} {
        create_fileset -blockset -define_from $module_name $module_name
        puts "Added $module_name to IP Sources"
    }
}

update_compile_order -fileset sources_1
puts "Registered ROM IPs: [llength [get_ips]]"
puts "Registered block source sets: [llength [get_filesets -filter {FILESET_TYPE == BlockSrcs}]]"

set runs_to_launch {}
foreach ip [get_ips] {
    if {$ip eq "body_left_right"} {
        continue
    }

    set run_name "${ip}_synth_1"
    if {[llength [get_runs -quiet $run_name]] == 0} {
        error "Missing out-of-context synthesis run $run_name"
    }
    set status [get_property STATUS [get_runs $run_name]]
    if {[string first "Complete" $status] < 0} {
        lappend runs_to_launch $run_name
    }
}

if {[llength $runs_to_launch] > 0} {
    launch_runs $runs_to_launch -jobs 4
    foreach run_name $runs_to_launch {
        wait_on_run $run_name
        set status [get_property STATUS [get_runs $run_name]]
        puts "$run_name: $status"
        if {[string first "Complete" $status] < 0} {
            error "Out-of-context synthesis did not complete successfully: $run_name ($status)"
        }
    }
}

close_project
