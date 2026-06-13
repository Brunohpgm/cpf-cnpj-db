CREATE OR REPLACE FUNCTION SISTEMAS.FC_ATUALIZA_CLIENTE(P_CPF             VARCHAR2,
                                               P_NOME            VARCHAR2,
                                               P_TIPO            VARCHAR2,
                                               P_SEXO            VARCHAR2,
                                               P_NASCIMENTO      VARCHAR2,
                                               P_CEP             INTEGER,
                                               P_ENDERECO        VARCHAR2,
                                               P_NUMERO          VARCHAR2,
                                               P_BAIRRO          VARCHAR2,
                                               P_COMPLEMENTO     VARCHAR2,
                                               P_CIDADE          INTEGER DEFAULT 0,
                                               P_UF              INTEGER DEFAULT 0,
                                               P_SENHA           VARCHAR2,
                                               P_CELULAR         INTEGER,
                                               P_TELEFONE        INTEGER,
                                               P_EMAIL           VARCHAR2,
                                               P_FAVORITA        INTEGER,
                                               P_IDENTIDADE      VARCHAR2,
                                               P_USCADASTRO      VARCHAR2 DEFAULT 'PORTAL CRM',
                                               P_CELULAR_OPTOUT  VARCHAR2,
                                               P_TELEFONE_OPTOUT VARCHAR2,
                                               P_EMAIL_OPTOUT    VARCHAR2,
                                               P_REGULAMENTO     VARCHAR2 DEFAULT 'P',
                                               P_TERMO           VARCHAR2 DEFAULT 'P',
                                               P_TX_CIDADE       VARCHAR2 DEFAULT NULL,
                                               P_TX_UF           VARCHAR2 DEFAULT NULL,
                                               P_EMPREGADOR      VARCHAR2 DEFAULT NULL,
                                               P_OCUPACAO        VARCHAR2 DEFAULT NULL,
                                               P_TEMPO_SERVICO   NUMBER DEFAULT NULL,
                                               P_TIPO_RESIDENCIA VARCHAR2 DEFAULT NULL,
                                               P_RENDA           VARCHAR2 DEFAULT NULL,
                                               P_BANCO           INTEGER DEFAULT NULL,
                                               P_AGENCIA         INTEGER DEFAULT NULL,
                                               P_DIG_AGENCIA     INTEGER DEFAULT NULL,
                                               P_CONTA           INTEGER DEFAULT NULL,
                                               P_DIG_CONTA       INTEGER DEFAULT NULL,
                                               P_LIMITE_CREDITO  NUMBER DEFAULT NULL,
                                               P_SPC_SERASA      VARCHAR2 DEFAULT NULL)

 RETURN VARCHAR2 IS

  PRAGMA AUTONOMOUS_TRANSACTION;

  VVALID       INTEGER;
  VSEQPESSOA   INTEGER;
  VSEQUENCE    INTEGER;
  RET          VARCHAR2(200);
  V_ID_CIDADE  INTEGER;
  V_ID_UF      INTEGER;
  V_SENHA      VARCHAR2(200);
  V_CHECK_NOME INTEGER;
BEGIN
  
  /* Autor: Bruno Gritti - Data: 08/08/2023
     Descrição: Adicionado verificação de nomes improprios.
  */
  SELECT NVL(SUM(1), 0) CHECK_NOME
    INTO V_CHECK_NOME
    FROM TB_NOME_IMPROPRIO NI
   WHERE UPPER(P_NOME) LIKE '%' || UPPER(NI.TEXTO) || '%';

  IF (V_CHECK_NOME = 1) THEN
    RETURN 'Nome improprio identificado. Nenhum dado foi alterado.';
  END IF;

  V_ID_CIDADE := P_CIDADE;
  V_ID_UF     := P_UF;

  IF (P_CIDADE = 0) THEN
    /*Autor: Bruno Gritti - Data: 21/07/2022
    Descrição: Melhora na consulta e acerto sobre cidades com acentuação.*/
    SELECT C.ID_CIDADE
      INTO V_ID_CIDADE
      FROM TB_CIDADE C
     WHERE UPPER(FC_REMOVE_ACENTO(C.NOME)) =
           UPPER(FC_REMOVE_ACENTO(P_TX_CIDADE));
  END IF;

  IF (P_SENHA = '' OR P_SENHA IS NULL) THEN
    V_SENHA := SUBSTR(TO_CHAR(P_CPF), 0, 6);
  ELSE
    V_SENHA := P_SENHA;
  END IF;

  IF (P_UF = 0) THEN
    SELECT UF.ID_UF INTO V_ID_UF FROM TB_UF UF WHERE UF.UF = P_TX_UF;
  END IF;

  SELECT COUNT(1) INTO VVALID FROM TB_PESSOA A WHERE CPF = P_CPF;
  DBMS_OUTPUT.PUT_LINE(VVALID);

  IF (VVALID > 0) THEN
    SELECT ID_PESSOA INTO VSEQPESSOA FROM TB_PESSOA A WHERE CPF = P_CPF;
    DBMS_OUTPUT.PUT_LINE(VSEQPESSOA);
    UPDATE TB_PESSOA
       SET NOME          = UPPER(P_NOME),
           TIPO_PESSOA   = P_TIPO,
           SEXO          = P_SEXO,
           DT_NASCIMENTO = TO_DATE(P_NASCIMENTO, 'DD/MM/YYYY'),
           CEP           = P_CEP,
           ENDERECO      = UPPER(P_ENDERECO),
           NUMERO        = P_NUMERO,
           BAIRRO        = UPPER(P_BAIRRO),
           COMPLEMENTO   = UPPER(P_COMPLEMENTO),
           ID_CIDADE     = V_ID_CIDADE,
           ID_UF         = V_ID_UF,
           DT_ALTERACAO  = SYSDATE
     WHERE ID_PESSOA = VSEQPESSOA;
  
    UPDATE TB_PESSOA_ATRIBUTO
       SET CELULAR         = P_CELULAR,
           TELEFONE        = P_TELEFONE,
           EMAIL           = P_EMAIL,
           LOJA_FAVORITA   = P_FAVORITA,
           IDENTIDADE      = P_IDENTIDADE,
           DH_ALTERACAO    = SYSDATE,
           CELULAR_OPTOUT  = P_CELULAR_OPTOUT,
           TELEFONE_OPTOUT = P_TELEFONE_OPTOUT,
           EMAIL_OPTOUT    = P_EMAIL_OPTOUT,
           EMPREGADOR      = P_EMPREGADOR,
           OCUPACAO        = P_OCUPACAO,
           TEMPO_SERVICO   = P_TEMPO_SERVICO,
           TIPO_RESIDENCIA = P_TIPO_RESIDENCIA,
           RENDA           = P_RENDA,
           BANCO           = P_BANCO,
           AGENCIA         = P_AGENCIA,
           DIG_AGENCIA     = P_DIG_AGENCIA,
           CONTA           = P_CONTA,
           DIG_CONTA       = P_DIG_CONTA,
           LIMITE_CREDITO  = P_LIMITE_CREDITO,
           SPC_SERASA      = P_SPC_SERASA,
           REGULAMENTO     = P_REGULAMENTO,
           TERMO           = P_TERMO
     WHERE ID_PESSOA = VSEQPESSOA;
  
    IF (LENGTH(P_SENHA) > 0) THEN
      UPDATE TB_PESSOA_ATRIBUTO
         SET SENHA = FC_GERAR_SENHA(P_SENHA)
       WHERE ID_PESSOA = VSEQPESSOA;
    END IF;
  
    COMMIT;
  
    RET := '0';
    RETURN RET;
  
  ELSE
    SELECT SQ_PESSOA.NEXTVAL INTO VSEQUENCE FROM DUAL;
    DBMS_OUTPUT.PUT_LINE(VSEQUENCE);
    INSERT INTO TB_PESSOA
      (ID_PESSOA,
       CPF,
       NOME,
       TIPO_PESSOA,
       SEXO,
       DT_NASCIMENTO,
       CEP,
       ENDERECO,
       NUMERO,
       BAIRRO,
       COMPLEMENTO,
       ID_CIDADE,
       ID_UF,
       US_CADASTRO,
       CA_ORIGEM,
       DT_ALTERACAO,
       DT_CADASTRO)
    VALUES
      (VSEQUENCE,
       P_CPF,
       UPPER(P_NOME),
       P_TIPO,
       P_SEXO,
       TO_DATE(P_NASCIMENTO, 'DD/MM/YYYY'),
       P_CEP,
       UPPER(P_ENDERECO),
       P_NUMERO,
       UPPER(P_BAIRRO),
       UPPER(P_COMPLEMENTO),
       V_ID_CIDADE,
       V_ID_UF,
       P_USCADASTRO,
       P_USCADASTRO,
       SYSDATE,
       SYSDATE);
  
    INSERT INTO TB_PESSOA_ATRIBUTO
      (ID_PESSOA,
       ID_BENEFICIARIO,
       ID_HOUSEHOLD,
       STATUS,
       SENHA,
       CELULAR,
       CELULAR_VALIDADO,
       CELULAR_OPTOUT,
       TELEFONE,
       TELEFONE_OPTOUT,
       EMAIL,
       EMAIL_VALIDADO,
       EMAIL_OPTOUT,
       LOJA_FAVORITA,
       FUNCIONARIO,
       IDENTIDADE,
       DT_ULTIMA_COMPRA,
       DH_ALTERACAO,
       US_ALTERACAO,
       EMPREGADOR,
       OCUPACAO,
       TEMPO_SERVICO,
       TIPO_RESIDENCIA,
       RENDA,
       BANCO,
       AGENCIA,
       DIG_AGENCIA,
       CONTA,
       DIG_CONTA,
       LIMITE_CREDITO,
       SPC_SERASA,
       REGULAMENTO,
       TERMO)
    VALUES
      (VSEQUENCE,
       NULL,
       NULL,
       'A',
       FC_GERAR_SENHA(V_SENHA),
       P_CELULAR,
       NULL,
       P_CELULAR_OPTOUT,
       P_TELEFONE,
       P_TELEFONE_OPTOUT,
       P_EMAIL,
       NULL,
       P_EMAIL_OPTOUT,
       P_FAVORITA,
       'N',
       P_IDENTIDADE,
       NULL,
       SYSDATE,
       SYSDATE,
       P_EMPREGADOR,
       P_OCUPACAO,
       P_TEMPO_SERVICO,
       P_TIPO_RESIDENCIA,
       P_RENDA,
       P_BANCO,
       P_AGENCIA,
       P_DIG_AGENCIA,
       P_CONTA,
       P_DIG_CONTA,
       P_LIMITE_CREDITO,
       P_SPC_SERASA,
       P_REGULAMENTO,
       P_TERMO);
  
    COMMIT;
  
    RET := '1';
    RETURN RET;
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    RET := 'Mensagem Oracle: ' || SQLERRM;
    COMMIT;
    RETURN RET;
END;
