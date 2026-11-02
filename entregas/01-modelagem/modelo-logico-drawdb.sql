-- Modelo lógico do schema public (FrigusDB), gerado do Dev em 2026-11-02.
-- Para o DrawDB: File > Import > From SQL (PostgreSQL). Enums viram varchar com os valores em comentário.
-- Contém tabelas, colunas, PK, UNIQUE e FK. Não contém CHECK, índices, triggers, views nem funções.

CREATE TABLE public."advertisements" (
    "id" uuid NOT NULL,
    "advertiser_id" uuid NOT NULL,
    "name" character varying(120) NOT NULL,
    "product_name" character varying(160) NOT NULL,
    "category" character varying(80) NOT NULL,
    "description" character varying(2000) NOT NULL,
    "image_url" character varying(2048) NOT NULL,
    "destination_url" character varying(2048),
    "price" numeric(12,2),
    "start_date" date,
    "end_date" date,
    "status" character varying(16) NOT NULL,
    "impressions" bigint NOT NULL,
    "clicks" bigint NOT NULL,
    "created_at" timestamp without time zone NOT NULL,
    "updated_at" timestamp without time zone NOT NULL,
    CONSTRAINT "advertisements_pkey" PRIMARY KEY (id)
);

CREATE TABLE public."business_expenses" (
    "id" uuid NOT NULL,
    "group_id" uuid NOT NULL,
    "created_by" uuid NOT NULL,
    "description" character varying(255) NOT NULL,
    "category" character varying(120) NOT NULL,
    "amount" numeric(12,2) NOT NULL,
    "expense_date" date NOT NULL,
    "supplier" character varying(255),
    "shopping_list_id" uuid,
    "created_at" timestamp without time zone NOT NULL,
    "updated_at" timestamp without time zone NOT NULL,
    CONSTRAINT "business_expenses_pkey" PRIMARY KEY (id),
    CONSTRAINT "business_expenses_shopping_list_id_key" UNIQUE (shopping_list_id)
);

CREATE TABLE public."conversation_participants" (
    "conversation_id" uuid NOT NULL,
    "user_id" uuid NOT NULL,
    "joined_at" timestamp without time zone NOT NULL,
    "left_at" timestamp without time zone,
    "updated_at" timestamp without time zone NOT NULL,
    CONSTRAINT "conversation_participants_pkey" PRIMARY KEY (conversation_id, user_id)
);

CREATE TABLE public."conversations" (
    "id" uuid NOT NULL,
    "conversation_type" varchar(32) /* enum conversation_type_enum: PRIVATE, GROUP */ NOT NULL,
    "group_id" uuid,
    "name" character varying,
    "pair_key" character varying,
    "created_at" timestamp without time zone,
    "updated_at" timestamp without time zone NOT NULL,
    CONSTRAINT "conversations_pkey" PRIMARY KEY (id),
    CONSTRAINT "uq_pair" UNIQUE (pair_key)
);

CREATE TABLE public."discard" (
    "id" integer NOT NULL,
    "stock_product_id" integer NOT NULL,
    "reason" text,
    "date" timestamp without time zone NOT NULL,
    "updated_at" timestamp without time zone NOT NULL,
    "quantity" integer,
    "movement_id" integer,
    "reason_code" character varying(24),
    "canceled_at" timestamp with time zone,
    CONSTRAINT "discard_pkey" PRIMARY KEY (id),
    CONSTRAINT "discard_movement_id_key" UNIQUE (movement_id)
);

CREATE TABLE public."dm_recipe_performance" (
    "dm_id" bigint NOT NULL,
    "recipe_id" integer NOT NULL,
    "recipe_name" character varying NOT NULL,
    "total_suggestions" integer,
    "unique_stocks_suggested" integer,
    "avg_suggestion_score" numeric(5,2),
    "total_ingredients" integer,
    "avg_available_ingredients" numeric(5,2),
    "suggestion_trend_7d" integer,
    "suggestion_trend_30d" integer,
    "is_domestic_only" boolean,
    "is_active" boolean,
    "last_suggested_date" timestamp without time zone,
    "created_at" timestamp without time zone,
    "updated_at" timestamp without time zone,
    CONSTRAINT "dm_recipe_performance_pkey" PRIMARY KEY (dm_id)
);

CREATE TABLE public."dm_stock_health_daily" (
    "dm_id" bigint NOT NULL,
    "snapshot_date" date NOT NULL,
    "stock_id" integer NOT NULL,
    "stock_name" character varying NOT NULL,
    "group_id" uuid NOT NULL,
    "total_products" integer,
    "fresh_products" integer,
    "near_expiration_products" integer,
    "expired_products" integer,
    "total_quantity" integer,
    "daily_inbound" integer,
    "daily_outbound" integer,
    "daily_adjustments" integer,
    "net_movement" integer,
    "top_category" character varying,
    "top_category_quantity" integer,
    "unique_users_accessing" integer,
    "total_shopping_lists" bigint,
    "created_at" timestamp without time zone,
    "updated_at" timestamp without time zone,
    CONSTRAINT "dm_stock_health_daily_pkey" PRIMARY KEY (dm_id)
);

CREATE TABLE public."dm_user_ltv" (
    "dm_id" bigint NOT NULL,
    "user_id" uuid NOT NULL,
    "user_name" character varying NOT NULL,
    "account_type" character varying,
    "total_messages" integer,
    "total_stock_movements" integer,
    "total_requests" integer,
    "total_transactions" bigint,
    "total_spent" numeric(12,2),
    "subscription_status" character varying,
    "days_active" integer,
    "engagement_score" numeric(8,2),
    "activity_frequency" character varying,
    "churn_risk" boolean,
    "first_activity_date" timestamp without time zone,
    "last_activity_date" timestamp without time zone,
    "created_at" timestamp without time zone,
    "updated_at" timestamp without time zone,
    CONSTRAINT "dm_user_ltv_pkey" PRIMARY KEY (dm_id),
    CONSTRAINT "dm_user_ltv_user_id_key" UNIQUE (user_id)
);

CREATE TABLE public."food_purchase_lines" (
    "id" bigint NOT NULL,
    "purchase_id" uuid NOT NULL,
    "stock_key" integer NOT NULL,
    "stock_product_id" integer,
    "product_id" integer,
    "product_name" text NOT NULL,
    "category" character varying(24) NOT NULL,
    "category_group" character varying(24) NOT NULL,
    "unit_of_measure" character varying(24) NOT NULL,
    "expire_date" date NOT NULL,
    "quantity" integer NOT NULL,
    "unit_price" numeric(10,2) NOT NULL,
    CONSTRAINT "food_purchase_lines_pkey" PRIMARY KEY (id)
);

CREATE TABLE public."food_purchase_revisions" (
    "id" bigint NOT NULL,
    "purchase_id" uuid NOT NULL,
    "previous_version" integer NOT NULL,
    "previous_state" jsonb NOT NULL,
    "changed_by" uuid NOT NULL,
    "changed_at" timestamp with time zone NOT NULL,
    CONSTRAINT "food_purchase_revisions_pkey" PRIMARY KEY (id)
);

CREATE TABLE public."food_purchases" (
    "id" uuid NOT NULL,
    "group_id" uuid NOT NULL,
    "purchase_date" date NOT NULL,
    "source" character varying(24) NOT NULL,
    "receipt_reference" character varying(160),
    "idempotency_key" character varying(160) NOT NULL,
    "request_hash" character varying(64) NOT NULL,
    "version" integer NOT NULL,
    "created_at" timestamp with time zone NOT NULL,
    "updated_at" timestamp with time zone NOT NULL,
    "deleted_at" timestamp with time zone,
    CONSTRAINT "food_purchases_pkey" PRIMARY KEY (id),
    CONSTRAINT "food_purchases_group_id_idempotency_key_key" UNIQUE (group_id, idempotency_key)
);

CREATE TABLE public."group_invitations" (
    "id" uuid NOT NULL,
    "group_id" uuid NOT NULL,
    "email" character varying(255) NOT NULL,
    "name" character varying(255),
    "member_role" character varying(16) NOT NULL,
    "token_hash" character varying(64) NOT NULL,
    "expires_at" timestamp without time zone NOT NULL,
    "accepted_at" timestamp without time zone,
    "revoked_at" timestamp without time zone,
    "created_at" timestamp without time zone NOT NULL,
    CONSTRAINT "group_invitations_pkey" PRIMARY KEY (id),
    CONSTRAINT "group_invitations_token_hash_key" UNIQUE (token_hash)
);

CREATE TABLE public."groups" (
    "id" uuid NOT NULL,
    "name" character varying NOT NULL,
    "banner_picture" text,
    "created_at" timestamp without time zone NOT NULL,
    "updated_at" timestamp without time zone NOT NULL,
    "deleted_at" timestamp without time zone,
    "owner_id" uuid,
    "time_zone" character varying(80) NOT NULL,
    CONSTRAINT "groups_pkey" PRIMARY KEY (id)
);

CREATE TABLE public."message_attachments" (
    "id" integer NOT NULL,
    "message_id" integer NOT NULL,
    "file_url" text NOT NULL,
    "file_name" character varying,
    "mime_type" character varying NOT NULL,
    "file_size" integer,
    "created_at" timestamp without time zone NOT NULL,
    "updated_at" timestamp without time zone NOT NULL,
    CONSTRAINT "message_attachments_pkey" PRIMARY KEY (id)
);

CREATE TABLE public."message_reactions" (
    "id" integer NOT NULL,
    "message_id" integer NOT NULL,
    "user_id" uuid NOT NULL,
    "emoji" character varying(16) NOT NULL,
    "created_at" timestamp without time zone NOT NULL,
    CONSTRAINT "message_reactions_pkey" PRIMARY KEY (id),
    CONSTRAINT "uq_message_reactions_message_user_emoji" UNIQUE (message_id, user_id, emoji)
);

CREATE TABLE public."message_reads" (
    "message_id" integer NOT NULL,
    "conversation_id" uuid NOT NULL,
    "user_id" uuid NOT NULL,
    "read_at" timestamp without time zone NOT NULL,
    CONSTRAINT "message_reads_pkey" PRIMARY KEY (message_id, user_id)
);

CREATE TABLE public."messages" (
    "id" integer NOT NULL,
    "conversation_id" uuid NOT NULL,
    "sender_id" uuid NOT NULL,
    "message_type" varchar(32) /* enum message_type_enum: TEXT, IMAGE, SYSTEM */ NOT NULL,
    "content" text,
    "related_shopping_list_product_id" integer,
    "created_at" timestamp without time zone,
    "updated_at" timestamp without time zone NOT NULL,
    CONSTRAINT "messages_pkey" PRIMARY KEY (id),
    CONSTRAINT "uq_messages_id_conversation" UNIQUE (id, conversation_id)
);

CREATE TABLE public."money_allocations" (
    "id" bigint NOT NULL,
    "exit_id" bigint NOT NULL,
    "supply_id" bigint,
    "quantity" integer NOT NULL,
    "amount" numeric(20,2),
    "category_group" character varying(24),
    CONSTRAINT "money_allocations_pkey" PRIMARY KEY (id)
);

CREATE TABLE public."money_exits" (
    "id" bigint NOT NULL,
    "group_id" uuid NOT NULL,
    "stock_key" integer NOT NULL,
    "stock_product_id" integer,
    "product_name" text NOT NULL,
    "category" character varying(24) NOT NULL,
    "unit_of_measure" character varying(24) NOT NULL,
    "expire_date" date NOT NULL,
    "occurred_at" timestamp with time zone NOT NULL,
    "local_date" date NOT NULL,
    "quantity" integer NOT NULL,
    "kind" character varying(24) NOT NULL,
    "reason_code" character varying(24),
    "movement_id" integer,
    "discard_id" integer,
    "canceled_at" timestamp with time zone,
    CONSTRAINT "money_exits_pkey" PRIMARY KEY (id)
);

CREATE TABLE public."money_supplies" (
    "id" bigint NOT NULL,
    "stock_key" integer NOT NULL,
    "stock_product_id" integer,
    "purchase_line_id" bigint,
    "available_on" date NOT NULL,
    "quantity" integer NOT NULL,
    "unknown_cost" boolean NOT NULL,
    "created_at" timestamp with time zone NOT NULL,
    CONSTRAINT "money_supplies_pkey" PRIMARY KEY (id),
    CONSTRAINT "money_supplies_purchase_line_id_key" UNIQUE (purchase_line_id)
);

CREATE TABLE public."notifications" (
    "id" uuid NOT NULL,
    "recipient_user_id" uuid NOT NULL,
    "group_id" uuid,
    "type" varchar(32) /* enum notification_type_enum: PRODUCT_NEAR_EXPIRATION, GROUP_MEMBER_JOINED, SHOPPING_LIST_PRODUCT_ADDED, SHOPPING_LIST_REMINDER, LOW_STOCK, OUT_OF_STOCK, AD_CLICK_MILESTONE, WEEKLY_SUMMARY */ NOT NULL,
    "title" character varying NOT NULL,
    "body" text NOT NULL,
    "reference_id" character varying(120),
    "deduplication_key" character varying(220),
    "read_at" timestamp without time zone,
    "created_at" timestamp without time zone NOT NULL,
    "deleted_at" timestamp without time zone,
    CONSTRAINT "notifications_pkey" PRIMARY KEY (id)
);

CREATE TABLE public."password_reset_tokens" (
    "id" uuid NOT NULL,
    "user_id" uuid NOT NULL,
    "token_hash" character varying(64) NOT NULL,
    "expires_at" timestamp without time zone NOT NULL,
    "consumed_at" timestamp without time zone,
    "created_at" timestamp without time zone NOT NULL,
    CONSTRAINT "password_reset_tokens_pkey" PRIMARY KEY (id),
    CONSTRAINT "password_reset_tokens_token_hash_key" UNIQUE (token_hash)
);

CREATE TABLE public."plans" (
    "id" integer NOT NULL,
    "name" character varying NOT NULL,
    "description" text,
    "price" numeric(10,2) NOT NULL,
    "billing_interval" varchar(32) /* enum billing_interval_enum: MONTHLY, YEARLY */,
    "active" boolean NOT NULL,
    "created_at" timestamp without time zone NOT NULL,
    "updated_at" timestamp without time zone NOT NULL,
    "deleted_at" timestamp without time zone,
    "plan_code" character varying(20) NOT NULL,
    CONSTRAINT "plans_pkey" PRIMARY KEY (id),
    CONSTRAINT "uq_plans_plan_code" UNIQUE (plan_code)
);

CREATE TABLE public."product_categories" (
    "id" integer NOT NULL,
    "name" character varying(80) NOT NULL,
    "parent_id" integer,
    "enum_value" varchar(32) /* enum category_enum: FRUIT, VEGETABLE, DAIRY, MEAT, GRAIN, BEVERAGE, CLEANING, PERSONAL_HYGIENE, FISH, FROZEN, SWEETS, CANNED, SEASONING */,
    CONSTRAINT "product_categories_pkey" PRIMARY KEY (id),
    CONSTRAINT "product_categories_enum_value_key" UNIQUE (enum_value),
    CONSTRAINT "product_categories_name_key" UNIQUE (name)
);

CREATE TABLE public."products" (
    "id" integer NOT NULL,
    "name" character varying NOT NULL,
    "category" varchar(32) /* enum category_enum: FRUIT, VEGETABLE, DAIRY, MEAT, GRAIN, BEVERAGE, CLEANING, PERSONAL_HYGIENE, FISH, FROZEN, SWEETS, CANNED, SEASONING */ NOT NULL,
    "storage_place" varchar(32) /* enum storage_place_enum: FRIDGE, FREEZER, PANTRY, CABINET, SHELF */ NOT NULL,
    "unit_price" numeric(10,2) NOT NULL,
    "unit_of_measure" varchar(32) /* enum unit_of_measure_enum: KILOGRAM, GRAM, LITER, MILLILITER, UNIT, DOZEN, PACKAGE */ NOT NULL,
    "created_at" timestamp without time zone NOT NULL,
    "updated_at" timestamp without time zone NOT NULL,
    "brand" character varying(120),
    "image_url" text,
    "owner_group_id" uuid,
    CONSTRAINT "products_pkey" PRIMARY KEY (id)
);

CREATE TABLE public."receipt_draft_lines" (
    "id" uuid NOT NULL,
    "receipt_id" uuid NOT NULL,
    "description" character varying(500) NOT NULL,
    "quantity" integer NOT NULL,
    "unit" character varying(30),
    "unit_price" numeric(12,2),
    "total_price" numeric(12,2),
    "confidence" double precision,
    "evidence" character varying(1000),
    "matched_product_id" integer,
    "expire_date" date,
    "normalized_product_name" character varying(255),
    "brand" character varying(120),
    "category" character varying(30),
    "storage_place" character varying(30),
    "unit_of_measure" character varying(30),
    CONSTRAINT "receipt_draft_lines_pkey" PRIMARY KEY (id)
);

CREATE TABLE public."receipt_drafts" (
    "id" uuid NOT NULL,
    "stock_id" integer NOT NULL,
    "created_by" uuid NOT NULL,
    "status" character varying(30) NOT NULL,
    "access_key" character varying(44),
    "issuer_name" character varying(255),
    "issued_at" timestamp with time zone,
    "total_amount" numeric(12,2),
    "warnings" jsonb NOT NULL,
    "created_at" timestamp with time zone NOT NULL,
    "imported_at" timestamp with time zone,
    CONSTRAINT "receipt_drafts_pkey" PRIMARY KEY (id),
    CONSTRAINT "receipt_drafts_stock_id_access_key_key" UNIQUE (stock_id, access_key)
);

CREATE TABLE public."recipe_favorites" (
    "id" uuid NOT NULL,
    "user_id" uuid NOT NULL,
    "recipe_id" integer NOT NULL,
    "created_at" timestamp without time zone NOT NULL,
    CONSTRAINT "recipe_favorites_pkey" PRIMARY KEY (id),
    CONSTRAINT "recipe_favorites_user_id_recipe_id_key" UNIQUE (user_id, recipe_id)
);

CREATE TABLE public."recipe_ingredients" (
    "id" integer NOT NULL,
    "recipe_id" integer NOT NULL,
    "product_id" integer NOT NULL,
    "quantity" numeric,
    "unit" character varying,
    "required" boolean NOT NULL,
    "created_at" timestamp without time zone NOT NULL,
    "updated_at" timestamp without time zone NOT NULL,
    CONSTRAINT "recipe_ingredients_pkey" PRIMARY KEY (id),
    CONSTRAINT "uq_recipe_ingredients_recipe_product" UNIQUE (recipe_id, product_id)
);

CREATE TABLE public."recipe_suggestions" (
    "id" integer NOT NULL,
    "recipe_id" integer NOT NULL,
    "stock_id" integer NOT NULL,
    "matched_ingredients" integer NOT NULL,
    "missing_ingredients" integer NOT NULL,
    "nearest_expire_date" date,
    "score" numeric,
    "created_at" timestamp without time zone NOT NULL,
    "updated_at" timestamp without time zone NOT NULL,
    CONSTRAINT "recipe_suggestions_pkey" PRIMARY KEY (id)
);

CREATE TABLE public."recipes" (
    "id" integer NOT NULL,
    "name" character varying NOT NULL,
    "description" text,
    "instructions" text,
    "domestic_only" boolean NOT NULL,
    "active" boolean NOT NULL,
    "created_at" timestamp without time zone NOT NULL,
    "updated_at" timestamp without time zone NOT NULL,
    CONSTRAINT "recipes_pkey" PRIMARY KEY (id)
);

CREATE TABLE public."requests" (
    "id" integer NOT NULL,
    "user_id" uuid NOT NULL,
    "product_id" integer NOT NULL,
    "stock_id" integer NOT NULL,
    "quantity" integer NOT NULL,
    "description" text,
    "picture" text,
    "date" date NOT NULL,
    "conversation_id" uuid,
    "message_id" integer,
    "updated_at" timestamp without time zone NOT NULL,
    CONSTRAINT "requests_pkey" PRIMARY KEY (id)
);

CREATE TABLE public."shopping_list_products" (
    "id" integer NOT NULL,
    "list_id" uuid NOT NULL,
    "product_id" integer NOT NULL,
    "status" varchar(32) /* enum product_list_status_enum: PENDING, PURCHASED, REMOVED */ NOT NULL,
    "quantity" integer NOT NULL,
    "created_at" timestamp without time zone NOT NULL,
    "updated_at" timestamp without time zone NOT NULL,
    "purchased_unit_price" numeric(10,2),
    "notes" character varying(255),
    "added_by" character varying(50) NOT NULL,
    CONSTRAINT "shopping_list_products_pkey" PRIMARY KEY (id),
    CONSTRAINT "uq_shopping_list_products_list_product" UNIQUE (list_id, product_id)
);

CREATE TABLE public."shopping_lists" (
    "id" uuid NOT NULL,
    "date" date NOT NULL,
    "stock_id" integer NOT NULL,
    "status" varchar(32) /* enum list_status_enum: OPEN, COMPLETED, CANCELED */ NOT NULL,
    "created_at" timestamp without time zone NOT NULL,
    "updated_at" timestamp without time zone NOT NULL,
    "name" character varying(255) NOT NULL,
    "supplier" character varying(255),
    "completed_at" timestamp without time zone,
    "total" numeric(12,2),
    "added_by" character varying(50) NOT NULL,
    CONSTRAINT "shopping_lists_pkey" PRIMARY KEY (id)
);

CREATE TABLE public."stock_movements" (
    "id" integer NOT NULL,
    "stock_product_id" integer NOT NULL,
    "user_id" uuid NOT NULL,
    "movement_type" varchar(32) /* enum movement_type_enum: IN, OUT, ADJUSTMENT */ NOT NULL,
    "quantity" integer NOT NULL,
    "date" timestamp without time zone,
    "observation" character varying(2000),
    "balance_after" integer,
    "purpose" character varying(20) NOT NULL,
    "reason_code" character varying(24),
    CONSTRAINT "stock_movements_pkey" PRIMARY KEY (id)
);

CREATE TABLE public."stock_products" (
    "id" integer NOT NULL,
    "product_id" integer NOT NULL,
    "stock_id" integer NOT NULL,
    "quantity" integer NOT NULL,
    "minimal_quantity" integer,
    "expire_date" date NOT NULL,
    "product_status" varchar(32) /* enum product_status_enum: FRESH, NEAR_EXPIRATION, EXPIRED */,
    "category" varchar(32) /* enum category_enum: FRUIT, VEGETABLE, DAIRY, MEAT, GRAIN, BEVERAGE, CLEANING, PERSONAL_HYGIENE, FISH, FROZEN, SWEETS, CANNED, SEASONING */ NOT NULL,
    "created_at" timestamp without time zone NOT NULL,
    "updated_at" timestamp without time zone NOT NULL,
    "purchase_unit_price" numeric(10,2),
    "deleted_at" timestamp without time zone,
    "batch" character varying(120),
    "initial_quantity" integer,
    CONSTRAINT "stock_products_pkey" PRIMARY KEY (id),
    CONSTRAINT "uq_stock_products_product_stock_expire" UNIQUE (product_id, stock_id, expire_date)
);

CREATE TABLE public."stocks" (
    "id" integer NOT NULL,
    "group_id" uuid NOT NULL,
    "name" character varying NOT NULL,
    "created_at" timestamp without time zone NOT NULL,
    "updated_at" timestamp without time zone NOT NULL,
    "deleted_at" timestamp without time zone,
    CONSTRAINT "stocks_pkey" PRIMARY KEY (id)
);

CREATE TABLE public."subscriptions" (
    "id" uuid NOT NULL,
    "user_id" uuid NOT NULL,
    "plan_id" integer NOT NULL,
    "status" varchar(32) /* enum subscription_status_enum: TRIAL, ACTIVE, CANCELED, EXPIRED, DELINQUENT */ NOT NULL,
    "started_at" timestamp without time zone NOT NULL,
    "current_period_start" timestamp without time zone NOT NULL,
    "current_period_end" timestamp without time zone,
    "canceled_at" timestamp without time zone,
    "updated_at" timestamp without time zone NOT NULL,
    "deleted_at" timestamp without time zone,
    CONSTRAINT "subscriptions_pkey" PRIMARY KEY (id)
);

CREATE TABLE public."support_requests" (
    "id" uuid NOT NULL,
    "user_id" uuid NOT NULL,
    "protocol" character varying(16) NOT NULL,
    "status" character varying(24) NOT NULL,
    "subject" character varying(120) NOT NULL,
    "description" character varying(5000) NOT NULL,
    "created_at" timestamp with time zone NOT NULL,
    "updated_at" timestamp with time zone NOT NULL,
    CONSTRAINT "support_requests_pkey" PRIMARY KEY (id),
    CONSTRAINT "support_requests_protocol_key" UNIQUE (protocol)
);

CREATE TABLE public."transaction_events" (
    "id" integer NOT NULL,
    "transaction_id" uuid NOT NULL,
    "status" varchar(32) /* enum transaction_status_enum: PENDING, PROCESSING, APPROVED, REJECTED, CANCELED, ERROR */ NOT NULL,
    "message" text,
    "created_at" timestamp without time zone NOT NULL,
    CONSTRAINT "transaction_events_pkey" PRIMARY KEY (id)
);

CREATE TABLE public."transactions" (
    "id" uuid NOT NULL,
    "user_id" uuid NOT NULL,
    "subscription_id" uuid,
    "plan_id" integer NOT NULL,
    "amount" numeric(10,2) NOT NULL,
    "payment_method" varchar(32) /* enum payment_method_enum: CREDIT_CARD, DEBIT_CARD, PIX, BOLETO */ NOT NULL,
    "fake_card_last4" character varying(4),
    "fake_pix_key" character varying,
    "status" varchar(32) /* enum transaction_status_enum: PENDING, PROCESSING, APPROVED, REJECTED, CANCELED, ERROR */ NOT NULL,
    "queue_job_id" character varying,
    "attempts" integer NOT NULL,
    "max_attempts" integer NOT NULL,
    "error_message" text,
    "created_at" timestamp without time zone NOT NULL,
    "queued_at" timestamp without time zone,
    "processed_at" timestamp without time zone,
    "updated_at" timestamp without time zone NOT NULL,
    "idempotency_key" character varying(120) NOT NULL,
    CONSTRAINT "transactions_pkey" PRIMARY KEY (id),
    CONSTRAINT "uq_transactions_idempotency_key" UNIQUE (idempotency_key)
);

CREATE TABLE public."user_app_settings" (
    "user_id" uuid NOT NULL,
    "dietary_preferences" jsonb NOT NULL,
    "dietary_restrictions" jsonb NOT NULL,
    "quick_recipes_enabled" boolean NOT NULL,
    "budget_recipes_enabled" boolean NOT NULL,
    "weight_unit" character varying(8) NOT NULL,
    "volume_unit" character varying(8) NOT NULL,
    "temperature_unit" character varying(12) NOT NULL,
    "usage_data_collection_allowed" boolean NOT NULL,
    "personalized_suggestions_allowed" boolean NOT NULL,
    "created_at" timestamp with time zone NOT NULL,
    "updated_at" timestamp with time zone NOT NULL,
    CONSTRAINT "user_app_settings_pkey" PRIMARY KEY (user_id)
);

CREATE TABLE public."user_groups" (
    "id" integer NOT NULL,
    "user_id" uuid NOT NULL,
    "group_id" uuid NOT NULL,
    "created_at" timestamp without time zone NOT NULL,
    "updated_at" timestamp without time zone NOT NULL,
    "member_role" character varying(16) NOT NULL,
    CONSTRAINT "user_groups_pkey" PRIMARY KEY (id),
    CONSTRAINT "uq_user_groups_user_group" UNIQUE (user_id, group_id)
);

CREATE TABLE public."user_preferences" (
    "user_id" uuid NOT NULL,
    "expiration_alerts_enabled" boolean NOT NULL,
    "low_stock_alerts_enabled" boolean NOT NULL,
    "shopping_reminders_enabled" boolean NOT NULL,
    "weekly_summary_enabled" boolean NOT NULL,
    "theme" character varying(16) NOT NULL,
    "created_at" timestamp without time zone NOT NULL,
    "updated_at" timestamp without time zone NOT NULL,
    CONSTRAINT "user_preferences_pkey" PRIMARY KEY (user_id)
);

CREATE TABLE public."users" (
    "id" uuid NOT NULL,
    "name" character varying NOT NULL,
    "birth_date" date,
    "account_type" varchar(32) /* enum account_type_enum: DOMESTIC, BUSINESS, COMMERCIAL */ NOT NULL,
    "email" character varying NOT NULL,
    "created_at" timestamp without time zone NOT NULL,
    "updated_at" timestamp without time zone NOT NULL,
    "deleted_at" timestamp without time zone,
    "role" varchar(32) /* enum user_role_enum: USER, ADMIN */ NOT NULL,
    "hash_password" character varying,
    "senha" character varying(100),
    "google_id" character varying(255),
    "token_version" integer NOT NULL,
    "profile_picture_url" character varying(2048),
    "email_verified" boolean NOT NULL,
    "plan_selection_required" boolean NOT NULL,
    "pending_plan_transaction_id" uuid,
    CONSTRAINT "users_pkey" PRIMARY KEY (id),
    CONSTRAINT "users_google_id_key" UNIQUE (google_id)
);

ALTER TABLE public."advertisements" ADD CONSTRAINT "advertisements_advertiser_id_fkey" FOREIGN KEY (advertiser_id) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE public."business_expenses" ADD CONSTRAINT "business_expenses_created_by_fkey" FOREIGN KEY (created_by) REFERENCES users(id);
ALTER TABLE public."business_expenses" ADD CONSTRAINT "business_expenses_group_id_fkey" FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE RESTRICT;
ALTER TABLE public."business_expenses" ADD CONSTRAINT "business_expenses_shopping_list_id_fkey" FOREIGN KEY (shopping_list_id) REFERENCES shopping_lists(id) ON DELETE RESTRICT;
ALTER TABLE public."conversation_participants" ADD CONSTRAINT "fk_conversation_participants_conversation_id_conversations" FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE;
ALTER TABLE public."conversation_participants" ADD CONSTRAINT "fk_conversation_participants_user_id_users" FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE public."conversations" ADD CONSTRAINT "fk_conversations_group_id_groups" FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE SET NULL;
ALTER TABLE public."discard" ADD CONSTRAINT "discard_movement_id_fkey" FOREIGN KEY (movement_id) REFERENCES stock_movements(id);
ALTER TABLE public."discard" ADD CONSTRAINT "fk_discard_stock_product_id_stock_products" FOREIGN KEY (stock_product_id) REFERENCES stock_products(id) ON DELETE CASCADE;
ALTER TABLE public."food_purchase_lines" ADD CONSTRAINT "food_purchase_lines_product_id_fkey" FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE SET NULL;
ALTER TABLE public."food_purchase_lines" ADD CONSTRAINT "food_purchase_lines_purchase_id_fkey" FOREIGN KEY (purchase_id) REFERENCES food_purchases(id);
ALTER TABLE public."food_purchase_lines" ADD CONSTRAINT "food_purchase_lines_stock_product_id_fkey" FOREIGN KEY (stock_product_id) REFERENCES stock_products(id) ON DELETE SET NULL;
ALTER TABLE public."food_purchase_revisions" ADD CONSTRAINT "food_purchase_revisions_changed_by_fkey" FOREIGN KEY (changed_by) REFERENCES users(id);
ALTER TABLE public."food_purchase_revisions" ADD CONSTRAINT "food_purchase_revisions_purchase_id_fkey" FOREIGN KEY (purchase_id) REFERENCES food_purchases(id);
ALTER TABLE public."food_purchases" ADD CONSTRAINT "food_purchases_group_id_fkey" FOREIGN KEY (group_id) REFERENCES groups(id);
ALTER TABLE public."group_invitations" ADD CONSTRAINT "group_invitations_group_id_fkey" FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE;
ALTER TABLE public."groups" ADD CONSTRAINT "fk_groups_owner_id_users" FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE public."message_attachments" ADD CONSTRAINT "fk_message_attachments_message_id_messages" FOREIGN KEY (message_id) REFERENCES messages(id) ON DELETE CASCADE;
ALTER TABLE public."message_reactions" ADD CONSTRAINT "message_reactions_message_id_fkey" FOREIGN KEY (message_id) REFERENCES messages(id) ON DELETE CASCADE;
ALTER TABLE public."message_reactions" ADD CONSTRAINT "message_reactions_user_id_fkey" FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE public."message_reads" ADD CONSTRAINT "fk_message_reads_conversation_id_participants" FOREIGN KEY (conversation_id, user_id) REFERENCES conversation_participants(conversation_id, user_id) ON DELETE CASCADE;
ALTER TABLE public."message_reads" ADD CONSTRAINT "fk_message_reads_message_id_messages" FOREIGN KEY (message_id, conversation_id) REFERENCES messages(id, conversation_id) ON DELETE CASCADE;
ALTER TABLE public."messages" ADD CONSTRAINT "fk_messages_conversation_id_conversations" FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE;
ALTER TABLE public."messages" ADD CONSTRAINT "fk_messages_conversation_id_participants" FOREIGN KEY (conversation_id, sender_id) REFERENCES conversation_participants(conversation_id, user_id);
ALTER TABLE public."messages" ADD CONSTRAINT "fk_messages_related_shopping_list_product_id_slp" FOREIGN KEY (related_shopping_list_product_id) REFERENCES shopping_list_products(id) ON DELETE SET NULL;
ALTER TABLE public."messages" ADD CONSTRAINT "fk_messages_sender_id_users" FOREIGN KEY (sender_id) REFERENCES users(id);
ALTER TABLE public."money_allocations" ADD CONSTRAINT "money_allocations_exit_id_fkey" FOREIGN KEY (exit_id) REFERENCES money_exits(id) ON DELETE CASCADE;
ALTER TABLE public."money_allocations" ADD CONSTRAINT "money_allocations_supply_id_fkey" FOREIGN KEY (supply_id) REFERENCES money_supplies(id) ON DELETE SET NULL;
ALTER TABLE public."money_exits" ADD CONSTRAINT "money_exits_group_id_fkey" FOREIGN KEY (group_id) REFERENCES groups(id);
ALTER TABLE public."money_exits" ADD CONSTRAINT "money_exits_movement_id_fkey" FOREIGN KEY (movement_id) REFERENCES stock_movements(id) ON DELETE SET NULL;
ALTER TABLE public."money_exits" ADD CONSTRAINT "money_exits_stock_product_id_fkey" FOREIGN KEY (stock_product_id) REFERENCES stock_products(id) ON DELETE SET NULL;
ALTER TABLE public."money_supplies" ADD CONSTRAINT "money_supplies_purchase_line_id_fkey" FOREIGN KEY (purchase_line_id) REFERENCES food_purchase_lines(id);
ALTER TABLE public."money_supplies" ADD CONSTRAINT "money_supplies_stock_product_id_fkey" FOREIGN KEY (stock_product_id) REFERENCES stock_products(id) ON DELETE SET NULL;
ALTER TABLE public."notifications" ADD CONSTRAINT "fk_notifications_group_id_groups" FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE;
ALTER TABLE public."notifications" ADD CONSTRAINT "fk_notifications_recipient_user_id_users" FOREIGN KEY (recipient_user_id) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE public."password_reset_tokens" ADD CONSTRAINT "password_reset_tokens_user_id_fkey" FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE public."product_categories" ADD CONSTRAINT "product_categories_parent_id_fkey" FOREIGN KEY (parent_id) REFERENCES product_categories(id);
ALTER TABLE public."products" ADD CONSTRAINT "products_owner_group_id_fkey" FOREIGN KEY (owner_group_id) REFERENCES groups(id) ON DELETE RESTRICT;
ALTER TABLE public."receipt_draft_lines" ADD CONSTRAINT "receipt_draft_lines_matched_product_id_fkey" FOREIGN KEY (matched_product_id) REFERENCES products(id);
ALTER TABLE public."receipt_draft_lines" ADD CONSTRAINT "receipt_draft_lines_receipt_id_fkey" FOREIGN KEY (receipt_id) REFERENCES receipt_drafts(id) ON DELETE CASCADE;
ALTER TABLE public."receipt_drafts" ADD CONSTRAINT "receipt_drafts_created_by_fkey" FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE public."receipt_drafts" ADD CONSTRAINT "receipt_drafts_stock_id_fkey" FOREIGN KEY (stock_id) REFERENCES stocks(id) ON DELETE CASCADE;
ALTER TABLE public."recipe_favorites" ADD CONSTRAINT "recipe_favorites_recipe_id_fkey" FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE;
ALTER TABLE public."recipe_favorites" ADD CONSTRAINT "recipe_favorites_user_id_fkey" FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE public."recipe_ingredients" ADD CONSTRAINT "fk_recipe_ingredients_product_id_products" FOREIGN KEY (product_id) REFERENCES products(id);
ALTER TABLE public."recipe_ingredients" ADD CONSTRAINT "fk_recipe_ingredients_recipe_id_recipes" FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE;
ALTER TABLE public."recipe_suggestions" ADD CONSTRAINT "fk_recipe_suggestions_recipe_id_recipes" FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE;
ALTER TABLE public."recipe_suggestions" ADD CONSTRAINT "fk_recipe_suggestions_stock_id_stocks" FOREIGN KEY (stock_id) REFERENCES stocks(id) ON DELETE CASCADE;
ALTER TABLE public."requests" ADD CONSTRAINT "fk_requests_conversation_id_conversations" FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE SET NULL;
ALTER TABLE public."requests" ADD CONSTRAINT "fk_requests_message_id_messages" FOREIGN KEY (message_id, conversation_id) REFERENCES messages(id, conversation_id) ON DELETE SET NULL;
ALTER TABLE public."requests" ADD CONSTRAINT "fk_requests_product_id_products" FOREIGN KEY (product_id) REFERENCES products(id);
ALTER TABLE public."requests" ADD CONSTRAINT "fk_requests_stock_id_stocks" FOREIGN KEY (stock_id) REFERENCES stocks(id) ON DELETE CASCADE;
ALTER TABLE public."requests" ADD CONSTRAINT "fk_requests_user_id_users" FOREIGN KEY (user_id) REFERENCES users(id);
ALTER TABLE public."shopping_list_products" ADD CONSTRAINT "fk_shopping_list_products_list_id_shopping_lists" FOREIGN KEY (list_id) REFERENCES shopping_lists(id) ON DELETE CASCADE;
ALTER TABLE public."shopping_list_products" ADD CONSTRAINT "fk_shopping_list_products_product_id_products" FOREIGN KEY (product_id) REFERENCES products(id);
ALTER TABLE public."shopping_lists" ADD CONSTRAINT "fk_shopping_lists_stock_id_stocks" FOREIGN KEY (stock_id) REFERENCES stocks(id) ON DELETE CASCADE;
ALTER TABLE public."stock_movements" ADD CONSTRAINT "fk_stock_movements_stock_product_id_stock_products" FOREIGN KEY (stock_product_id) REFERENCES stock_products(id) ON DELETE CASCADE;
ALTER TABLE public."stock_movements" ADD CONSTRAINT "fk_stock_movements_user_id_users" FOREIGN KEY (user_id) REFERENCES users(id);
ALTER TABLE public."stock_products" ADD CONSTRAINT "fk_stock_products_product_id_products" FOREIGN KEY (product_id) REFERENCES products(id);
ALTER TABLE public."stock_products" ADD CONSTRAINT "fk_stock_products_stock_id_stocks" FOREIGN KEY (stock_id) REFERENCES stocks(id) ON DELETE CASCADE;
ALTER TABLE public."stocks" ADD CONSTRAINT "fk_stocks_group_id_groups" FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE;
ALTER TABLE public."subscriptions" ADD CONSTRAINT "fk_subscriptions_plan_id_plans" FOREIGN KEY (plan_id) REFERENCES plans(id);
ALTER TABLE public."subscriptions" ADD CONSTRAINT "fk_subscriptions_user_id_users" FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE public."support_requests" ADD CONSTRAINT "support_requests_user_id_fkey" FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE public."transaction_events" ADD CONSTRAINT "fk_transaction_events_transaction_id_transactions" FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE CASCADE;
ALTER TABLE public."transactions" ADD CONSTRAINT "fk_transactions_plan_id_plans" FOREIGN KEY (plan_id) REFERENCES plans(id);
ALTER TABLE public."transactions" ADD CONSTRAINT "fk_transactions_subscription_id_subscriptions" FOREIGN KEY (subscription_id) REFERENCES subscriptions(id) ON DELETE CASCADE;
ALTER TABLE public."transactions" ADD CONSTRAINT "fk_transactions_user_id_users" FOREIGN KEY (user_id) REFERENCES users(id);
ALTER TABLE public."user_app_settings" ADD CONSTRAINT "user_app_settings_user_id_fkey" FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE public."user_groups" ADD CONSTRAINT "fk_user_groups_group_id_groups" FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE;
ALTER TABLE public."user_groups" ADD CONSTRAINT "fk_user_groups_user_id_users" FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE public."user_preferences" ADD CONSTRAINT "user_preferences_user_id_fkey" FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
