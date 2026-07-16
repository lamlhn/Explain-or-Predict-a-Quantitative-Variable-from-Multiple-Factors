/* Adapted from SAE.sas: original PROC IMPORT reads two Excel workbooks
   ("Salaires joueurs NBA.xlsx" and "Statistiques joueurs NBA.xlsx") from a
   Windows path (D:\BUT2 - EMS\...) and a SAS Studio path
   (/home/u64049984/sasuser.v94/...). Neither file ships in the repo, so this
   bundle substitutes two small inline DATALINES tables with the same shape
   (Player + Salaire text-with-commas; Player + game stats), then runs the
   author's own cleaning / sort / merge logic unmodified. */

DATA work.TAB_Player;
    INFILE DATALINES DLM='|' DSD;
    INPUT Player $ Salaire :$12.;
    DATALINES;
LeBron_James|20,966,978
Stephen_Curry|38,379,473
Kevin_Durant|35,530,848
Giannis_Antetokounmpo|28,771,977
Nikola_Jokic|20,194,526
Joel_Embiid|39,059,817
Luka_Doncic|24,576,977
Jayson_Tatum|23,903,149
Damian_Lillard|22,031,635
Devin_Booker|36,937,388
;
RUN;

DATA work.TAB_Stat;
    INFILE DATALINES DLM='|' DSD;
    INPUT Player $ PTS REB AST;
    DATALINES;
LeBron_James|27.4|7.3|6.8
Stephen_Curry|31.1|8.3|10.3
Kevin_Durant|29.3|9.1|2.6
Giannis_Antetokounmpo|20.0|9.4|3.2
Nikola_Jokic|12.9|8.9|10.3
Joel_Embiid|31.1|7.8|7.2
Luka_Doncic|16.8|7.4|10.0
Jayson_Tatum|17.0|3.4|2.3
Damian_Lillard|15.8|6.1|5.4
Karl_Anthony_Towns|25.2|10.1|4.8
;
RUN;

/* Nettoyage de la table TAB_Player : convertir le salaire (texte avec virgules) en numerique */
DATA work.TAB_Player_CLEAN;
    SET work.TAB_Player;
    SALAIRE_NUM = INPUT(Salaire, COMMA12.);
    DROP Salaire;
    RENAME SALAIRE_NUM = Salaire;
RUN;

/* Verification de la structure des tables nettoyees */
PROC CONTENTS DATA=work.TAB_Player_CLEAN;
RUN;

PROC CONTENTS DATA=work.TAB_Stat;
RUN;

/* Trier les tables par nom de joueur pour pouvoir les fusionner correctement */
PROC SORT DATA=work.TAB_Player_CLEAN OUT=work.TAB_Player_Sorted;
    BY Player;
RUN;

PROC SORT DATA=work.TAB_Stat OUT=work.TAB_Stat_Sorted;
    BY Player;
RUN;

/* Fusionner les deux tables par le nom du joueur */
DATA work.TAB_NBA_Final work.TAB_NBA_Erreurs;
    MERGE work.TAB_Player_Sorted(IN=a) work.TAB_Stat_Sorted(IN=b);
    BY Player;

    /* Conserver les lignes ou le joueur existe dans les deux tables */
    IF a AND b THEN OUTPUT work.TAB_NBA_Final;

    /* Conserver les lignes ou le joueur n'existe que dans une seule table (erreurs) */
    IF (a AND NOT b) OR (NOT a AND b) THEN OUTPUT work.TAB_NBA_Erreurs;
RUN;

PROC PRINT DATA=work.TAB_NBA_Final;
RUN;

PROC PRINT DATA=work.TAB_NBA_Erreurs;
RUN;
