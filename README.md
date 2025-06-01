
# 🧠 Checklist de Análise de Ambiente PostgreSQL

Este repositório contém um script shell para validação e diagnóstico de instâncias PostgreSQL. Ideal para DBAs/Analistas que precisam verificar rapidamente o estado do ambiente, especialmente em produção ou após incidentes.

## 📄 Arquivo principal

- `analise_ambiente_postgres.sh` — Script de análise automatizada

## 🔍 O que o script verifica

- Versão do PostgreSQL
- Estado do serviço
- Configurações principais (`max_connections`, `shared_buffers`, `work_mem`, etc.)
- Espaço em disco (data directory e mounts)
- Locks ativos
- Status de autovacuum
- Replicação (se configurada)
- Conexões ativas e idle
- Tamanho das maiores tabelas


## ▶️ Como usar

```bash
chmod +x analise_ambiente_postgres.sh
./analise_ambiente_postgres.sh
```

> Recomendado executar com um usuário com permissões no banco e acesso ao sistema operacional.

## 💡 Observações

- Este script é adaptável: você pode incluir variáveis como host, porta, usuário e database
- Ideal para automatizar checagens em rotinas de manutenção preventiva
- Colocando em seu ambiente, você pode adicionar mais consultas para conferir

## 🧑‍💻 Autor

Criado por [Ralbert Rodrigues](https://www.linkedin.com/in/ralbert-rodrigues/)  
Analista de Banco de Dados com foco em PostgreSQL, focado em analise e administração de ambientes críticos.

---

Se esse script te ajudar ou tiver sugestões, sinta-se à vontade para contribuir ou abrir issues 🚀
