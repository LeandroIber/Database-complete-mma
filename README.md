# MMA Global Dataset

Dataset estruturado de **129.285 lutas de MMA** cobrindo o período **1993-2026** de mais de **4.300 organizações**, das quais **10 são organizações principais** (UFC, Bellator, ACA, Cage Warriors, LFA, Jungle Fight, PFL, KSW, Oktagon, Rizin). Construído em DuckDB, com pipeline ELT reprodutível, validação cruzada contra fontes externas e modelagem dimensional para análise.

Pronto para uso em Python (pandas), SQL puro ou ferramentas como DBeaver, Tableau e Power BI.

## 1. Visão geral

| Métrica | Valor |
|---|---|
| Lutas totais multi-organização | 129.285 |
| Lutas com estatísticas técnicas | 28.118 |
| Lutadores únicos | 15.801 |
| Organizações distintas | 4.353 |
| Organizações principais | 10 |
| Período coberto | 1993-02-11 a 2026-01-31 |
| Title fights validados | 383 |
| Recordes oficiais linkados | 1.060 |
---

## 2. Estrutura do banco

Arquivo único `data/dataset_global_v3.duckdb` com 6 tabelas:

### Tabelas principais

| Tabela | Linhas | Função |
|---|---|---|
| `fights_career_longitudinal` | 129.285 | Fato principal: lutas em todas as organizações |
| `fights_master_typed` | 28.118 | Fato detalhado: lutas com estatísticas técnicas granulares |
| `fighters_master` | 15.801 | Dimensão de lutadores (físico, nacionalidade, academia) |

### Tabelas de recordes oficiais

| Tabela | Linhas | Função |
|---|---|---|
| `records_career` | 346 | Recordes de carreira por lutador (Somente UFC) |
| `records_fight` | 572 | Recordes de luta única e por round (Somente UFC) |
| `records_event` | 142 | Recordes por evento (Somente UFC) |

### Relacionamentos

```
fighters_master ←── fighter_id ─── fights_career_longitudinal
                                    (todas as 4.353 organizações)
                │
                └── fighter_id ─── fights_master_typed
                                    (subset com stats técnicas)
                                            │
                                            └── fight_id ──→ records_fight
                                            
fighters_master ←── fighter_id ─── records_career

fights_master_typed ──── event_signature ──→ records_event
```

Detalhamento completo de cada coluna em `data_dictionary.md`

---

## 3. Fontes de dados

| Fonte | Cobertura | Uso no projeto |
|---|---|---|
| **Sherdog Fight Finder** | 1993-2026, todas as organizações | Base principal de lutas e lutadores |
| **UFCStats.com** | UFC oficial | Estatísticas técnicas granulares (sig_str, td, kd, ctrl) |
| **Wikipedia (List_of_UFC_champions)** | UFC, todas as divisões | Validação cruzada da flag `is_title_fight` |
| **statleaders.ufc.com** | UFC oficial | Recordes históricos (1.060 entradas, 93 leaderboards) |

---

## 4. Cobertura por organização

A cobertura de dados é **assimétrica entre organizações**. Esta é uma característica estrutural do dataset, decorrente da disponibilidade pública de informações.

### 4.1 Distribuição de lutas

| Organização | Lutas | Cobertura de stats técnicas |
|---|---|---|
| UFC | ~8.708 | 96-99% (sig_str, td, kd, ctrl, reach) |
| Demais 9 majors | ~28.000 | Apenas metadados (lutadores, método, round, tempo) |
| Organizações regionais | ~92.000 | Apenas metadados |

### 4.2 Por que UFC tem mais dados detalhados

A diferença de cobertura **não é uma escolha do projeto** é consequência de quais dados as próprias organizações divulgam publicamente:

| Aspecto | UFC | Demais organizações |
|---|---|---|
| Estatísticas granulares (sig_str, td, ctrl, kd) | ✓ Publicadas em `ufcstats.com` | ✗ Não publicadas oficialmente |
| Cobertura no Sherdog | ✓ Completa | ✓ Completa (metadados) |
| Recordes históricos consolidados | ✓ `statleaders.ufc.com` | ✗ Não existem equivalentes |
| Histórico de campeões estruturado | ✓ Wikipedia mantém | ⚠ Parcial |

Em termos práticos:

- **Você sabe quem ganhou e como** em qualquer luta de qualquer organização do banco (9 orgs)
- **Você sabe quantos golpes foram desferidos, quantas quedas, tempo de controle** apenas em lutas UFC
- **Você tem recordes oficiais cruzados** apenas para UFC

### 4.3 O que está coberto em **todas** as organizações

Para as 129.285 lutas em `fights_career_longitudinal`, você tem:

- Identificação: `fight_id`, `organization`, `event_name`, `event_date`, `event_location`
- Lutadores: `fighter_1`, `fighter_2`, `winner`
- Resultado: `method_normalized`, `round_num`, `time_finish_seconds`
- Categoria: `weight_class`, `is_title_fight`
- Físico no momento da luta: altura, peso (quando disponíveis no Sherdog)
- Contexto: árbitro, academias, nacionalidades, `is_major_org`

### 4.4 O que existe apenas para UFC

Em `fights_master_typed` (subset de 28.118 lutas), adicionalmente:

- `f1_sig_str_landed`, `f1_sig_str_attempted` (golpes significativos)
- `f1_td_landed`, `f1_td_attempted` (quedas)
- `f1_kd` (knockdowns aplicados)
- `f1_ctrl_seconds` (tempo de controle no chão)
- `f1_reach_cm` (envergadura — Sherdog não coleta esse campo)

Equivalentes para `f2_*`.

### 4.5 Recomendação de uso

Para análises **multi-organização** (carreiras de lutadores que passaram por UFC + Bellator + outros), use `fights_career_longitudinal`. Para análises **profundas de performance técnica** (eficiência de striking, padrão de quedas), use `fights_master_typed`.

---

## 5. Metodologia

### 5.1 Coleta inicial

Lutas e lutadores raspados do Sherdog Fight Finder, que mantém o catálogo público mais completo de eventos de MMA. Para UFC especificamente, estatísticas técnicas adicionais foram unidas via JOIN composto contra UFCStats.com por `(event_date ± 2 dias, sobrenomes dos lutadores)`.

### 5.2 Normalização de métodos

O campo bruto `method` tem 200+ variações (`KO (Punch to the Head)`, `Submission (Rear-Naked Choke)`, etc). Foi normalizado em 7 categorias canônicas via `method_normalized`:

- `KO` - Knockout (perda de consciência)
- `TKO` - Technical Knockout (interrupção médica/arbitral)
- `Submission` - Finalização
- `Decision` - Decisão dos juízes
- `DQ` - Desqualificação
- `Overturned` - Resultado revertido
- `Other` - Casos atípicos (ex: contusão sem golpe)

## 6. Limitações conhecidas

### 6.1 Estruturais (decorrentes das fontes)

| Limitação | Razão | Impacto |
|---|---|---|
| Estatísticas técnicas apenas UFC | Demais organizações não publicam dados granulares | Análises de striking/grappling restritas a UFC |
| `reach_cm` 70% NULL globalmente | Sherdog não coleta esse campo | Cobertura de reach: 96% UFC, ~0% fora |
| Pré-1993 ausente | UFC foi a primeira org com cobertura midiática | Banco começa em 11-02-1993 (UFC 1) |
| Eventos amadores ausentes | Sherdog não cataloga MMA amador | Análises focam em carreira profissional |

### 6.2 Divergências documentadas vs UFC oficial

Comparações sistemáticas contra `statleaders.ufc.com` revelaram divergências esperadas, todas explicáveis:

| Divergência | Causa | Lado afetado |
|---|---|---|
| Era pré-1997 incluída no banco | UFC oficial exclui torneios UFC 1-12 (open-weight) | Banco lista finalizações pré-1997 que oficial omite |
| Streak Jon Jones (19 vs 13) | Banco computa NC do UFC 214 diferente do oficial | Apenas em queries de sequência de vitórias |
| Title wins Matt Hughes (+2) | UFC 56 vs Riggs foi catchweight (oficial não conta) | Diferença ±2 entradas |
| Knockdowns ±1 | Sherdog e UFCStats divergem em rounds antigos | Margem editorial |

Essas divergências **não invalidam o dataset**. Refletem decisões editoriais da fonte oficial UFC que o banco não replica por escolha de cobertura histórica mais ampla.

---

## 7. Como usar

### Pré-requisitos

```bash
pip install -r requirements.txt
```

### Conexão básica (Python)

```python
import duckdb

con = duckdb.connect('data/dataset_global_v3.duckdb', read_only=True)

# Lista as tabelas
print(con.execute("SHOW TABLES").fetchall())

# Consulta multi-organização
df = con.execute("""
    SELECT organization, COUNT(*) AS lutas
    FROM fights_career_longitudinal
    WHERE is_major_org
    GROUP BY organization
    ORDER BY lutas DESC
""").fetchdf()
```

### Conexão via DBeaver

1. Instale o driver DuckDB: `Database` → `Driver Manager` → adicionar JDBC driver do DuckDB
2. Crie nova conexão apontando para `data/dataset_global_v3.duckdb`
3. As 6 tabelas aparecem no schema `main`

---

## 8. Exemplos de queries

### 8.1 Distribuição de lutas por organização principal

```sql
SELECT 
    organization,
    COUNT(*) AS lutas,
    COUNT(DISTINCT event_name) AS eventos,
    MIN(event_date) AS primeira,
    MAX(event_date) AS ultima
FROM fights_career_longitudinal
WHERE is_major_org
GROUP BY organization
ORDER BY lutas DESC;
```
<img width="669" height="300" alt="image" src="https://github.com/user-attachments/assets/72297b66-c6fd-48dd-84eb-82882e6256e1" />



### 8.2 Carreiras multi-organização

```sql
SELECT 
    fighter_name,
    COUNT(DISTINCT organization) AS orgs,
    STRING_AGG(DISTINCT organization, ', ') AS organizacoes
FROM (
    SELECT fighter_1 AS fighter_name, organization FROM fights_career_longitudinal WHERE is_major_org
    UNION ALL
    SELECT fighter_2, organization FROM fights_career_longitudinal WHERE is_major_org
)
GROUP BY fighter_name
HAVING COUNT(DISTINCT organization) >= 4
ORDER BY orgs DESC;
```
<img width="623" height="533" alt="image" src="https://github.com/user-attachments/assets/752a93e0-47a7-4ee4-a0d4-bf7610b63dbb" />


### 8.3 Performance técnica UFC (queda + controle)

```sql
SELECT 
    fighter_1,
    f1_td_landed,
    f1_ctrl_seconds,
    weight_class,
    event_name
FROM fights_master_typed
WHERE organization = 'ufc'
  AND f1_td_landed >= 10
  AND winner = fighter_1
ORDER BY f1_td_landed DESC
LIMIT 20;
```
<img width="843" height="414" alt="image" src="https://github.com/user-attachments/assets/8835136e-a0b7-465a-a0a3-4782251d1853" />


### 8.4 Validação cross-source

```sql
SELECT 
    r.rank, r.fighter_name,
    r.valor_num AS oficial,
    COUNT(fmt.fight_id) AS banco,
    COUNT(fmt.fight_id) - r.valor_num AS diferenca
FROM records_career r
JOIN fighters_master f ON f.fighter_id = r.fighter_id
LEFT JOIN fights_master_typed fmt 
    ON fmt.winner = f.fighter_name 
   AND fmt.organization = 'ufc'
WHERE r.categoria = 'Vitórias'
GROUP BY r.rank, r.fighter_name, r.valor_num
ORDER BY r.rank LIMIT 10;
```
<img width="619" height="223" alt="image" src="https://github.com/user-attachments/assets/3230a6ac-d61b-4b99-a595-dd9fde653833" />

### 8.5 Maiores finalizadores UFC

```sql
SELECT 
    winner AS lutador,
    COUNT(*) AS submissoes
FROM fights_master_typed
WHERE organization = 'ufc'
  AND method_normalized = 'Submission'
  AND winner IN (fighter_1, fighter_2)
GROUP BY winner
ORDER BY submissoes DESC
LIMIT 20;
```
<img width="291" height="413" alt="image" src="https://github.com/user-attachments/assets/266c721d-d9c0-4392-b4cc-a1995adad5ec" />

### 8.6 Maiores nocauteadores UFC

```sql
SELECT 
    winner AS lutador,
    COUNT(*) AS nocautes,
    SUM(CASE WHEN method_normalized = 'KO' THEN 1 ELSE 0 END) AS ko,
    SUM(CASE WHEN method_normalized = 'TKO' THEN 1 ELSE 0 END) AS tko
FROM fights_master_typed
WHERE organization = 'ufc'
  AND method_normalized IN ('KO', 'TKO')
  AND winner IN (fighter_1, fighter_2)
GROUP BY winner
ORDER BY nocautes DESC
LIMIT 20;
```
<img width="449" height="412" alt="image" src="https://github.com/user-attachments/assets/fb11225a-d4ff-4cf7-9daf-dce523f417f6" />







---

