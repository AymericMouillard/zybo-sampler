circbuf_sync.vhd		-> 	FIFO d'origne
Makefile				-> 	make = analyse/elaboration et lancement de test benchs
rbtx_sampler.vhd		-> 	IP principale qui remplace sample.vhd
rb_tx_v1_0_M00_AXI.vhd	-> 	Maître AXI d'origine, lit les données sur la fifo et
							les écris dans la RAM à l'@ voulue
rb_tx_v1_0_S00_AXI.vhd	-> 	Esclave AXI d'origine modifié: il permet la 
							configuration de la fréquence d'échantillonnage,
							la configuration du signal à échantillonner
							du mode de trigger et l'extraction des flags d'erreurs.
rb_tx_v1_0.vhd			-> 	Wrapper
sample.vhd				-> 	Générateur de valeur d'origine
tb_rbtx_clkdiv.vhd		-> 	Test de la division de la fréquance d'échantillonnage
tb_rbtx_errs.vhd		-> 	Test sur la génération des flags d'erreurs
tb_rbtx_sampler01.vhd	-> 	Test d'échantillonnage sur toutes les valeurs de validation*
tb_rbtx_sampler.vhd		-> 	Test du pilotage de l'IP d'échantillonnage par l'extérieur
tb_rbtx_trigger0.vhd	-> 	Test du mode de trigger de l'IP d'échantillonnage
testtools.vhd			-> 	Utilitaires d'affichage de message de tests
waves					->	Dossier contenant les résultats de la simulation

valeur de validation* 	->	valeurs déterminées dans le plan de validation
