CREATE OR REPLACE FUNCTION SISTEMAS.FC_INTEGRA_OCORRENCIA_CRM(P_CPF             IN VARCHAR2, --IN INTEGER,
                                                              P_TIPO_OCORRENCIA IN INTEGER DEFAULT 1,
                                                              P_USER            IN VARCHAR2)
  RETURN VARCHAR IS
  PRAGMA AUTONOMOUS_TRANSACTION;
  V_RETORNO           VARCHAR2(4000);
  V_CHECK             INTEGER := 0;
  V_ERROR             VARCHAR2(4000);
  V_ID_OCORRENCIA     INTEGER := 0;
  V_COUNT_OCORRENCIAS INTEGER := 0;

BEGIN
  /* Data: 10/08/2022
     Autor: Bruno Gritti
     Tarefa: DELY22-60
     Descrição: Realiza o processo de inclusão e todos os passos para integração do BP pelas ocorrências.
  */

  IF (P_TIPO_OCORRENCIA = 1) THEN
    --Realiza a inclusão da ocorrência para dar inicio a integração.
    SELECT COUNT(1)
      INTO V_CHECK
      FROM TB_OCORRENCIA O
     WHERE O.CPF = P_CPF
       AND O.ID_TIPO_OCORRENCIA IN (1, 2, 3)
       AND O.CONTROLE IS NULL;
  
    IF (V_CHECK = 0) THEN
      --Insere a ocorrência para integração
      INSERT INTO TB_OCORRENCIA O
        (O.ID_OCORRENCIA,
         O.CPF,
         O.ID_TIPO_OCORRENCIA,
         O.CONTROLE,
         O.US_INCLUSAO,
         O.DT_INCLUSAO,
         O.DH_INCLUSAO)
      VALUES
        ((SELECT MAX(O.ID_OCORRENCIA) + 1 FROM TB_OCORRENCIA O),
         P_CPF,
         P_TIPO_OCORRENCIA,
         NULL,
         P_USER,
         SYSDATE,
         SYSDATE);
      COMMIT;
      V_RETORNO := 'Ocorrência cadastrada com sucesso.';
      RETURN V_RETORNO;
    ELSE
      --Retorna informando que já existe uma integração em andamento
      V_RETORNO := 'Já existe uma ocorrência de integração para o CPF ' ||
                   P_CPF || ' em andamento!';
      RETURN V_RETORNO;
    END IF;
  ELSIF (P_TIPO_OCORRENCIA = 2) THEN
    --Insere a ocorrência de tipo 2 na tabela e atualiza a ocorrência do tipo 1
    MERGE INTO TB_OCORRENCIA O
    USING (SELECT (MAX(O.ID_OCORRENCIA) + 1) AS ID_OCORRENCIA,
                  P_CPF AS CPF,
                  P_TIPO_OCORRENCIA AS ID_TIPO_OCORRENCIA,
                  NULL AS CONTROLE,
                  'LYNKER' AS US_INCLUSAO,
                  SYSDATE AS DT_INCLUSAO,
                  SYSDATE AS DH_INCLUSAO
             FROM TB_OCORRENCIA O) MG
    ON (O.CPF = MG.CPF AND O.ID_TIPO_OCORRENCIA = MG.ID_TIPO_OCORRENCIA AND NVL(O.CONTROLE, 0) = NVL(MG.CONTROLE, 0))
    WHEN NOT MATCHED THEN
      INSERT
        (O.ID_OCORRENCIA,
         O.CPF,
         O.ID_TIPO_OCORRENCIA,
         O.CONTROLE,
         O.US_INCLUSAO,
         O.DT_INCLUSAO,
         O.DH_INCLUSAO)
      VALUES
        (MG.ID_OCORRENCIA,
         MG.CPF,
         MG.ID_TIPO_OCORRENCIA,
         MG.CONTROLE,
         MG.US_INCLUSAO,
         MG.DT_INCLUSAO,
         MG.DH_INCLUSAO);
    COMMIT;
  
    UPDATE TB_OCORRENCIA O
       SET O.CONTROLE =
           (SELECT O.ID_OCORRENCIA
              FROM TB_OCORRENCIA O
             WHERE O.CPF = P_CPF
               AND O.ID_TIPO_OCORRENCIA = P_TIPO_OCORRENCIA
               AND O.CONTROLE IS NULL)
     WHERE O.CPF = P_CPF
       AND O.ID_TIPO_OCORRENCIA = 1
       AND O.CONTROLE IS NULL;
    COMMIT;
  
    V_RETORNO := 0;
    RETURN V_RETORNO;
  ELSIF (P_TIPO_OCORRENCIA = 3) THEN
    --Realiza o processo de inclusão e finalização da ocorrência.
    FOR X IN (SELECT SBP.P_O_ID_FISCAL1 CPF,
                     P_TIPO_OCORRENCIA ID_TIPO_OCORRENCIA,
                     'LYNKER' US_INCLUSAO,
                     SI.DATE_SUCCESS DT_INCLUSAO,
                     SI.DATE_SUCCESS DH_INCLUSAO
                FROM SAP.TB_INBOUND_BP@INTEGRACOES  SBP,
                     SAP.TB_INTEGRACOES@INTEGRACOES SI,
                     TB_OCORRENCIA                  SO
               WHERE SBP.ID = SI.CHAVE
                 AND SO.CPF = SBP.P_O_ID_FISCAL1
                 AND SO.ID_TIPO_OCORRENCIA = 2
                 AND SO.CONTROLE IS NULL
                 AND SI.TIPO_INTEGRACAO = 'PRDCLNT300 => INTERFACE BP'
                 AND SI.DATE_SUCCESS >= SO.DT_INCLUSAO
               ORDER BY SBP.P_O_ID_FISCAL1) LOOP
    
      INSERT INTO TB_OCORRENCIA SO
        (ID_OCORRENCIA,
         CPF,
         ID_TIPO_OCORRENCIA,
         CONTROLE,
         US_INCLUSAO,
         DT_INCLUSAO,
         DH_INCLUSAO)
      VALUES
        ((SELECT MAX(SO_2.ID_OCORRENCIA) + 1 FROM TB_OCORRENCIA SO_2),
         X.CPF,
         X.ID_TIPO_OCORRENCIA,
         NULL,
         X.US_INCLUSAO,
         X.DT_INCLUSAO,
         X.DH_INCLUSAO)
      RETURNING SO.ID_OCORRENCIA INTO V_ID_OCORRENCIA;
      COMMIT;
    
      UPDATE TB_OCORRENCIA SO
         SET SO.CONTROLE = V_ID_OCORRENCIA
       WHERE SO.CPF = X.CPF
         AND SO.ID_TIPO_OCORRENCIA IN (2, 3)
         AND SO.CONTROLE IS NULL;
      COMMIT;
      V_COUNT_OCORRENCIAS := V_COUNT_OCORRENCIAS + 1;
    END LOOP;
    V_RETORNO := V_COUNT_OCORRENCIAS || ' Ocorrências tratadas.';
    RETURN V_RETORNO;
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    V_ERROR   := SQLERRM;
    V_RETORNO := V_ERROR;
    RETURN V_RETORNO;
END;
