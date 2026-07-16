/* Adapted from SAE.sas: the author's stepwise / forward / backward
   PROC REG model-selection block on Ln_Salaire, run unmodified against a
   small inline sample shaped like the author's merged TAB_NBA_Final. The
   predictor list is a subset of the author's Age--Plus_minus range so the
   selection procedures stay well-posed on this sample size; the technique
   (stepwise / forward / backward with slentry/slstay) is exactly the
   author's. */

DATA work.TAB_NBA_Final;
    INFILE DATALINES DLM=' ' DSD;
    INPUT Player $ Classement Age GP W L Min PTS FGM FGA FG_ _3PM _3PA _3P_
          FTM FTA FT_ OREB DREB REB AST TOV STL BLK PF FP DD2 TD3 Plus_minus Salaire :$12.;
    DATALINES;
LeBron_James 1 24 46 32 14 27.4 14.8 6.9 13.4 51.5 2.7 7.3 37.0 1.2 1.8 66.7 0.9 6.4 7.3 6.8 3.6 1.7 1.2 2.1 38.9 17 0 5.1 20,966,978
Stephen_Curry 2 34 66 32 34 26.2 31.1 13.7 31.7 43.2 0.9 2.2 40.9 5.2 6.1 85.2 2.3 6.0 8.3 10.3 2.4 1.4 2.1 2.4 64.6 23 3 4.5 38,379,473
Kevin_Durant 3 28 63 20 43 36.0 29.3 12.8 26.7 47.9 3.8 11.9 31.9 3.5 4.3 81.4 2.2 6.9 9.1 2.6 3.3 1.4 0.8 2.1 47.4 17 8 -1.4 35,530,848
Giannis_Antetokounmpo 4 22 59 17 42 35.3 20.0 9.4 17.4 54.0 2.8 7.3 38.4 2.5 3.2 78.1 2.7 6.7 9.4 3.2 1.7 1.8 1.4 2.7 44.0 27 6 0.3 28,771,977
Nikola_Jokic 5 25 77 46 31 25.3 12.9 6.0 12.0 50.0 3.7 10.6 34.9 1.4 1.9 73.7 3.0 5.9 8.9 10.3 4.0 0.5 1.9 2.6 42.2 34 4 5.2 20,194,526
Joel_Embiid 6 30 72 25 47 30.4 31.1 12.3 27.1 45.4 2.5 7.8 32.1 7.4 8.5 87.1 1.1 6.7 7.8 7.2 1.7 1.8 1.4 2.8 59.2 33 0 3.2 39,059,817
Luka_Doncic 7 24 68 34 34 27.4 16.8 7.0 16.3 42.9 3.4 8.5 40.0 7.8 10.0 78.0 0.6 6.8 7.4 10.0 1.7 1.4 1.6 3.1 48.0 34 3 4.6 24,576,977
Jayson_Tatum 8 32 73 48 25 30.3 17.0 8.0 18.9 42.3 2.7 7.3 37.0 1.1 1.3 84.6 0.5 2.9 3.4 2.3 2.3 1.4 0.8 2.2 28.8 34 2 4.7 23,903,149
Damian_Lillard 9 36 60 45 15 35.3 15.8 7.4 15.5 47.7 2.2 6.2 35.5 6.1 7.5 81.3 3.0 3.1 6.1 5.4 2.3 2.0 0.8 1.6 37.3 28 2 1.1 22,031,635
Devin_Booker 10 28 49 43 6 35.3 29.1 13.5 26.7 50.6 2.7 8.9 30.3 1.7 2.0 85.0 0.9 5.1 6.0 6.1 4.1 2.0 0.6 1.2 49.1 24 4 7.1 36,937,388
Anthony_Davis 11 30 72 50 22 33.3 21.7 9.9 22.1 44.8 0.7 1.8 38.9 1.4 1.9 73.7 0.4 5.6 6.0 9.8 3.0 0.6 1.4 2.9 46.6 4 1 4.1 28,327,612
Kawhi_Leonard 12 24 81 30 51 32.1 12.8 6.0 11.9 50.4 2.8 8.3 33.7 2.8 3.4 82.4 1.1 4.2 5.3 3.1 3.3 1.3 2.3 3.1 31.3 0 7 3.5 19,464,981
Jimmy_Butler 13 24 49 49 0 27.0 17.3 6.7 12.5 53.6 4.0 11.6 34.5 2.1 2.4 87.5 2.2 6.5 8.7 10.4 3.4 0.5 2.1 1.8 47.7 42 1 7.3 24,196,873
Trae_Young 14 24 51 50 1 26.2 17.6 8.0 17.2 46.5 3.2 8.0 40.0 4.5 6.3 71.4 2.8 2.8 5.6 7.4 3.9 0.6 1.0 1.5 36.3 16 2 4.9 24,351,041
Ja_Morant 15 34 80 15 65 25.6 30.9 12.6 28.7 43.9 0.6 1.7 35.3 4.9 6.5 75.4 0.4 4.9 5.3 9.9 4.4 0.6 1.0 2.6 52.5 42 1 0.2 38,289,651
Zion_Williamson 16 34 54 30 24 36.1 31.5 12.6 23.6 53.4 0.6 1.5 40.0 3.3 3.7 89.2 2.5 8.1 10.6 8.9 2.1 1.8 0.4 2.9 62.1 30 3 -1.6 41,057,356
Karl_Anthony_Towns 17 32 64 29 35 27.1 25.2 11.0 24.1 45.6 0.8 2.0 40.0 3.5 4.5 77.8 2.1 8.0 10.1 4.8 1.3 2.0 0.8 2.4 51.6 16 0 -2.7 32,675,691
Bam_Adebayo 18 31 72 53 19 37.8 14.3 5.6 12.6 44.4 0.7 2.0 35.0 4.6 5.4 85.2 2.2 8.6 10.8 8.3 1.9 1.2 2.4 3.0 48.6 39 5 4.0 21,575,876
;
RUN;

/* Nettoyage de la table TAB_Player : convertir le salaire (texte avec virgules) en numerique */
DATA work.TAB_NBA_Final;
    SET work.TAB_NBA_Final;
    SALAIRE_NUM = INPUT(Salaire, COMMA12.);
    DROP Salaire;
    RENAME SALAIRE_NUM = Salaire;
RUN;

DATA work.TAB_NBA_Final;
    SET work.TAB_NBA_Final;
    Ln_Salaire = log(Salaire);
RUN;

/* Stepwise Ln_Salaire ~ Age GP W L Min PTS FGM FGA AST TOV STL BLK PF */
PROC REG DATA=work.TAB_NBA_Final corr;
    MODEL Ln_Salaire = Age GP W L Min PTS FGM FGA AST TOV STL BLK PF
    / selection=stepwise slentry=0.05 slstay=0.05;
RUN;
QUIT;

/* forward */
PROC REG DATA=work.TAB_NBA_Final;
    MODEL Ln_Salaire = Age GP W L Min PTS FGM FGA AST TOV STL BLK PF
        / SELECTION=forward SLENTRY=0.05;
RUN;

/* backward */
PROC REG DATA=work.TAB_NBA_Final;
    MODEL Ln_Salaire = Age GP W L Min PTS FGM FGA AST TOV STL BLK PF
        / SELECTION=backward SLSTAY=0.05;
RUN;
