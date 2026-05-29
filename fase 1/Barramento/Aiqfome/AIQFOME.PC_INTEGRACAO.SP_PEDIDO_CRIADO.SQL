CREATE OR REPLACE PACKAGE BODY AIQFOME.PC_INTEGRACAO IS

  --================================================================================================================
  ----- SP_EVENTOS - Autor: Higor Dias - Data: 25/03/2024
  --================================================================================================================

  PROCEDURE SP_EVENTOS(PN_STATUS IN VARCHAR2, PN_JSON IN CLOB) AS
  BEGIN
    IF PN_STATUS = 'CONFIRMADO' THEN
      SP_PEDIDO_CRIADO(PN_JSON);
    ELSIF PN_STATUS = 'DESPACHADO' THEN
      SP_PEDIDO_FINALIZADO(PN_JSON);
    ELSIF PN_STATUS = 'ENTREGUE' THEN
      SP_PEDIDO_ENTREGUE(PN_JSON);
    ELSIF PN_STATUS = 'CANCELADO' THEN
      SP_PEDIDO_CANCELADO(PN_JSON);
    END IF;
  END SP_EVENTOS;

  --=======================0=========================================================================================
  ----- SP_PEDIDO_CRIADO - Autor: Higor Dias - Data: 25/03/2024
  --================================================================================================================

  PROCEDURE SP_PEDIDO_CRIADO(PN_JSON IN CLOB) AS
    V_ERRO VARCHAR2(4000);
  BEGIN
    MERGE INTO TB_PEDIDO X
    USING (SELECT JT.CODIGO_PEDIDO AS ID_PEDIDO,
                  JT.CENTRO        AS CENTRO, -- Suponha que o centro seja fixo como 1001
                  JT.CPF           AS CPF,
                  JT.NOME_CLIENTE,
                  JT.LOGRADOURO,
                  JT.NUMERO,
                  JT.BAIRRO,
                  JT.CIDADE,
                  JT.UF,
                  JT.COMPLEMENTO,
                  JT.MODALIDADE,
                  JT.STATUS_ATUAL,
                  JT.TAXA_ENTREGA,
                  JT.VALOR_PEDIDO,
                  NULL             AS DT_CANCELAMENTO,
                  NULL             AS DT_ENTREGA,
                  SYSDATE          AS DT_INSERCAO,
                  NULL             AS DT_ATUALIZACAO
             FROM JSON_TABLE(PN_JSON,
                             '$[*]'
                             COLUMNS(CODIGO_PEDIDO PATH '$.codigo_pedido',
                                     CENTRO PATH '$.centro',
                                     STATUS_ATUAL VARCHAR2(255) PATH
                                     '$.status',
                                     CPF PATH '$.cpf',
                                     NOME_CLIENTE PATH '$.nome_cliente',
                                     LOGRADOURO PATH
                                     '$.endereco_entrega.logradouro',
                                     NUMERO PATH '$.endereco_entrega.numero',
                                     BAIRRO PATH '$.endereco_entrega.bairro',
                                     CIDADE PATH '$.endereco_entrega.cidade',
                                     UF PATH '$.endereco_entrega.uf',
                                     COMPLEMENTO PATH
                                     '$.endereco_entrega.complemento',
                                     MODALIDADE PATH '$.modalidade',
                                     TAXA_ENTREGA PATH '$.taxaEntrega',
                                     VALOR_PEDIDO PATH '$.valor_total_pedido')) JT) Y
    ON (X.ID_PEDIDO = Y.ID_PEDIDO)
    WHEN MATCHED THEN
      UPDATE
         SET X.CENTRO         = Y.CENTRO,
             X.CPF            = Y.CPF,
             X.NOME_CLIENTE   = Y.NOME_CLIENTE,
             X.LOGRADOURO     = Y.LOGRADOURO,
             X.NUMERO         = Y.NUMERO,
             X.BAIRRO         = Y.BAIRRO,
             X.CIDADE         = Y.CIDADE,
             X.UF             = Y.UF,
             X.COMPLEMENTO    = Y.COMPLEMENTO,
             X.MODALIDADE     = Y.MODALIDADE,
             X.TAXA_ENTREGA   = Y.TAXA_ENTREGA,
             X.VALOR_PEDIDO   = Y.VALOR_PEDIDO,
             X.DT_ATUALIZACAO = SYSDATE
    WHEN NOT MATCHED THEN
      INSERT
        (ID_PEDIDO,
         CENTRO,
         CPF,
         NOME_CLIENTE,
         LOGRADOURO,
         NUMERO,
         BAIRRO,
         CIDADE,
         UF,
         COMPLEMENTO,
         MODALIDADE,
         STATUS_ATUAL,
         TAXA_ENTREGA,
         VALOR_PEDIDO,
         DT_INSERCAO)
      VALUES
        (Y.ID_PEDIDO,
         Y.CENTRO,
         Y.CPF,
         Y.NOME_CLIENTE,
         Y.LOGRADOURO,
         Y.NUMERO,
         Y.BAIRRO,
         Y.CIDADE,
         Y.UF,
         Y.COMPLEMENTO,
         Y.MODALIDADE,
         Y.STATUS_ATUAL,
         Y.TAXA_ENTREGA,
         Y.VALOR_PEDIDO,
         Y.DT_INSERCAO);
  
  EXCEPTION
    WHEN OTHERS THEN
      V_ERRO := SUBSTR(SQLERRM, 0, 3999);
      DBMS_OUTPUT.PUT_LINE(V_ERRO);
      ROLLBACK;
      INSERT INTO TB_PEDIDO_ACOMPANHAMENTO_ERRO
        (ID_PEDIDO, CENTRO, STATUS, ERRO)
        SELECT ID_PEDIDO, CENTRO, 'CONFIRMADO' STATUS, V_ERRO ERRO
          FROM JSON_TABLE(PN_JSON,
                          '$[*]' COLUMNS(ID_PEDIDO INTEGER PATH '$.id',
                                  CENTRO INTEGER PATH '$.store.id'));
  END SP_PEDIDO_CRIADO;

  --================================================================================================================
  ----- SP_PEDIDO_EXPORTAR - Autor: Higor Dias - Data: 25/03/2024
  --================================================================================================================

  PROCEDURE SP_PEDIDO_FINALIZADO(PN_JSON IN CLOB) AS
    V_ERRO VARCHAR2(4000);
  BEGIN
    MERGE INTO TB_PEDIDO_ITEM X
    USING (SELECT JT.ID_PEDIDO     AS ID_PEDIDO,
                  JT.CENTRO        AS CENTRO,
                  JT.CODBARRAS     AS EAN,
                  JT.CODIGOINTERNO AS ID_PRODUTO,
                  JT.QUANTIDADE,
                  JT.VALOR_UNIDADE,
                  JT.VALOR_TOTAL,
                  SYSDATE          AS DT_INSERCAO,
                  NULL             AS DT_ATUALIZACAO
             FROM JSON_TABLE(PN_JSON,
                             '$[*]'
                             COLUMNS(ID_PEDIDO PATH '$.codigo_pedido',
                                     CENTRO PATH '$.centro',
                                     NESTED PATH '$.produtos[*]'
                                     COLUMNS(CODBARRAS PATH '$.cod_barras',
                                             CODIGOINTERNO PATH
                                             '$.codigo_interno',
                                             QUANTIDADE PATH '$.quantidade',
                                             VALOR_UNIDADE PATH
                                             '$.valor_unitario',
                                             VALOR_TOTAL PATH '$.valor_total'))) JT) Y
    ON (X.ID_PEDIDO = Y.ID_PEDIDO AND X.EAN = Y.EAN AND X.ID_PRODUTO = Y.ID_PRODUTO AND X.CENTRO = Y.CENTRO)
    WHEN MATCHED THEN
      UPDATE
         SET X.QUANTIDADE     = Y.QUANTIDADE,
             X.VALOR_UNIDADE  = Y.VALOR_UNIDADE,
             X.VALOR_TOTAL    = Y.VALOR_TOTAL,
             X.DT_ATUALIZACAO = SYSDATE
    WHEN NOT MATCHED THEN
      INSERT
        (ID_PEDIDO,
         CENTRO,
         EAN,
         ID_PRODUTO,
         QUANTIDADE,
         VALOR_UNIDADE,
         VALOR_TOTAL,
         DT_INSERCAO)
      VALUES
        (Y.ID_PEDIDO,
         Y.CENTRO,
         Y.EAN,
         Y.ID_PRODUTO,
         Y.QUANTIDADE,
         Y.VALOR_UNIDADE,
         Y.VALOR_TOTAL,
         Y.DT_INSERCAO);
  
    MERGE INTO TB_PEDIDO P
    USING (SELECT JT.ID_PEDIDO, JT.CENTRO, JT.VALOR_PEDIDO, JT.STATUS_ATUAL
             FROM JSON_TABLE(PN_JSON,
                             '$[*]'
                             COLUMNS(ID_PEDIDO PATH '$.codigo_pedido',
                                     CENTRO PATH '$.centro',
                                     VALOR_PEDIDO PATH '$.valor_total_pedido',
                                     STATUS_ATUAL PATH '$.status')) JT) X
    ON (P.ID_PEDIDO = X.ID_PEDIDO AND P.CENTRO = X.CENTRO)
    WHEN MATCHED THEN
      UPDATE
         SET P.VALOR_PEDIDO   = X.VALOR_PEDIDO,
             P.STATUS_ATUAL   = 'DESPACHADO',
             P.DT_ATUALIZACAO = SYSDATE;
  
  EXCEPTION
    WHEN OTHERS THEN
      V_ERRO := SUBSTR(SQLERRM, 0, 3999);
      DBMS_OUTPUT.PUT_LINE(V_ERRO);
      ROLLBACK;
      INSERT INTO TB_PEDIDO_ACOMPANHAMENTO_ERRO L
        (ID_PEDIDO, CENTRO, STATUS, ERRO)
        SELECT ID_PEDIDO, CENTRO, 'DESPACHADO' STATUS, V_ERRO ERRO
          FROM JSON_TABLE(PN_JSON,
                          '$[*]'
                          COLUMNS(ID_PEDIDO INTEGER PATH '$.codigo_pedido',
                                  CENTRO INTEGER PATH '$.centro'));
    
  END SP_PEDIDO_FINALIZADO;

  --================================================================================================================
  ----- SP_PEDIDO_ENTREGUE - Autor: Higor Dias - Data: 27/03/2024
  --================================================================================================================

  PROCEDURE SP_PEDIDO_ENTREGUE(PN_JSON IN CLOB) AS
    V_ERRO VARCHAR2(4000);
  BEGIN
    MERGE INTO TB_PEDIDO P
    USING (SELECT JT.ID_PEDIDO, JT.CENTRO
             FROM JSON_TABLE(PN_JSON,
                             '$[*]' COLUMNS(ID_PEDIDO PATH '$.codigo_pedido',
                                     CENTRO PATH '$.centro')) JT) X
    ON (P.ID_PEDIDO = X.ID_PEDIDO AND P.CENTRO = X.CENTRO)
    WHEN MATCHED THEN
      UPDATE
         SET P.DT_ENTREGA     = SYSDATE,
             P.DT_ATUALIZACAO = SYSDATE,
             P.STATUS_ATUAL   = 'ENTREGUE';
  
  EXCEPTION
    WHEN OTHERS THEN
      V_ERRO := SUBSTR(SQLERRM, 0, 3999);
      DBMS_OUTPUT.PUT_LINE(V_ERRO);
      ROLLBACK;
      INSERT INTO TB_PEDIDO_ACOMPANHAMENTO_ERRO L
        (ID_PEDIDO, CENTRO, STATUS, ERRO)
        SELECT ID_PEDIDO, CENTRO, 'ENTREGUE', V_ERRO ERRO
          FROM JSON_TABLE(PN_JSON,
                          '$[*]'
                          COLUMNS(ID_PEDIDO INTEGER PATH '$.codigo_pedido',
                                  CENTRO INTEGER PATH '$.centro'));
    
  END SP_PEDIDO_ENTREGUE;

  --================================================================================================================
  ----- SP_PEDIDO_CANCELADO - Autor: Higor Dias - Data: 27/03/2024
  --================================================================================================================

  PROCEDURE SP_PEDIDO_CANCELADO(PN_JSON IN CLOB) AS
    V_ERRO VARCHAR2(4000);
  BEGIN
    MERGE INTO TB_PEDIDO P
    USING (SELECT JT.ID_PEDIDO, JT.CENTRO
             FROM JSON_TABLE(PN_JSON,
                             '$[*]' COLUMNS(ID_PEDIDO PATH '$.codigo_pedido',
                                     CENTRO PATH '$.centro')) JT) X
    ON (P.ID_PEDIDO = X.ID_PEDIDO AND P.CENTRO = X.CENTRO)
    WHEN MATCHED THEN
      UPDATE
         SET P.DT_CANCELAMENTO = SYSDATE,
             P.DT_ATUALIZACAO  = SYSDATE,
             P.STATUS_ATUAL    = 'CANCELADO';
  
  EXCEPTION
    WHEN OTHERS THEN
      V_ERRO := SUBSTR(SQLERRM, 0, 3999);
      DBMS_OUTPUT.PUT_LINE(V_ERRO);
      ROLLBACK;
      INSERT INTO TB_PEDIDO_ACOMPANHAMENTO_ERRO L
        (ID_PEDIDO, CENTRO, STATUS, ERRO)
        SELECT ID_PEDIDO, CENTRO, 'CANCELADO' STATUS, V_ERRO ERRO
          FROM JSON_TABLE(PN_JSON,
                          '$[*]'
                          COLUMNS(ID_PEDIDO INTEGER PATH '$.codigo_pedido',
                                  CENTRO INTEGER PATH '$.centro'));
    
  END SP_PEDIDO_CANCELADO;

END PC_INTEGRACAO;
