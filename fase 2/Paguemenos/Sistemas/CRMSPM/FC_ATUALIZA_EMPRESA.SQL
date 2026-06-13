CREATE OR REPLACE FUNCTION SISTEMAS.FC_ATUALIZA_EMPRESA(P_ID_EMPRESA    INTEGER,
                                             P_FANTASIA      VARCHAR2,
                                             P_RAZAO_SOCIAL  VARCHAR2,
                                             P_CNPJ          VARCHAR2,
                                             P_CEP           INTEGER,
                                             P_ENDERECO      VARCHAR2,
                                             P_NUMERO        VARCHAR2,
                                             P_BAIRRO        VARCHAR2,
                                             P_COMPLEMENTO   VARCHAR2,
                                             P_ID_CIDADE     INTEGER,
                                             P_ID_UF         INTEGER,
                                             P_TELEFONE      NUMBER,
                                             P_EMAIL         VARCHAR2,
                                             P_LATITUDE      NUMBER,
                                             P_LONGITUTE     NUMBER,
                                             P_US_CADASTRO   VARCHAR2,
                                             P_IMAGEM_1      VARCHAR2,
                                             P_IMAGEM_2      VARCHAR2,
                                             P_IMAGEM_3      VARCHAR2,
                                             P_SEGUNDA       VARCHAR2,
                                             P_TERCA         VARCHAR2,
                                             P_QUARTA        VARCHAR2,
                                             P_QUINTA        VARCHAR2, 
                                             P_SEXTA         VARCHAR2, 
                                             P_SABADO        VARCHAR2,
                                             P_DOMINGO       VARCHAR2)

 RETURN VARCHAR2 IS

  PRAGMA AUTONOMOUS_TRANSACTION;
  VRET INTEGER;
BEGIN

  UPDATE TB_EMPRESA A
     SET          
         FANTASIA = P_FANTASIA,
         RAZAO_SOCIAL = P_RAZAO_SOCIAL,
         CNPJ = P_CNPJ,
         CEP = P_CEP,
         ENDERECO = P_ENDERECO,
         NUMERO = P_NUMERO,
         BAIRRO = P_BAIRRO,
         COMPLEMENTO = P_COMPLEMENTO,
         ID_CIDADE = P_ID_CIDADE,
         ID_UF = P_ID_UF,
         TELEFONE =P_TELEFONE,
         EMAIL = P_EMAIL,
         LATITUDE = P_LATITUDE,
         LONGITUTE = P_LONGITUTE,
         US_CADASTRO = P_US_CADASTRO,
         DT_CADASTRO = SYSDATE,
         IMAGEM_1 = P_IMAGEM_1,
         IMAGEM_2 = P_IMAGEM_2,
         IMAGEM_3 = P_IMAGEM_3
   WHERE a.Id_Empresa = P_ID_EMPRESA;
   
   UPDATE TB_EMPRESA_FUNCIONAMENTO
   
   SET 
     SEGUNDA = P_SEGUNDA,
     TERCA = P_TERCA,
     QUARTA = P_QUARTA,
     QUINTA = P_QUINTA,
     SEXTA = P_SEXTA,
     SABADO = P_SABADO,
     DOMINGO = P_DOMINGO
    WHERE ID_EMPRESA = P_ID_EMPRESA;

  COMMIT;
  VRET := 0;
  RETURN VRET;

EXCEPTION
  WHEN OTHERS THEN
    VRET := SQLERRM;
    RETURN VRET;
END;
