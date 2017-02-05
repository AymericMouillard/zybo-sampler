###############################################################################
#	Script de création du design FPGA mettant en oeuvre l'IP déchantillonnage
#	VERSION 2015.2
###############################################################################
create_project minimal . -part xc7z010clg400-1
set_property board_part digilentinc.com:zybo:part0:1.0 [current_project]
#ajout du repo contenant l'IP d'échantillonnage
set_property  ip_repo_paths  ../rbtx [current_project]
update_ip_catalog

#création du design
source ../vivado/design_1_2015_2.tcl

set design_name [get_bd_designs]
add_files -norecurse [make_wrapper -files [get_files $design_name.bd] -top -force]

set obj [get_filesets sources_1]
set_property "top" "${design_name}_wrapper" $obj

#Génération des contraintes
if {[string equal [get_filesets -quiet constrs_1] ""]} {
  create_fileset -constrset constrs_1
}
add_files -fileset constrs_1 -quiet ../vivado/constraints
