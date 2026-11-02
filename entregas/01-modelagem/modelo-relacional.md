# Modelo relacional Frigus

Inventario exportado do FrigusDB Prod em 2026-11-01 apos o bootstrap. A descricao completa de colunas, constraints, cardinalidades e chaves esta nos arquivos vinculados abaixo.

## Escopo e normalizacao

O modelo transacional e composto pelas tabelas de `public`; `analytics` e `dw` implementam a camada dimensional para BI, e `audit.row_change_log` e um registro de eventos. Tabelas agregadas `public.dm_*` sao resultados analiticos e nao fazem parte da avaliacao de 3FN do modelo transacional.

As entidades operacionais tem PKs declaradas; associacoes N:N sao representadas por tabelas de ligacao com constraints de unicidade. As tabelas de dimensao e fato seguem o Star Schema, portanto sua desnormalizacao e intencional e separada da normalizacao transacional. O arquivo `normalizacao-3fn.md` registra o escopo e as excecoes que devem ser consideradas ao avaliar dependencias funcionais.

## Chaves e relacionamentos

- [`relacionamentos-pk-fk.csv`](relacionamentos-pk-fk.csv) lista todas as FKs do snapshot com relacao pai/filho, obrigatoriedade no lado filho e cardinalidade maxima calculada pela existencia de PK/UNIQUE equivalente.
- [`../04-governanca/catalogo-de-dados.csv`](../04-governanca/catalogo-de-dados.csv) lista cada objeto e coluna com tipo, regras estruturais, nivel de acesso e classificacao.

## Tabelas, colunas e chaves

### `audit.row_change_log`

| Coluna | Tipo | Nulavel | Default |
|---|---|---:|---|
| `id` | `bigint` | nao | `` |
| `changed_at` | `timestamp with time zone` | nao | `clock_timestamp()` |
| `table_schema` | `text` | nao | `` |
| `table_name` | `text` | nao | `` |
| `operation` | `text` | nao | `` |
| `current_user_name` | `text` | nao | `` |
| `old_row` | `jsonb` | sim | `` |
| `new_row` | `jsonb` | sim | `` |

PK: `PRIMARY KEY (id)`

### `dw.dim_date`

| Coluna | Tipo | Nulavel | Default |
|---|---|---:|---|
| `date_key` | `date` | nao | `` |
| `year` | `integer` | nao | `` |
| `month` | `integer` | nao | `` |
| `week_start` | `date` | nao | `` |
| `day_of_week` | `integer` | nao | `` |
| `is_weekend` | `boolean` | nao | `` |

PK: `PRIMARY KEY (date_key)`

### `dw.dim_group`

| Coluna | Tipo | Nulavel | Default |
|---|---|---:|---|
| `group_key` | `integer` | nao | `` |
| `group_id` | `uuid` | nao | `` |
| `group_name` | `character varying` | nao | `` |

PK: `PRIMARY KEY (group_key)`

UNIQUE: `UNIQUE (group_id)`

### `dw.dim_product`

| Coluna | Tipo | Nulavel | Default |
|---|---|---:|---|
| `product_key` | `integer` | nao | `` |
| `product_id` | `integer` | nao | `` |
| `product_name` | `character varying` | nao | `` |
| `category` | `text` | sim | `` |
| `storage_place` | `text` | sim | `` |
| `unit_of_measure` | `text` | sim | `` |
| `brand` | `character varying` | sim | `` |

PK: `PRIMARY KEY (product_key)`

UNIQUE: `UNIQUE (product_id)`

### `dw.dim_stock`

| Coluna | Tipo | Nulavel | Default |
|---|---|---:|---|
| `stock_key` | `integer` | nao | `` |
| `stock_id` | `integer` | nao | `` |
| `stock_name` | `character varying` | nao | `` |
| `group_key` | `integer` | sim | `` |

PK: `PRIMARY KEY (stock_key)`

UNIQUE: `UNIQUE (stock_id)`

### `dw.dim_user`

| Coluna | Tipo | Nulavel | Default |
|---|---|---:|---|
| `user_key` | `integer` | nao | `` |
| `user_id` | `uuid` | nao | `` |
| `user_name` | `character varying` | sim | `` |
| `account_type` | `text` | sim | `` |

PK: `PRIMARY KEY (user_key)`

UNIQUE: `UNIQUE (user_id)`

### `dw.fact_stock_movement`

| Coluna | Tipo | Nulavel | Default |
|---|---|---:|---|
| `movement_id` | `integer` | nao | `` |
| `date_key` | `date` | nao | `` |
| `moved_at` | `timestamp without time zone` | nao | `` |
| `product_key` | `integer` | nao | `` |
| `stock_key` | `integer` | nao | `` |
| `group_key` | `integer` | nao | `` |
| `user_key` | `integer` | sim | `` |
| `movement_type` | `text` | nao | `` |
| `quantity` | `integer` | nao | `` |
| `balance_after_source` | `integer` | sim | `` |
| `purpose` | `character varying` | sim | `` |
| `loaded_at` | `timestamp with time zone` | nao | `now()` |

PK: `PRIMARY KEY (movement_id)`

### `dw.user_daily_access`

| Coluna | Tipo | Nulavel | Default |
|---|---|---:|---|
| `user_id` | `uuid` | nao | `` |
| `access_date` | `date` | nao | `` |
| `first_access_at` | `timestamp with time zone` | nao | `` |

PK: `PRIMARY KEY (user_id, access_date)`

### `governance.data_catalog`

| Coluna | Tipo | Nulavel | Default |
|---|---|---:|---|
| `object_schema` | `text` | nao | `` |
| `object_name` | `text` | nao | `` |
| `object_type` | `text` | nao | `` |
| `column_name` | `text` | nao | `` |
| `ordinal_position` | `integer` | nao | `0` |
| `data_type` | `text` | sim | `` |
| `description` | `text` | nao | `` |
| `business_rules` | `text` | nao | `` |
| `access_level` | `text` | nao | `` |
| `data_classification` | `text` | nao | `` |
| `metadata_updated_at` | `timestamp with time zone` | nao | `now()` |

PK: `PRIMARY KEY (object_schema, object_name, column_name)`

### `public.advertisements`

| Coluna | Tipo | Nulavel | Default |
|---|---|---:|---|
| `id` | `uuid` | nao | `gen_random_uuid()` |
| `advertiser_id` | `uuid` | nao | `` |
| `name` | `character varying(120)` | nao | `` |
| `product_name` | `character varying(160)` | nao | `` |
| `category` | `character varying(80)` | nao | `` |
| `description` | `character varying(2000)` | nao | `` |
| `image_url` | `character varying(2048)` | nao | `` |
| `destination_url` | `character varying(2048)` | sim | `` |
| `price` | `numeric(12,2)` | sim | `` |
| `start_date` | `date` | sim | `` |
| `end_date` | `date` | sim | `` |
| `status` | `character varying(16)` | nao | `'DRAFT'::character varying` |
| `impressions` | `bigint` | nao | `0` |
| `clicks` | `bigint` | nao | `0` |
| `created_at` | `timestamp without time zone` | nao | `CURRENT_TIMESTAMP` |
| `updated_at` | `timestamp without time zone` | nao | `CURRENT_TIMESTAMP` |

PK: `PRIMARY KEY (id)`

### `public.business_expenses`

| Coluna | Tipo | Nulavel | Default |
|---|---|---:|---|
| `id` | `uuid` | nao | `gen_random_uuid()` |
| `group_id` | `uuid` | nao | `` |
| `created_by` | `uuid` | nao | `` |
| `description` | `character varying(255)` | nao | `` |
| `category` | `character varying(120)` | nao | `` |
| `amount` | `numeric(12,2)` | nao | `` |
| `expense_date` | `date` | nao | `` |
| `supplier` | `character varying(255)` | sim | `` |
| `shopping_list_id` | `uuid` | sim | `` |
| `created_at` | `timestamp without time zone` | nao | `CURRENT_TIMESTAMP` |
| `updated_at` | `timestamp without time zone` | nao | `CURRENT_TIMESTAMP` |

PK: `PRIMARY KEY (id)`

UNIQUE: `UNIQUE (shopping_list_id)`

### `public.conversation_participants`

| Coluna | Tipo | Nulavel | Default |
|---|---|---:|---|
| `conversation_id` | `uuid` | nao | `` |
| `user_id` | `uuid` | nao | `` |
| `joined_at` | `timestamp without time zone` | nao | `CURRENT_TIMESTAMP` |
| `left_at` | `timestamp without time zone` | sim | `` |
| `updated_at` | `timestamp without time zone` | nao | `CURRENT_TIMESTAMP` |

PK: `PRIMARY KEY (conversation_id, user_id)`

### `public.conversations`

| Coluna | Tipo | Nulavel | Default |
|---|---|---:|---|
| `id` | `uuid` | nao | `gen_random_uuid()` |
| `conversation_type` | `conversation_type_enum` | nao | `` |
| `group_id` | `uuid` | sim | `` |
| `name` | `character varying` | sim | `` |
| `pair_key` | `character varying` | sim | `` |
| `created_at` | `timestamp without time zone` | sim | `CURRENT_TIMESTAMP` |
| `updated_at` | `timestamp without time zone` | nao | `CURRENT_TIMESTAMP` |

PK: `PRIMARY KEY (id)`

UNIQUE: `UNIQUE (pair_key)`

### `public.discard`

| Coluna | Tipo | Nulavel | Default |
|---|---|---:|---|
| `id` | `integer` | nao | `nextval('discard_id_seq'::regclass)` |
| `stock_product_id` | `integer` | nao | `` |
| `reason` | `text` | sim | `` |
| `date` | `timestamp without time zone` | nao | `CURRENT_TIMESTAMP` |
| `updated_at` | `timestamp without time zone` | nao | `CURRENT_TIMESTAMP` |
| `quantity` | `integer` | sim | `1` |
| `movement_id` | `integer` | sim | `` |
| `reason_code` | `character varying(24)` | sim | `` |
| `canceled_at` | `timestamp with time zone` | sim | `` |

PK: `PRIMARY KEY (id)`

UNIQUE: `UNIQUE (movement_id)`

### `public.dm_recipe_performance`

| Coluna | Tipo | Nulavel | Default |
|---|---|---:|---|
| `dm_id` | `bigint` | nao | `nextval('dm_recipe_performance_dm_id_seq'::regclass)` |
| `recipe_id` | `integer` | nao | `` |
| `recipe_name` | `character varying` | nao | `` |
| `total_suggestions` | `integer` | sim | `0` |
| `unique_stocks_suggested` | `integer` | sim | `0` |
| `avg_suggestion_score` | `numeric(5,2)` | sim | `` |
| `total_ingredients` | `integer` | sim | `` |
| `avg_available_ingredients` | `numeric(5,2)` | sim | `` |
| `suggestion_trend_7d` | `integer` | sim | `` |
| `suggestion_trend_30d` | `integer` | sim | `` |
| `is_domestic_only` | `boolean` | sim | `true` |
| `is_active` | `boolean` | sim | `true` |
| `last_suggested_date` | `timestamp without time zone` | sim | `` |
| `created_at` | `timestamp without time zone` | sim | `CURRENT_TIMESTAMP` |
| `updated_at` | `timestamp without time zone` | sim | `CURRENT_TIMESTAMP` |

PK: `PRIMARY KEY (dm_id)`

### `public.dm_stock_health_daily`

| Coluna | Tipo | Nulavel | Default |
|---|---|---:|---|
| `dm_id` | `bigint` | nao | `nextval('dm_stock_health_daily_dm_id_seq'::regclass)` |
| `snapshot_date` | `date` | nao | `` |
| `stock_id` | `integer` | nao | `` |
| `stock_name` | `character varying` | nao | `` |
| `group_id` | `uuid` | nao | `` |
| `total_products` | `integer` | sim | `` |
| `fresh_products` | `integer` | sim | `` |
| `near_expiration_products` | `integer` | sim | `` |
| `expired_products` | `integer` | sim | `` |
| `total_quantity` | `integer` | sim | `` |
| `daily_inbound` | `integer` | sim | `0` |
| `daily_outbound` | `integer` | sim | `0` |
| `daily_adjustments` | `integer` | sim | `0` |
| `net_movement` | `integer` | sim | `` |
| `top_category` | `character varying` | sim | `` |
| `top_category_quantity` | `integer` | sim | `` |
| `unique_users_accessing` | `integer` | sim | `` |
| `total_shopping_lists` | `bigint` | sim | `` |
| `created_at` | `timestamp without time zone` | sim | `CURRENT_TIMESTAMP` |
| `updated_at` | `timestamp without time zone` | sim | `CURRENT_TIMESTAMP` |

PK: `PRIMARY KEY (dm_id)`

### `public.dm_user_ltv`

| Coluna | Tipo | Nulavel | Default |
|---|---|---:|---|
| `dm_id` | `bigint` | nao | `nextval('dm_user_ltv_dm_id_seq'::regclass)` |
| `user_id` | `uuid` | nao | `` |
| `user_name` | `character varying` | nao | `` |
| `account_type` | `character varying` | sim | `` |
| `total_messages` | `integer` | sim | `0` |
| `total_stock_movements` | `integer` | sim | `0` |
| `total_requests` | `integer` | sim | `0` |
| `total_transactions` | `bigint` | sim | `0` |
| `total_spent` | `numeric(12,2)` | sim | `0` |
| `subscription_status` | `character varying` | sim | `` |
| `days_active` | `integer` | sim | `` |
| `engagement_score` | `numeric(8,2)` | sim | `` |
| `activity_frequency` | `character varying` | sim | `` |
| `churn_risk` | `boolean` | sim | `false` |
| `first_activity_date` | `timestamp without time zone` | sim | `` |
| `last_activity_date` | `timestamp without time zone` | sim | `` |
| `created_at` | `timestamp without time zone` | sim | `CURRENT_TIMESTAMP` |
| `updated_at` | `timestamp without time zone` | sim | `CURRENT_TIMESTAMP` |

PK: `PRIMARY KEY (dm_id)`

UNIQUE: `UNIQUE (user_id)`

### `public.flyway_schema_history`

| Coluna | Tipo | Nulavel | Default |
|---|---|---:|---|
| `installed_rank` | `integer` | nao | `` |
| `version` | `character varying(50)` | sim | `` |
| `description` | `character varying(200)` | nao | `` |
| `type` | `character varying(20)` | nao | `` |
| `script` | `character varying(1000)` | nao | `` |
| `checksum` | `integer` | sim | `` |
| `installed_by` | `character varying(100)` | nao | `` |
| `installed_on` | `timestamp without time zone` | nao | `now()` |
| `execution_time` | `integer` | nao | `` |
| `success` | `boolean` | nao | `` |

PK: `PRIMARY KEY (installed_rank)`

### `public.food_purchase_lines`

| Coluna | Tipo | Nulavel | Default |
|---|---|---:|---|
| `id` | `bigint` | nao | `nextval('food_purchase_lines_id_seq'::regclass)` |
| `purchase_id` | `uuid` | nao | `` |
| `stock_key` | `integer` | nao | `` |
| `stock_product_id` | `integer` | sim | `` |
| `product_id` | `integer` | sim | `` |
| `product_name` | `text` | nao | `` |
| `category` | `character varying(24)` | nao | `` |
| `category_group` | `character varying(24)` | nao | `` |
| `unit_of_measure` | `character varying(24)` | nao | `` |
| `expire_date` | `date` | nao | `` |
| `quantity` | `integer` | nao | `` |
| `unit_price` | `numeric(10,2)` | nao | `` |

PK: `PRIMARY KEY (id)`

### `public.food_purchase_revisions`

| Coluna | Tipo | Nulavel | Default |
|---|---|---:|---|
| `id` | `bigint` | nao | `nextval('food_purchase_revisions_id_seq'::regclass)` |
| `purchase_id` | `uuid` | nao | `` |
| `previous_version` | `integer` | nao | `` |
| `previous_state` | `jsonb` | nao | `` |
| `changed_by` | `uuid` | nao | `` |
| `changed_at` | `timestamp with time zone` | nao | `now()` |

PK: `PRIMARY KEY (id)`

### `public.food_purchases`

| Coluna | Tipo | Nulavel | Default |
|---|---|---:|---|
| `id` | `uuid` | nao | `gen_random_uuid()` |
| `group_id` | `uuid` | nao | `` |
| `purchase_date` | `date` | nao | `` |
| `source` | `character varying(24)` | nao | `` |
| `receipt_reference` | `character varying(160)` | sim | `` |
| `idempotency_key` | `character varying(160)` | nao | `` |
| `request_hash` | `character varying(64)` | nao | `` |
| `version` | `integer` | nao | `1` |
| `created_at` | `timestamp with time zone` | nao | `now()` |
| `updated_at` | `timestamp with time zone` | nao | `now()` |
| `deleted_at` | `timestamp with time zone` | sim | `` |

PK: `PRIMARY KEY (id)`

UNIQUE: `UNIQUE (group_id, idempotency_key)`

### `public.group_invitations`

| Coluna | Tipo | Nulavel | Default |
|---|---|---:|---|
| `id` | `uuid` | nao | `gen_random_uuid()` |
| `group_id` | `uuid` | nao | `` |
| `email` | `character varying(255)` | nao | `` |
| `name` | `character varying(255)` | sim | `` |
| `member_role` | `character varying(16)` | nao | `` |
| `token_hash` | `character varying(64)` | nao | `` |
| `expires_at` | `timestamp without time zone` | nao | `` |
| `accepted_at` | `timestamp without time zone` | sim | `` |
| `revoked_at` | `timestamp without time zone` | sim | `` |
| `created_at` | `timestamp without time zone` | nao | `CURRENT_TIMESTAMP` |

PK: `PRIMARY KEY (id)`

UNIQUE: `UNIQUE (token_hash)`

### `public.groups`

| Coluna | Tipo | Nulavel | Default |
|---|---|---:|---|
| `id` | `uuid` | nao | `gen_random_uuid()` |
| `name` | `character varying` | nao | `` |
| `banner_picture` | `text` | sim | `` |
| `created_at` | `timestamp without time zone` | nao | `CURRENT_TIMESTAMP` |
| `updated_at` | `timestamp without time zone` | nao | `CURRENT_TIMESTAMP` |
| `deleted_at` | `timestamp without time zone` | sim | `` |
| `owner_id` | `uuid` | sim | `` |
| `time_zone` | `character varying(80)` | nao | `'America/Sao_Paulo'::character varying` |

PK: `PRIMARY KEY (id)`

### `public.message_attachments`

| Coluna | Tipo | Nulavel | Default |
|---|---|---:|---|
| `id` | `integer` | nao | `nextval('message_attachments_id_seq'::regclass)` |
| `message_id` | `integer` | nao | `` |
| `file_url` | `text` | nao | `` |
| `file_name` | `character varying` | sim | `` |
| `mime_type` | `character varying` | nao | `` |
| `file_size` | `integer` | sim | `` |
| `created_at` | `timestamp without time zone` | nao | `CURRENT_TIMESTAMP` |
| `updated_at` | `timestamp without time zone` | nao | `CURRENT_TIMESTAMP` |

PK: `PRIMARY KEY (id)`

### `public.message_reactions`

| Coluna | Tipo | Nulavel | Default |
|---|---|---:|---|
| `id` | `integer` | nao | `nextval('message_reactions_id_seq'::regclass)` |
| `message_id` | `integer` | nao | `` |
| `user_id` | `uuid` | nao | `` |
| `emoji` | `character varying(16)` | nao | `` |
| `created_at` | `timestamp without time zone` | nao | `CURRENT_TIMESTAMP` |

PK: `PRIMARY KEY (id)`

UNIQUE: `UNIQUE (message_id, user_id, emoji)`

### `public.message_reads`

| Coluna | Tipo | Nulavel | Default |
|---|---|---:|---|
| `message_id` | `integer` | nao | `` |
| `conversation_id` | `uuid` | nao | `` |
| `user_id` | `uuid` | nao | `` |
| `read_at` | `timestamp without time zone` | nao | `CURRENT_TIMESTAMP` |

PK: `PRIMARY KEY (message_id, user_id)`

### `public.messages`

| Coluna | Tipo | Nulavel | Default |
|---|---|---:|---|
| `id` | `integer` | nao | `nextval('messages_id_seq'::regclass)` |
| `conversation_id` | `uuid` | nao | `` |
| `sender_id` | `uuid` | nao | `` |
| `message_type` | `message_type_enum` | nao | `` |
| `content` | `text` | sim | `` |
| `related_shopping_list_product_id` | `integer` | sim | `` |
| `created_at` | `timestamp without time zone` | sim | `CURRENT_TIMESTAMP` |
| `updated_at` | `timestamp without time zone` | nao | `CURRENT_TIMESTAMP` |

PK: `PRIMARY KEY (id)`

UNIQUE: `UNIQUE (id, conversation_id)`

### `public.money_allocations`

| Coluna | Tipo | Nulavel | Default |
|---|---|---:|---|
| `id` | `bigint` | nao | `nextval('money_allocations_id_seq'::regclass)` |
| `exit_id` | `bigint` | nao | `` |
| `supply_id` | `bigint` | sim | `` |
| `quantity` | `integer` | nao | `` |
| `amount` | `numeric(20,2)` | sim | `` |
| `category_group` | `character varying(24)` | sim | `` |

PK: `PRIMARY KEY (id)`

### `public.money_exits`

| Coluna | Tipo | Nulavel | Default |
|---|---|---:|---|
| `id` | `bigint` | nao | `nextval('money_exits_id_seq'::regclass)` |
| `group_id` | `uuid` | nao | `` |
| `stock_key` | `integer` | nao | `` |
| `stock_product_id` | `integer` | sim | `` |
| `product_name` | `text` | nao | `` |
| `category` | `character varying(24)` | nao | `` |
| `unit_of_measure` | `character varying(24)` | nao | `` |
| `expire_date` | `date` | nao | `` |
| `occurred_at` | `timestamp with time zone` | nao | `` |
| `local_date` | `date` | nao | `` |
| `quantity` | `integer` | nao | `` |
| `kind` | `character varying(24)` | nao | `` |
| `reason_code` | `character varying(24)` | sim | `` |
| `movement_id` | `integer` | sim | `` |
| `discard_id` | `integer` | sim | `` |
| `canceled_at` | `timestamp with time zone` | sim | `` |

PK: `PRIMARY KEY (id)`

### `public.money_supplies`

| Coluna | Tipo | Nulavel | Default |
|---|---|---:|---|
| `id` | `bigint` | nao | `nextval('money_supplies_id_seq'::regclass)` |
| `stock_key` | `integer` | nao | `` |
| `stock_product_id` | `integer` | sim | `` |
| `purchase_line_id` | `bigint` | sim | `` |
| `available_on` | `date` | nao | `` |
| `quantity` | `integer` | nao | `` |
| `unknown_cost` | `boolean` | nao | `` |
| `created_at` | `timestamp with time zone` | nao | `now()` |

PK: `PRIMARY KEY (id)`

UNIQUE: `UNIQUE (purchase_line_id)`

### `public.notifications`

| Coluna | Tipo | Nulavel | Default |
|---|---|---:|---|
| `id` | `uuid` | nao | `gen_random_uuid()` |
| `recipient_user_id` | `uuid` | nao | `` |
| `group_id` | `uuid` | sim | `` |
| `type` | `notification_type_enum` | nao | `` |
| `title` | `character varying` | nao | `` |
| `body` | `text` | nao | `` |
| `reference_id` | `character varying(120)` | sim | `` |
| `deduplication_key` | `character varying(220)` | sim | `` |
| `read_at` | `timestamp without time zone` | sim | `` |
| `created_at` | `timestamp without time zone` | nao | `CURRENT_TIMESTAMP` |
| `deleted_at` | `timestamp without time zone` | sim | `` |

PK: `PRIMARY KEY (id)`

### `public.password_reset_tokens`

| Coluna | Tipo | Nulavel | Default |
|---|---|---:|---|
| `id` | `uuid` | nao | `gen_random_uuid()` |
| `user_id` | `uuid` | nao | `` |
| `token_hash` | `character varying(64)` | nao | `` |
| `expires_at` | `timestamp without time zone` | nao | `` |
| `consumed_at` | `timestamp without time zone` | sim | `` |
| `created_at` | `timestamp without time zone` | nao | `CURRENT_TIMESTAMP` |

PK: `PRIMARY KEY (id)`

UNIQUE: `UNIQUE (token_hash)`

### `public.plans`

| Coluna | Tipo | Nulavel | Default |
|---|---|---:|---|
| `id` | `integer` | nao | `nextval('plans_id_seq'::regclass)` |
| `name` | `character varying` | nao | `` |
| `description` | `text` | sim | `` |
| `price` | `numeric(10,2)` | nao | `0` |
| `billing_interval` | `billing_interval_enum` | sim | `` |
| `active` | `boolean` | nao | `true` |
| `created_at` | `timestamp without time zone` | nao | `CURRENT_TIMESTAMP` |
| `updated_at` | `timestamp without time zone` | nao | `CURRENT_TIMESTAMP` |
| `deleted_at` | `timestamp without time zone` | sim | `` |
| `plan_code` | `character varying(20)` | nao | `` |

PK: `PRIMARY KEY (id)`

UNIQUE: `UNIQUE (plan_code)`

### `public.products`

| Coluna | Tipo | Nulavel | Default |
|---|---|---:|---|
| `id` | `integer` | nao | `nextval('products_id_seq'::regclass)` |
| `name` | `character varying` | nao | `` |
| `category` | `category_enum` | nao | `` |
| `storage_place` | `storage_place_enum` | nao | `` |
| `unit_price` | `numeric(10,2)` | nao | `` |
| `unit_of_measure` | `unit_of_measure_enum` | nao | `` |
| `created_at` | `timestamp without time zone` | nao | `CURRENT_TIMESTAMP` |
| `updated_at` | `timestamp without time zone` | nao | `CURRENT_TIMESTAMP` |
| `brand` | `character varying(120)` | sim | `` |
| `image_url` | `text` | sim | `` |
| `owner_group_id` | `uuid` | sim | `` |

PK: `PRIMARY KEY (id)`

### `public.receipt_draft_lines`

| Coluna | Tipo | Nulavel | Default |
|---|---|---:|---|
| `id` | `uuid` | nao | `gen_random_uuid()` |
| `receipt_id` | `uuid` | nao | `` |
| `description` | `character varying(500)` | nao | `` |
| `quantity` | `integer` | nao | `` |
| `unit` | `character varying(30)` | sim | `` |
| `unit_price` | `numeric(12,2)` | sim | `` |
| `total_price` | `numeric(12,2)` | sim | `` |
| `confidence` | `double precision` | sim | `` |
| `evidence` | `character varying(1000)` | sim | `` |
| `matched_product_id` | `integer` | sim | `` |
| `expire_date` | `date` | sim | `` |
| `normalized_product_name` | `character varying(255)` | sim | `` |
| `brand` | `character varying(120)` | sim | `` |
| `category` | `character varying(30)` | sim | `` |
| `storage_place` | `character varying(30)` | sim | `` |
| `unit_of_measure` | `character varying(30)` | sim | `` |

PK: `PRIMARY KEY (id)`

### `public.receipt_drafts`

| Coluna | Tipo | Nulavel | Default |
|---|---|---:|---|
| `id` | `uuid` | nao | `gen_random_uuid()` |
| `stock_id` | `integer` | nao | `` |
| `created_by` | `uuid` | nao | `` |
| `status` | `character varying(30)` | nao | `` |
| `access_key` | `character varying(44)` | sim | `` |
| `issuer_name` | `character varying(255)` | sim | `` |
| `issued_at` | `timestamp with time zone` | sim | `` |
| `total_amount` | `numeric(12,2)` | sim | `` |
| `warnings` | `jsonb` | nao | `'[]'::jsonb` |
| `created_at` | `timestamp with time zone` | nao | `CURRENT_TIMESTAMP` |
| `imported_at` | `timestamp with time zone` | sim | `` |

PK: `PRIMARY KEY (id)`

UNIQUE: `UNIQUE (stock_id, access_key)`

### `public.recipe_favorites`

| Coluna | Tipo | Nulavel | Default |
|---|---|---:|---|
| `id` | `uuid` | nao | `gen_random_uuid()` |
| `user_id` | `uuid` | nao | `` |
| `recipe_id` | `integer` | nao | `` |
| `created_at` | `timestamp without time zone` | nao | `CURRENT_TIMESTAMP` |

PK: `PRIMARY KEY (id)`

UNIQUE: `UNIQUE (user_id, recipe_id)`

### `public.recipe_ingredients`

| Coluna | Tipo | Nulavel | Default |
|---|---|---:|---|
| `id` | `integer` | nao | `nextval('recipe_ingredients_id_seq'::regclass)` |
| `recipe_id` | `integer` | nao | `` |
| `product_id` | `integer` | nao | `` |
| `quantity` | `numeric` | sim | `` |
| `unit` | `character varying` | sim | `` |
| `required` | `boolean` | nao | `true` |
| `created_at` | `timestamp without time zone` | nao | `CURRENT_TIMESTAMP` |
| `updated_at` | `timestamp without time zone` | nao | `CURRENT_TIMESTAMP` |

PK: `PRIMARY KEY (id)`

UNIQUE: `UNIQUE (recipe_id, product_id)`

### `public.recipe_suggestions`

| Coluna | Tipo | Nulavel | Default |
|---|---|---:|---|
| `id` | `integer` | nao | `nextval('recipe_suggestions_id_seq'::regclass)` |
| `recipe_id` | `integer` | nao | `` |
| `stock_id` | `integer` | nao | `` |
| `matched_ingredients` | `integer` | nao | `0` |
| `missing_ingredients` | `integer` | nao | `0` |
| `nearest_expire_date` | `date` | sim | `` |
| `score` | `numeric` | sim | `` |
| `created_at` | `timestamp without time zone` | nao | `CURRENT_TIMESTAMP` |
| `updated_at` | `timestamp without time zone` | nao | `CURRENT_TIMESTAMP` |

PK: `PRIMARY KEY (id)`

### `public.recipes`

| Coluna | Tipo | Nulavel | Default |
|---|---|---:|---|
| `id` | `integer` | nao | `nextval('recipes_id_seq'::regclass)` |
| `name` | `character varying` | nao | `` |
| `description` | `text` | sim | `` |
| `instructions` | `text` | sim | `` |
| `domestic_only` | `boolean` | nao | `true` |
| `active` | `boolean` | nao | `true` |
| `created_at` | `timestamp without time zone` | nao | `CURRENT_TIMESTAMP` |
| `updated_at` | `timestamp without time zone` | nao | `CURRENT_TIMESTAMP` |

PK: `PRIMARY KEY (id)`

### `public.requests`

| Coluna | Tipo | Nulavel | Default |
|---|---|---:|---|
| `id` | `integer` | nao | `nextval('requests_id_seq'::regclass)` |
| `user_id` | `uuid` | nao | `` |
| `product_id` | `integer` | nao | `` |
| `stock_id` | `integer` | nao | `` |
| `quantity` | `integer` | nao | `` |
| `description` | `text` | sim | `` |
| `picture` | `text` | sim | `` |
| `date` | `date` | nao | `CURRENT_DATE` |
| `conversation_id` | `uuid` | sim | `` |
| `message_id` | `integer` | sim | `` |
| `updated_at` | `timestamp without time zone` | nao | `CURRENT_TIMESTAMP` |

PK: `PRIMARY KEY (id)`

### `public.shopping_list_products`

| Coluna | Tipo | Nulavel | Default |
|---|---|---:|---|
| `id` | `integer` | nao | `nextval('shopping_list_products_id_seq'::regclass)` |
| `list_id` | `uuid` | nao | `` |
| `product_id` | `integer` | nao | `` |
| `status` | `product_list_status_enum` | nao | `'PENDING'::product_list_status_enum` |
| `quantity` | `integer` | nao | `1` |
| `created_at` | `timestamp without time zone` | nao | `CURRENT_TIMESTAMP` |
| `updated_at` | `timestamp without time zone` | nao | `CURRENT_TIMESTAMP` |
| `purchased_unit_price` | `numeric(10,2)` | sim | `` |
| `notes` | `character varying(255)` | sim | `` |
| `added_by` | `character varying(50)` | nao | `'Adicionado por você'::character varying` |

PK: `PRIMARY KEY (id)`

UNIQUE: `UNIQUE (list_id, product_id)`

### `public.shopping_lists`

| Coluna | Tipo | Nulavel | Default |
|---|---|---:|---|
| `id` | `uuid` | nao | `gen_random_uuid()` |
| `date` | `date` | nao | `CURRENT_DATE` |
| `stock_id` | `integer` | nao | `` |
| `status` | `list_status_enum` | nao | `` |
| `created_at` | `timestamp without time zone` | nao | `CURRENT_TIMESTAMP` |
| `updated_at` | `timestamp without time zone` | nao | `CURRENT_TIMESTAMP` |
| `name` | `character varying(255)` | nao | `'Lista de compras'::character varying` |
| `supplier` | `character varying(255)` | sim | `` |
| `completed_at` | `timestamp without time zone` | sim | `` |
| `total` | `numeric(12,2)` | sim | `` |
| `added_by` | `character varying(50)` | nao | `'Adicionado por você'::character varying` |

PK: `PRIMARY KEY (id)`

### `public.stock_movements`

| Coluna | Tipo | Nulavel | Default |
|---|---|---:|---|
| `id` | `integer` | nao | `nextval('stock_movements_id_seq'::regclass)` |
| `stock_product_id` | `integer` | nao | `` |
| `user_id` | `uuid` | nao | `` |
| `movement_type` | `movement_type_enum` | nao | `` |
| `quantity` | `integer` | nao | `` |
| `date` | `timestamp without time zone` | sim | `CURRENT_TIMESTAMP` |
| `observation` | `character varying(2000)` | sim | `` |
| `balance_after` | `integer` | sim | `` |
| `purpose` | `character varying(20)` | nao | `'INVENTORY'::character varying` |
| `reason_code` | `character varying(24)` | sim | `` |

PK: `PRIMARY KEY (id)`

### `public.stock_products`

| Coluna | Tipo | Nulavel | Default |
|---|---|---:|---|
| `id` | `integer` | nao | `nextval('stock_products_id_seq'::regclass)` |
| `product_id` | `integer` | nao | `` |
| `stock_id` | `integer` | nao | `` |
| `quantity` | `integer` | nao | `` |
| `minimal_quantity` | `integer` | sim | `` |
| `expire_date` | `date` | nao | `` |
| `product_status` | `product_status_enum` | sim | `` |
| `category` | `category_enum` | nao | `` |
| `created_at` | `timestamp without time zone` | nao | `CURRENT_TIMESTAMP` |
| `updated_at` | `timestamp without time zone` | nao | `CURRENT_TIMESTAMP` |
| `purchase_unit_price` | `numeric(10,2)` | sim | `` |
| `deleted_at` | `timestamp without time zone` | sim | `` |
| `batch` | `character varying(120)` | sim | `` |
| `initial_quantity` | `integer` | sim | `1` |

PK: `PRIMARY KEY (id)`

### `public.stocks`

| Coluna | Tipo | Nulavel | Default |
|---|---|---:|---|
| `id` | `integer` | nao | `nextval('stocks_id_seq'::regclass)` |
| `group_id` | `uuid` | nao | `` |
| `name` | `character varying` | nao | `` |
| `created_at` | `timestamp without time zone` | nao | `CURRENT_TIMESTAMP` |
| `updated_at` | `timestamp without time zone` | nao | `CURRENT_TIMESTAMP` |
| `deleted_at` | `timestamp without time zone` | sim | `` |

PK: `PRIMARY KEY (id)`

### `public.subscriptions`

| Coluna | Tipo | Nulavel | Default |
|---|---|---:|---|
| `id` | `uuid` | nao | `gen_random_uuid()` |
| `user_id` | `uuid` | nao | `` |
| `plan_id` | `integer` | nao | `` |
| `status` | `subscription_status_enum` | nao | `'TRIAL'::subscription_status_enum` |
| `started_at` | `timestamp without time zone` | nao | `CURRENT_TIMESTAMP` |
| `current_period_start` | `timestamp without time zone` | nao | `CURRENT_TIMESTAMP` |
| `current_period_end` | `timestamp without time zone` | sim | `` |
| `canceled_at` | `timestamp without time zone` | sim | `` |
| `updated_at` | `timestamp without time zone` | nao | `CURRENT_TIMESTAMP` |
| `deleted_at` | `timestamp without time zone` | sim | `` |

PK: `PRIMARY KEY (id)`

### `public.transaction_events`

| Coluna | Tipo | Nulavel | Default |
|---|---|---:|---|
| `id` | `integer` | nao | `nextval('transaction_events_id_seq'::regclass)` |
| `transaction_id` | `uuid` | nao | `` |
| `status` | `transaction_status_enum` | nao | `` |
| `message` | `text` | sim | `` |
| `created_at` | `timestamp without time zone` | nao | `CURRENT_TIMESTAMP` |

PK: `PRIMARY KEY (id)`

### `public.transactions`

| Coluna | Tipo | Nulavel | Default |
|---|---|---:|---|
| `id` | `uuid` | nao | `gen_random_uuid()` |
| `user_id` | `uuid` | nao | `` |
| `subscription_id` | `uuid` | sim | `` |
| `plan_id` | `integer` | nao | `` |
| `amount` | `numeric(10,2)` | nao | `` |
| `payment_method` | `payment_method_enum` | nao | `` |
| `fake_card_last4` | `character varying(4)` | sim | `` |
| `fake_pix_key` | `character varying` | sim | `` |
| `status` | `transaction_status_enum` | nao | `'PENDING'::transaction_status_enum` |
| `queue_job_id` | `character varying` | sim | `` |
| `attempts` | `integer` | nao | `0` |
| `max_attempts` | `integer` | nao | `3` |
| `error_message` | `text` | sim | `` |
| `created_at` | `timestamp without time zone` | nao | `CURRENT_TIMESTAMP` |
| `queued_at` | `timestamp without time zone` | sim | `` |
| `processed_at` | `timestamp without time zone` | sim | `` |
| `updated_at` | `timestamp without time zone` | nao | `CURRENT_TIMESTAMP` |
| `idempotency_key` | `character varying(120)` | nao | `` |

PK: `PRIMARY KEY (id)`

UNIQUE: `UNIQUE (idempotency_key)`

### `public.user_groups`

| Coluna | Tipo | Nulavel | Default |
|---|---|---:|---|
| `id` | `integer` | nao | `nextval('user_groups_id_seq'::regclass)` |
| `user_id` | `uuid` | nao | `` |
| `group_id` | `uuid` | nao | `` |
| `created_at` | `timestamp without time zone` | nao | `CURRENT_TIMESTAMP` |
| `updated_at` | `timestamp without time zone` | nao | `CURRENT_TIMESTAMP` |
| `member_role` | `character varying(16)` | nao | `'EDITOR'::character varying` |

PK: `PRIMARY KEY (id)`

UNIQUE: `UNIQUE (user_id, group_id)`

### `public.user_preferences`

| Coluna | Tipo | Nulavel | Default |
|---|---|---:|---|
| `user_id` | `uuid` | nao | `` |
| `expiration_alerts_enabled` | `boolean` | nao | `true` |
| `low_stock_alerts_enabled` | `boolean` | nao | `true` |
| `shopping_reminders_enabled` | `boolean` | nao | `true` |
| `weekly_summary_enabled` | `boolean` | nao | `false` |
| `theme` | `character varying(16)` | nao | `'SYSTEM'::character varying` |
| `created_at` | `timestamp without time zone` | nao | `CURRENT_TIMESTAMP` |
| `updated_at` | `timestamp without time zone` | nao | `CURRENT_TIMESTAMP` |

PK: `PRIMARY KEY (user_id)`

### `public.users`

| Coluna | Tipo | Nulavel | Default |
|---|---|---:|---|
| `id` | `uuid` | nao | `gen_random_uuid()` |
| `name` | `character varying` | nao | `` |
| `birth_date` | `date` | sim | `` |
| `account_type` | `account_type_enum` | nao | `` |
| `email` | `character varying` | nao | `` |
| `created_at` | `timestamp without time zone` | nao | `CURRENT_TIMESTAMP` |
| `updated_at` | `timestamp without time zone` | nao | `CURRENT_TIMESTAMP` |
| `deleted_at` | `timestamp without time zone` | sim | `` |
| `role` | `user_role_enum` | nao | `'USER'::user_role_enum` |
| `hash_password` | `character varying` | sim | `` |
| `senha` | `character varying(100)` | sim | `'VAZIO'::character varying` |
| `google_id` | `character varying(255)` | sim | `` |
| `token_version` | `integer` | nao | `0` |
| `profile_picture_url` | `character varying(2048)` | sim | `` |

PK: `PRIMARY KEY (id)`

UNIQUE: `UNIQUE (google_id)`
