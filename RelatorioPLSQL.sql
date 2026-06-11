CREATE OR REPLACE PROCEDURE PR_RELATORIO IS
    CURSOR c_servidores IS
        SELECT CLIENTE, SERVIDOR, IP, MAX(DATA_HORA) AS MAX_DATA_HORA
        FROM MONITORAMENTO
        GROUP BY CLIENTE, SERVIDOR, IP
        ORDER BY CLIENTE, SERVIDOR, IP;

    CURSOR c_grupos(p_cliente VARCHAR2, p_servidor VARCHAR2, p_ip VARCHAR2, p_data_hora DATE) IS
        SELECT DISTINCT GRUPO
        FROM MONITORAMENTO
        WHERE CLIENTE = p_cliente
          AND SERVIDOR = p_servidor
          AND IP = p_ip
          AND DATA_HORA = p_data_hora
        ORDER BY GRUPO;

    CURSOR c_parametros(p_cliente VARCHAR2, p_servidor VARCHAR2, p_ip VARCHAR2, p_data_hora DATE, p_grupo VARCHAR2) IS
        SELECT DISTINCT PARAMETRO
        FROM MONITORAMENTO
        WHERE CLIENTE = p_cliente
          AND SERVIDOR = p_servidor
          AND IP = p_ip
          AND DATA_HORA = p_data_hora
          AND GRUPO = p_grupo
        ORDER BY PARAMETRO;

    TYPE t_parametros IS TABLE OF VARCHAR2(300) INDEX BY PLS_INTEGER;
    v_parametros t_parametros;
    
    v_qtd_parametros NUMBER;
    v_linha_cabecalho VARCHAR2(32767);
    v_linha_valor VARCHAR2(32767);
    v_valor VARCHAR2(300);
    v_indice_linha NUMBER;
    v_qtd_excecoes NUMBER;
BEGIN
    FOR r_servidor IN c_servidores LOOP
        DBMS_OUTPUT.PUT_LINE('NOME CLIENTE: ' || r_servidor.CLIENTE);
        DBMS_OUTPUT.PUT_LINE('SERVIDOR: ' || RPAD(r_servidor.SERVIDOR, 15) || 
                             ' IP: ' || RPAD(r_servidor.IP, 20) || 
                             ' HORA DA COLETA: ' || TO_CHAR(r_servidor.MAX_DATA_HORA, 'DD/MM/YYYY HH24:MI:SS'));
        
        FOR r_grupo IN c_grupos(r_servidor.CLIENTE, r_servidor.SERVIDOR, r_servidor.IP, r_servidor.MAX_DATA_HORA) LOOP
            DBMS_OUTPUT.PUT_LINE('--' || r_grupo.GRUPO || '--');
            
            v_qtd_parametros := 0;
            v_parametros.DELETE;
            v_linha_cabecalho := '';
            
            FOR r_parametro IN c_parametros(r_servidor.CLIENTE, r_servidor.SERVIDOR, r_servidor.IP, r_servidor.MAX_DATA_HORA, r_grupo.GRUPO) LOOP
                v_qtd_parametros := v_qtd_parametros + 1;
                v_parametros(v_qtd_parametros) := r_parametro.PARAMETRO;
                v_linha_cabecalho := v_linha_cabecalho || RPAD(r_parametro.PARAMETRO, 24);
            END LOOP;
            
            DBMS_OUTPUT.PUT_LINE(v_linha_cabecalho);
            
            v_indice_linha := 1;
            LOOP
                v_linha_valor := '';
                v_qtd_excecoes := 0;
                
                FOR i IN 1..v_qtd_parametros LOOP
                    BEGIN
                        SELECT VALOR INTO v_valor
                        FROM (
                            SELECT VALOR, ROW_NUMBER() OVER (ORDER BY ROWID) as num_linha
                            FROM MONITORAMENTO
                            WHERE CLIENTE = r_servidor.CLIENTE
                              AND SERVIDOR = r_servidor.SERVIDOR
                              AND IP = r_servidor.IP
                              AND DATA_HORA = r_servidor.MAX_DATA_HORA
                              AND GRUPO = r_grupo.GRUPO
                              AND PARAMETRO = v_parametros(i)
                        )
                        WHERE num_linha = v_indice_linha;
                        
                        v_linha_valor := v_linha_valor || RPAD(v_valor, 24);
                    EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                            v_linha_valor := v_linha_valor || RPAD('-', 24);
                            v_qtd_excecoes := v_qtd_excecoes + 1;
                    END;
                END LOOP;
                
                IF v_qtd_excecoes = v_qtd_parametros THEN
                    EXIT;
                END IF;
                
                DBMS_OUTPUT.PUT_LINE(v_linha_valor);
                v_indice_linha := v_indice_linha + 1;
            END LOOP;
            
            DBMS_OUTPUT.PUT_LINE('');
        END LOOP;
        DBMS_OUTPUT.PUT_LINE('');
    END LOOP;
END PR_RELATORIO;
/

SET SERVEROUTPUT ON;
CALL PR_RELATORIO();