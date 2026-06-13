CREATE OR REPLACE FUNCTION SISTEMAS.FC_CADASTRO_USUARIO (P_LOGIN VARCHAR2,
                                               P_SENHA VARCHAR2,
                                               P_NOME VARCHAR2,
                                               P_CPF VARCHAR2,
                                               P_EMAIL VARCHAR2,
                                               P_LOJA VARCHAR2,
                                               P_LOGIN_LAST_CHAN VARCHAR,
                                               P_AVATAR VARCHAR2)
RETURN INTEGER IS
PRAGMA AUTONOMOUS_TRANSACTION;
vSEQUENCE INTEGER;
vVALID INTEGER;
vRET INTEGER;

BEGIN
SELECT COUNT(1) INTO vVALID FROM TB_USUARIO WHERE LOGIN = P_LOGIN;

IF (vVALID = 0) THEN
  SELECT SQ_USER.NEXTVAL INTO vSEQUENCE FROM DUAL;

  INSERT INTO TB_USUARIO(ID_USUARIO,
                         LOGIN,
                         SENHA,
                         NOME,
                         CPF,
                         EMAIL,
                         STATUS,
                         EMPRESA,
                         ULT_ALT_LOGIN,
                         DT_ALTERACAO,
                         AVATAR)
  VALUES
    (vSEQUENCE,
     UPPER(P_LOGIN),
     FC_GERAR_SENHA(P_SENHA),
     UPPER(P_NOME),
     LPAD(P_CPF, 11, '0'),
     P_EMAIL,
     'A',
     P_LOJA,
     P_LOGIN_LAST_CHAN,
     SYSDATE,
     P_AVATAR);

  COMMIT;
  vRET := vSEQUENCE;
  RETURN vRET;
ELSE
  vRET := 0;
  RETURN vRET;
END IF;
END;
