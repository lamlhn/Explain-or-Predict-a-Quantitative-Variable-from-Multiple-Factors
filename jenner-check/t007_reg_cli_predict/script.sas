/* Adapted from SAE.sas: the original PROC IMPORT reads
   "TAB_NBA_Final.xlsx" (the author's own cleaned/exported TAB_NBA_Final,
   re-imported as a small prediction shortlist) from a Windows/SAS-Studio
   path that isn't in the repo. This bundle substitutes a small inline
   DATALINES table in the same shape and with Salaire already numeric
   (as it is by this point in the author's pipeline, post-cleaning), then
   runs the author's own transform + CLI-prediction logic unmodified. */

DATA work.TAB_PREVI;
    INPUT Player $ Salaire Age PTS W Min FP;
    DATALINES;
Franz_Wagner 9072410 22 19.7 41 32.1 38.4
Paolo_Banchero 11227440 21 22.6 25 33.8 41.9
Victor_Wembanyama 13088190 20 21.4 18 29.8 45.2
Chet_Holmgren 9585300 21 16.5 31 29.4 39.1
Anthony_Edwards 13534120 22 25.9 56 35.1 44.6
;
RUN;

/* 1. Transformation de la variable dependante : racine carree du salaire */
DATA work.TAB_PREVI;
    SET work.TAB_PREVI;
    Racine_Salaire = sqrt(Salaire);
    Ln_Salaire = log(Salaire);
RUN;

/* Regression avec la variable transformee : Racine_Salaire ~ PTS */
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
