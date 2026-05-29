ALTER TABLE CONDUCTOR.TB_INTEGRACAO_SENIOR ADD FIELD_KEY_CHAR VARCHAR(14);

UPDATE CONDUCTOR.TB_INTEGRACAO_SENIOR
   SET FIELD_KEY_CHAR = CASE
                      WHEN LENGTH(FIELD_KEY) <= 10 THEN
                       LPAD(TO_CHAR(FIELD_KEY), 11, '0')
                      ELSE
                       TO_CHAR(FIELD_KEY)
                    END;
 
ALTER TABLE CONDUCTOR.TB_INTEGRACAO_SENIOR DROP COLUMN FIELD_KEY;                    

ALTER TABLE CONDUCTOR.TB_INTEGRACAO_SENIOR RENAME COLUMN FIELD_KEY_CHAR TO FIELD_KEY;

CREATE INDEX CONDUCTOR.IDX_INTEG_SENIOR_BUSCA_BMSKY ON CONDUCTOR.TB_INTEGRACAO_SENIOR(FIELD_KEY,
                                                                                      TP_IDENTIFICATION,
                                                                                STATUS,
                                                                                      IDENTIFICATION);
--campo relacionado ao id cartao
UPDATE CONDUCTOR.TB_INTEGRACAO_SENIOR
      SET FIELD_KEY = LTRIM(FIELD_KEY, 0)
    WHERE TP_IDENTIFICATION = 3;   