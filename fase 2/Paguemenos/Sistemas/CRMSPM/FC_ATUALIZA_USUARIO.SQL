CREATE OR REPLACE FUNCTION SISTEMAS.FC_ATUALIZA_USUARIO(P_ID            VARCHAR2,
                                                        P_NOME          VARCHAR2,
                                                        P_EMAIL         VARCHAR2,
                                                        P_STATUS        VARCHAR2,
                                                        P_EMPRESA       VARCHAR2,
                                                        P_ULT_ALT_LOGIN VARCHAR2,
                                                        P_AVATAR        VARCHAR2,
                                                        P_SENHA         VARCHAR2,
                                                        P_CPF           VARCHAR2)
  RETURN VARCHAR2 IS
  PRAGMA AUTONOMOUS_TRANSACTION;

  VVALID INTEGER;
  VRET   VARCHAR2(100);
BEGIN
  SELECT COUNT(1) INTO VVALID FROM TB_USUARIO WHERE ID_USUARIO = P_ID;

  IF (VVALID > 0) THEN
  
    UPDATE TB_USUARIO
       SET NOME          = UPPER(P_NOME),
           EMAIL         = LOWER(P_EMAIL),
           STATUS        = P_STATUS,
           EMPRESA       = P_EMPRESA,
           ULT_ALT_LOGIN = P_ULT_ALT_LOGIN,
           DT_ALTERACAO  = SYSDATE,
           AVATAR        = P_AVATAR
    
     WHERE ID_USUARIO = P_ID;
    COMMIT;
    IF (LENGTH(P_CPF) > 0) THEN
      UPDATE TB_USUARIO SET CPF = P_CPF WHERE ID_USUARIO = P_ID;
    END IF;
  
    IF (LENGTH(P_SENHA) > 0) THEN
      UPDATE TB_USUARIO
         SET SENHA = FC_GERAR_SENHA(P_SENHA)
       WHERE ID_USUARIO = P_ID;
    END IF;
    COMMIT;
    VRET := 0;
    RETURN VRET;
  ELSE
    VRET := 1;
    RETURN VRET;
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    VRET := SQLERRM;
    RETURN VRET;
END;
