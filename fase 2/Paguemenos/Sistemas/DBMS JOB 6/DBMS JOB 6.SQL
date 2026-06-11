/*---[Cadastra Cartao Leve Mais - Dump Conductor]---*/

BEGIN

  sistemas.SP_CADASTRA_CARTAO_LEVEMAIS;

  /*---[Associa Clientes do Cartao Leve Mais na Mala 26 - Cartão Leve Mais]---*/
  FOR X IN (SELECT 26 AS ID_LEAD, P.ID_PESSOA AS ID_PESSOA
              FROM sistemas.TB_PESSOA                              P,
                   T_PESSOAFISICA@CONDUCTOR               PF,
                   T_CLIENTETITULARPESSOAFISICA@CONDUCTOR CTPF
             WHERE P.CPF = PF.CPF
               AND PF.IDPESSOAFISICA = CTPF.IDCLIENTETITULARPESSOAFISICA
               AND CTPF.STATUS_CLIENTE NOT IN ('B', 'C')
               AND NOT EXISTS
             (SELECT 1
                      FROM TB_LEAD_PESSOA LP
                     WHERE LP.ID_LEAD = 26
                       AND LP.ID_PESSOA = P.ID_PESSOA)
             GROUP BY P.ID_PESSOA) LOOP
  
    INSERT INTO sistemas.TB_LEAD_PESSOA
      (ID_LEAD, ID_PESSOA)
    VALUES
      (X.ID_LEAD, X.ID_PESSOA);
    COMMIT;
  END LOOP;

END;