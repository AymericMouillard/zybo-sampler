###############################################################################
#	Script de création des projets Vivado POUR LA VERSION 2015.2
###############################################################################
#créaction de l'IP d'échantillonnage
cd rbtx
source create_rbtx.tcl
#création du design FPGA
cd ../minimal
source create_minimal_2015_2.tcl
cd ..
