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
    ORDER BY 
      CASE PARAMETRO
        WHEN 'STATUS' THEN 1
        WHEN 'INSTANCE_NAME' THEN 2
        WHEN 'STARTUP_TIME' THEN 3
        WHEN 'MEMORY_TARGET_GB' THEN 4
        WHEN 'SGA_MAX_SIZE_GB' THEN 5
        WHEN 'TABLESPACE_NAME' THEN 6
        WHEN 'USED_GB' THEN 7
        WHEN 'FREE_GB' THEN 8
        WHEN 'MAX_GB' THEN 9
        WHEN 'CACHE_HIT_RATIO' THEN 10
        ELSE 99
      END,
      PARAMETRO;

  CURSOR c_dados(p_cliente VARCHAR2, p_servidor VARCHAR2, p_ip VARCHAR2, p_data_hora DATE, p_grupo VARCHAR2) IS
    SELECT PARAMETRO, VALOR
    FROM MONITORAMENTO
    WHERE CLIENTE = p_cliente
      AND SERVIDOR = p_servidor
      AND IP = p_ip
      AND DATA_HORA = p_data_hora
      AND GRUPO = p_grupo
    ORDER BY ROWID;

  TYPE t_colunas IS TABLE OF VARCHAR2(300) INDEX BY PLS_INTEGER;
  v_colunas t_colunas;
  
  TYPE t_valores IS TABLE OF VARCHAR2(300) INDEX BY VARCHAR2(300);
  v_valores t_valores;
  
  v_cabecalho VARCHAR2(32767);
  v_linha VARCHAR2(32767);
  v_idx_col PLS_INTEGER;
  v_espaco CONSTANT PLS_INTEGER := 20;
  
  v_first_server BOOLEAN := TRUE;
BEGIN
  FOR r_srv IN c_servidores LOOP
    IF NOT v_first_server THEN
      DBMS_OUTPUT.PUT_LINE('');
    END IF;
    v_first_server := FALSE;
    
    DBMS_OUTPUT.PUT_LINE('NOME CLIENTE: ' || r_srv.CLIENTE);
    DBMS_OUTPUT.PUT_LINE('SERVIDOR: ' || r_srv.SERVIDOR || '  IP: ' || r_srv.IP || '  HORA DA COLETA: ' || TO_CHAR(r_srv.MAX_DATA_HORA, 'DD/MM/YYYY HH24:MI:SS'));
    
    FOR r_grp IN c_grupos(r_srv.CLIENTE, r_srv.SERVIDOR, r_srv.IP, r_srv.MAX_DATA_HORA) LOOP
      DBMS_OUTPUT.PUT_LINE('--' || r_grp.GRUPO || '--');
      
      v_idx_col := 0;
      v_cabecalho := '';
      v_colunas.DELETE;
      
      FOR r_param IN c_parametros(r_srv.CLIENTE, r_srv.SERVIDOR, r_srv.IP, r_srv.MAX_DATA_HORA, r_grp.GRUPO) LOOP
        v_idx_col := v_idx_col + 1;
        v_colunas(v_idx_col) := r_param.PARAMETRO;
        v_cabecalho := v_cabecalho || RPAD(r_param.PARAMETRO, v_espaco);
      END LOOP;
      
      DBMS_OUTPUT.PUT_LINE(v_cabecalho);
      
      v_valores.DELETE;
      
      FOR r_dado IN c_dados(r_srv.CLIENTE, r_srv.SERVIDOR, r_srv.IP, r_srv.MAX_DATA_HORA, r_grp.GRUPO) LOOP
        IF v_valores.EXISTS(r_dado.PARAMETRO) THEN
          v_linha := '';
          FOR i IN 1..v_idx_col LOOP
            BEGIN
              v_linha := v_linha || RPAD(v_valores(v_colunas(i)), v_espaco);
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                v_linha := v_linha || RPAD('-', v_espaco);
            END;
          END LOOP;
          DBMS_OUTPUT.PUT_LINE(v_linha);
          
          v_valores.DELETE;
        END IF;
        
        v_valores(r_dado.PARAMETRO) := r_dado.VALOR;
      END LOOP;
      
      IF v_valores.COUNT > 0 THEN
        v_linha := '';
        FOR i IN 1..v_idx_col LOOP
            BEGIN
              v_linha := v_linha || RPAD(v_valores(v_colunas(i)), v_espaco);
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                v_linha := v_linha || RPAD('-', v_espaco);
            END;
        END LOOP;
        DBMS_OUTPUT.PUT_LINE(v_linha);
      END IF;
      
    END LOOP;
  END LOOP;
END PR_RELATORIO;
/

SET SERVEROUTPUT ON;
CALL PR_RELATORIO();