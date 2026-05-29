CREATE OR REPLACE PROCEDURE SENIOR.SP_HASH_STOREMATE(P_SERVICE IN VARCHAR2,
                                              P_JSON    IN CLOB) AS
BEGIN
  IF P_SERVICE = 'storemate-collaborators' THEN
    -- Reakuza a atualização da TB_STOREMATE_COLLABORATORS_HASH para controle dos colaboradores já enviados
    MERGE INTO TB_STOREMATE_COLLABORATORS_HASH SCH
    USING (SELECT DISTINCT JT.DOCUMENT,
                  CAST(STANDARD_HASH(JT.DOCUMENT || JT.NAME || JT.ID_CENTER ||
                                     JT.COST_CENTER || JT.OFFICE ||
                                     JT.STATUS,
                                     'SHA512') AS VARCHAR2(512)) AS HASH
             FROM JSON_TABLE(P_JSON,
                             '$[*]'
                             COLUMNS(DOCUMENT VARCHAR2 PATH '$.DOCUMENT',
                                     NAME VARCHAR2 PATH '$.NAME',
                                     ID_CENTER INTEGER PATH '$.ID_CENTER',
                                     COST_CENTER INTEGER PATH '$.COST_CENTER',
                                     OFFICE VARCHAR2 PATH '$.OFFICE',
                                     STATUS VARCHAR2 PATH '$.STATUS')) JT) MG
    ON (SCH.DOCUMENT = MG.DOCUMENT)
    WHEN MATCHED THEN
      UPDATE SET HASH = MG.HASH, DT_GRAVACAO = SYSDATE
    WHEN NOT MATCHED THEN
      INSERT (DOCUMENT, HASH, DT_GRAVACAO) VALUES (MG.DOCUMENT, MG.HASH, SYSDATE);
    COMMIT;
  END IF;
END;
