#!/bin/bash

# consultas para analisar ambientes postgres -
## FEITO POR RALBERT RODRIGUES - MARÇO/2024
## Atualizado JANEIRO/2025


# CONEXÃO
DB_NAME="nomeBanco"
DB_PORT="porta"

#  status do serviço PostgreSQL
echo "========================================================================="
echo " Você esta conectado no banco '$DB_NAME'"
echo " Status do serviço PostgreSQL..."
systemctl status postgresql@exemplo-nomeserviço.service | grep -i Active  # aqui você coloca o nome do serviço do postgres
echo "========================================================================="
echo " "
echo " "
echo "================================================|"

echo "             BEM VINDO AO MENU DE ANÁLISE....   |"

# menu
show_menu() {
    echo "================================================|"
    echo "      Análise ambiente PostgreSQL Versão 2025   |"
    echo "================================================|"
    echo "1. Consultas Lentas                             |"
    echo "2. Consultas Causando Lock                      |"
    echo "3. Conexões com Mais de 30 Minutos              |"
    echo "4. Sessões Ativas                               |"
    echo "5. Consultas em Execução no Momento             |"
    echo "6. Consultas Bloqueadas                         |"
    echo "7. Total de Conexões por Usuário                |"
    echo "8. Consultas Mais Executadas                    |"
    echo "9. Consultas Ocupando Mais Memória              |"
    echo "10. Consultas Mais Recorrentes                  |"
    echo "11. Tabelas Mais Consultadas (I/O)              |"
    echo "12. Índices Mais Usados                         |"
    echo "13. Índices Não Utilizados                      |"
    echo "14. Tabelas com Mais Dead Tuples                |"
    echo "15. Uso de Espaço por Tabela                    |"
    echo "16. Conexões por Host                           |"
    echo "17. Consultas que Mais Esperam                  |"
    echo "18. Deadlocks Recentes                          |"
    echo "19. Cache Hit Ratio                             |"
    echo "20. Limite de Conexões                          |"
    echo "21. Lock Wait                                   |"
    echo "22. Verificar uso de Tablespace                 |"
    echo "23. Verifica transações XA                      |"
    echo "24. Cancelar/Matar uma Sessão 30min+            |"
    echo "25. Verificar Replicação                        |"
    echo "0. Sair do menu                                 |"
    echo "------------------------------------------------|"
    echo -n "Escolha uma opção: "
}

# função
run_query() {
    case $1 in
        1)
            QUERY="SELECT query, calls, total_exec_time, mean_exec_time, rows
                   FROM pg_stat_statements
                   ORDER BY mean_exec_time DESC LIMIT 10;"
            ;;
        2)
            QUERY="SELECT bl.pid AS bloqueado_pid,ka.query AS query_bloqueante,bl_sa.query AS query_bloqueada,bl.mode AS tipo_lock
                   FROM pg_locks bl
                        JOIN pg_stat_activity bl_sa ON bl.pid = bl_sa.pid
                        JOIN pg_locks kl ON kl.locktype = bl.locktype
                   AND kl.database IS NOT DISTINCT FROM bl.database
                   AND kl.relation IS NOT DISTINCT FROM bl.relation
                   AND kl.page IS NOT DISTINCT FROM bl.page
                   AND kl.tuple IS NOT DISTINCT FROM bl.tuple
                   AND kl.transactionid IS NOT DISTINCT FROM bl.transactionid
                   AND kl.classid IS NOT DISTINCT FROM bl.classid
                   AND kl.objid IS NOT DISTINCT FROM bl.objid
                   AND kl.objsubid IS NOT DISTINCT FROM bl.objsubid
                   AND kl.pid != bl.pid
                        JOIN pg_stat_activity ka ON kl.pid = ka.pid;"
            ;;
        3)
            QUERY="SELECT pid, usename, datname, state, backend_start, query_start, query
                   FROM pg_stat_activity
                   WHERE state = 'active'
                   AND now() - query_start > interval '30 minutes';"
            ;;
        4)
            QUERY="SELECT pid, usename, datname, application_name, client_addr, state, query_start, query
                   FROM pg_stat_activity WHERE state = 'active';"
            ;;
        5)
            QUERY="SELECT pid, usename, datname, query, state, now() - query_start AS tempo_execucao
                   FROM pg_stat_activity
                   WHERE state = 'active'
                   ORDER BY tempo_execucao DESC;"
            ;;
        6)
            QUERY="SELECT blocked_locks.pid AS pid_bloqueado, blocked_activity.usename AS usuario_bloqueado,
                          blocked_activity.query AS query_bloqueada, blocking_locks.pid AS pid_bloqueante,
                          blocking_activity.usename AS usuario_bloqueante, blocking_activity.query AS query_bloqueante
                   FROM pg_locks blocked_locks
                   JOIN pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
                   JOIN pg_locks blocking_locks ON blocking_locks.locktype = blocked_locks.locktype
                   AND blocking_locks.database IS NOT DISTINCT FROM blocked_locks.database
                   AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
                   AND blocking_locks.pid != blocked_locks.pid
                   JOIN pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
                   WHERE NOT blocked_locks.granted;"
            ;;
        7)
            QUERY="SELECT usename AS usuario, COUNT(*) AS conexoes
                   FROM pg_stat_activity
                   GROUP BY usename
                   ORDER BY conexoes DESC;"
            ;;
        8)
            QUERY="SELECT query, calls, total_exec_time, rows
                   FROM pg_stat_statements
                   ORDER BY calls DESC LIMIT 10;"
            ;;
        9)
            QUERY="SELECT query, shared_blks_hit + shared_blks_read AS memoria_usada, calls
                   FROM pg_stat_statements
                   ORDER BY memoria_usada DESC LIMIT 10;"
            ;;
        10)
            QUERY="SELECT query, total_exec_time / calls AS tempo_medio, calls, rows
                   FROM pg_stat_statements
                   ORDER BY calls DESC LIMIT 10;"
            ;;
        11)
            QUERY="SELECT relname AS tabela, seq_scan AS leituras_sequenciais,
                          idx_scan AS leituras_por_indice,
                          seq_tup_read + idx_tup_fetch AS tuplas_lidas
                   FROM pg_stat_user_tables
                   ORDER BY seq_tup_read + idx_tup_fetch DESC LIMIT 10;"
            ;;
        12)
            QUERY="SELECT relname AS indice, idx_scan AS leituras_por_indice, idx_tup_read AS tuplas_lidas
                   FROM pg_stat_user_indexes
                   ORDER BY idx_scan DESC LIMIT 10;"
            ;;
        13)
            QUERY="SELECT relname AS indice, idx_scan AS leituras_por_indice
                   FROM pg_stat_user_indexes
                   WHERE idx_scan = 0;"
            ;;
        14)
            QUERY="SELECT relname AS tabela, n_dead_tup AS linhas_mortas
                   FROM pg_stat_user_tables
                   WHERE n_dead_tup > 0
                   ORDER BY n_dead_tup DESC LIMIT 10;"
            ;;
        15)
            QUERY="SELECT n.nspname AS schema, c.relname AS tabela, pg_size_pretty(pg_total_relation_size(c.oid)) AS tamanho
                    FROM   pg_catalog.pg_statio_user_tables s
                    JOIN   pg_catalog.pg_class c ON s.relid = c.oid
                    JOIN   pg_catalog.pg_namespace n ON c.relnamespace = n.oid
                    ORDER BY pg_total_relation_size(c.oid) DESC
                    LIMIT 20;"
            ;;
        16)
            QUERY="SELECT client_addr AS endereco, COUNT(*) AS conexoes
                   FROM pg_stat_activity
                   GROUP BY client_addr
                   ORDER BY conexoes DESC;"
            ;;
        17)
            QUERY="SELECT pid, usename, query, state, wait_event, wait_event_type,
                          now() - query_start AS tempo_esperando
                   FROM pg_stat_activity
                   WHERE wait_event IS NOT NULL
                   ORDER BY tempo_esperando DESC LIMIT 10;"
            ;;
        18)
            QUERY="SELECT sa.query_start AS log_time, pl.pid,   pl.virtualtransaction,  pl.transactionid,  pl.mode,  pl.locktype, pl.relation::regclass AS tabela,   sa.query
                   FROM pg_locks pl
                   JOIN pg_stat_activity sa ON pl.pid = sa.pid
                   WHERE
                   NOT pl.granted;"
            ;;
        19)
            QUERY="SELECT sum(blks_hit) / (sum(blks_hit) + sum(blks_read)) AS cache_hit_ratio
                   FROM pg_stat_database;"
            ;;
        20)
            QUERY="SELECT datname AS banco, numbackends AS conexoes_ativas,
                          pg_settings.setting AS limite_conexoes
                   FROM pg_stat_database
                   JOIN pg_settings ON pg_settings.name = 'max_connections';"
            ;;
        21)
            QUERY="SELECT pid,usename,pg_blocking_pids(pid) as blocked_by,query as blocked_query
                    FROM pg_stat_activity
                    WHERE cardinality(pg_blocking_pids(pid)) > 0;"
            ;;

        22) echo "Verificando uso de tablespace..."
        QUERY="SELECT ts.spcname AS tablespace,  pg_size_pretty(pg_tablespace_size(ts.spcname)) AS size, COUNT(t.tablename) AS tables_in_use
        FROM pg_tablespace ts
        LEFT JOIN pg_tables t ON t.tablespace = ts.spcname
        GROUP BY   ts.spcname;"

        ;;

        23) QUERY="select * from pg_prepared_xacts;"

          ;;

        24)
            echo "Listando sessões com mais de 30 minutos..."
            QUERY="SELECT pid, usename, datname, query, query_start
                   FROM pg_stat_activity
                   WHERE now() - query_start > interval '30 minutes';"
            psql -d "$DB_NAME" -p "$DB_PORT" -c "$QUERY"
            echo -n "Digite o PID para matar ou pressione ENTER para cancelar: "
            read -r PID
            if [[ -n $PID ]]; then
                psql -d "$DB_NAME" -p "$DB_PORT" -c "SELECT pg_terminate_backend($PID);"
                echo "Sessão com PID $PID terminada."
            else
                echo "Operação cancelada."
            fi
            return
            ;; 

                25)echo "Verificar Replicação"
                QUERY="SELECT application_name, client_addr, state, sync_state, sent_lsn, write_lsn, flush_lsn, replay_lsn,
                (sent_lsn - replay_lsn) AS atraso_bytes
                FROM pg_stat_replication;;"

                ;;


        *)
            echo "Opção inválida!"
            return
            ;;
    esac

    # Execução da consulta
    echo "Analisando ..."
    psql -d "$DB_NAME" -p "$DB_PORT" -c "$QUERY"
}

# Loop  do menu
while true; do
    show_menu
    read -r OPTION

    if [ "$OPTION" -eq 0 ]; then
        echo "Saindo do Menu, obrigado!!!..."
        echo "x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x "
        break
    fi

    run_query "$OPTION"
    echo
done
