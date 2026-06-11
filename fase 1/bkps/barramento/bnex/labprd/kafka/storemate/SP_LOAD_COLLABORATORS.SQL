CREATE OR REPLACE PROCEDURE STOREMATE.SP_LOAD_COLLABORATORS(ID_INTEGRATION IN INTEGER) AS

  V_STATUS TB_INTEGRATIONS.STATUS%TYPE;
  V_ERROR  TB_INTEGRATIONS.ERROR%TYPE;

BEGIN

  -- Realiza atualização dos dados na TB_COLLABORATOS
  MERGE INTO TB_COLLABORATORS C
  USING (SELECT X.DOCUMENT,
                X.NAME,
                X.ID_CENTER,
                X.COST_CENTER,
                X.OFFICE,
                X.STATUS
           FROM (SELECT JT.DOCUMENT,
                        JT.NAME,
                        JT.ID_CENTER,
                        CC.ID AS COST_CENTER,
                        JT.OFFICE,
                        JT.STATUS,
                        ROW_NUMBER() OVER(PARTITION BY JT.DOCUMENT ORDER BY JT.DOCUMENT) AS RN
                   FROM JSON_TABLE((SELECT I.JSON
                                     FROM TB_INTEGRATIONS I
                                    WHERE I.ID = ID_INTEGRATION),
                                   '$[*]'
                                   COLUMNS(DOCUMENT INTEGER PATH '$.DOCUMENT',
                                           NAME VARCHAR2 PATH '$.NAME',
                                           ID_CENTER INTEGER PATH '$.ID_CENTER',
                                           COST_CENTER INTEGER PATH
                                           '$.COST_CENTER',
                                           OFFICE VARCHAR2 PATH '$.OFFICE',
                                           STATUS VARCHAR2 PATH '$.STATUS')) JT
                  INNER JOIN TB_COST_CENTER CC
                     ON CC.INTERNAL_CODE = JT.COST_CENTER) X
          WHERE X.RN = 1) MG
  ON (C.DOCUMENT = MG.DOCUMENT)
  WHEN NOT MATCHED THEN
    INSERT
      (DOCUMENT, NAME, ID_CENTER, ID_COST_CENTER, OFFICE, STATUS, ORIGIN)
    VALUES
      (MG.DOCUMENT,
       MG.NAME,
       MG.ID_CENTER,
       MG.COST_CENTER,
       MG.OFFICE,
       MG.STATUS,
       'INTEGRATION')
  WHEN MATCHED THEN
    UPDATE
       SET NAME           = MG.NAME,
           ID_CENTER      = MG.ID_CENTER,
           ID_COST_CENTER = MG.COST_CENTER,
           OFFICE         = MG.OFFICE,
           STATUS         = MG.STATUS;
  COMMIT;

  -- Alimenta variáveis para atualização da linha integrada
  V_STATUS := 'I';
  V_ERROR  := '';
  -- Atualiza linha da integração TB_INTEGRATIONS
  UPDATE TB_INTEGRATIONS TI
     SET STATUS = V_STATUS, DT_UPDATE = SYSDATE, ERROR = V_ERROR
   WHERE TI.ID = ID_INTEGRATION;
  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    V_STATUS := 'E';
    V_ERROR  := SQLERRM;
    -- Atualiza linha da integração TB_INTEGRATIONS
    UPDATE TB_INTEGRATIONS TI
       SET STATUS = V_STATUS, DT_UPDATE = SYSDATE, ERROR = V_ERROR
     WHERE TI.ID = ID_INTEGRATION;
    COMMIT;
END;
