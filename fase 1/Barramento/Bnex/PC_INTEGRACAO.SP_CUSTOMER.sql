CREATE OR REPLACE PACKAGE BODY BNEX.PC_INTEGRACAO IS

  PROCEDURE SP_INTEGRA(PN_TYPE      IN TB_JSON.TP_INTEGRATION%TYPE,
                       PN_JSON      IN TB_JSON.JSON%TYPE,
                       PN_PROCESSED IN TB_JSON.DT_PROCESSED%TYPE,
                       PN_ID        IN TB_JSON.ID%TYPE) AS
  BEGIN
    IF PN_PROCESSED IS NULL THEN
      IF PN_TYPE = 'SALES' THEN
        SP_SALES(PN_JSON, PN_ID);
      ELSIF PN_TYPE = 'CUSTOMER' THEN
        SP_CUSTOMER(PN_JSON, PN_ID);
      ELSIF PN_TYPE = 'UPDATE_CUSTOMER' THEN
        SP_UPDATE_CUSTOMER(PN_JSON, PN_ID);
      END IF;
    END IF;
  END SP_INTEGRA;
  --=============================================================================
  --SALES--
  --=============================================================================
  PROCEDURE SP_SALES(PN_JSON IN TB_JSON.JSON%TYPE,
                     PN_ID   IN TB_JSON.ID%TYPE) AS
  BEGIN
    MERGE INTO TB_SALES_INTEGRATION SI
    USING (SELECT J.ID_MOVIMENTO,
                  J.HASH_CONTROLE,
                  X.CODIGORETORNO,
                  X.MSGRETORNO
             FROM JSON_TABLE((PN_JSON),
                             '$[*]' COLUMNS(ID_MOVIMENTO INTEGER PATH
                                     '$.id_movimento',
                                     HASH_CONTROLE VARCHAR(254) PATH
                                     '$.hash_controle',
                                     XML_DATA CLOB PATH '$.retorno')) J,
                  XMLTABLE(XMLNAMESPACES('http://schemas.xmlsoap.org/soap/envelope/' AS "S",
                                         'http://ws.integrador.gs.com.br/' AS
                                         "ns2"),
                           '/S:Envelope/S:Body/ns2:setNotificaVendaResponse/return'
                           PASSING XMLTYPE(J.XML_DATA) COLUMNS CODIGORETORNO
                           NUMBER PATH 'codigoretorno',
                           MSGRETORNO VARCHAR2(4000) PATH 'msgretorno') X) Z
    ON (Z.ID_MOVIMENTO = SI.ID_MOVIMENTO)
    WHEN MATCHED THEN
      UPDATE
         SET SI.CODERETORNO    = Z.CODIGORETORNO,
             SI.MESSAGERETORNO = Z.MSGRETORNO,
             SI.DT_UPDATED     = SYSDATE
    WHEN NOT MATCHED THEN
      INSERT
        (ID_MOVIMENTO, HASH, DT_UPDATED, CODERETORNO, MESSAGERETORNO)
      VALUES
        (Z.ID_MOVIMENTO,
         Z.HASH_CONTROLE,
         SYSDATE,
         Z.CODIGORETORNO,
         Z.MSGRETORNO);
  
    UPDATE TB_JSON
       SET DT_PROCESSED = SYSDATE
     WHERE TP_INTEGRATION = 'SALES'
       AND DT_PROCESSED IS NULL
       AND ID = PN_ID;
  
    COMMIT;
  END SP_SALES;
  --=============================================================================
  --CUSTOMER--
  --=============================================================================
  PROCEDURE SP_CUSTOMER(PN_JSON IN TB_JSON.JSON%TYPE,
                        PN_ID   IN TB_JSON.ID%TYPE) AS
  BEGIN
    MERGE INTO TB_CUSTOMER_INTEGRATION C
    USING (SELECT J.N_DOC, MAX(J.HASH) HASH, MAX(J.RETORNO) RETORNO
             FROM JSON_TABLE(PN_JSON,
                             '$[*]'
                             COLUMNS(N_DOC VARCHAR2 PATH '$.cpfCnpj',
                                     HASH VARCHAR2 PATH '$.hash_controle',
                                     RETORNO VARCHAR2 PATH '$.retorno')) J
            GROUP BY J.N_DOC) X
    ON (C.N_DOC = X.N_DOC)
    WHEN MATCHED THEN
      UPDATE
         SET C.HASH = X.HASH, C.DT_UPDATED = SYSDATE, C.RETORNO = X.RETORNO
    WHEN NOT MATCHED THEN
      INSERT
        (C.N_DOC, C.HASH, C.DT_UPDATED, RETORNO)
      VALUES
        (X.N_DOC, X.HASH, SYSDATE, X.RETORNO);
  
    UPDATE TB_JSON
       SET DT_PROCESSED = SYSDATE
     WHERE TP_INTEGRATION = 'CUSTOMER'
       AND DT_PROCESSED IS NULL
       AND ID = PN_ID;
  
    COMMIT;
  
  END SP_CUSTOMER;
  --=============================================================================
  --CUSTOMER--
  --=============================================================================
  PROCEDURE SP_UPDATE_CUSTOMER(PN_JSON IN TB_JSON.JSON%TYPE,
                               PN_ID   IN TB_JSON.ID%TYPE) AS
  BEGIN
    MERGE INTO TB_UPDATE_CUSTOMER_INTEGRATION CI
    USING (
      WITH CTE AS
       (SELECT SISTEMAS.FC_GET_IDPESSOA@PAGUEMENOS(JT.CPF) AS ID_PESSOA,
               CASE
                 WHEN JT.ACEITEEMAIL = 'true' THEN
                  'N'
                 ELSE
                  'S'
               END AS ACEITEEMAIL,
               CASE
                 WHEN JT.ACEITESMS = 'true' THEN
                  'N'
                 ELSE
                  'S'
               END AS ACEITESMS,
               CASE
                 WHEN JT.ACEITEPUSH = 'true' THEN
                  'N'
                 ELSE
                  'S'
               END AS ACEITEPUSH,
               ROW_NUMBER() OVER(PARTITION BY SISTEMAS.FC_GET_IDPESSOA@PAGUEMENOS(JT.CPF) ORDER BY TO_DATE(JT.DATAALTERACAO, 'DD-MM-YYYY HH24:MI:SS') DESC) AS RN
          FROM JSON_TABLE(PN_JSON,
                          '$[*]'
                          COLUMNS(ACEITEEMAIL VARCHAR2(5) PATH
                                  '$.aceiteEmail',
                                  ACEITEPUSH VARCHAR2(5) PATH '$.aceitePush',
                                  ACEITESMS VARCHAR2(5) PATH '$.aceiteSms',
                                  CPF VARCHAR2(20) PATH '$.cpf',
                                  DATAALTERACAO VARCHAR2(20) PATH
                                  '$.dataalteracao')) JT)
      SELECT ID_PESSOA, ACEITEEMAIL, ACEITESMS, ACEITEPUSH
        FROM CTE
       WHERE RN = 1
         AND ID_PESSOA IS NOT NULL) X ON (CI.ID_PESSOA = X.ID_PESSOA) WHEN MATCHED THEN
        UPDATE
           SET CI.ACEITEEMAIL = X.ACEITEEMAIL,
               CI.ACEITESMS   = X.ACEITESMS,
               CI.ACEITEPUSH  = X.ACEITEPUSH,
               CI.DT_UPDATE   = SYSDATE,
               CI.UPDATED     = 'N'
      WHEN NOT MATCHED THEN
        INSERT
          (CI.ID_PESSOA,
           CI.ACEITEEMAIL,
           CI.ACEITESMS,
           CI.ACEITEPUSH,
           CI.UPDATED)
        VALUES
          (X.ID_PESSOA, X.ACEITEEMAIL, X.ACEITESMS, X.ACEITEPUSH, 'N');
  
    UPDATE TB_JSON
       SET DT_PROCESSED = SYSDATE
     WHERE TP_INTEGRATION = 'UPDATE_CUSTOMER'
       AND DT_PROCESSED IS NULL
       AND ID = PN_ID;
    COMMIT;
  
  END SP_UPDATE_CUSTOMER;
  --=============================================================================
END PC_INTEGRACAO;
