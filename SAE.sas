/* Importer les donn�es depuis les fichiers Excel */
PROC IMPORT DATAFILE="D:\BUT2 - EMS\S2\SAE modlinearie\SAE\Salaires joueurs NBA.xlsx"
    OUT=TAB_Player DBMS=XLSX replace;
    GETNAMES=YES;
    SHEET=Tab_Player;
RUN;

PROC IMPORT DATAFILE="D:\BUT2 - EMS\S2\SAE modlinearie\SAE\Statistiques joueurs NBA.xlsx"
    OUT=TAB_Stat DBMS=XLSX replace;
    GETNAMES=YES;
    SHEET=Tab_Stat;
RUN;

PROC IMPORT DATAFILE="D:\BUT2 - EMS\S2\SAE modlinearie\SAE\TAB_NBA_Final.xlsx"
    OUT=TAB_PREVI DBMS=XLSX replace;
    GETNAMES=YES;
RUN;


/* Nettoyage de la table TAB_Player : convertir le salaire (texte avec virgules) en num�rique */
DATA work.TAB_Player_CLEAN;
    SET work.TAB_Player;
    SALAIRE_NUM = INPUT(Salaire, COMMA12.);
    DROP Salaire; 
    RENAME SALAIRE_NUM = Salaire; 
RUN;


/* V�rification de la structure des tables nettoy�es */
PROC CONTENTS DATA=work.TAB_Player_CLEAN;
RUN;

PROC CONTENTS DATA=work.TAB_Stat;
RUN;


/* Trier les tables par nom de joueur pour pouvoir les fusionner correctement */
PROC SORT DATA=work.TAB_Player_CLEAN OUT=work.TAB_Player_Sorted ;
    BY Player;
RUN;

PROC SORT DATA=work.TAB_Stat OUT=work.TAB_Stat_Sorted;
    BY Player;
RUN;

/* Fusionner les deux tables par le nom du joueur */
DATA work.TAB_NBA_Final work.TAB_NBA_Erreurs;
    MERGE work.TAB_Player_Sorted(IN=a) work.TAB_Stat_Sorted(IN=b);
    BY Player;

    /* Conserver les lignes o� le joueur existe dans les deux tables */
    IF a AND b THEN OUTPUT work.TAB_NBA_Final;
    
    /* Conserver les lignes o� le joueur n'existe que dans une seule table (erreurs) */
    IF (a AND NOT b) OR (NOT a AND b) THEN OUTPUT work.TAB_NBA_Erreurs;
RUN;

/* Verification des donnees apres fusion */
PROC CONTENTS DATA=work.TAB_NBA_Final;
RUN;


/* Calcul des statistiques descriptives completes */
PROC MEANS DATA=work.TAB_NBA_Final N MEAN MEDIAN STD MIN MAX RANGE Q1 Q3;
    VAR _NUMERIC_;
RUN;

/* Analyse de la distribution des variables num�riques */
PROC UNIVARIATE DATA=work.TAB_NBA_Final;
    VAR _NUMERIC_;
    HISTOGRAM / NORMAL;
    QQPLOT;
RUN;

/* Analyse des variables qualitatives (caract�res) */
PROC FREQ DATA=work.TAB_NBA_Final;
    TABLES _CHARACTER_ / NOCUM MISSING;
RUN;


/* R�gression lin�aire multiple sur toutes les variables explicatives possibles avec s�lection par R� */
PROC REG DATA=work.TAB_NBA_Final ;
    MODEL Salaire = Classement Age GP W L Min PTS FGM FGA FG_ _3PM _3PA _3P_ 
                    FTM FTA FT_ OREB DREB REB AST TOV STL BLK PF FP DD2 TD3 Plus_minus 
                    / selection = rsquare;
    OUTPUT OUT=Correlation R=res;
RUN;
QUIT;


/* R�gression simple : Salaire en fonction de PTS */
PROC REG DATA=work.TAB_NBA_Final;
    MODEL Salaire = PTS/ CLB R INFLUENCE DWPROB;
    OUTPUT OUT=residus_PTS R=res;
RUN;
QUIT;

PROC UNIVARIATE DATA=residus_PTS NORMAL;
    VAR res;
    HISTOGRAM / NORMAL;
RUN;

/* R�gression simple : Salaire en fonction de FGM */
PROC REG DATA=work.TAB_NBA_Final;
    MODEL Salaire = FGM/ CLB R INFLUENCE DWPROB;
    OUTPUT OUT=residus_FGM R=res;
RUN;
QUIT;

proc univariate DATA= residus_FGM NORMAL;
    VAR res;
    HISTOGRAM / NORMAL;
RUN; 


/* 1. Transformation de la variable d�pendante : racine carr�e du salaire */
DATA work.TAB_NBA_Final;
    SET work.TAB_NBA_Final;
    Racine_Salaire = sqrt(Salaire);
	Racine3_Salaire = Salaire**(1/3);
	Ln_Salaire = log(Salaire);
RUN;

/* R�gression avec la variable transform�e : Racine_Salaire ~ PTS */
PROC REG DATA=work.TAB_NBA_Final;
    MODEL Racine_Salaire = PTS / CLB R INFLUENCE DWPROB;
    OUTPUT OUT=residus_racine_salaire R=res;
RUN;
QUIT;

proc univariate DATA= residus_racine_salaire NORMAL;
    VAR res; /* Analyse des r�sidus pour tester la normalit� */
    HISTOGRAM / NORMAL; /* Histogramme des r�sidus avec une courbe normale superpos�e */
RUN; 

/* R�gression avec la variable transform�e : Racine3_Salaire ~ PTS */
PROC REG DATA=work.TAB_NBA_Final;
    MODEL Racine3_Salaire = PTS / CLB R INFLUENCE DWPROB;
    OUTPUT OUT=residus_racine3_salaire R=res;
RUN;
QUIT;

PROC UNIVARIATE DATA=residus_racine3_salaire NORMAL;
    VAR res;
    HISTOGRAM / NORMAL;
RUN;



PROC REG DATA=work.TAB_NBA_Final;
    MODEL Ln_Salaire = Age--Plus_minus  /* Variables quantitatives ind�pendantes de Age � Plus_minus */
    / selection = rsquare;
RUN;

/* Modele racine avec 2 variable age fgm */
PROC REG DATA=work.TAB_NBA_Final corr;
    MODEL Ln_Salaire = W Min / CLB R INFLUENCE DWPROB VIF ;
    OUTPUT OUT=residus_racine_AF R=res_r_AF;
RUN;
QUIT;

PROC UNIVARIATE DATA=residus_racine_AF NORMAL;
    VAR res_r_AF;
    HISTOGRAM / NORMAL;
RUN;

/* Verifier multi variable */
PROC REG DATA=work.TAB_NBA_Final corr;
    MODEL Ln_Salaire = Age--Plus_minus  /* Variables quantitatives ind�pendantes de Age � Plus_minus */
    / selection = rsquare;
RUN;

/* Stepwise Ln_Salire - Age W Min FP*/
PROC REG DATA=work.TAB_NBA_Final corr ;
	MODEL Ln_Salaire = age--Plus_minus 
	/ selection=stepwise slentry=0.05 slstay=0.05;
RUN;
QUIT;

/* racine Age W PTS FT% FP */
PROC REG DATA=work.TAB_NBA_Final corr;
	MODEL Ln_Salaire = Age W FP
		/ CLB R INFLUENCE DWPROB VIF;
	OUTPUT OUT=residus_step R=res_step;
RUN;
QUIT;

PROC UNIVARIATE DATA=residus_step NORMAL;
    VAR res_step;
    HISTOGRAM / NORMAL;
RUN;

/* forward Age L PTS DD2 Plus_minus*/
PROC REG DATA=work.TAB_NBA_Final;
	MODEL Ln_Salaire = age--Plus_minus 
		/ SELECTION=forward SLENTRY=0.05;
RUN;

/* backward Age L PTS FGA FG% FTA FT% TOV DD2 DD2 Plus_minus*/
PROC REG DATA=work.TAB_NBA_Final;
	MODEL Ln_Salaire = age--Plus_minus 
		/ SELECTION=backward SLSTAY=0.05;
RUN;


/* Verifier salaire 5 player*/
/* 1. Transformation de la variable d�pendante : racine carr�e du salaire */
DATA work.TAB_PREVI;
    SET work.TAB_PREVI;
    Racine_Salaire = sqrt(Salaire);
	Ln_Salaire = log(Salaire);
RUN;

/* R�gression avec la variable transform�e : Racine_Salaire ~ PTS */
PROC REG DATA=work.TAB_PREVI;
    MODEL Salaire = Age PTS / CLI;
RUN;
QUIT;

/* */
PROC REG DATA=work.TAB_PREVI;
    MODEL Ln_Salaire = W Min / CLI;
RUN;
QUIT;

/* */
PROC REG DATA=work.TAB_PREVI;
    MODEL Ln_Salaire = Age W FP / CLI;
RUN;
QUIT;



/* Exportation des resultats en PDF */
ODS PDF FILE="D:\BUT2 - EMS\S2\SAE modlinearie\SAE\NOM1_NOM2_Partie2.pdf";
PROC PRINT DATA=work.TAB_NBA_Final;
RUN;
ODS PDF CLOSE;

PROC EXPORT DATA=work.TAB_NBA_Erreurs
            OUTFILE="D:\BUT2 - EMS\S2\SAE modlinearie\SAE\TAB_NBA_Erreurs.xlsx"
            DBMS=XLSX REPLACE;
    SHEET="Erreurs";
RUN;

PROC EXPORT DATA=work.TAB_NBA_Final
            OUTFILE="D:\BUT2 - EMS\S2\SAE modlinearie\SAE\TAB_NBA_Final.xlsx"
            DBMS=XLSX REPLACE;
RUN;


/* Importer fichier Excel */
PROC IMPORT DATAFILE="/home/u64049984/sasuser.v94/SAE_NBA/Salaires joueurs NBA.xlsx"
    OUT=TAB_Player DBMS=XLSX replace;
    GETNAMES=YES;
    SHEET=Tab_Player;
RUN;

PROC IMPORT DATAFILE="/home/u64049984/sasuser.v94/SAE_NBA/Statistiques joueurs NBA.xlsx"
    OUT=TAB_Stat DBMS=XLSX replace;
    GETNAMES=YES;
    SHEET=Tab_Stat;
RUN;

PROC IMPORT DATAFILE="/home/u64049984/sasuser.v94/SAE_NBA/TAB_NBA_Final.xlsx"
    OUT=TAB_PREVI DBMS=XLSX replace;
    GETNAMES=YES;
RUN;


/* Nettoyage de la table TAB_Player : convertir le salaire (texte avec virgules) en num�rique */
DATA work.TAB_Player_CLEAN;
    SET work.TAB_Player;
    SALAIRE_NUM = INPUT(Salaire, COMMA12.);
    DROP Salaire; 
    RENAME SALAIRE_NUM = Salaire; 
RUN;


/* V�rification de la structure des tables nettoy�es */
PROC CONTENTS DATA=work.TAB_Player_CLEAN;
RUN;

PROC CONTENTS DATA=work.TAB_Stat;
RUN;


/* Trier les tables par nom de joueur pour pouvoir les fusionner correctement */
PROC SORT DATA=work.TAB_Player_CLEAN OUT=work.TAB_Player_Sorted ;
    BY Player;
RUN;

PROC SORT DATA=work.TAB_Stat OUT=work.TAB_Stat_Sorted;
    BY Player;
RUN;

/* Fusionner les deux tables par le nom du joueur */
DATA work.TAB_NBA_Final work.TAB_NBA_Erreurs;
    MERGE work.TAB_Player_Sorted(IN=a) work.TAB_Stat_Sorted(IN=b);
    BY Player;

    /* Conserver les lignes o� le joueur existe dans les deux tables */
    IF a AND b THEN OUTPUT work.TAB_NBA_Final;
    
    /* Conserver les lignes o� le joueur n'existe que dans une seule table (erreurs) */
    IF (a AND NOT b) OR (NOT a AND b) THEN OUTPUT work.TAB_NBA_Erreurs;
RUN;

/* Verification des donnees apres fusion */
PROC CONTENTS DATA=work.TAB_NBA_Final;
RUN;


/* Calcul des statistiques descriptives completes */
PROC MEANS DATA=work.TAB_NBA_Final N MEAN MEDIAN STD MIN MAX RANGE Q1 Q3;
    VAR _NUMERIC_;
RUN;

/* Analyse de la distribution des variables num�riques */
PROC UNIVARIATE DATA=work.TAB_NBA_Final;
    VAR _NUMERIC_;
    HISTOGRAM / NORMAL;
    QQPLOT;
RUN;

/* Analyse des variables qualitatives (caract�res) */
PROC FREQ DATA=work.TAB_NBA_Final;
    TABLES _CHARACTER_ / NOCUM MISSING;
RUN;


/* R�gression lin�aire multiple sur toutes les variables explicatives possibles avec s�lection par R� */
PROC REG DATA=work.TAB_NBA_Final ;
    MODEL Salaire = Classement Age GP W L Min PTS FGM FGA FG_percent 3PM 3PA 3P_percent 
                    FTM FTA FT_percent OREB DREB REB AST TOV STL BLK PF FP DD2 TD3 Plus_minus 
                    / selection = rsquare;
    OUTPUT OUT=Correlation R=res;
RUN;
QUIT;


/* R�gression simple : Salaire en fonction de PTS */
PROC REG DATA=work.TAB_NBA_Final;
    MODEL Salaire = PTS/ CLB R INFLUENCE DWPROB;
    OUTPUT OUT=residus_PTS R=res;
RUN;
QUIT;

PROC UNIVARIATE DATA=residus_PTS NORMAL;
    VAR res;
    HISTOGRAM / NORMAL;
RUN;

/* R�gression simple : Salaire en fonction de FGM */
PROC REG DATA=work.TAB_NBA_Final;
    MODEL Salaire = FGM/ CLB R INFLUENCE DWPROB;
    OUTPUT OUT=residus_FGM R=res;
RUN;
QUIT;

proc univariate DATA= residus_FGM NORMAL;
    VAR res;
    HISTOGRAM / NORMAL;
RUN; 






/* 1. Transformation de la variable d�pendante : racine carr�e du salaire */
DATA work.TAB_NBA_Final;
    SET work.TAB_NBA_Final;
    Racine_Salaire = sqrt(Salaire);
	Racine3_Salaire = Salaire**(1/3);
RUN;

/* R�gression avec la variable transform�e : Racine_Salaire ~ PTS */
PROC REG DATA=work.TAB_NBA_Final;
    MODEL Racine_Salaire = PTS / CLB R INFLUENCE DWPROB;
    OUTPUT OUT=residus_racine_salaire R=res;
RUN;
QUIT;

proc univariate DATA= residus_racine_salaire NORMAL;
    VAR res; /* Analyse des r�sidus pour tester la normalit� */
    HISTOGRAM / NORMAL; /* Histogramme des r�sidus avec une courbe normale superpos�e */
RUN; 

/* R�gression avec la variable transform�e : Racine3_Salaire ~ PTS */
PROC REG DATA=work.TAB_NBA_Final;
    MODEL Racine3_Salaire = PTS / CLB R INFLUENCE DWPROB;
    OUTPUT OUT=residus_racine3_salaire R=res;
RUN;
QUIT;

PROC UNIVARIATE DATA=residus_racine3_salaire NORMAL;
    VAR res;
    HISTOGRAM / NORMAL;
RUN;




PROC REG DATA=work.TAB_NBA_Final;
    MODEL Salaire = Age--Plus_minus  /* Variables quantitatives ind�pendantes de Age � Plus_minus */
    / selection = rsquare;
RUN;

PROC REG DATA=work.TAB_NBA_Final corr;
    MODEL Salaire = Age PTS / CLB R INFLUENCE DWPROB VIF ;
    OUTPUT OUT=residus_racine_AP R=res_r_AP;
RUN;
QUIT;

PROC UNIVARIATE DATA=residus_racine_AP NORMAL;
    VAR res_r_AP;
    HISTOGRAM / NORMAL;
RUN;



PROC REG DATA=work.TAB_NBA_Final;
    MODEL Racine_Salaire = Age--Plus_minus  /* Variables quantitatives ind�pendantes de Age � Plus_minus */
    / selection = rsquare;
RUN;

/* Modele racine avec 2 variable age fgm */
PROC REG DATA=work.TAB_NBA_Final corr;
    MODEL Racine_Salaire = Age FP / CLB R INFLUENCE DWPROB VIF ;
    OUTPUT OUT=residus_racine_AFP R=res_r_AFP;
RUN;
QUIT;

PROC UNIVARIATE DATA=residus_racine_AFP NORMAL;
    VAR res_r_AFP;
    HISTOGRAM / NORMAL;
RUN;

PROC REG DATA=work.TAB_NBA_Final;
    MODEL Salaire = Age--Plus_minus  /* Variables quantitatives ind�pendantes de Age � Plus_minus */
    / selection = rsquare;
RUN;

/* Modele racine avec 2 variable age fgm */
PROC REG DATA=work.TAB_NBA_Final corr;
    MODEL Salaire = PTS Plus_minus / CLB R INFLUENCE DWPROB VIF ;
    OUTPUT OUT=residus_racine_AP R=res_r_AP;
RUN;
QUIT;

PROC UNIVARIATE DATA=residus_racine_AP NORMAL;
    VAR res_r_AP;
    HISTOGRAM / NORMAL;
RUN;






/* Verifier multi variable */
PROC REG DATA=work.TAB_NBA_Final corr;
    MODEL Racine_Salaire = Age--Plus_minus  /* Variables quantitatives ind�pendantes de Age � Plus_minus */
    / selection = rsquare;
RUN;

/* Stepwise Ln_Salire - Age W Min FP*/
PROC REG DATA=work.TAB_NBA_Final corr ;
	MODEL Racine_Salaire = age--Plus_minus 
	/ selection=stepwise slentry=0.05 slstay=0.05;
RUN;
QUIT;

/* racine Age W PTS FT% FP */
PROC REG DATA=work.TAB_NBA_Final corr;
	MODEL Racine_Salaire = Age W FT_PERCENT PTS
		/ CLB R INFLUENCE DWPROB VIF;
	OUTPUT OUT=residus_step R=res_step;
RUN;
QUIT;

PROC UNIVARIATE DATA=residus_step NORMAL;
    VAR res_step;
    HISTOGRAM / NORMAL;
RUN;

/* forward Age L PTS DD2 Plus_minus*/
PROC REG DATA=work.TAB_NBA_Final;
	MODEL Racine_Salaire = age--Plus_minus 
		/ SELECTION=forward SLENTRY=0.05;
RUN;

/* backward Age L PTS FGA FG% FTA FT% TOV DD2 DD2 Plus_minus*/
PROC REG DATA=work.TAB_NBA_Final;
	MODEL Racine_Salaire = age--Plus_minus 
		/ SELECTION=backward SLSTAY=0.05;
RUN;


/* Verifier salaire 5 player*/
/* 1. Transformation de la variable d�pendante : racine carr�e du salaire */
DATA work.TAB_PREVI;
    SET work.TAB_PREVI;
    Racine_Salaire = sqrt(Salaire);
	Ln_Salaire = log(Salaire);
RUN;

/* R�gression avec la variable transform�e : Racine_Salaire ~ PTS */
PROC REG DATA=work.TAB_PREVI;
    MODEL Salaire = Age PTS / CLI;
RUN;
QUIT;

/* R�gression avec la variable transform�e : Racine_Salaire ~ PTS */
PROC REG DATA=work.TAB_PREVI;
    MODEL Racine_Salaire = Age PTS / CLI;
RUN;

QUIT;
/* R�gression avec la variable transform�e : Racine_Salaire ~ PTS */
PROC REG DATA=work.TAB_PREVI;
    MODEL Salaire = Age PTS / CLI;
RUN;
QUIT;

/* */
PROC REG DATA=work.TAB_PREVI;
    MODEL Racine_Salaire = Age FP / CLI;
RUN;
QUIT;

/* */
PROC REG DATA=work.TAB_PREVI;
    MODEL Racine_Salaire = Age W PTS FT_PERCENT / CLI;
RUN;
QUIT;


