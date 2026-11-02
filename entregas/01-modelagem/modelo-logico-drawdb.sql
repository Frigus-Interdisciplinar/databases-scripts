CREATE TABLE advertisements (
  id uuid NOT NULL,
  advertiser_id uuid NOT NULL,
  name varchar(120) NOT NULL,
  product_name varchar(160) NOT NULL,
  category varchar(80) NOT NULL,
  description varchar(2000) NOT NULL,
  image_url varchar(2048) NOT NULL,
  destination_url varchar(2048),
  price numeric(12,2),
  start_date date,
  end_date date,
  status varchar(16) NOT NULL,
  impressions bigint NOT NULL,
  clicks bigint NOT NULL,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE business_expenses (
  id uuid NOT NULL,
  group_id uuid NOT NULL,
  created_by uuid NOT NULL,
  description varchar(255) NOT NULL,
  category varchar(120) NOT NULL,
  amount numeric(12,2) NOT NULL,
  expense_date date NOT NULL,
  supplier varchar(255),
  shopping_list_id uuid,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  PRIMARY KEY (id),
  UNIQUE (shopping_list_id)
);

CREATE TABLE conversation_participants (
  conversation_id uuid NOT NULL,
  user_id uuid NOT NULL,
  joined_at timestamp NOT NULL,
  left_at timestamp,
  updated_at timestamp NOT NULL,
  PRIMARY KEY (conversation_id, user_id)
);

CREATE TABLE conversations (
  id uuid NOT NULL,
  conversation_type varchar(32) NOT NULL,
  group_id uuid,
  name varchar,
  pair_key varchar,
  created_at timestamp,
  updated_at timestamp NOT NULL,
  PRIMARY KEY (id),
  UNIQUE (pair_key)
);

CREATE TABLE discard (
  id integer NOT NULL,
  stock_product_id integer NOT NULL,
  reason text,
  date timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  quantity integer,
  movement_id integer,
  reason_code varchar(24),
  canceled_at timestamptz,
  PRIMARY KEY (id),
  UNIQUE (movement_id)
);

CREATE TABLE dm_recipe_performance (
  dm_id bigint NOT NULL,
  recipe_id integer NOT NULL,
  recipe_name varchar NOT NULL,
  total_suggestions integer,
  unique_stocks_suggested integer,
  avg_suggestion_score numeric(5,2),
  total_ingredients integer,
  avg_available_ingredients numeric(5,2),
  suggestion_trend_7d integer,
  suggestion_trend_30d integer,
  is_domestic_only boolean,
  is_active boolean,
  last_suggested_date timestamp,
  created_at timestamp,
  updated_at timestamp,
  PRIMARY KEY (dm_id)
);

CREATE TABLE dm_stock_health_daily (
  dm_id bigint NOT NULL,
  snapshot_date date NOT NULL,
  stock_id integer NOT NULL,
  stock_name varchar NOT NULL,
  group_id uuid NOT NULL,
  total_products integer,
  fresh_products integer,
  near_expiration_products integer,
  expired_products integer,
  total_quantity integer,
  daily_inbound integer,
  daily_outbound integer,
  daily_adjustments integer,
  net_movement integer,
  top_category varchar,
  top_category_quantity integer,
  unique_users_accessing integer,
  total_shopping_lists bigint,
  created_at timestamp,
  updated_at timestamp,
  PRIMARY KEY (dm_id)
);

CREATE TABLE dm_user_ltv (
  dm_id bigint NOT NULL,
  user_id uuid NOT NULL,
  user_name varchar NOT NULL,
  account_type varchar,
  total_messages integer,
  total_stock_movements integer,
  total_requests integer,
  total_transactions bigint,
  total_spent numeric(12,2),
  subscription_status varchar,
  days_active integer,
  engagement_score numeric(8,2),
  activity_frequency varchar,
  churn_risk boolean,
  first_activity_date timestamp,
  last_activity_date timestamp,
  created_at timestamp,
  updated_at timestamp,
  PRIMARY KEY (dm_id),
  UNIQUE (user_id)
);

CREATE TABLE food_purchase_lines (
  id bigint NOT NULL,
  purchase_id uuid NOT NULL,
  stock_key integer NOT NULL,
  stock_product_id integer,
  product_id integer,
  product_name text NOT NULL,
  category varchar(24) NOT NULL,
  category_group varchar(24) NOT NULL,
  unit_of_measure varchar(24) NOT NULL,
  expire_date date NOT NULL,
  quantity integer NOT NULL,
  unit_price numeric(10,2) NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE food_purchase_revisions (
  id bigint NOT NULL,
  purchase_id uuid NOT NULL,
  previous_version integer NOT NULL,
  previous_state jsonb NOT NULL,
  changed_by uuid NOT NULL,
  changed_at timestamptz NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE food_purchases (
  id uuid NOT NULL,
  group_id uuid NOT NULL,
  purchase_date date NOT NULL,
  source varchar(24) NOT NULL,
  receipt_reference varchar(160),
  idempotency_key varchar(160) NOT NULL,
  request_hash varchar(64) NOT NULL,
  version integer NOT NULL,
  created_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL,
  deleted_at timestamptz,
  PRIMARY KEY (id),
  UNIQUE (group_id, idempotency_key)
);

CREATE TABLE group_invitations (
  id uuid NOT NULL,
  group_id uuid NOT NULL,
  email varchar(255) NOT NULL,
  name varchar(255),
  member_role varchar(16) NOT NULL,
  token_hash varchar(64) NOT NULL,
  expires_at timestamp NOT NULL,
  accepted_at timestamp,
  revoked_at timestamp,
  created_at timestamp NOT NULL,
  PRIMARY KEY (id),
  UNIQUE (token_hash)
);

CREATE TABLE groups (
  id uuid NOT NULL,
  name varchar NOT NULL,
  banner_picture text,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  deleted_at timestamp,
  owner_id uuid,
  time_zone varchar(80) NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE message_attachments (
  id integer NOT NULL,
  message_id integer NOT NULL,
  file_url text NOT NULL,
  file_name varchar,
  mime_type varchar NOT NULL,
  file_size integer,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE message_reactions (
  id integer NOT NULL,
  message_id integer NOT NULL,
  user_id uuid NOT NULL,
  emoji varchar(16) NOT NULL,
  created_at timestamp NOT NULL,
  PRIMARY KEY (id),
  UNIQUE (message_id, user_id, emoji)
);

CREATE TABLE message_reads (
  message_id integer NOT NULL,
  conversation_id uuid NOT NULL,
  user_id uuid NOT NULL,
  read_at timestamp NOT NULL,
  PRIMARY KEY (message_id, user_id)
);

CREATE TABLE messages (
  id integer NOT NULL,
  conversation_id uuid NOT NULL,
  sender_id uuid NOT NULL,
  message_type varchar(32) NOT NULL,
  content text,
  related_shopping_list_product_id integer,
  created_at timestamp,
  updated_at timestamp NOT NULL,
  PRIMARY KEY (id),
  UNIQUE (id, conversation_id)
);

CREATE TABLE money_allocations (
  id bigint NOT NULL,
  exit_id bigint NOT NULL,
  supply_id bigint,
  quantity integer NOT NULL,
  amount numeric(20,2),
  category_group varchar(24),
  PRIMARY KEY (id)
);

CREATE TABLE money_exits (
  id bigint NOT NULL,
  group_id uuid NOT NULL,
  stock_key integer NOT NULL,
  stock_product_id integer,
  product_name text NOT NULL,
  category varchar(24) NOT NULL,
  unit_of_measure varchar(24) NOT NULL,
  expire_date date NOT NULL,
  occurred_at timestamptz NOT NULL,
  local_date date NOT NULL,
  quantity integer NOT NULL,
  kind varchar(24) NOT NULL,
  reason_code varchar(24),
  movement_id integer,
  discard_id integer,
  canceled_at timestamptz,
  PRIMARY KEY (id)
);

CREATE TABLE money_supplies (
  id bigint NOT NULL,
  stock_key integer NOT NULL,
  stock_product_id integer,
  purchase_line_id bigint,
  available_on date NOT NULL,
  quantity integer NOT NULL,
  unknown_cost boolean NOT NULL,
  created_at timestamptz NOT NULL,
  PRIMARY KEY (id),
  UNIQUE (purchase_line_id)
);

CREATE TABLE notifications (
  id uuid NOT NULL,
  recipient_user_id uuid NOT NULL,
  group_id uuid,
  type varchar(32) NOT NULL,
  title varchar NOT NULL,
  body text NOT NULL,
  reference_id varchar(120),
  deduplication_key varchar(220),
  read_at timestamp,
  created_at timestamp NOT NULL,
  deleted_at timestamp,
  PRIMARY KEY (id)
);

CREATE TABLE password_reset_tokens (
  id uuid NOT NULL,
  user_id uuid NOT NULL,
  token_hash varchar(64) NOT NULL,
  expires_at timestamp NOT NULL,
  consumed_at timestamp,
  created_at timestamp NOT NULL,
  PRIMARY KEY (id),
  UNIQUE (token_hash)
);

CREATE TABLE plans (
  id integer NOT NULL,
  name varchar NOT NULL,
  description text,
  price numeric(10,2) NOT NULL,
  billing_interval varchar(32),
  active boolean NOT NULL,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  deleted_at timestamp,
  plan_code varchar(20) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE (plan_code)
);

CREATE TABLE product_categories (
  id integer NOT NULL,
  name varchar(80) NOT NULL,
  parent_id integer,
  enum_value varchar(32),
  PRIMARY KEY (id),
  UNIQUE (enum_value),
  UNIQUE (name)
);

CREATE TABLE products (
  id integer NOT NULL,
  name varchar NOT NULL,
  category varchar(32) NOT NULL,
  storage_place varchar(32) NOT NULL,
  unit_price numeric(10,2) NOT NULL,
  unit_of_measure varchar(32) NOT NULL,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  brand varchar(120),
  image_url text,
  owner_group_id uuid,
  PRIMARY KEY (id)
);

CREATE TABLE receipt_draft_lines (
  id uuid NOT NULL,
  receipt_id uuid NOT NULL,
  description varchar(500) NOT NULL,
  quantity integer NOT NULL,
  unit varchar(30),
  unit_price numeric(12,2),
  total_price numeric(12,2),
  confidence float8,
  evidence varchar(1000),
  matched_product_id integer,
  expire_date date,
  normalized_product_name varchar(255),
  brand varchar(120),
  category varchar(30),
  storage_place varchar(30),
  unit_of_measure varchar(30),
  PRIMARY KEY (id)
);

CREATE TABLE receipt_drafts (
  id uuid NOT NULL,
  stock_id integer NOT NULL,
  created_by uuid NOT NULL,
  status varchar(30) NOT NULL,
  access_key varchar(44),
  issuer_name varchar(255),
  issued_at timestamptz,
  total_amount numeric(12,2),
  warnings jsonb NOT NULL,
  created_at timestamptz NOT NULL,
  imported_at timestamptz,
  PRIMARY KEY (id),
  UNIQUE (stock_id, access_key)
);

CREATE TABLE recipe_favorites (
  id uuid NOT NULL,
  user_id uuid NOT NULL,
  recipe_id integer NOT NULL,
  created_at timestamp NOT NULL,
  PRIMARY KEY (id),
  UNIQUE (user_id, recipe_id)
);

CREATE TABLE recipe_ingredients (
  id integer NOT NULL,
  recipe_id integer NOT NULL,
  product_id integer NOT NULL,
  quantity numeric,
  unit varchar,
  required boolean NOT NULL,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  PRIMARY KEY (id),
  UNIQUE (recipe_id, product_id)
);

CREATE TABLE recipe_suggestions (
  id integer NOT NULL,
  recipe_id integer NOT NULL,
  stock_id integer NOT NULL,
  matched_ingredients integer NOT NULL,
  missing_ingredients integer NOT NULL,
  nearest_expire_date date,
  score numeric,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE recipes (
  id integer NOT NULL,
  name varchar NOT NULL,
  description text,
  instructions text,
  domestic_only boolean NOT NULL,
  active boolean NOT NULL,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE requests (
  id integer NOT NULL,
  user_id uuid NOT NULL,
  product_id integer NOT NULL,
  stock_id integer NOT NULL,
  quantity integer NOT NULL,
  description text,
  picture text,
  date date NOT NULL,
  conversation_id uuid,
  message_id integer,
  updated_at timestamp NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE shopping_list_products (
  id integer NOT NULL,
  list_id uuid NOT NULL,
  product_id integer NOT NULL,
  status varchar(32) NOT NULL,
  quantity integer NOT NULL,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  purchased_unit_price numeric(10,2),
  notes varchar(255),
  added_by varchar(50) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE (list_id, product_id)
);

CREATE TABLE shopping_lists (
  id uuid NOT NULL,
  date date NOT NULL,
  stock_id integer NOT NULL,
  status varchar(32) NOT NULL,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  name varchar(255) NOT NULL,
  supplier varchar(255),
  completed_at timestamp,
  total numeric(12,2),
  added_by varchar(50) NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE stock_movements (
  id integer NOT NULL,
  stock_product_id integer NOT NULL,
  user_id uuid NOT NULL,
  movement_type varchar(32) NOT NULL,
  quantity integer NOT NULL,
  date timestamp,
  observation varchar(2000),
  balance_after integer,
  purpose varchar(20) NOT NULL,
  reason_code varchar(24),
  PRIMARY KEY (id)
);

CREATE TABLE stock_products (
  id integer NOT NULL,
  product_id integer NOT NULL,
  stock_id integer NOT NULL,
  quantity integer NOT NULL,
  minimal_quantity integer,
  expire_date date NOT NULL,
  product_status varchar(32),
  category varchar(32) NOT NULL,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  purchase_unit_price numeric(10,2),
  deleted_at timestamp,
  batch varchar(120),
  initial_quantity integer,
  PRIMARY KEY (id),
  UNIQUE (product_id, stock_id, expire_date)
);

CREATE TABLE stocks (
  id integer NOT NULL,
  group_id uuid NOT NULL,
  name varchar NOT NULL,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  deleted_at timestamp,
  PRIMARY KEY (id)
);

CREATE TABLE subscriptions (
  id uuid NOT NULL,
  user_id uuid NOT NULL,
  plan_id integer NOT NULL,
  status varchar(32) NOT NULL,
  started_at timestamp NOT NULL,
  current_period_start timestamp NOT NULL,
  current_period_end timestamp,
  canceled_at timestamp,
  updated_at timestamp NOT NULL,
  deleted_at timestamp,
  PRIMARY KEY (id)
);

CREATE TABLE support_requests (
  id uuid NOT NULL,
  user_id uuid NOT NULL,
  protocol varchar(16) NOT NULL,
  status varchar(24) NOT NULL,
  subject varchar(120) NOT NULL,
  description varchar(5000) NOT NULL,
  created_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL,
  PRIMARY KEY (id),
  UNIQUE (protocol)
);

CREATE TABLE transaction_events (
  id integer NOT NULL,
  transaction_id uuid NOT NULL,
  status varchar(32) NOT NULL,
  message text,
  created_at timestamp NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE transactions (
  id uuid NOT NULL,
  user_id uuid NOT NULL,
  subscription_id uuid,
  plan_id integer NOT NULL,
  amount numeric(10,2) NOT NULL,
  payment_method varchar(32) NOT NULL,
  fake_card_last4 varchar(4),
  fake_pix_key varchar,
  status varchar(32) NOT NULL,
  queue_job_id varchar,
  attempts integer NOT NULL,
  max_attempts integer NOT NULL,
  error_message text,
  created_at timestamp NOT NULL,
  queued_at timestamp,
  processed_at timestamp,
  updated_at timestamp NOT NULL,
  idempotency_key varchar(120) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE (idempotency_key)
);

CREATE TABLE user_app_settings (
  user_id uuid NOT NULL,
  dietary_preferences jsonb NOT NULL,
  dietary_restrictions jsonb NOT NULL,
  quick_recipes_enabled boolean NOT NULL,
  budget_recipes_enabled boolean NOT NULL,
  weight_unit varchar(8) NOT NULL,
  volume_unit varchar(8) NOT NULL,
  temperature_unit varchar(12) NOT NULL,
  usage_data_collection_allowed boolean NOT NULL,
  personalized_suggestions_allowed boolean NOT NULL,
  created_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL,
  PRIMARY KEY (user_id)
);

CREATE TABLE user_groups (
  id integer NOT NULL,
  user_id uuid NOT NULL,
  group_id uuid NOT NULL,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  member_role varchar(16) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE (user_id, group_id)
);

CREATE TABLE user_preferences (
  user_id uuid NOT NULL,
  expiration_alerts_enabled boolean NOT NULL,
  low_stock_alerts_enabled boolean NOT NULL,
  shopping_reminders_enabled boolean NOT NULL,
  weekly_summary_enabled boolean NOT NULL,
  theme varchar(16) NOT NULL,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  PRIMARY KEY (user_id)
);

CREATE TABLE users (
  id uuid NOT NULL,
  name varchar NOT NULL,
  birth_date date,
  account_type varchar(32) NOT NULL,
  email varchar NOT NULL,
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL,
  deleted_at timestamp,
  role varchar(32) NOT NULL,
  hash_password varchar,
  senha varchar(100),
  google_id varchar(255),
  token_version integer NOT NULL,
  profile_picture_url varchar(2048),
  email_verified boolean NOT NULL,
  plan_selection_required boolean NOT NULL,
  pending_plan_transaction_id uuid,
  PRIMARY KEY (id),
  UNIQUE (google_id)
);

ALTER TABLE advertisements ADD CONSTRAINT advertisements_advertiser_id_fkey FOREIGN KEY (advertiser_id) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE business_expenses ADD CONSTRAINT business_expenses_created_by_fkey FOREIGN KEY (created_by) REFERENCES users(id);
ALTER TABLE business_expenses ADD CONSTRAINT business_expenses_group_id_fkey FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE RESTRICT;
ALTER TABLE business_expenses ADD CONSTRAINT business_expenses_shopping_list_id_fkey FOREIGN KEY (shopping_list_id) REFERENCES shopping_lists(id) ON DELETE RESTRICT;
ALTER TABLE conversation_participants ADD CONSTRAINT fk_conversation_participants_conversation_id_conversations FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE;
ALTER TABLE conversation_participants ADD CONSTRAINT fk_conversation_participants_user_id_users FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE conversations ADD CONSTRAINT fk_conversations_group_id_groups FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE SET NULL;
ALTER TABLE discard ADD CONSTRAINT discard_movement_id_fkey FOREIGN KEY (movement_id) REFERENCES stock_movements(id);
ALTER TABLE discard ADD CONSTRAINT fk_discard_stock_product_id_stock_products FOREIGN KEY (stock_product_id) REFERENCES stock_products(id) ON DELETE CASCADE;
ALTER TABLE food_purchase_lines ADD CONSTRAINT food_purchase_lines_product_id_fkey FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE SET NULL;
ALTER TABLE food_purchase_lines ADD CONSTRAINT food_purchase_lines_purchase_id_fkey FOREIGN KEY (purchase_id) REFERENCES food_purchases(id);
ALTER TABLE food_purchase_lines ADD CONSTRAINT food_purchase_lines_stock_product_id_fkey FOREIGN KEY (stock_product_id) REFERENCES stock_products(id) ON DELETE SET NULL;
ALTER TABLE food_purchase_revisions ADD CONSTRAINT food_purchase_revisions_changed_by_fkey FOREIGN KEY (changed_by) REFERENCES users(id);
ALTER TABLE food_purchase_revisions ADD CONSTRAINT food_purchase_revisions_purchase_id_fkey FOREIGN KEY (purchase_id) REFERENCES food_purchases(id);
ALTER TABLE food_purchases ADD CONSTRAINT food_purchases_group_id_fkey FOREIGN KEY (group_id) REFERENCES groups(id);
ALTER TABLE group_invitations ADD CONSTRAINT group_invitations_group_id_fkey FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE;
ALTER TABLE groups ADD CONSTRAINT fk_groups_owner_id_users FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE message_attachments ADD CONSTRAINT fk_message_attachments_message_id_messages FOREIGN KEY (message_id) REFERENCES messages(id) ON DELETE CASCADE;
ALTER TABLE message_reactions ADD CONSTRAINT message_reactions_message_id_fkey FOREIGN KEY (message_id) REFERENCES messages(id) ON DELETE CASCADE;
ALTER TABLE message_reactions ADD CONSTRAINT message_reactions_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE message_reads ADD CONSTRAINT fk_message_reads_conversation_id_participants FOREIGN KEY (conversation_id, user_id) REFERENCES conversation_participants(conversation_id, user_id) ON DELETE CASCADE;
ALTER TABLE message_reads ADD CONSTRAINT fk_message_reads_message_id_messages FOREIGN KEY (message_id, conversation_id) REFERENCES messages(id, conversation_id) ON DELETE CASCADE;
ALTER TABLE messages ADD CONSTRAINT fk_messages_conversation_id_conversations FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE;
ALTER TABLE messages ADD CONSTRAINT fk_messages_conversation_id_participants FOREIGN KEY (conversation_id, sender_id) REFERENCES conversation_participants(conversation_id, user_id);
ALTER TABLE messages ADD CONSTRAINT fk_messages_related_shopping_list_product_id_slp FOREIGN KEY (related_shopping_list_product_id) REFERENCES shopping_list_products(id) ON DELETE SET NULL;
ALTER TABLE messages ADD CONSTRAINT fk_messages_sender_id_users FOREIGN KEY (sender_id) REFERENCES users(id);
ALTER TABLE money_allocations ADD CONSTRAINT money_allocations_exit_id_fkey FOREIGN KEY (exit_id) REFERENCES money_exits(id) ON DELETE CASCADE;
ALTER TABLE money_allocations ADD CONSTRAINT money_allocations_supply_id_fkey FOREIGN KEY (supply_id) REFERENCES money_supplies(id) ON DELETE SET NULL;
ALTER TABLE money_exits ADD CONSTRAINT money_exits_group_id_fkey FOREIGN KEY (group_id) REFERENCES groups(id);
ALTER TABLE money_exits ADD CONSTRAINT money_exits_movement_id_fkey FOREIGN KEY (movement_id) REFERENCES stock_movements(id) ON DELETE SET NULL;
ALTER TABLE money_exits ADD CONSTRAINT money_exits_stock_product_id_fkey FOREIGN KEY (stock_product_id) REFERENCES stock_products(id) ON DELETE SET NULL;
ALTER TABLE money_supplies ADD CONSTRAINT money_supplies_purchase_line_id_fkey FOREIGN KEY (purchase_line_id) REFERENCES food_purchase_lines(id);
ALTER TABLE money_supplies ADD CONSTRAINT money_supplies_stock_product_id_fkey FOREIGN KEY (stock_product_id) REFERENCES stock_products(id) ON DELETE SET NULL;
ALTER TABLE notifications ADD CONSTRAINT fk_notifications_group_id_groups FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE;
ALTER TABLE notifications ADD CONSTRAINT fk_notifications_recipient_user_id_users FOREIGN KEY (recipient_user_id) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE password_reset_tokens ADD CONSTRAINT password_reset_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE product_categories ADD CONSTRAINT product_categories_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES product_categories(id);
ALTER TABLE products ADD CONSTRAINT products_owner_group_id_fkey FOREIGN KEY (owner_group_id) REFERENCES groups(id) ON DELETE RESTRICT;
ALTER TABLE receipt_draft_lines ADD CONSTRAINT receipt_draft_lines_matched_product_id_fkey FOREIGN KEY (matched_product_id) REFERENCES products(id);
ALTER TABLE receipt_draft_lines ADD CONSTRAINT receipt_draft_lines_receipt_id_fkey FOREIGN KEY (receipt_id) REFERENCES receipt_drafts(id) ON DELETE CASCADE;
ALTER TABLE receipt_drafts ADD CONSTRAINT receipt_drafts_created_by_fkey FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE receipt_drafts ADD CONSTRAINT receipt_drafts_stock_id_fkey FOREIGN KEY (stock_id) REFERENCES stocks(id) ON DELETE CASCADE;
ALTER TABLE recipe_favorites ADD CONSTRAINT recipe_favorites_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE;
ALTER TABLE recipe_favorites ADD CONSTRAINT recipe_favorites_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE recipe_ingredients ADD CONSTRAINT fk_recipe_ingredients_product_id_products FOREIGN KEY (product_id) REFERENCES products(id);
ALTER TABLE recipe_ingredients ADD CONSTRAINT fk_recipe_ingredients_recipe_id_recipes FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE;
ALTER TABLE recipe_suggestions ADD CONSTRAINT fk_recipe_suggestions_recipe_id_recipes FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE;
ALTER TABLE recipe_suggestions ADD CONSTRAINT fk_recipe_suggestions_stock_id_stocks FOREIGN KEY (stock_id) REFERENCES stocks(id) ON DELETE CASCADE;
ALTER TABLE requests ADD CONSTRAINT fk_requests_conversation_id_conversations FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE SET NULL;
ALTER TABLE requests ADD CONSTRAINT fk_requests_message_id_messages FOREIGN KEY (message_id, conversation_id) REFERENCES messages(id, conversation_id) ON DELETE SET NULL;
ALTER TABLE requests ADD CONSTRAINT fk_requests_product_id_products FOREIGN KEY (product_id) REFERENCES products(id);
ALTER TABLE requests ADD CONSTRAINT fk_requests_stock_id_stocks FOREIGN KEY (stock_id) REFERENCES stocks(id) ON DELETE CASCADE;
ALTER TABLE requests ADD CONSTRAINT fk_requests_user_id_users FOREIGN KEY (user_id) REFERENCES users(id);
ALTER TABLE shopping_list_products ADD CONSTRAINT fk_shopping_list_products_list_id_shopping_lists FOREIGN KEY (list_id) REFERENCES shopping_lists(id) ON DELETE CASCADE;
ALTER TABLE shopping_list_products ADD CONSTRAINT fk_shopping_list_products_product_id_products FOREIGN KEY (product_id) REFERENCES products(id);
ALTER TABLE shopping_lists ADD CONSTRAINT fk_shopping_lists_stock_id_stocks FOREIGN KEY (stock_id) REFERENCES stocks(id) ON DELETE CASCADE;
ALTER TABLE stock_movements ADD CONSTRAINT fk_stock_movements_stock_product_id_stock_products FOREIGN KEY (stock_product_id) REFERENCES stock_products(id) ON DELETE CASCADE;
ALTER TABLE stock_movements ADD CONSTRAINT fk_stock_movements_user_id_users FOREIGN KEY (user_id) REFERENCES users(id);
ALTER TABLE stock_products ADD CONSTRAINT fk_stock_products_product_id_products FOREIGN KEY (product_id) REFERENCES products(id);
ALTER TABLE stock_products ADD CONSTRAINT fk_stock_products_stock_id_stocks FOREIGN KEY (stock_id) REFERENCES stocks(id) ON DELETE CASCADE;
ALTER TABLE stocks ADD CONSTRAINT fk_stocks_group_id_groups FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE;
ALTER TABLE subscriptions ADD CONSTRAINT fk_subscriptions_plan_id_plans FOREIGN KEY (plan_id) REFERENCES plans(id);
ALTER TABLE subscriptions ADD CONSTRAINT fk_subscriptions_user_id_users FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE support_requests ADD CONSTRAINT support_requests_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE transaction_events ADD CONSTRAINT fk_transaction_events_transaction_id_transactions FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE CASCADE;
ALTER TABLE transactions ADD CONSTRAINT fk_transactions_plan_id_plans FOREIGN KEY (plan_id) REFERENCES plans(id);
ALTER TABLE transactions ADD CONSTRAINT fk_transactions_subscription_id_subscriptions FOREIGN KEY (subscription_id) REFERENCES subscriptions(id) ON DELETE CASCADE;
ALTER TABLE transactions ADD CONSTRAINT fk_transactions_user_id_users FOREIGN KEY (user_id) REFERENCES users(id);
ALTER TABLE user_app_settings ADD CONSTRAINT user_app_settings_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE user_groups ADD CONSTRAINT fk_user_groups_group_id_groups FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE;
ALTER TABLE user_groups ADD CONSTRAINT fk_user_groups_user_id_users FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE user_preferences ADD CONSTRAINT user_preferences_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
