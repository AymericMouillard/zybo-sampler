Organisation du répertoire:
	.
	├── arduino 		-> Programmes Arduino pour les tests d'échantillonnages 
	├── minimal			-> Emplacement contenant le projet Vivado complet après execution de create.tcl
	├── petalinux		-> Contient les fichiers nécessaire à l'implantation d'un petalinux pouvant acceder à l'IP d'échantillonnage
	├── rbtx			-> Emplacement contenant le projet Vivado du bloc d'échantillonnage après l'execution de create.tcl
	├── soft			-> Programmes baremetal pour les tests d'échantillonnages
	├── vhdl			-> Sources du bloc d'échantillonnage ainsi que les tests benchs
	└── vivado			-> Fichiers de configuration pour les projets Vivado

Scripts create*.tcl:
	utilisez vivado TCL pour lancer ces scripts à partir du répertoire contenant le fichier README que vous liez actuellment.
	Ils créeront, pour la version de vivado correspondante, les projets nécessaire à l'implantation de notre travail.
