CREATE OR REPLACE PROCEDURE SP_CADASTRA_CARTAO_LEVEMAIS IS
  V_STATUS INTEGER;
BEGIN
  FOR X IN (SELECT P.IDPESSOA,
                   TO_NUMBER(PF.CPF) AS CPF,
                   P.NOME AS NOME,
                   /*(SELECT SUBSTR(B.ID_ESTABELECIMENTO, 3, 2) AS LOJA
                    FROM T_LOJA@CONDUCTOR                  L,
                         LG.TB_ESTABELECIMENTO@INTEGRACOES B
                   WHERE B.IDENTIFICACAO = L.CNPJ
                     AND L.IDLOJA = CTPF.IDLOJACADASTRO)*/
                   (SELECT LPAD(B.ID_EMPRESA, 2, 0) AS LOJA
                      FROM T_LOJA@CONDUCTOR L, TB_EMPRESA B
                     WHERE B.CNPJ = L.CNPJ
                       AND L.IDLOJA = CTPF.IDLOJACADASTRO) AS LOJA,
                   PF.SEXO AS SEXO,
                   PF.DATANASCIMENTO,
                   E.CEP AS CEP,
                   E.LOGRADOURO AS ENDERECO,
                   E.NUMERO AS NUMERO,
                   E.BAIRRO AS BAIRRO,
                   E.COMPLEMENTO AS COMPLEMENTO,
                   E.LOCALIDADE AS CIDADE,
                   E.UF AS UF,
                   (SELECT T.AREA
                      FROM T_TELEFONE@CONDUCTOR        T,
                           T_TELEFONE_PESSOA@CONDUCTOR TP
                     WHERE P.IDPESSOA = TP.IDPESSOA
                       AND T.IDTELEFONE = TP.IDTELEFONE
                       AND T.TIPOTELEFONE = 'X'
                       AND ROWNUM = 1) AS DDCELULAR,
                   (SELECT TRIM(REPLACE(T.TELEFONE, '-', '')) AS TELEFONE
                      FROM T_TELEFONE@CONDUCTOR        T,
                           T_TELEFONE_PESSOA@CONDUCTOR TP
                     WHERE P.IDPESSOA = TP.IDPESSOA
                       AND T.IDTELEFONE = TP.IDTELEFONE
                       AND T.TIPOTELEFONE = 'X'
                       AND ROWNUM = 1) AS CELULAR,
                   (SELECT T.AREA
                      FROM T_TELEFONE@CONDUCTOR        T,
                           T_TELEFONE_PESSOA@CONDUCTOR TP
                     WHERE P.IDPESSOA = TP.IDPESSOA
                       AND T.IDTELEFONE = TP.IDTELEFONE
                       AND T.TIPOTELEFONE = 'R'
                       AND ROWNUM = 1) AS DDTELEFONE,
                   (SELECT TRIM(REPLACE(T.TELEFONE, '-', '')) AS TELEFONE
                      FROM T_TELEFONE@CONDUCTOR        T,
                           T_TELEFONE_PESSOA@CONDUCTOR TP
                     WHERE P.IDPESSOA = TP.IDPESSOA
                       AND T.IDTELEFONE = TP.IDTELEFONE
                       AND T.TIPOTELEFONE = 'R'
                       AND ROWNUM = 1) AS TELEFONE,
                   PF.EMAIL AS EMAIL,
                   PF.RG AS IDENTIDADE
              FROM T_PESSOA@CONDUCTOR                     P,
                   T_PESSOAFISICA@CONDUCTOR               PF,
                   T_CLIENTETITULARPESSOAFISICA@CONDUCTOR CTPF,
                   T_ENDERECO@CONDUCTOR                   E
             WHERE P.IDPESSOA = PF.IDPESSOAFISICA
               AND P.IDPESSOA = CTPF.IDCLIENTETITULARPESSOAFISICA
               AND CTPF.IDENDERECORESIDENCIAL = E.IDENDERECO
               AND E.CEP != '00000000'
                  --AND PF.CPF = '18810190807'
               AND NOT EXISTS
             (SELECT 1
                      FROM TB_PESSOA A
                     WHERE TO_NUMBER(A.CPF) = TO_NUMBER(PF.CPF))) LOOP
  
    DBMS_OUTPUT.PUT_LINE(X.CPF);
  
    SP_CADASTRO_CLIENTE(CPF             => X.CPF,
                        NOME            => X.NOME,
                        LOJA            => X.LOJA,
                        CELULAR_DDD     => X.DDCELULAR,
                        CELULAR         => X.CELULAR,
                        SENHA           => '123456',
                        ENDERECO        => X.ENDERECO,
                        CIDADE          => X.CIDADE,
                        COMPLEMENTO     => X.COMPLEMENTO,
                        DISTRITO        => X.BAIRRO,
                        NUMERO          => X.NUMERO,
                        ESTADO          => X.UF,
                        DATA_NASCIMENTO => X.DATANASCIMENTO,
                        CEP             => X.CEP,
                        EMAIL           => X.EMAIL,
                        TELEFONE_DDD    => X.DDTELEFONE,
                        TELEFONE        => X.TELEFONE,
                        RG              => X.IDENTIDADE,
                        US_CADASTRO     => 'JOB 6',
                        ORIGEM          => 'CARTAOLEVEMAIS',
                        STATUS          => V_STATUS);
  
  END LOOP;
END;
