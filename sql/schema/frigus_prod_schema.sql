--
-- PostgreSQL database dump
--

\restrict O2BFD8CNqnkYEKkqC6a75hBRvcdHhjtQqP0FFbBCUyiGFNCbxzE2uoAFeoAvNPT

-- Dumped from database version 17.6
-- Dumped by pg_dump version 18.6

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: analytics; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA analytics;


--
-- Name: audit; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA audit;


--
-- Name: dw; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA dw;


--
-- Name: governance; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA governance;


--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA public;


--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- Name: account_type_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.account_type_enum AS ENUM (
    'DOMESTIC',
    'BUSINESS',
    'COMMERCIAL'
);


--
-- Name: billing_interval_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.billing_interval_enum AS ENUM (
    'MONTHLY',
    'YEARLY'
);


--
-- Name: category_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.category_enum AS ENUM (
    'FRUIT',
    'VEGETABLE',
    'DAIRY',
    'MEAT',
    'GRAIN',
    'BEVERAGE',
    'CLEANING',
    'PERSONAL_HYGIENE',
    'FISH',
    'FROZEN',
    'SWEETS',
    'CANNED',
    'SEASONING'
);


--
-- Name: conversation_type_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.conversation_type_enum AS ENUM (
    'PRIVATE',
    'GROUP'
);


--
-- Name: list_status_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.list_status_enum AS ENUM (
    'OPEN',
    'COMPLETED',
    'CANCELED'
);


--
-- Name: message_type_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.message_type_enum AS ENUM (
    'TEXT',
    'IMAGE',
    'SYSTEM'
);


--
-- Name: movement_type_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.movement_type_enum AS ENUM (
    'IN',
    'OUT',
    'ADJUSTMENT'
);


--
-- Name: notification_type_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.notification_type_enum AS ENUM (
    'PRODUCT_NEAR_EXPIRATION',
    'GROUP_MEMBER_JOINED',
    'SHOPPING_LIST_PRODUCT_ADDED',
    'SHOPPING_LIST_REMINDER',
    'LOW_STOCK',
    'OUT_OF_STOCK',
    'AD_CLICK_MILESTONE',
    'WEEKLY_SUMMARY'
);


--
-- Name: payment_method_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.payment_method_enum AS ENUM (
    'CREDIT_CARD',
    'DEBIT_CARD',
    'PIX',
    'BOLETO'
);


--
-- Name: product_list_status_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.product_list_status_enum AS ENUM (
    'PENDING',
    'PURCHASED',
    'REMOVED'
);


--
-- Name: product_status_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.product_status_enum AS ENUM (
    'FRESH',
    'NEAR_EXPIRATION',
    'EXPIRED'
);


--
-- Name: storage_place_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.storage_place_enum AS ENUM (
    'FRIDGE',
    'FREEZER',
    'PANTRY',
    'CABINET',
    'SHELF'
);


--
-- Name: subscription_status_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.subscription_status_enum AS ENUM (
    'TRIAL',
    'ACTIVE',
    'CANCELED',
    'EXPIRED',
    'DELINQUENT'
);


--
-- Name: transaction_status_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.transaction_status_enum AS ENUM (
    'PENDING',
    'PROCESSING',
    'APPROVED',
    'REJECTED',
    'CANCELED',
    'ERROR'
);


--
-- Name: unit_of_measure_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.unit_of_measure_enum AS ENUM (
    'KILOGRAM',
    'GRAM',
    'LITER',
    'MILLILITER',
    'UNIT',
    'DOZEN',
    'PACKAGE'
);


--
-- Name: user_role_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.user_role_enum AS ENUM (
    'USER',
    'ADMIN'
);


--
-- Name: capture_row_change(); Type: FUNCTION; Schema: audit; Owner: -
--

CREATE FUNCTION audit.capture_row_change() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
BEGIN
    INSERT INTO audit.row_change_log (
        table_schema,
        table_name,
        operation,
        current_user_name,
        old_row,
        new_row
    )
    VALUES (
        TG_TABLE_SCHEMA,
        TG_TABLE_NAME,
        TG_OP,
        CURRENT_USER::text,
        CASE WHEN TG_OP IN ('UPDATE', 'DELETE') THEN to_jsonb(OLD) ELSE NULL END,
        CASE WHEN TG_OP IN ('INSERT', 'UPDATE') THEN to_jsonb(NEW) ELSE NULL END
    );

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;
    RETURN NEW;
END;
$$;


--
-- Name: sp_load_all(); Type: FUNCTION; Schema: dw; Owner: -
--

CREATE FUNCTION dw.sp_load_all() RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'dw', 'public', 'pg_temp'
    AS $$
BEGIN
  INSERT INTO dw.dim_group (group_id, group_name)
  SELECT g.id, g.name
  FROM public.groups g
  WHERE g.deleted_at IS NULL
  ON CONFLICT (group_id) DO UPDATE
    SET group_name = EXCLUDED.group_name;

  INSERT INTO dw.dim_stock (stock_id, stock_name, group_key)
  SELECT s.id, s.name, dg.group_key
  FROM public.stocks s
  JOIN dw.dim_group dg ON dg.group_id = s.group_id
  WHERE s.deleted_at IS NULL
  ON CONFLICT (stock_id) DO UPDATE
    SET stock_name = EXCLUDED.stock_name,
        group_key  = EXCLUDED.group_key;

  INSERT INTO dw.dim_product (product_id, product_name, category, storage_place, unit_of_measure, brand)
  SELECT p.id, p.name, p.category::text, p.storage_place::text, p.unit_of_measure::text, p.brand
  FROM public.products p
  ON CONFLICT (product_id) DO UPDATE
    SET product_name    = EXCLUDED.product_name,
        category        = EXCLUDED.category,
        storage_place   = EXCLUDED.storage_place,
        unit_of_measure = EXCLUDED.unit_of_measure,
        brand           = EXCLUDED.brand;

  INSERT INTO dw.dim_user (user_id, user_name, account_type)
  SELECT u.id, u.name, u.account_type::text
  FROM public.users u
  WHERE u.deleted_at IS NULL
  ON CONFLICT (user_id) DO UPDATE
    SET user_name    = EXCLUDED.user_name,
        account_type = EXCLUDED.account_type;

  INSERT INTO dw.dim_date (date_key, year, month, week_start, day_of_week, is_weekend)
  SELECT
    d::date,
    EXTRACT(YEAR FROM d)::int,
    EXTRACT(MONTH FROM d)::int,
    DATE_TRUNC('week', d)::date,
    EXTRACT(ISODOW FROM d)::int,
    EXTRACT(ISODOW FROM d) IN (6, 7)
  FROM generate_series('2024-01-01'::date, (CURRENT_DATE + 365)::date, INTERVAL '1 day') AS d
  ON CONFLICT (date_key) DO NOTHING;

  TRUNCATE dw.fact_stock_movement;

  INSERT INTO dw.fact_stock_movement (
    movement_id, date_key, moved_at, product_key, stock_key, group_key,
    user_key, movement_type, quantity, balance_after_source, purpose
  )
  WITH src AS (
    SELECT
      sm.id,
      sm.date,
      sm.movement_type::text AS movement_type,
      sm.quantity,
      sm.balance_after,
      sm.purpose,
      sm.user_id,
      sp.product_id,
      sp.stock_id
    FROM public.stock_movements sm
    JOIN public.stock_products sp ON sp.id = sm.stock_product_id
    JOIN public.stocks s          ON s.id  = sp.stock_id
  )
  SELECT
    src.id,
    src.date::date,
    src.date,
    dp.product_key,
    ds.stock_key,
    ds.group_key,
    du.user_key,
    src.movement_type,
    src.quantity,
    src.balance_after,
    src.purpose
  FROM src
  JOIN dw.dim_product dp   ON dp.product_id = src.product_id
  JOIN dw.dim_stock   ds   ON ds.stock_id   = src.stock_id
  LEFT JOIN dw.dim_user du ON du.user_id    = src.user_id;
END;
$$;


--
-- Name: fn_compute_product_status(date, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_compute_product_status(p_expire_date date, p_warn_days integer DEFAULT 3) RETURNS character varying
    LANGUAGE sql STABLE
    AS $$
    SELECT CASE fn_compute_product_status_enum(p_expire_date, p_warn_days)
        WHEN 'EXPIRED'::product_status_enum         THEN 'Vencido'
        WHEN 'NEAR_EXPIRATION'::product_status_enum THEN 'Próximo do vencimento'
        WHEN 'FRESH'::product_status_enum           THEN 'Fresco'
    END;
$$;


--
-- Name: fn_compute_product_status_enum(date, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_compute_product_status_enum(p_expire_date date, p_warn_days integer DEFAULT 3) RETURNS public.product_status_enum
    LANGUAGE sql STABLE
    AS $$
    SELECT CASE
        WHEN p_expire_date < CURRENT_DATE THEN 'EXPIRED'::product_status_enum
        WHEN p_expire_date <= CURRENT_DATE + p_warn_days THEN 'NEAR_EXPIRATION'::product_status_enum
        ELSE 'FRESH'::product_status_enum
    END;
$$;


--
-- Name: fn_log_transaction_status_change(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_log_transaction_status_change() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'INSERT' OR NEW.status IS DISTINCT FROM OLD.status THEN
        INSERT INTO transaction_events (transaction_id, status, message)
        VALUES (NEW.id, NEW.status, NULL);
    END IF;
    RETURN NEW;
END;
$$;


--
-- Name: fn_low_stock_products(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_low_stock_products(p_stock_id integer) RETURNS TABLE(stock_product_id integer, product_id integer, product_name character varying, quantity integer, minimal_quantity integer)
    LANGUAGE sql STABLE
    AS $$
    SELECT sp.id, sp.product_id, p.name, sp.quantity, sp.minimal_quantity
    FROM stock_products sp
    JOIN products p ON p.id = sp.product_id
    WHERE sp.stock_id = p_stock_id
      AND sp.minimal_quantity IS NOT NULL
      AND sp.quantity < sp.minimal_quantity;
$$;


--
-- Name: fn_pair_key(integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_pair_key(p_user_a integer, p_user_b integer) RETURNS character varying
    LANGUAGE sql IMMUTABLE
    AS $$
    SELECT LEAST(p_user_a, p_user_b)::VARCHAR || '_' || GREATEST(p_user_a, p_user_b)::VARCHAR;
$$;


--
-- Name: fn_set_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_set_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


--
-- Name: fn_suggest_recipes(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_suggest_recipes(p_stock_id integer) RETURNS TABLE(recipe_id integer, matched_ingredients integer, missing_ingredients integer, nearest_expire_date date, score numeric)
    LANGUAGE sql STABLE
    AS $$
    WITH ingredient_match AS (
        SELECT
            ri.recipe_id,
            ri.product_id,
            bool_or(sp.id IS NOT NULL)  AS in_stock,
            MIN(sp.expire_date)          AS earliest_expire_date
        FROM recipe_ingredients ri
        LEFT JOIN stock_products sp
            ON sp.product_id = ri.product_id
           AND sp.stock_id = p_stock_id
        GROUP BY ri.recipe_id, ri.product_id
    )
    SELECT
        recipe_id,
        COUNT(*) FILTER (WHERE in_stock)::INTEGER      AS matched_ingredients,
        COUNT(*) FILTER (WHERE NOT in_stock)::INTEGER  AS missing_ingredients,
        MIN(earliest_expire_date)                       AS nearest_expire_date,
        ROUND(COUNT(*) FILTER (WHERE in_stock)::NUMERIC / NULLIF(COUNT(*), 0), 2) AS score
    FROM ingredient_match
    GROUP BY recipe_id;
$$;


--
-- Name: sp_close_shopping_list(integer); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_close_shopping_list(IN p_list_id integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM shopping_list_products
        WHERE list_id = p_list_id
          AND status NOT IN ('PURCHASED', 'REMOVED')
    ) THEN
        UPDATE shopping_lists
           SET status = 'COMPLETED'
         WHERE id = p_list_id;
    END IF;
END;
$$;


--
-- Name: sp_get_or_create_private_conversation(integer, integer, integer); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_get_or_create_private_conversation(IN p_user_a integer, IN p_user_b integer, INOUT p_conversation_id integer DEFAULT NULL::integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_pair_key VARCHAR;
BEGIN
    v_pair_key := fn_pair_key(p_user_a, p_user_b);

    SELECT id INTO p_conversation_id
    FROM conversations
    WHERE pair_key = v_pair_key;

    IF p_conversation_id IS NULL THEN
        INSERT INTO conversations (conversation_type)
        VALUES ('PRIVATE')
        RETURNING id INTO p_conversation_id;

        INSERT INTO conversation_participants (conversation_id, user_id)
        VALUES (p_conversation_id, p_user_a), (p_conversation_id, p_user_b);
        -- trg_conversation_participants_pair_key seta o pair_key após o 2º insert acima
    END IF;
END;
$$;


--
-- Name: sp_purchase_shopping_list_item(integer, integer, integer, integer, integer, date, integer); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_purchase_shopping_list_item(IN p_list_id integer, IN p_product_id integer, IN p_stock_id integer, IN p_stock_product_id integer, IN p_quantity integer, IN p_expire_date date, IN p_user_id integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE shopping_list_products
       SET status = 'PURCHASED'
     WHERE list_id = p_list_id
       AND product_id = p_product_id;

    INSERT INTO stock_products (id, product_id, stock_id, quantity, expire_date, category)
    SELECT p_stock_product_id, p_product_id, p_stock_id, 0, p_expire_date, category
    FROM products
    WHERE id = p_product_id
    ON CONFLICT (product_id, stock_id, expire_date) DO NOTHING;

    INSERT INTO stock_movements (stock_product_id, user_id, movement_type, quantity)
    VALUES (p_stock_product_id, p_user_id, 'IN', p_quantity);
    -- trg_stock_movements_apply soma p_quantity em stock_products.quantity
END;
$$;


--
-- Name: trg_fn_conversation_participants_pair_key(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.trg_fn_conversation_participants_pair_key() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_conversation_type conversation_type_enum;
    v_participants       INTEGER[];
BEGIN
    SELECT conversation_type INTO v_conversation_type
    FROM conversations
    WHERE id = NEW.conversation_id;

    IF v_conversation_type = 'PRIVATE' THEN
        SELECT array_agg(user_id ORDER BY user_id) INTO v_participants
        FROM conversation_participants
        WHERE conversation_id = NEW.conversation_id;

        IF array_length(v_participants, 1) = 2 THEN
            UPDATE conversations
               SET pair_key = fn_pair_key(v_participants[1], v_participants[2])
             WHERE id = NEW.conversation_id;
        END IF;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: trg_fn_filter_notification_preferences(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.trg_fn_filter_notification_preferences() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
 IF EXISTS (SELECT 1 FROM user_preferences p WHERE p.user_id=NEW.recipient_user_id AND (
  (NEW.type::text='PRODUCT_NEAR_EXPIRATION' AND NOT p.expiration_alerts_enabled) OR
  (NEW.type::text IN ('LOW_STOCK','OUT_OF_STOCK') AND NOT p.low_stock_alerts_enabled) OR
  (NEW.type::text='SHOPPING_LIST_REMINDER' AND NOT p.shopping_reminders_enabled) OR
  (NEW.type::text='WEEKLY_SUMMARY' AND NOT p.weekly_summary_enabled)
 )) THEN RETURN NULL; END IF;
 RETURN NEW;
END $$;


--
-- Name: trg_fn_notify_commercial_stock_level(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.trg_fn_notify_commercial_stock_level() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE v_group_id UUID; v_type notification_type_enum; v_title VARCHAR;
BEGIN
 SELECT s.group_id INTO v_group_id FROM stocks s JOIN groups g ON g.id=s.group_id
 JOIN users u ON u.id=g.owner_id WHERE s.id=NEW.stock_id AND s.deleted_at IS NULL
 AND g.deleted_at IS NULL AND u.account_type IN ('DOMESTIC','COMMERCIAL');
 IF v_group_id IS NULL OR NEW.deleted_at IS NOT NULL THEN RETURN NEW; END IF;
 IF NEW.quantity=0 AND (TG_OP='INSERT' OR OLD.quantity IS DISTINCT FROM 0) THEN
  v_type:='OUT_OF_STOCK'; v_title:='Estoque zerado';
 ELSIF NEW.minimal_quantity IS NOT NULL AND NEW.quantity>0 AND NEW.quantity<=NEW.minimal_quantity
 AND (TG_OP='INSERT' OR OLD.quantity>COALESCE(OLD.minimal_quantity,-1)
 OR OLD.minimal_quantity IS DISTINCT FROM NEW.minimal_quantity) THEN
  v_type:='LOW_STOCK'; v_title:='Produto com pouca quantidade no estoque';
 ELSE RETURN NEW; END IF;
 INSERT INTO notifications(recipient_user_id,group_id,type,title,body,reference_id)
 SELECT ug.user_id,v_group_id,v_type,v_title,p.name || ': quantidade atual ' || NEW.quantity,NEW.id::text
 FROM user_groups ug CROSS JOIN products p WHERE ug.group_id=v_group_id AND p.id=NEW.product_id;
 RETURN NEW;
END $$;


--
-- Name: trg_fn_notify_shopping_list_product_added(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.trg_fn_notify_shopping_list_product_added() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_group_id UUID;
BEGIN
    SELECT s.group_id INTO v_group_id
      FROM shopping_lists sl
      JOIN stocks s ON s.id = sl.stock_id
      JOIN groups g ON g.id = s.group_id
      JOIN users u ON u.id = g.owner_id
     WHERE sl.id = NEW.list_id
       AND u.account_type IN ('DOMESTIC', 'COMMERCIAL');

    IF v_group_id IS NULL THEN
        RETURN NEW;
    END IF;

    INSERT INTO notifications (
        recipient_user_id, group_id, type, title, body, reference_id, deduplication_key
    )
    SELECT ug.user_id, v_group_id, 'SHOPPING_LIST_PRODUCT_ADDED',
           'Item adicionado à lista de compras',
           'Um novo item foi adicionado à lista de compras do grupo.',
           NEW.id::VARCHAR,
           'shopping-list-product:' || NEW.id::VARCHAR || ':' || ug.user_id::VARCHAR
      FROM user_groups ug
     WHERE ug.group_id = v_group_id
    ON CONFLICT (deduplication_key) WHERE deduplication_key IS NOT NULL DO NOTHING;

    RETURN NEW;
END;
$$;


--
-- Name: trg_fn_stock_products_set_initial_quantity(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.trg_fn_stock_products_set_initial_quantity() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.initial_quantity IS NULL THEN
        NEW.initial_quantity := COALESCE(NEW.quantity, 1);
    END IF;
    RETURN NEW;
END;
$$;


--
-- Name: trg_fn_stock_products_set_status(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.trg_fn_stock_products_set_status() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- usa a versão que retorna o enum (valores em inglês), não a versão
    -- de exibição em português, já que a coluna é do tipo product_status_enum.
    NEW.product_status := fn_compute_product_status_enum(NEW.expire_date);
    RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: stock_movements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stock_movements (
    id integer NOT NULL,
    stock_product_id integer NOT NULL,
    user_id uuid NOT NULL,
    movement_type public.movement_type_enum NOT NULL,
    quantity integer NOT NULL,
    date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    observation character varying(2000),
    balance_after integer,
    purpose character varying(20) DEFAULT 'INVENTORY'::character varying NOT NULL,
    reason_code character varying(24),
    CONSTRAINT stock_movements_purpose_check CHECK (((purpose)::text = ANY (ARRAY[('INVENTORY'::character varying)::text, ('CONSUMPTION'::character varying)::text, ('DISCARD'::character varying)::text])))
);


--
-- Name: stock_products; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stock_products (
    id integer NOT NULL,
    product_id integer NOT NULL,
    stock_id integer NOT NULL,
    quantity integer NOT NULL,
    minimal_quantity integer,
    expire_date date NOT NULL,
    product_status public.product_status_enum,
    category public.category_enum NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    purchase_unit_price numeric(10,2),
    deleted_at timestamp without time zone,
    batch character varying(120),
    initial_quantity integer DEFAULT 1,
    CONSTRAINT chk_stock_products_initial_quantity CHECK ((initial_quantity >= 0)),
    CONSTRAINT chk_stock_products_minimal_quantity CHECK (((minimal_quantity IS NULL) OR (minimal_quantity >= 0))),
    CONSTRAINT chk_stock_products_purchase_unit_price CHECK (((purchase_unit_price IS NULL) OR (purchase_unit_price > (0)::numeric)))
);


--
-- Name: transactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.transactions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    subscription_id uuid,
    plan_id integer NOT NULL,
    amount numeric(10,2) NOT NULL,
    payment_method public.payment_method_enum NOT NULL,
    fake_card_last4 character varying(4),
    fake_pix_key character varying,
    status public.transaction_status_enum DEFAULT 'PENDING'::public.transaction_status_enum NOT NULL,
    queue_job_id character varying,
    attempts integer DEFAULT 0 NOT NULL,
    max_attempts integer DEFAULT 3 NOT NULL,
    error_message text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    queued_at timestamp without time zone,
    processed_at timestamp without time zone,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    idempotency_key character varying(120) NOT NULL,
    CONSTRAINT chk_transactions_processed_at CHECK ((((status = ANY (ARRAY['PENDING'::public.transaction_status_enum, 'PROCESSING'::public.transaction_status_enum])) AND (processed_at IS NULL)) OR (status <> ALL (ARRAY['PENDING'::public.transaction_status_enum, 'PROCESSING'::public.transaction_status_enum])))),
    CONSTRAINT transactions_amount_check CHECK ((amount >= (0)::numeric))
);


--
-- Name: dim_date; Type: VIEW; Schema: analytics; Owner: -
--

CREATE VIEW analytics.dim_date WITH (security_invoker='true') AS
 WITH source_dates AS (
         SELECT (transactions.created_at)::date AS d
           FROM public.transactions
          WHERE (transactions.created_at IS NOT NULL)
        UNION ALL
         SELECT (stock_movements.date)::date AS date
           FROM public.stock_movements
          WHERE (stock_movements.date IS NOT NULL)
        UNION ALL
         SELECT (stock_products.created_at)::date AS created_at
           FROM public.stock_products
          WHERE (stock_products.created_at IS NOT NULL)
        ), bounds AS (
         SELECT LEAST(COALESCE(min(source_dates.d), CURRENT_DATE), CURRENT_DATE) AS start_date,
            GREATEST(COALESCE(max(source_dates.d), CURRENT_DATE), CURRENT_DATE) AS end_date
           FROM source_dates
        )
 SELECT (generated.day)::date AS date_key,
    (EXTRACT(year FROM generated.day))::integer AS calendar_year,
    (EXTRACT(quarter FROM generated.day))::integer AS calendar_quarter,
    (EXTRACT(month FROM generated.day))::integer AS calendar_month,
    (EXTRACT(day FROM generated.day))::integer AS day_of_month,
    (EXTRACT(isodow FROM generated.day))::integer AS iso_day_of_week,
    ((EXTRACT(isodow FROM generated.day))::integer = ANY (ARRAY[6, 7])) AS is_weekend
   FROM (bounds
     CROSS JOIN LATERAL generate_series((bounds.start_date)::timestamp without time zone, (bounds.end_date)::timestamp without time zone, '1 day'::interval) generated(day));


--
-- Name: plans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.plans (
    id integer NOT NULL,
    name character varying NOT NULL,
    description text,
    price numeric(10,2) DEFAULT 0 NOT NULL,
    billing_interval public.billing_interval_enum,
    active boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted_at timestamp without time zone,
    plan_code character varying(20) NOT NULL
);


--
-- Name: dim_plan; Type: VIEW; Schema: analytics; Owner: -
--

CREATE VIEW analytics.dim_plan WITH (security_invoker='true') AS
 SELECT id AS plan_key,
    plan_code,
    name AS plan_name,
    billing_interval,
    active
   FROM public.plans p
  WHERE (deleted_at IS NULL);


--
-- Name: products; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.products (
    id integer NOT NULL,
    name character varying NOT NULL,
    category public.category_enum NOT NULL,
    storage_place public.storage_place_enum NOT NULL,
    unit_price numeric(10,2) NOT NULL,
    unit_of_measure public.unit_of_measure_enum NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    brand character varying(120),
    image_url text,
    owner_group_id uuid
);


--
-- Name: dim_product; Type: VIEW; Schema: analytics; Owner: -
--

CREATE VIEW analytics.dim_product WITH (security_invoker='true') AS
 SELECT id AS product_key,
    name AS product_name,
    category,
    storage_place,
    unit_of_measure,
    unit_price
   FROM public.products p;


--
-- Name: groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.groups (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying NOT NULL,
    banner_picture text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted_at timestamp without time zone,
    owner_id uuid,
    time_zone character varying(80) DEFAULT 'America/Sao_Paulo'::character varying NOT NULL,
    CONSTRAINT chk_active_groups_require_owner CHECK (((deleted_at IS NOT NULL) OR (owner_id IS NOT NULL)))
);


--
-- Name: stocks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stocks (
    id integer NOT NULL,
    group_id uuid NOT NULL,
    name character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted_at timestamp without time zone
);


--
-- Name: dim_stock; Type: VIEW; Schema: analytics; Owner: -
--

CREATE VIEW analytics.dim_stock WITH (security_invoker='true') AS
 SELECT s.id AS stock_key,
    s.name AS stock_name,
    s.group_id,
    g.name AS group_name
   FROM (public.stocks s
     LEFT JOIN public.groups g ON ((g.id = s.group_id)))
  WHERE (s.deleted_at IS NULL);


--
-- Name: fact_inventory_snapshot; Type: VIEW; Schema: analytics; Owner: -
--

CREATE VIEW analytics.fact_inventory_snapshot WITH (security_invoker='true') AS
 SELECT id AS inventory_row_key,
    stock_id AS stock_key,
    product_id AS product_key,
    quantity,
    minimal_quantity,
    expire_date,
    product_status,
    (created_at)::date AS created_date_key,
    (updated_at)::date AS updated_date_key
   FROM public.stock_products sp;


--
-- Name: fact_transactions; Type: VIEW; Schema: analytics; Owner: -
--

CREATE VIEW analytics.fact_transactions WITH (security_invoker='true') AS
 WITH base_transactions AS (
         SELECT t.id AS transaction_key,
            t.created_at,
            (t.created_at)::date AS date_key,
            t.plan_id AS plan_key,
            t.amount,
            t.status,
            t.payment_method,
                CASE
                    WHEN (t.status = 'APPROVED'::public.transaction_status_enum) THEN t.amount
                    ELSE (0)::numeric
                END AS approved_amount
           FROM public.transactions t
        )
 SELECT transaction_key,
    date_key,
    plan_key,
    amount,
    status,
    payment_method,
    approved_amount,
    sum(approved_amount) OVER (ORDER BY created_at, transaction_key ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_approved_revenue,
    rank() OVER (PARTITION BY date_key ORDER BY approved_amount DESC) AS approved_amount_rank_for_day
   FROM base_transactions bt;


--
-- Name: row_change_log; Type: TABLE; Schema: audit; Owner: -
--

CREATE TABLE audit.row_change_log (
    id bigint NOT NULL,
    changed_at timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    table_schema text NOT NULL,
    table_name text NOT NULL,
    operation text NOT NULL,
    current_user_name text NOT NULL,
    old_row jsonb,
    new_row jsonb,
    CONSTRAINT row_change_log_operation_check CHECK ((operation = ANY (ARRAY['INSERT'::text, 'UPDATE'::text, 'DELETE'::text])))
);


--
-- Name: row_change_log_id_seq; Type: SEQUENCE; Schema: audit; Owner: -
--

ALTER TABLE audit.row_change_log ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME audit.row_change_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: dim_date; Type: TABLE; Schema: dw; Owner: -
--

CREATE TABLE dw.dim_date (
    date_key date NOT NULL,
    year integer NOT NULL,
    month integer NOT NULL,
    week_start date NOT NULL,
    day_of_week integer NOT NULL,
    is_weekend boolean NOT NULL
);


--
-- Name: dim_group; Type: TABLE; Schema: dw; Owner: -
--

CREATE TABLE dw.dim_group (
    group_key integer NOT NULL,
    group_id uuid NOT NULL,
    group_name character varying NOT NULL
);


--
-- Name: dim_group_group_key_seq; Type: SEQUENCE; Schema: dw; Owner: -
--

ALTER TABLE dw.dim_group ALTER COLUMN group_key ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME dw.dim_group_group_key_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: dim_product; Type: TABLE; Schema: dw; Owner: -
--

CREATE TABLE dw.dim_product (
    product_key integer NOT NULL,
    product_id integer NOT NULL,
    product_name character varying NOT NULL,
    category text,
    storage_place text,
    unit_of_measure text,
    brand character varying
);


--
-- Name: dim_product_product_key_seq; Type: SEQUENCE; Schema: dw; Owner: -
--

ALTER TABLE dw.dim_product ALTER COLUMN product_key ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME dw.dim_product_product_key_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: dim_stock; Type: TABLE; Schema: dw; Owner: -
--

CREATE TABLE dw.dim_stock (
    stock_key integer NOT NULL,
    stock_id integer NOT NULL,
    stock_name character varying NOT NULL,
    group_key integer
);


--
-- Name: dim_stock_stock_key_seq; Type: SEQUENCE; Schema: dw; Owner: -
--

ALTER TABLE dw.dim_stock ALTER COLUMN stock_key ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME dw.dim_stock_stock_key_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: dim_user; Type: TABLE; Schema: dw; Owner: -
--

CREATE TABLE dw.dim_user (
    user_key integer NOT NULL,
    user_id uuid NOT NULL,
    user_name character varying,
    account_type text
);


--
-- Name: dim_user_user_key_seq; Type: SEQUENCE; Schema: dw; Owner: -
--

ALTER TABLE dw.dim_user ALTER COLUMN user_key ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME dw.dim_user_user_key_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: fact_stock_movement; Type: TABLE; Schema: dw; Owner: -
--

CREATE TABLE dw.fact_stock_movement (
    movement_id integer NOT NULL,
    date_key date NOT NULL,
    moved_at timestamp without time zone NOT NULL,
    product_key integer NOT NULL,
    stock_key integer NOT NULL,
    group_key integer NOT NULL,
    user_key integer,
    movement_type text NOT NULL,
    quantity integer NOT NULL,
    balance_after_source integer,
    purpose character varying,
    loaded_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT fact_stock_movement_movement_type_check CHECK ((movement_type = ANY (ARRAY['IN'::text, 'OUT'::text, 'ADJUSTMENT'::text])))
);


--
-- Name: user_daily_access; Type: TABLE; Schema: dw; Owner: -
--

CREATE TABLE dw.user_daily_access (
    user_id uuid NOT NULL,
    access_date date NOT NULL,
    first_access_at timestamp with time zone NOT NULL
);


--
-- Name: TABLE user_daily_access; Type: COMMENT; Schema: dw; Owner: -
--

COMMENT ON TABLE dw.user_daily_access IS 'Um registro por usuario autenticado por dia; Core API registra apos validar token e sessao.';


--
-- Name: COLUMN user_daily_access.access_date; Type: COMMENT; Schema: dw; Owner: -
--

COMMENT ON COLUMN dw.user_daily_access.access_date IS 'Data local do primeiro acesso autenticado no fuso America/Sao_Paulo.';


--
-- Name: messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.messages (
    id integer NOT NULL,
    conversation_id uuid NOT NULL,
    sender_id uuid NOT NULL,
    message_type public.message_type_enum NOT NULL,
    content text,
    related_shopping_list_product_id integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.requests (
    id integer NOT NULL,
    user_id uuid NOT NULL,
    product_id integer NOT NULL,
    stock_id integer NOT NULL,
    quantity integer NOT NULL,
    description text,
    picture text,
    date date DEFAULT CURRENT_DATE NOT NULL,
    conversation_id uuid,
    message_id integer,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT chk_requests_message_conversation CHECK (((message_id IS NULL) OR (conversation_id IS NOT NULL)))
);


--
-- Name: vw_activity; Type: VIEW; Schema: dw; Owner: -
--

CREATE VIEW dw.vw_activity AS
 SELECT messages.sender_id AS user_id,
    (messages.created_at)::date AS activity_date
   FROM public.messages
  WHERE (messages.sender_id IS NOT NULL)
UNION ALL
 SELECT stock_movements.user_id,
    (stock_movements.date)::date AS activity_date
   FROM public.stock_movements
  WHERE (stock_movements.user_id IS NOT NULL)
UNION ALL
 SELECT requests.user_id,
    requests.date AS activity_date
   FROM public.requests
  WHERE (requests.user_id IS NOT NULL);


--
-- Name: vw_dau; Type: VIEW; Schema: dw; Owner: -
--

CREATE VIEW dw.vw_dau AS
 WITH daily AS (
         SELECT user_daily_access.access_date AS day,
            count(DISTINCT user_daily_access.user_id) AS dau
           FROM dw.user_daily_access
          GROUP BY user_daily_access.access_date
        ), wau AS (
         SELECT d_1.day,
            ( SELECT count(DISTINCT a.user_id) AS count
                   FROM dw.user_daily_access a
                  WHERE ((a.access_date >= (d_1.day - 6)) AND (a.access_date <= d_1.day))) AS wau_7d
           FROM daily d_1
        ), mau AS (
         SELECT d_1.day,
            ( SELECT count(DISTINCT a.user_id) AS count
                   FROM dw.user_daily_access a
                  WHERE ((a.access_date >= (d_1.day - 29)) AND (a.access_date <= d_1.day))) AS mau_30d
           FROM daily d_1
        )
 SELECT d.day,
    d.dau,
    w.wau_7d,
    m.mau_30d,
    round(((100.0 * (d.dau)::numeric) / (NULLIF(m.mau_30d, 0))::numeric), 1) AS dau_mau_pct,
    (d.dau - lag(d.dau) OVER (ORDER BY d.day)) AS dau_change
   FROM ((daily d
     JOIN wau w ON ((w.day = d.day)))
     JOIN mau m ON ((m.day = d.day)));


--
-- Name: VIEW vw_dau; Type: COMMENT; Schema: dw; Owner: -
--

COMMENT ON VIEW dw.vw_dau IS 'DAU/WAU/MAU de usuarios com acesso autenticado a Core API; depende do registro diario da aplicacao.';


--
-- Name: data_catalog; Type: TABLE; Schema: governance; Owner: -
--

CREATE TABLE governance.data_catalog (
    object_schema text NOT NULL,
    object_name text NOT NULL,
    object_type text NOT NULL,
    column_name text NOT NULL,
    ordinal_position integer DEFAULT 0 NOT NULL,
    data_type text,
    description text NOT NULL,
    business_rules text NOT NULL,
    access_level text NOT NULL,
    data_classification text NOT NULL,
    metadata_updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT data_catalog_object_type_check CHECK ((object_type = ANY (ARRAY['BASE TABLE'::text, 'VIEW'::text, 'MATERIALIZED VIEW'::text])))
);


--
-- Name: TABLE data_catalog; Type: COMMENT; Schema: governance; Owner: -
--

COMMENT ON TABLE governance.data_catalog IS 'Catalogo tecnico de objetos e colunas PostgreSQL, com regras estruturais, acesso e classificacao; nao substitui autorizacao da API.';


--
-- Name: advertisements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.advertisements (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    advertiser_id uuid NOT NULL,
    name character varying(120) NOT NULL,
    product_name character varying(160) NOT NULL,
    category character varying(80) NOT NULL,
    description character varying(2000) NOT NULL,
    image_url character varying(2048) NOT NULL,
    destination_url character varying(2048),
    price numeric(12,2),
    start_date date,
    end_date date,
    status character varying(16) DEFAULT 'DRAFT'::character varying NOT NULL,
    impressions bigint DEFAULT 0 NOT NULL,
    clicks bigint DEFAULT 0 NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT advertisements_clicks_check CHECK ((clicks >= 0)),
    CONSTRAINT advertisements_impressions_check CHECK ((impressions >= 0)),
    CONSTRAINT advertisements_price_check CHECK (((price IS NULL) OR (price >= (0)::numeric))),
    CONSTRAINT advertisements_status_check CHECK (((status)::text = ANY (ARRAY[('DRAFT'::character varying)::text, ('ACTIVE'::character varying)::text, ('PAUSED'::character varying)::text, ('ARCHIVED'::character varying)::text]))),
    CONSTRAINT chk_advertisement_dates CHECK (((start_date IS NULL) OR (end_date IS NULL) OR (end_date >= start_date)))
);


--
-- Name: business_expenses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.business_expenses (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    group_id uuid NOT NULL,
    created_by uuid NOT NULL,
    description character varying(255) NOT NULL,
    category character varying(120) NOT NULL,
    amount numeric(12,2) NOT NULL,
    expense_date date NOT NULL,
    supplier character varying(255),
    shopping_list_id uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT business_expenses_amount_check CHECK ((amount > (0)::numeric))
);


--
-- Name: conversation_participants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.conversation_participants (
    conversation_id uuid NOT NULL,
    user_id uuid NOT NULL,
    joined_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    left_at timestamp without time zone,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: conversations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.conversations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    conversation_type public.conversation_type_enum NOT NULL,
    group_id uuid,
    name character varying,
    pair_key character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT chk_conversation_type_group CHECK ((((conversation_type = 'GROUP'::public.conversation_type_enum) AND (group_id IS NOT NULL)) OR ((conversation_type = 'PRIVATE'::public.conversation_type_enum) AND (group_id IS NULL))))
);


--
-- Name: discard; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.discard (
    id integer NOT NULL,
    stock_product_id integer NOT NULL,
    reason text,
    date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    quantity integer DEFAULT 1,
    movement_id integer,
    reason_code character varying(24),
    canceled_at timestamp with time zone,
    CONSTRAINT chk_discard_quantity_positive CHECK (((quantity IS NULL) OR (quantity > 0)))
);


--
-- Name: discard_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.discard_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: discard_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.discard_id_seq OWNED BY public.discard.id;


--
-- Name: dm_recipe_performance; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dm_recipe_performance (
    dm_id bigint NOT NULL,
    recipe_id integer NOT NULL,
    recipe_name character varying NOT NULL,
    total_suggestions integer DEFAULT 0,
    unique_stocks_suggested integer DEFAULT 0,
    avg_suggestion_score numeric(5,2),
    total_ingredients integer,
    avg_available_ingredients numeric(5,2),
    suggestion_trend_7d integer,
    suggestion_trend_30d integer,
    is_domestic_only boolean DEFAULT true,
    is_active boolean DEFAULT true,
    last_suggested_date timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: dm_recipe_performance_dm_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.dm_recipe_performance_dm_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dm_recipe_performance_dm_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.dm_recipe_performance_dm_id_seq OWNED BY public.dm_recipe_performance.dm_id;


--
-- Name: dm_stock_health_daily; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dm_stock_health_daily (
    dm_id bigint NOT NULL,
    snapshot_date date NOT NULL,
    stock_id integer NOT NULL,
    stock_name character varying NOT NULL,
    group_id uuid NOT NULL,
    total_products integer,
    fresh_products integer,
    near_expiration_products integer,
    expired_products integer,
    total_quantity integer,
    daily_inbound integer DEFAULT 0,
    daily_outbound integer DEFAULT 0,
    daily_adjustments integer DEFAULT 0,
    net_movement integer,
    top_category character varying,
    top_category_quantity integer,
    unique_users_accessing integer,
    total_shopping_lists bigint,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: dm_stock_health_daily_dm_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.dm_stock_health_daily_dm_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dm_stock_health_daily_dm_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.dm_stock_health_daily_dm_id_seq OWNED BY public.dm_stock_health_daily.dm_id;


--
-- Name: dm_user_ltv; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dm_user_ltv (
    dm_id bigint NOT NULL,
    user_id uuid NOT NULL,
    user_name character varying NOT NULL,
    account_type character varying,
    total_messages integer DEFAULT 0,
    total_stock_movements integer DEFAULT 0,
    total_requests integer DEFAULT 0,
    total_transactions bigint DEFAULT 0,
    total_spent numeric(12,2) DEFAULT 0,
    subscription_status character varying,
    days_active integer,
    engagement_score numeric(8,2),
    activity_frequency character varying,
    churn_risk boolean DEFAULT false,
    first_activity_date timestamp without time zone,
    last_activity_date timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: dm_user_ltv_dm_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.dm_user_ltv_dm_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dm_user_ltv_dm_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.dm_user_ltv_dm_id_seq OWNED BY public.dm_user_ltv.dm_id;


--
-- Name: flyway_schema_history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.flyway_schema_history (
    installed_rank integer NOT NULL,
    version character varying(50),
    description character varying(200) NOT NULL,
    type character varying(20) NOT NULL,
    script character varying(1000) NOT NULL,
    checksum integer,
    installed_by character varying(100) NOT NULL,
    installed_on timestamp without time zone DEFAULT now() NOT NULL,
    execution_time integer NOT NULL,
    success boolean NOT NULL
);


--
-- Name: food_purchase_lines; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.food_purchase_lines (
    id bigint NOT NULL,
    purchase_id uuid NOT NULL,
    stock_key integer NOT NULL,
    stock_product_id integer,
    product_id integer,
    product_name text NOT NULL,
    category character varying(24) NOT NULL,
    category_group character varying(24) NOT NULL,
    unit_of_measure character varying(24) NOT NULL,
    expire_date date NOT NULL,
    quantity integer NOT NULL,
    unit_price numeric(10,2) NOT NULL,
    CONSTRAINT food_purchase_lines_quantity_check CHECK ((quantity > 0)),
    CONSTRAINT food_purchase_lines_unit_price_check CHECK ((unit_price > (0)::numeric))
);


--
-- Name: food_purchase_lines_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.food_purchase_lines_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: food_purchase_lines_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.food_purchase_lines_id_seq OWNED BY public.food_purchase_lines.id;


--
-- Name: food_purchase_revisions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.food_purchase_revisions (
    id bigint NOT NULL,
    purchase_id uuid NOT NULL,
    previous_version integer NOT NULL,
    previous_state jsonb NOT NULL,
    changed_by uuid NOT NULL,
    changed_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: food_purchase_revisions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.food_purchase_revisions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: food_purchase_revisions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.food_purchase_revisions_id_seq OWNED BY public.food_purchase_revisions.id;


--
-- Name: food_purchases; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.food_purchases (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    group_id uuid NOT NULL,
    purchase_date date NOT NULL,
    source character varying(24) NOT NULL,
    receipt_reference character varying(160),
    idempotency_key character varying(160) NOT NULL,
    request_hash character varying(64) NOT NULL,
    version integer DEFAULT 1 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    CONSTRAINT food_purchases_source_check CHECK (((source)::text = ANY (ARRAY[('USER_CONFIRMED'::character varying)::text, ('RECEIPT_CAPTURED'::character varying)::text])))
);


--
-- Name: group_invitations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.group_invitations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    group_id uuid NOT NULL,
    email character varying(255) NOT NULL,
    name character varying(255),
    member_role character varying(16) NOT NULL,
    token_hash character varying(64) NOT NULL,
    expires_at timestamp without time zone NOT NULL,
    accepted_at timestamp without time zone,
    revoked_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT group_invitations_member_role_check CHECK (((member_role)::text = ANY (ARRAY[('EDITOR'::character varying)::text, ('VIEWER'::character varying)::text])))
);


--
-- Name: message_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.message_attachments (
    id integer NOT NULL,
    message_id integer NOT NULL,
    file_url text NOT NULL,
    file_name character varying,
    mime_type character varying NOT NULL,
    file_size integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: message_attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.message_attachments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: message_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.message_attachments_id_seq OWNED BY public.message_attachments.id;


--
-- Name: message_reactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.message_reactions (
    id integer NOT NULL,
    message_id integer NOT NULL,
    user_id uuid NOT NULL,
    emoji character varying(16) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: message_reactions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.message_reactions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: message_reactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.message_reactions_id_seq OWNED BY public.message_reactions.id;


--
-- Name: message_reads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.message_reads (
    message_id integer NOT NULL,
    conversation_id uuid NOT NULL,
    user_id uuid NOT NULL,
    read_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.messages_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.messages_id_seq OWNED BY public.messages.id;


--
-- Name: money_allocations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.money_allocations (
    id bigint NOT NULL,
    exit_id bigint NOT NULL,
    supply_id bigint,
    quantity integer NOT NULL,
    amount numeric(20,2),
    category_group character varying(24),
    CONSTRAINT money_allocations_quantity_check CHECK ((quantity > 0))
);


--
-- Name: money_allocations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.money_allocations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: money_allocations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.money_allocations_id_seq OWNED BY public.money_allocations.id;


--
-- Name: money_exits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.money_exits (
    id bigint NOT NULL,
    group_id uuid NOT NULL,
    stock_key integer NOT NULL,
    stock_product_id integer,
    product_name text NOT NULL,
    category character varying(24) NOT NULL,
    unit_of_measure character varying(24) NOT NULL,
    expire_date date NOT NULL,
    occurred_at timestamp with time zone NOT NULL,
    local_date date NOT NULL,
    quantity integer NOT NULL,
    kind character varying(24) NOT NULL,
    reason_code character varying(24),
    movement_id integer,
    discard_id integer,
    canceled_at timestamp with time zone,
    CONSTRAINT money_exits_kind_check CHECK (((kind)::text = ANY (ARRAY[('CONSUMED'::character varying)::text, ('DISCARDED'::character varying)::text, ('OTHER'::character varying)::text]))),
    CONSTRAINT money_exits_quantity_check CHECK ((quantity > 0))
);


--
-- Name: money_exits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.money_exits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: money_exits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.money_exits_id_seq OWNED BY public.money_exits.id;


--
-- Name: money_supplies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.money_supplies (
    id bigint NOT NULL,
    stock_key integer NOT NULL,
    stock_product_id integer,
    purchase_line_id bigint,
    available_on date NOT NULL,
    quantity integer NOT NULL,
    unknown_cost boolean NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT money_supplies_quantity_check CHECK ((quantity > 0))
);


--
-- Name: money_supplies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.money_supplies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: money_supplies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.money_supplies_id_seq OWNED BY public.money_supplies.id;


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notifications (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    recipient_user_id uuid NOT NULL,
    group_id uuid,
    type public.notification_type_enum NOT NULL,
    title character varying NOT NULL,
    body text NOT NULL,
    reference_id character varying(120),
    deduplication_key character varying(220),
    read_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted_at timestamp without time zone
);


--
-- Name: password_reset_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.password_reset_tokens (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    token_hash character varying(64) NOT NULL,
    expires_at timestamp without time zone NOT NULL,
    consumed_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: plans_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.plans_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: plans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.plans_id_seq OWNED BY public.plans.id;


--
-- Name: products_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.products_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: products_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.products_id_seq OWNED BY public.products.id;


--
-- Name: receipt_draft_lines; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.receipt_draft_lines (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    receipt_id uuid NOT NULL,
    description character varying(500) NOT NULL,
    quantity integer NOT NULL,
    unit character varying(30),
    unit_price numeric(12,2),
    total_price numeric(12,2),
    confidence double precision,
    evidence character varying(1000),
    matched_product_id integer,
    expire_date date,
    normalized_product_name character varying(255),
    brand character varying(120),
    category character varying(30),
    storage_place character varying(30),
    unit_of_measure character varying(30),
    CONSTRAINT receipt_draft_lines_confidence_check CHECK (((confidence IS NULL) OR ((confidence >= (0)::double precision) AND (confidence <= (1)::double precision)))),
    CONSTRAINT receipt_draft_lines_quantity_check CHECK ((quantity > 0))
);


--
-- Name: receipt_drafts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.receipt_drafts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    stock_id integer NOT NULL,
    created_by uuid NOT NULL,
    status character varying(30) NOT NULL,
    access_key character varying(44),
    issuer_name character varying(255),
    issued_at timestamp with time zone,
    total_amount numeric(12,2),
    warnings jsonb DEFAULT '[]'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    imported_at timestamp with time zone
);


--
-- Name: recipe_favorites; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.recipe_favorites (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    recipe_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: recipe_ingredients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.recipe_ingredients (
    id integer NOT NULL,
    recipe_id integer NOT NULL,
    product_id integer NOT NULL,
    quantity numeric,
    unit character varying,
    required boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: recipe_ingredients_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.recipe_ingredients_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: recipe_ingredients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.recipe_ingredients_id_seq OWNED BY public.recipe_ingredients.id;


--
-- Name: recipe_suggestions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.recipe_suggestions (
    id integer NOT NULL,
    recipe_id integer NOT NULL,
    stock_id integer NOT NULL,
    matched_ingredients integer DEFAULT 0 NOT NULL,
    missing_ingredients integer DEFAULT 0 NOT NULL,
    nearest_expire_date date,
    score numeric,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: recipe_suggestions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.recipe_suggestions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: recipe_suggestions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.recipe_suggestions_id_seq OWNED BY public.recipe_suggestions.id;


--
-- Name: recipes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.recipes (
    id integer NOT NULL,
    name character varying NOT NULL,
    description text,
    instructions text,
    domestic_only boolean DEFAULT true NOT NULL,
    active boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: recipes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.recipes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: recipes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.recipes_id_seq OWNED BY public.recipes.id;


--
-- Name: requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.requests_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.requests_id_seq OWNED BY public.requests.id;


--
-- Name: shopping_list_products; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.shopping_list_products (
    id integer NOT NULL,
    list_id uuid NOT NULL,
    product_id integer NOT NULL,
    status public.product_list_status_enum DEFAULT 'PENDING'::public.product_list_status_enum NOT NULL,
    quantity integer DEFAULT 1 NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    purchased_unit_price numeric(10,2),
    notes character varying(255),
    added_by character varying(50) DEFAULT 'Adicionado por você'::character varying NOT NULL,
    CONSTRAINT shopping_list_products_purchased_unit_price_check CHECK ((purchased_unit_price >= (0)::numeric))
);


--
-- Name: shopping_list_products_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.shopping_list_products_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: shopping_list_products_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.shopping_list_products_id_seq OWNED BY public.shopping_list_products.id;


--
-- Name: shopping_lists; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.shopping_lists (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    date date DEFAULT CURRENT_DATE NOT NULL,
    stock_id integer NOT NULL,
    status public.list_status_enum NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    name character varying(255) DEFAULT 'Lista de compras'::character varying NOT NULL,
    supplier character varying(255),
    completed_at timestamp without time zone,
    total numeric(12,2),
    added_by character varying(50) DEFAULT 'Adicionado por você'::character varying NOT NULL,
    CONSTRAINT shopping_lists_total_check CHECK ((total >= (0)::numeric))
);


--
-- Name: stock_movements_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.stock_movements_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: stock_movements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.stock_movements_id_seq OWNED BY public.stock_movements.id;


--
-- Name: stock_products_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.stock_products_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: stock_products_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.stock_products_id_seq OWNED BY public.stock_products.id;


--
-- Name: stocks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.stocks_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: stocks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.stocks_id_seq OWNED BY public.stocks.id;


--
-- Name: subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.subscriptions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    plan_id integer NOT NULL,
    status public.subscription_status_enum DEFAULT 'TRIAL'::public.subscription_status_enum NOT NULL,
    started_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    current_period_start timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    current_period_end timestamp without time zone,
    canceled_at timestamp without time zone,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted_at timestamp without time zone
);


--
-- Name: transaction_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.transaction_events (
    id integer NOT NULL,
    transaction_id uuid NOT NULL,
    status public.transaction_status_enum NOT NULL,
    message text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: transaction_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.transaction_events_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: transaction_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.transaction_events_id_seq OWNED BY public.transaction_events.id;


--
-- Name: user_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_groups (
    id integer NOT NULL,
    user_id uuid NOT NULL,
    group_id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    member_role character varying(16) DEFAULT 'EDITOR'::character varying NOT NULL,
    CONSTRAINT user_groups_member_role_check CHECK (((member_role)::text = ANY (ARRAY[('EDITOR'::character varying)::text, ('VIEWER'::character varying)::text])))
);


--
-- Name: user_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_groups_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_groups_id_seq OWNED BY public.user_groups.id;


--
-- Name: user_preferences; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_preferences (
    user_id uuid NOT NULL,
    expiration_alerts_enabled boolean DEFAULT true NOT NULL,
    low_stock_alerts_enabled boolean DEFAULT true NOT NULL,
    shopping_reminders_enabled boolean DEFAULT true NOT NULL,
    weekly_summary_enabled boolean DEFAULT false NOT NULL,
    theme character varying(16) DEFAULT 'SYSTEM'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT user_preferences_theme_check CHECK (((theme)::text = ANY (ARRAY[('LIGHT'::character varying)::text, ('DARK'::character varying)::text, ('SYSTEM'::character varying)::text])))
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying NOT NULL,
    birth_date date,
    account_type public.account_type_enum NOT NULL,
    email character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted_at timestamp without time zone,
    role public.user_role_enum DEFAULT 'USER'::public.user_role_enum NOT NULL,
    hash_password character varying,
    senha character varying(100) DEFAULT 'VAZIO'::character varying,
    google_id character varying(255),
    token_version integer DEFAULT 0 NOT NULL,
    profile_picture_url character varying(2048)
);


--
-- Name: vw_dm_group_summary; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_dm_group_summary AS
 WITH stock_agg AS (
         SELECT s.group_id,
            count(DISTINCT s.id) AS stocks,
            count(sp.id) FILTER (WHERE ((sp.deleted_at IS NULL) AND (sp.quantity > 0))) AS active_items,
            count(sp.id) FILTER (WHERE ((sp.deleted_at IS NULL) AND (sp.quantity > 0) AND ((sp.expire_date >= CURRENT_DATE) AND (sp.expire_date <= (CURRENT_DATE + 7))))) AS expiring_7d,
            count(sp.id) FILTER (WHERE ((sp.deleted_at IS NULL) AND (sp.quantity > 0) AND (sp.product_status = 'EXPIRED'::public.product_status_enum))) AS expired_items
           FROM (public.stocks s
             LEFT JOIN public.stock_products sp ON ((sp.stock_id = s.id)))
          WHERE (s.deleted_at IS NULL)
          GROUP BY s.group_id
        ), members AS (
         SELECT user_groups.group_id,
            count(*) AS members
           FROM public.user_groups
          GROUP BY user_groups.group_id
        )
 SELECT g.id AS group_id,
    g.name AS group_name,
    (g.created_at)::date AS created_date,
    COALESCE(m.members, (0)::bigint) AS members,
    COALESCE(sa.stocks, (0)::bigint) AS stocks,
    COALESCE(sa.active_items, (0)::bigint) AS active_items,
    COALESCE(sa.expiring_7d, (0)::bigint) AS expiring_7d,
    COALESCE(sa.expired_items, (0)::bigint) AS expired_items
   FROM ((public.groups g
     LEFT JOIN stock_agg sa ON ((sa.group_id = g.id)))
     LEFT JOIN members m ON ((m.group_id = g.id)))
  WHERE (g.deleted_at IS NULL);


--
-- Name: vw_dm_stock_health; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_dm_stock_health AS
 WITH stock_items AS (
         SELECT sp.stock_id,
            count(*) FILTER (WHERE ((sp.deleted_at IS NULL) AND (sp.quantity > 0))) AS active_items,
            COALESCE(sum(sp.quantity) FILTER (WHERE (sp.deleted_at IS NULL)), (0)::bigint) AS total_qty,
            count(*) FILTER (WHERE ((sp.deleted_at IS NULL) AND (sp.quantity > 0) AND (sp.product_status = 'EXPIRED'::public.product_status_enum))) AS expired_items,
            count(*) FILTER (WHERE ((sp.deleted_at IS NULL) AND (sp.quantity > 0) AND ((sp.expire_date >= CURRENT_DATE) AND (sp.expire_date <= (CURRENT_DATE + 7))))) AS expiring_7d,
            count(*) FILTER (WHERE ((sp.deleted_at IS NULL) AND (sp.minimal_quantity IS NOT NULL) AND (sp.quantity < sp.minimal_quantity))) AS below_minimal
           FROM public.stock_products sp
          GROUP BY sp.stock_id
        ), stock_moves AS (
         SELECT sp.stock_id,
            COALESCE(sum(sm_1.quantity) FILTER (WHERE ((sm_1.movement_type = 'IN'::public.movement_type_enum) AND (sm_1.date >= (CURRENT_DATE - 30)))), (0)::bigint) AS in_30d,
            COALESCE(sum(sm_1.quantity) FILTER (WHERE ((sm_1.movement_type = 'OUT'::public.movement_type_enum) AND (sm_1.date >= (CURRENT_DATE - 30)))), (0)::bigint) AS out_30d
           FROM (public.stock_movements sm_1
             JOIN public.stock_products sp ON ((sp.id = sm_1.stock_product_id)))
          GROUP BY sp.stock_id
        )
 SELECT s.id AS stock_id,
    s.name AS stock_name,
    g.id AS group_id,
    g.name AS group_name,
    COALESCE(si.active_items, (0)::bigint) AS active_items,
    COALESCE(si.total_qty, (0)::bigint) AS total_qty,
    COALESCE(si.expired_items, (0)::bigint) AS expired_items,
    COALESCE(si.expiring_7d, (0)::bigint) AS expiring_7d,
    COALESCE(si.below_minimal, (0)::bigint) AS below_minimal,
    COALESCE(sm.in_30d, (0)::bigint) AS in_30d,
    COALESCE(sm.out_30d, (0)::bigint) AS out_30d
   FROM (((public.stocks s
     JOIN public.groups g ON ((g.id = s.group_id)))
     LEFT JOIN stock_items si ON ((si.stock_id = s.id)))
     LEFT JOIN stock_moves sm ON ((sm.stock_id = s.id)))
  WHERE (s.deleted_at IS NULL);


--
-- Name: vw_dm_user_summary; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_dm_user_summary AS
 WITH msg AS (
         SELECT messages.sender_id AS user_id,
            count(*) AS messages,
            max(messages.created_at) AS last_msg_at
           FROM public.messages
          GROUP BY messages.sender_id
        ), mov AS (
         SELECT stock_movements.user_id,
            count(*) AS movements,
            max(stock_movements.date) AS last_mov_at
           FROM public.stock_movements
          GROUP BY stock_movements.user_id
        ), req AS (
         SELECT requests.user_id,
            count(*) AS requests
           FROM public.requests
          GROUP BY requests.user_id
        ), subs AS (
         SELECT DISTINCT ON (subscriptions.user_id) subscriptions.user_id,
            subscriptions.status
           FROM public.subscriptions
          WHERE (subscriptions.deleted_at IS NULL)
          ORDER BY subscriptions.user_id, subscriptions.started_at DESC
        )
 SELECT u.id AS user_id,
    u.name AS user_name,
    u.account_type,
    (u.created_at)::date AS signup_date,
    COALESCE(msg.messages, (0)::bigint) AS messages,
    COALESCE(mov.movements, (0)::bigint) AS movements,
    COALESCE(req.requests, (0)::bigint) AS requests,
    (GREATEST(msg.last_msg_at, mov.last_mov_at))::date AS last_activity_date,
    COALESCE((subs.status)::text, 'NONE'::text) AS subscription_status,
    ((COALESCE(msg.messages, (0)::bigint) + (2 * COALESCE(mov.movements, (0)::bigint))) + (3 * COALESCE(req.requests, (0)::bigint))) AS engagement_score
   FROM ((((public.users u
     LEFT JOIN msg ON ((msg.user_id = u.id)))
     LEFT JOIN mov ON ((mov.user_id = u.id)))
     LEFT JOIN req ON ((req.user_id = u.id)))
     LEFT JOIN subs ON ((subs.user_id = u.id)))
  WHERE (u.deleted_at IS NULL);


--
-- Name: vw_top_ingredients_analytics; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_top_ingredients_analytics AS
 WITH ingredient_suggestions AS (
         SELECT ri.product_id,
            p.name,
            p.category,
            p.unit_price,
            count(DISTINCT rs.id) AS suggestion_count,
            count(DISTINCT rs.stock_id) AS unique_stocks,
            round(avg(rs.score), 2) AS avg_suggestion_score,
            max(rs.updated_at) AS last_suggested_date
           FROM ((public.recipe_ingredients ri
             JOIN public.products p ON ((ri.product_id = p.id)))
             LEFT JOIN public.recipe_suggestions rs ON ((rs.recipe_id = ri.recipe_id)))
          WHERE (ri.required = true)
          GROUP BY ri.product_id, p.name, p.category, p.unit_price
        )
 SELECT row_number() OVER (ORDER BY suggestion_count DESC) AS popularity_rank,
    rank() OVER (PARTITION BY category ORDER BY suggestion_count DESC) AS category_rank,
    product_id,
    name,
    category,
    suggestion_count,
    unique_stocks,
    avg_suggestion_score,
    unit_price,
    round((((suggestion_count)::numeric / sum(suggestion_count) OVER ()) * (100)::numeric), 2) AS percentage_of_total_suggestions,
    first_value(name) OVER (PARTITION BY category ORDER BY suggestion_count DESC) AS top_ingredient_in_category,
    last_suggested_date,
    CURRENT_TIMESTAMP AS view_updated_at
   FROM ingredient_suggestions;


--
-- Name: vw_user_engagement_analytics; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_user_engagement_analytics AS
 WITH user_activity AS (
         SELECT u_1.id,
            u_1.name,
            u_1.account_type,
            u_1.created_at AS user_created_at,
            count(DISTINCT m.id) AS total_messages,
            count(DISTINCT sm.id) AS total_stock_movements,
            count(DISTINCT r.id) AS total_requests,
            count(DISTINCT
                CASE
                    WHEN (m.created_at >= (now() - '30 days'::interval)) THEN m.id
                    ELSE NULL::integer
                END) AS messages_last_30d,
            count(DISTINCT
                CASE
                    WHEN (sm.date >= (now() - '30 days'::interval)) THEN sm.id
                    ELSE NULL::integer
                END) AS movements_last_30d,
            max(m.created_at) AS last_message_date,
            max(sm.date) AS last_movement_date,
            GREATEST(max(m.created_at), max(sm.date), (max(r.date))::timestamp without time zone) AS overall_last_activity
           FROM (((public.users u_1
             LEFT JOIN public.messages m ON ((u_1.id = m.sender_id)))
             LEFT JOIN public.stock_movements sm ON ((u_1.id = sm.user_id)))
             LEFT JOIN public.requests r ON ((u_1.id = r.user_id)))
          GROUP BY u_1.id, u_1.name, u_1.account_type, u_1.created_at
        )
 SELECT id,
    name,
    account_type,
    user_created_at,
    total_messages,
    total_stock_movements,
    total_requests,
    messages_last_30d,
    movements_last_30d,
    ((((total_messages)::numeric * 0.4) + ((total_stock_movements)::numeric * 0.35)) + ((total_requests)::numeric * 0.25)) AS engagement_score,
    rank() OVER (ORDER BY total_messages DESC) AS message_rank,
    dense_rank() OVER (PARTITION BY account_type ORDER BY total_stock_movements DESC) AS movement_rank_by_type,
    row_number() OVER (ORDER BY overall_last_activity DESC NULLS LAST) AS activity_recency_rank,
    overall_last_activity,
    (CURRENT_DATE - date(overall_last_activity)) AS days_since_activity
   FROM user_activity u
  WHERE ((total_messages > 0) OR (total_stock_movements > 0) OR (total_requests > 0));


--
-- Name: discard id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discard ALTER COLUMN id SET DEFAULT nextval('public.discard_id_seq'::regclass);


--
-- Name: dm_recipe_performance dm_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dm_recipe_performance ALTER COLUMN dm_id SET DEFAULT nextval('public.dm_recipe_performance_dm_id_seq'::regclass);


--
-- Name: dm_stock_health_daily dm_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dm_stock_health_daily ALTER COLUMN dm_id SET DEFAULT nextval('public.dm_stock_health_daily_dm_id_seq'::regclass);


--
-- Name: dm_user_ltv dm_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dm_user_ltv ALTER COLUMN dm_id SET DEFAULT nextval('public.dm_user_ltv_dm_id_seq'::regclass);


--
-- Name: food_purchase_lines id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.food_purchase_lines ALTER COLUMN id SET DEFAULT nextval('public.food_purchase_lines_id_seq'::regclass);


--
-- Name: food_purchase_revisions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.food_purchase_revisions ALTER COLUMN id SET DEFAULT nextval('public.food_purchase_revisions_id_seq'::regclass);


--
-- Name: message_attachments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message_attachments ALTER COLUMN id SET DEFAULT nextval('public.message_attachments_id_seq'::regclass);


--
-- Name: message_reactions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message_reactions ALTER COLUMN id SET DEFAULT nextval('public.message_reactions_id_seq'::regclass);


--
-- Name: messages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages ALTER COLUMN id SET DEFAULT nextval('public.messages_id_seq'::regclass);


--
-- Name: money_allocations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.money_allocations ALTER COLUMN id SET DEFAULT nextval('public.money_allocations_id_seq'::regclass);


--
-- Name: money_exits id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.money_exits ALTER COLUMN id SET DEFAULT nextval('public.money_exits_id_seq'::regclass);


--
-- Name: money_supplies id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.money_supplies ALTER COLUMN id SET DEFAULT nextval('public.money_supplies_id_seq'::regclass);


--
-- Name: plans id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plans ALTER COLUMN id SET DEFAULT nextval('public.plans_id_seq'::regclass);


--
-- Name: products id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products ALTER COLUMN id SET DEFAULT nextval('public.products_id_seq'::regclass);


--
-- Name: recipe_ingredients id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recipe_ingredients ALTER COLUMN id SET DEFAULT nextval('public.recipe_ingredients_id_seq'::regclass);


--
-- Name: recipe_suggestions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recipe_suggestions ALTER COLUMN id SET DEFAULT nextval('public.recipe_suggestions_id_seq'::regclass);


--
-- Name: recipes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recipes ALTER COLUMN id SET DEFAULT nextval('public.recipes_id_seq'::regclass);


--
-- Name: requests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requests ALTER COLUMN id SET DEFAULT nextval('public.requests_id_seq'::regclass);


--
-- Name: shopping_list_products id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shopping_list_products ALTER COLUMN id SET DEFAULT nextval('public.shopping_list_products_id_seq'::regclass);


--
-- Name: stock_movements id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stock_movements ALTER COLUMN id SET DEFAULT nextval('public.stock_movements_id_seq'::regclass);


--
-- Name: stock_products id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stock_products ALTER COLUMN id SET DEFAULT nextval('public.stock_products_id_seq'::regclass);


--
-- Name: stocks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stocks ALTER COLUMN id SET DEFAULT nextval('public.stocks_id_seq'::regclass);


--
-- Name: transaction_events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_events ALTER COLUMN id SET DEFAULT nextval('public.transaction_events_id_seq'::regclass);


--
-- Name: user_groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_groups ALTER COLUMN id SET DEFAULT nextval('public.user_groups_id_seq'::regclass);


--
-- Name: row_change_log row_change_log_pkey; Type: CONSTRAINT; Schema: audit; Owner: -
--

ALTER TABLE ONLY audit.row_change_log
    ADD CONSTRAINT row_change_log_pkey PRIMARY KEY (id);


--
-- Name: dim_date dim_date_pkey; Type: CONSTRAINT; Schema: dw; Owner: -
--

ALTER TABLE ONLY dw.dim_date
    ADD CONSTRAINT dim_date_pkey PRIMARY KEY (date_key);


--
-- Name: dim_group dim_group_group_id_key; Type: CONSTRAINT; Schema: dw; Owner: -
--

ALTER TABLE ONLY dw.dim_group
    ADD CONSTRAINT dim_group_group_id_key UNIQUE (group_id);


--
-- Name: dim_group dim_group_pkey; Type: CONSTRAINT; Schema: dw; Owner: -
--

ALTER TABLE ONLY dw.dim_group
    ADD CONSTRAINT dim_group_pkey PRIMARY KEY (group_key);


--
-- Name: dim_product dim_product_pkey; Type: CONSTRAINT; Schema: dw; Owner: -
--

ALTER TABLE ONLY dw.dim_product
    ADD CONSTRAINT dim_product_pkey PRIMARY KEY (product_key);


--
-- Name: dim_product dim_product_product_id_key; Type: CONSTRAINT; Schema: dw; Owner: -
--

ALTER TABLE ONLY dw.dim_product
    ADD CONSTRAINT dim_product_product_id_key UNIQUE (product_id);


--
-- Name: dim_stock dim_stock_pkey; Type: CONSTRAINT; Schema: dw; Owner: -
--

ALTER TABLE ONLY dw.dim_stock
    ADD CONSTRAINT dim_stock_pkey PRIMARY KEY (stock_key);


--
-- Name: dim_stock dim_stock_stock_id_key; Type: CONSTRAINT; Schema: dw; Owner: -
--

ALTER TABLE ONLY dw.dim_stock
    ADD CONSTRAINT dim_stock_stock_id_key UNIQUE (stock_id);


--
-- Name: dim_user dim_user_pkey; Type: CONSTRAINT; Schema: dw; Owner: -
--

ALTER TABLE ONLY dw.dim_user
    ADD CONSTRAINT dim_user_pkey PRIMARY KEY (user_key);


--
-- Name: dim_user dim_user_user_id_key; Type: CONSTRAINT; Schema: dw; Owner: -
--

ALTER TABLE ONLY dw.dim_user
    ADD CONSTRAINT dim_user_user_id_key UNIQUE (user_id);


--
-- Name: fact_stock_movement fact_stock_movement_pkey; Type: CONSTRAINT; Schema: dw; Owner: -
--

ALTER TABLE ONLY dw.fact_stock_movement
    ADD CONSTRAINT fact_stock_movement_pkey PRIMARY KEY (movement_id);


--
-- Name: user_daily_access user_daily_access_pk; Type: CONSTRAINT; Schema: dw; Owner: -
--

ALTER TABLE ONLY dw.user_daily_access
    ADD CONSTRAINT user_daily_access_pk PRIMARY KEY (user_id, access_date);


--
-- Name: data_catalog data_catalog_pk; Type: CONSTRAINT; Schema: governance; Owner: -
--

ALTER TABLE ONLY governance.data_catalog
    ADD CONSTRAINT data_catalog_pk PRIMARY KEY (object_schema, object_name, column_name);


--
-- Name: advertisements advertisements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.advertisements
    ADD CONSTRAINT advertisements_pkey PRIMARY KEY (id);


--
-- Name: business_expenses business_expenses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.business_expenses
    ADD CONSTRAINT business_expenses_pkey PRIMARY KEY (id);


--
-- Name: business_expenses business_expenses_shopping_list_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.business_expenses
    ADD CONSTRAINT business_expenses_shopping_list_id_key UNIQUE (shopping_list_id);


--
-- Name: shopping_list_products chk_shopping_quantity; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.shopping_list_products
    ADD CONSTRAINT chk_shopping_quantity CHECK ((quantity > 0)) NOT VALID;


--
-- Name: stock_products chk_stock_products_quantity; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.stock_products
    ADD CONSTRAINT chk_stock_products_quantity CHECK ((quantity >= 0)) NOT VALID;


--
-- Name: conversation_participants conversation_participants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversation_participants
    ADD CONSTRAINT conversation_participants_pkey PRIMARY KEY (conversation_id, user_id);


--
-- Name: conversations conversations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT conversations_pkey PRIMARY KEY (id);


--
-- Name: discard discard_movement_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discard
    ADD CONSTRAINT discard_movement_id_key UNIQUE (movement_id);


--
-- Name: discard discard_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discard
    ADD CONSTRAINT discard_pkey PRIMARY KEY (id);


--
-- Name: dm_recipe_performance dm_recipe_performance_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dm_recipe_performance
    ADD CONSTRAINT dm_recipe_performance_pkey PRIMARY KEY (dm_id);


--
-- Name: dm_stock_health_daily dm_stock_health_daily_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dm_stock_health_daily
    ADD CONSTRAINT dm_stock_health_daily_pkey PRIMARY KEY (dm_id);


--
-- Name: dm_user_ltv dm_user_ltv_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dm_user_ltv
    ADD CONSTRAINT dm_user_ltv_pkey PRIMARY KEY (dm_id);


--
-- Name: dm_user_ltv dm_user_ltv_user_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dm_user_ltv
    ADD CONSTRAINT dm_user_ltv_user_id_key UNIQUE (user_id);


--
-- Name: flyway_schema_history flyway_schema_history_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flyway_schema_history
    ADD CONSTRAINT flyway_schema_history_pk PRIMARY KEY (installed_rank);


--
-- Name: food_purchase_lines food_purchase_lines_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.food_purchase_lines
    ADD CONSTRAINT food_purchase_lines_pkey PRIMARY KEY (id);


--
-- Name: food_purchase_revisions food_purchase_revisions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.food_purchase_revisions
    ADD CONSTRAINT food_purchase_revisions_pkey PRIMARY KEY (id);


--
-- Name: food_purchases food_purchases_group_id_idempotency_key_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.food_purchases
    ADD CONSTRAINT food_purchases_group_id_idempotency_key_key UNIQUE (group_id, idempotency_key);


--
-- Name: food_purchases food_purchases_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.food_purchases
    ADD CONSTRAINT food_purchases_pkey PRIMARY KEY (id);


--
-- Name: group_invitations group_invitations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_invitations
    ADD CONSTRAINT group_invitations_pkey PRIMARY KEY (id);


--
-- Name: group_invitations group_invitations_token_hash_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_invitations
    ADD CONSTRAINT group_invitations_token_hash_key UNIQUE (token_hash);


--
-- Name: groups groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups
    ADD CONSTRAINT groups_pkey PRIMARY KEY (id);


--
-- Name: message_attachments message_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message_attachments
    ADD CONSTRAINT message_attachments_pkey PRIMARY KEY (id);


--
-- Name: message_reactions message_reactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message_reactions
    ADD CONSTRAINT message_reactions_pkey PRIMARY KEY (id);


--
-- Name: message_reads message_reads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message_reads
    ADD CONSTRAINT message_reads_pkey PRIMARY KEY (message_id, user_id);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- Name: money_allocations money_allocations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.money_allocations
    ADD CONSTRAINT money_allocations_pkey PRIMARY KEY (id);


--
-- Name: money_exits money_exits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.money_exits
    ADD CONSTRAINT money_exits_pkey PRIMARY KEY (id);


--
-- Name: money_supplies money_supplies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.money_supplies
    ADD CONSTRAINT money_supplies_pkey PRIMARY KEY (id);


--
-- Name: money_supplies money_supplies_purchase_line_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.money_supplies
    ADD CONSTRAINT money_supplies_purchase_line_id_key UNIQUE (purchase_line_id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: password_reset_tokens password_reset_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.password_reset_tokens
    ADD CONSTRAINT password_reset_tokens_pkey PRIMARY KEY (id);


--
-- Name: password_reset_tokens password_reset_tokens_token_hash_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.password_reset_tokens
    ADD CONSTRAINT password_reset_tokens_token_hash_key UNIQUE (token_hash);


--
-- Name: plans plans_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plans
    ADD CONSTRAINT plans_pkey PRIMARY KEY (id);


--
-- Name: products products_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_pkey PRIMARY KEY (id);


--
-- Name: receipt_draft_lines receipt_draft_lines_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.receipt_draft_lines
    ADD CONSTRAINT receipt_draft_lines_pkey PRIMARY KEY (id);


--
-- Name: receipt_drafts receipt_drafts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.receipt_drafts
    ADD CONSTRAINT receipt_drafts_pkey PRIMARY KEY (id);


--
-- Name: receipt_drafts receipt_drafts_stock_id_access_key_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.receipt_drafts
    ADD CONSTRAINT receipt_drafts_stock_id_access_key_key UNIQUE (stock_id, access_key);


--
-- Name: recipe_favorites recipe_favorites_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recipe_favorites
    ADD CONSTRAINT recipe_favorites_pkey PRIMARY KEY (id);


--
-- Name: recipe_favorites recipe_favorites_user_id_recipe_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recipe_favorites
    ADD CONSTRAINT recipe_favorites_user_id_recipe_id_key UNIQUE (user_id, recipe_id);


--
-- Name: recipe_ingredients recipe_ingredients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recipe_ingredients
    ADD CONSTRAINT recipe_ingredients_pkey PRIMARY KEY (id);


--
-- Name: recipe_suggestions recipe_suggestions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recipe_suggestions
    ADD CONSTRAINT recipe_suggestions_pkey PRIMARY KEY (id);


--
-- Name: recipes recipes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recipes
    ADD CONSTRAINT recipes_pkey PRIMARY KEY (id);


--
-- Name: requests requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requests
    ADD CONSTRAINT requests_pkey PRIMARY KEY (id);


--
-- Name: shopping_list_products shopping_list_products_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shopping_list_products
    ADD CONSTRAINT shopping_list_products_pkey PRIMARY KEY (id);


--
-- Name: shopping_lists shopping_lists_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shopping_lists
    ADD CONSTRAINT shopping_lists_pkey PRIMARY KEY (id);


--
-- Name: stock_movements stock_movements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stock_movements
    ADD CONSTRAINT stock_movements_pkey PRIMARY KEY (id);


--
-- Name: stock_products stock_products_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stock_products
    ADD CONSTRAINT stock_products_pkey PRIMARY KEY (id);


--
-- Name: stocks stocks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stocks
    ADD CONSTRAINT stocks_pkey PRIMARY KEY (id);


--
-- Name: subscriptions subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_pkey PRIMARY KEY (id);


--
-- Name: transaction_events transaction_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_events
    ADD CONSTRAINT transaction_events_pkey PRIMARY KEY (id);


--
-- Name: transactions transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (id);


--
-- Name: message_reactions uq_message_reactions_message_user_emoji; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message_reactions
    ADD CONSTRAINT uq_message_reactions_message_user_emoji UNIQUE (message_id, user_id, emoji);


--
-- Name: messages uq_messages_id_conversation; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT uq_messages_id_conversation UNIQUE (id, conversation_id);


--
-- Name: conversations uq_pair; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT uq_pair UNIQUE (pair_key);


--
-- Name: plans uq_plans_plan_code; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plans
    ADD CONSTRAINT uq_plans_plan_code UNIQUE (plan_code);


--
-- Name: recipe_ingredients uq_recipe_ingredients_recipe_product; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recipe_ingredients
    ADD CONSTRAINT uq_recipe_ingredients_recipe_product UNIQUE (recipe_id, product_id);


--
-- Name: shopping_list_products uq_shopping_list_products_list_product; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shopping_list_products
    ADD CONSTRAINT uq_shopping_list_products_list_product UNIQUE (list_id, product_id);


--
-- Name: transactions uq_transactions_idempotency_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT uq_transactions_idempotency_key UNIQUE (idempotency_key);


--
-- Name: user_groups uq_user_groups_user_group; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_groups
    ADD CONSTRAINT uq_user_groups_user_group UNIQUE (user_id, group_id);


--
-- Name: user_groups user_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_groups
    ADD CONSTRAINT user_groups_pkey PRIMARY KEY (id);


--
-- Name: user_preferences user_preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_preferences
    ADD CONSTRAINT user_preferences_pkey PRIMARY KEY (user_id);


--
-- Name: users users_google_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_google_id_key UNIQUE (google_id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: ix_fact_mov_date; Type: INDEX; Schema: dw; Owner: -
--

CREATE INDEX ix_fact_mov_date ON dw.fact_stock_movement USING btree (date_key);


--
-- Name: ix_fact_mov_product; Type: INDEX; Schema: dw; Owner: -
--

CREATE INDEX ix_fact_mov_product ON dw.fact_stock_movement USING btree (product_key);


--
-- Name: ix_fact_mov_stock; Type: INDEX; Schema: dw; Owner: -
--

CREATE INDEX ix_fact_mov_stock ON dw.fact_stock_movement USING btree (stock_key, date_key);


--
-- Name: ix_user_daily_access_date_user; Type: INDEX; Schema: dw; Owner: -
--

CREATE INDEX ix_user_daily_access_date_user ON dw.user_daily_access USING btree (access_date, user_id);


--
-- Name: flyway_schema_history_s_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX flyway_schema_history_s_idx ON public.flyway_schema_history USING btree (success);


--
-- Name: idx_advertisements_active_dates; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_advertisements_active_dates ON public.advertisements USING btree (status, start_date, end_date) WHERE ((status)::text = 'ACTIVE'::text);


--
-- Name: idx_advertisements_owner_updated; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_advertisements_owner_updated ON public.advertisements USING btree (advertiser_id, updated_at DESC);


--
-- Name: idx_business_expenses_group_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_business_expenses_group_date ON public.business_expenses USING btree (group_id, expense_date);


--
-- Name: idx_conversation_participants_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_conversation_participants_user ON public.conversation_participants USING btree (user_id);


--
-- Name: idx_conversations_group; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_conversations_group ON public.conversations USING btree (group_id);


--
-- Name: idx_dm_recipe_performance_score; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_dm_recipe_performance_score ON public.dm_recipe_performance USING btree (avg_suggestion_score DESC);


--
-- Name: idx_dm_recipe_performance_suggestions; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_dm_recipe_performance_suggestions ON public.dm_recipe_performance USING btree (total_suggestions DESC);


--
-- Name: idx_dm_stock_health_date_stock; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_dm_stock_health_date_stock ON public.dm_stock_health_daily USING btree (snapshot_date, stock_id);


--
-- Name: idx_dm_stock_health_group; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_dm_stock_health_group ON public.dm_stock_health_daily USING btree (group_id, snapshot_date);


--
-- Name: idx_dm_user_ltv_account_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_dm_user_ltv_account_type ON public.dm_user_ltv USING btree (account_type, engagement_score);


--
-- Name: idx_dm_user_ltv_churn; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_dm_user_ltv_churn ON public.dm_user_ltv USING btree (churn_risk, last_activity_date);


--
-- Name: idx_dm_user_ltv_engagement; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_dm_user_ltv_engagement ON public.dm_user_ltv USING btree (engagement_score DESC);


--
-- Name: idx_food_purchase_lines_purchase; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_food_purchase_lines_purchase ON public.food_purchase_lines USING btree (purchase_id);


--
-- Name: idx_group_invitations_group; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_group_invitations_group ON public.group_invitations USING btree (group_id, created_at DESC);


--
-- Name: idx_groups_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_groups_deleted_at ON public.groups USING btree (deleted_at);


--
-- Name: idx_groups_owner; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_groups_owner ON public.groups USING btree (owner_id);


--
-- Name: idx_message_attachments_message; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_message_attachments_message ON public.message_attachments USING btree (message_id);


--
-- Name: idx_message_reactions_message; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_message_reactions_message ON public.message_reactions USING btree (message_id);


--
-- Name: idx_message_reads_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_message_reads_user ON public.message_reads USING btree (user_id);


--
-- Name: idx_messages_content_search; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_messages_content_search ON public.messages USING gin (to_tsvector('simple'::regconfig, COALESCE(content, ''::text)));


--
-- Name: idx_messages_conversation_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_messages_conversation_created ON public.messages USING btree (conversation_id, created_at);


--
-- Name: idx_messages_sender; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_messages_sender ON public.messages USING btree (sender_id);


--
-- Name: idx_money_allocations_exit; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_money_allocations_exit ON public.money_allocations USING btree (exit_id);


--
-- Name: idx_money_exits_group_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_money_exits_group_date ON public.money_exits USING btree (group_id, local_date DESC, id DESC);


--
-- Name: idx_money_exits_stock; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_money_exits_stock ON public.money_exits USING btree (stock_key, occurred_at, id);


--
-- Name: idx_money_supplies_stock; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_money_supplies_stock ON public.money_supplies USING btree (stock_key, available_on, id);


--
-- Name: idx_notifications_group; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notifications_group ON public.notifications USING btree (group_id);


--
-- Name: idx_notifications_recipient_active_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notifications_recipient_active_created ON public.notifications USING btree (recipient_user_id, created_at DESC) WHERE (deleted_at IS NULL);


--
-- Name: idx_notifications_recipient_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notifications_recipient_created_at ON public.notifications USING btree (recipient_user_id, created_at DESC);


--
-- Name: idx_notifications_unread; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notifications_unread ON public.notifications USING btree (recipient_user_id) WHERE (read_at IS NULL);


--
-- Name: idx_password_reset_tokens_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_password_reset_tokens_user ON public.password_reset_tokens USING btree (user_id, created_at DESC);


--
-- Name: idx_plans_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_plans_deleted_at ON public.plans USING btree (deleted_at);


--
-- Name: idx_products_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_products_category ON public.products USING btree (category);


--
-- Name: idx_products_storage_place; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_products_storage_place ON public.products USING btree (storage_place);


--
-- Name: idx_receipt_draft_lines_receipt; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_receipt_draft_lines_receipt ON public.receipt_draft_lines USING btree (receipt_id);


--
-- Name: idx_receipt_drafts_owner; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_receipt_drafts_owner ON public.receipt_drafts USING btree (created_by, created_at DESC);


--
-- Name: idx_recipe_favorites_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_recipe_favorites_user ON public.recipe_favorites USING btree (user_id, created_at DESC);


--
-- Name: idx_recipe_ingredients_product; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_recipe_ingredients_product ON public.recipe_ingredients USING btree (product_id);


--
-- Name: idx_recipe_ingredients_recipe; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_recipe_ingredients_recipe ON public.recipe_ingredients USING btree (recipe_id);


--
-- Name: idx_recipe_suggestions_expire_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_recipe_suggestions_expire_date ON public.recipe_suggestions USING btree (nearest_expire_date);


--
-- Name: idx_recipe_suggestions_recipe; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_recipe_suggestions_recipe ON public.recipe_suggestions USING btree (recipe_id);


--
-- Name: idx_recipe_suggestions_stock; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_recipe_suggestions_stock ON public.recipe_suggestions USING btree (stock_id);


--
-- Name: idx_requests_conversation; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_requests_conversation ON public.requests USING btree (conversation_id);


--
-- Name: idx_requests_product; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_requests_product ON public.requests USING btree (product_id);


--
-- Name: idx_requests_stock; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_requests_stock ON public.requests USING btree (stock_id);


--
-- Name: idx_requests_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_requests_user ON public.requests USING btree (user_id);


--
-- Name: idx_shopping_list_products_list; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_shopping_list_products_list ON public.shopping_list_products USING btree (list_id);


--
-- Name: idx_shopping_list_products_product; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_shopping_list_products_product ON public.shopping_list_products USING btree (product_id);


--
-- Name: idx_shopping_lists_stock; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_shopping_lists_stock ON public.shopping_lists USING btree (stock_id);


--
-- Name: idx_shopping_lists_stock_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_shopping_lists_stock_status ON public.shopping_lists USING btree (stock_id, status, created_at DESC);


--
-- Name: idx_shopping_pending; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_shopping_pending ON public.shopping_list_products USING btree (list_id) WHERE (status = 'PENDING'::public.product_list_status_enum);


--
-- Name: idx_stock_movements_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_stock_movements_date ON public.stock_movements USING btree (date);


--
-- Name: idx_stock_movements_stock_product; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_stock_movements_stock_product ON public.stock_movements USING btree (stock_product_id);


--
-- Name: idx_stock_movements_summary; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_stock_movements_summary ON public.stock_movements USING btree (date, purpose, movement_type);


--
-- Name: idx_stock_movements_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_stock_movements_user ON public.stock_movements USING btree (user_id);


--
-- Name: idx_stock_products_active_stock; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_stock_products_active_stock ON public.stock_products USING btree (stock_id, expire_date) WHERE (deleted_at IS NULL);


--
-- Name: idx_stock_products_expire_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_stock_products_expire_date ON public.stock_products USING btree (expire_date);


--
-- Name: idx_stock_products_product; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_stock_products_product ON public.stock_products USING btree (product_id);


--
-- Name: idx_stock_products_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_stock_products_status ON public.stock_products USING btree (product_status);


--
-- Name: idx_stock_products_stock; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_stock_products_stock ON public.stock_products USING btree (stock_id);


--
-- Name: idx_stocks_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_stocks_deleted_at ON public.stocks USING btree (deleted_at);


--
-- Name: idx_stocks_group; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_stocks_group ON public.stocks USING btree (group_id);


--
-- Name: idx_subscriptions_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_subscriptions_deleted_at ON public.subscriptions USING btree (deleted_at);


--
-- Name: idx_subscriptions_plan; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_subscriptions_plan ON public.subscriptions USING btree (plan_id);


--
-- Name: idx_subscriptions_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_subscriptions_status ON public.subscriptions USING btree (status);


--
-- Name: idx_subscriptions_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_subscriptions_user ON public.subscriptions USING btree (user_id);


--
-- Name: idx_transaction_events_transaction; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transaction_events_transaction ON public.transaction_events USING btree (transaction_id, created_at);


--
-- Name: idx_transactions_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transactions_created_at ON public.transactions USING btree (created_at);


--
-- Name: idx_transactions_plan; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transactions_plan ON public.transactions USING btree (plan_id);


--
-- Name: idx_transactions_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transactions_status ON public.transactions USING btree (status);


--
-- Name: idx_transactions_subscription; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transactions_subscription ON public.transactions USING btree (subscription_id);


--
-- Name: idx_transactions_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transactions_user ON public.transactions USING btree (user_id);


--
-- Name: idx_user_groups_group; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_groups_group ON public.user_groups USING btree (group_id);


--
-- Name: idx_user_groups_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_groups_user ON public.user_groups USING btree (user_id);


--
-- Name: idx_users_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_deleted_at ON public.users USING btree (deleted_at);


--
-- Name: uq_food_purchases_receipt; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_food_purchases_receipt ON public.food_purchases USING btree (group_id, receipt_reference) WHERE ((receipt_reference IS NOT NULL) AND (deleted_at IS NULL));


--
-- Name: uq_group_invitations_pending; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_group_invitations_pending ON public.group_invitations USING btree (group_id, lower((email)::text)) WHERE ((accepted_at IS NULL) AND (revoked_at IS NULL));


--
-- Name: uq_notifications_deduplication_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_notifications_deduplication_key ON public.notifications USING btree (deduplication_key) WHERE (deduplication_key IS NOT NULL);


--
-- Name: uq_plans_name_active; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_plans_name_active ON public.plans USING btree (name) WHERE (deleted_at IS NULL);


--
-- Name: uq_products_global_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_products_global_name ON public.products USING btree (lower((name)::text)) WHERE (owner_group_id IS NULL);


--
-- Name: uq_products_group_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_products_group_name ON public.products USING btree (owner_group_id, lower((name)::text)) WHERE (owner_group_id IS NOT NULL);


--
-- Name: uq_stock_products_active_product_stock_expire_batch; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_stock_products_active_product_stock_expire_batch ON public.stock_products USING btree (product_id, stock_id, expire_date, COALESCE(batch, ''::character varying)) WHERE (deleted_at IS NULL);


--
-- Name: uq_subscriptions_one_active_per_user; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_subscriptions_one_active_per_user ON public.subscriptions USING btree (user_id) WHERE ((status = ANY (ARRAY['TRIAL'::public.subscription_status_enum, 'ACTIVE'::public.subscription_status_enum])) AND (deleted_at IS NULL));


--
-- Name: uq_users_email_active; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_users_email_active ON public.users USING btree (email) WHERE (deleted_at IS NULL);


--
-- Name: products audit_products_row_changes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_products_row_changes AFTER INSERT OR DELETE OR UPDATE ON public.products FOR EACH ROW EXECUTE FUNCTION audit.capture_row_change();


--
-- Name: stock_products audit_stock_products_row_changes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_stock_products_row_changes AFTER INSERT OR DELETE OR UPDATE ON public.stock_products FOR EACH ROW EXECUTE FUNCTION audit.capture_row_change();


--
-- Name: conversation_participants trg_conversation_participants_pair_key; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_conversation_participants_pair_key AFTER INSERT ON public.conversation_participants FOR EACH ROW EXECUTE FUNCTION public.trg_fn_conversation_participants_pair_key();


--
-- Name: notifications trg_filter_notification_preferences; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_filter_notification_preferences BEFORE INSERT ON public.notifications FOR EACH ROW EXECUTE FUNCTION public.trg_fn_filter_notification_preferences();


--
-- Name: transactions trg_log_transaction_status_change; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_log_transaction_status_change AFTER INSERT OR UPDATE ON public.transactions FOR EACH ROW EXECUTE FUNCTION public.fn_log_transaction_status_change();


--
-- Name: stock_products trg_notify_commercial_stock_level; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_notify_commercial_stock_level AFTER INSERT OR UPDATE OF quantity, minimal_quantity ON public.stock_products FOR EACH ROW EXECUTE FUNCTION public.trg_fn_notify_commercial_stock_level();


--
-- Name: shopping_list_products trg_notify_shopping_list_product_added; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_notify_shopping_list_product_added AFTER INSERT ON public.shopping_list_products FOR EACH ROW EXECUTE FUNCTION public.trg_fn_notify_shopping_list_product_added();


--
-- Name: conversation_participants trg_set_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON public.conversation_participants FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


--
-- Name: conversations trg_set_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON public.conversations FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


--
-- Name: discard trg_set_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON public.discard FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


--
-- Name: groups trg_set_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON public.groups FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


--
-- Name: message_attachments trg_set_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON public.message_attachments FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


--
-- Name: messages trg_set_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON public.messages FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


--
-- Name: plans trg_set_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON public.plans FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


--
-- Name: products trg_set_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON public.products FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


--
-- Name: recipe_ingredients trg_set_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON public.recipe_ingredients FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


--
-- Name: recipe_suggestions trg_set_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON public.recipe_suggestions FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


--
-- Name: recipes trg_set_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON public.recipes FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


--
-- Name: requests trg_set_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON public.requests FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


--
-- Name: shopping_list_products trg_set_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON public.shopping_list_products FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


--
-- Name: shopping_lists trg_set_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON public.shopping_lists FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


--
-- Name: stock_products trg_set_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON public.stock_products FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


--
-- Name: stocks trg_set_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON public.stocks FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


--
-- Name: subscriptions trg_set_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON public.subscriptions FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


--
-- Name: transactions trg_set_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON public.transactions FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


--
-- Name: user_groups trg_set_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON public.user_groups FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


--
-- Name: users trg_set_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


--
-- Name: stock_products trg_stock_products_set_initial_quantity; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_stock_products_set_initial_quantity BEFORE INSERT ON public.stock_products FOR EACH ROW EXECUTE FUNCTION public.trg_fn_stock_products_set_initial_quantity();


--
-- Name: stock_products trg_stock_products_set_status; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_stock_products_set_status BEFORE INSERT OR UPDATE OF expire_date ON public.stock_products FOR EACH ROW EXECUTE FUNCTION public.trg_fn_stock_products_set_status();


--
-- Name: dim_stock dim_stock_group_key_fkey; Type: FK CONSTRAINT; Schema: dw; Owner: -
--

ALTER TABLE ONLY dw.dim_stock
    ADD CONSTRAINT dim_stock_group_key_fkey FOREIGN KEY (group_key) REFERENCES dw.dim_group(group_key);


--
-- Name: fact_stock_movement fact_stock_movement_date_key_fkey; Type: FK CONSTRAINT; Schema: dw; Owner: -
--

ALTER TABLE ONLY dw.fact_stock_movement
    ADD CONSTRAINT fact_stock_movement_date_key_fkey FOREIGN KEY (date_key) REFERENCES dw.dim_date(date_key);


--
-- Name: fact_stock_movement fact_stock_movement_group_key_fkey; Type: FK CONSTRAINT; Schema: dw; Owner: -
--

ALTER TABLE ONLY dw.fact_stock_movement
    ADD CONSTRAINT fact_stock_movement_group_key_fkey FOREIGN KEY (group_key) REFERENCES dw.dim_group(group_key);


--
-- Name: fact_stock_movement fact_stock_movement_product_key_fkey; Type: FK CONSTRAINT; Schema: dw; Owner: -
--

ALTER TABLE ONLY dw.fact_stock_movement
    ADD CONSTRAINT fact_stock_movement_product_key_fkey FOREIGN KEY (product_key) REFERENCES dw.dim_product(product_key);


--
-- Name: fact_stock_movement fact_stock_movement_stock_key_fkey; Type: FK CONSTRAINT; Schema: dw; Owner: -
--

ALTER TABLE ONLY dw.fact_stock_movement
    ADD CONSTRAINT fact_stock_movement_stock_key_fkey FOREIGN KEY (stock_key) REFERENCES dw.dim_stock(stock_key);


--
-- Name: fact_stock_movement fact_stock_movement_user_key_fkey; Type: FK CONSTRAINT; Schema: dw; Owner: -
--

ALTER TABLE ONLY dw.fact_stock_movement
    ADD CONSTRAINT fact_stock_movement_user_key_fkey FOREIGN KEY (user_key) REFERENCES dw.dim_user(user_key);


--
-- Name: user_daily_access user_daily_access_user_id_fkey; Type: FK CONSTRAINT; Schema: dw; Owner: -
--

ALTER TABLE ONLY dw.user_daily_access
    ADD CONSTRAINT user_daily_access_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: advertisements advertisements_advertiser_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.advertisements
    ADD CONSTRAINT advertisements_advertiser_id_fkey FOREIGN KEY (advertiser_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: business_expenses business_expenses_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.business_expenses
    ADD CONSTRAINT business_expenses_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: business_expenses business_expenses_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.business_expenses
    ADD CONSTRAINT business_expenses_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.groups(id) ON DELETE RESTRICT;


--
-- Name: business_expenses business_expenses_shopping_list_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.business_expenses
    ADD CONSTRAINT business_expenses_shopping_list_id_fkey FOREIGN KEY (shopping_list_id) REFERENCES public.shopping_lists(id) ON DELETE RESTRICT;


--
-- Name: discard discard_movement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discard
    ADD CONSTRAINT discard_movement_id_fkey FOREIGN KEY (movement_id) REFERENCES public.stock_movements(id);


--
-- Name: conversation_participants fk_conversation_participants_conversation_id_conversations; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversation_participants
    ADD CONSTRAINT fk_conversation_participants_conversation_id_conversations FOREIGN KEY (conversation_id) REFERENCES public.conversations(id) ON DELETE CASCADE;


--
-- Name: conversation_participants fk_conversation_participants_user_id_users; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversation_participants
    ADD CONSTRAINT fk_conversation_participants_user_id_users FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: conversations fk_conversations_group_id_groups; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT fk_conversations_group_id_groups FOREIGN KEY (group_id) REFERENCES public.groups(id) ON DELETE SET NULL;


--
-- Name: discard fk_discard_stock_product_id_stock_products; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discard
    ADD CONSTRAINT fk_discard_stock_product_id_stock_products FOREIGN KEY (stock_product_id) REFERENCES public.stock_products(id) ON DELETE CASCADE;


--
-- Name: groups fk_groups_owner_id_users; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups
    ADD CONSTRAINT fk_groups_owner_id_users FOREIGN KEY (owner_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: message_attachments fk_message_attachments_message_id_messages; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message_attachments
    ADD CONSTRAINT fk_message_attachments_message_id_messages FOREIGN KEY (message_id) REFERENCES public.messages(id) ON DELETE CASCADE;


--
-- Name: message_reads fk_message_reads_conversation_id_participants; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message_reads
    ADD CONSTRAINT fk_message_reads_conversation_id_participants FOREIGN KEY (conversation_id, user_id) REFERENCES public.conversation_participants(conversation_id, user_id) ON DELETE CASCADE;


--
-- Name: message_reads fk_message_reads_message_id_messages; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message_reads
    ADD CONSTRAINT fk_message_reads_message_id_messages FOREIGN KEY (message_id, conversation_id) REFERENCES public.messages(id, conversation_id) ON DELETE CASCADE;


--
-- Name: messages fk_messages_conversation_id_conversations; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT fk_messages_conversation_id_conversations FOREIGN KEY (conversation_id) REFERENCES public.conversations(id) ON DELETE CASCADE;


--
-- Name: messages fk_messages_conversation_id_participants; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT fk_messages_conversation_id_participants FOREIGN KEY (conversation_id, sender_id) REFERENCES public.conversation_participants(conversation_id, user_id);


--
-- Name: messages fk_messages_related_shopping_list_product_id_slp; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT fk_messages_related_shopping_list_product_id_slp FOREIGN KEY (related_shopping_list_product_id) REFERENCES public.shopping_list_products(id) ON DELETE SET NULL;


--
-- Name: messages fk_messages_sender_id_users; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT fk_messages_sender_id_users FOREIGN KEY (sender_id) REFERENCES public.users(id);


--
-- Name: notifications fk_notifications_group_id_groups; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT fk_notifications_group_id_groups FOREIGN KEY (group_id) REFERENCES public.groups(id) ON DELETE CASCADE;


--
-- Name: notifications fk_notifications_recipient_user_id_users; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT fk_notifications_recipient_user_id_users FOREIGN KEY (recipient_user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: recipe_ingredients fk_recipe_ingredients_product_id_products; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recipe_ingredients
    ADD CONSTRAINT fk_recipe_ingredients_product_id_products FOREIGN KEY (product_id) REFERENCES public.products(id);


--
-- Name: recipe_ingredients fk_recipe_ingredients_recipe_id_recipes; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recipe_ingredients
    ADD CONSTRAINT fk_recipe_ingredients_recipe_id_recipes FOREIGN KEY (recipe_id) REFERENCES public.recipes(id) ON DELETE CASCADE;


--
-- Name: recipe_suggestions fk_recipe_suggestions_recipe_id_recipes; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recipe_suggestions
    ADD CONSTRAINT fk_recipe_suggestions_recipe_id_recipes FOREIGN KEY (recipe_id) REFERENCES public.recipes(id) ON DELETE CASCADE;


--
-- Name: recipe_suggestions fk_recipe_suggestions_stock_id_stocks; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recipe_suggestions
    ADD CONSTRAINT fk_recipe_suggestions_stock_id_stocks FOREIGN KEY (stock_id) REFERENCES public.stocks(id) ON DELETE CASCADE;


--
-- Name: requests fk_requests_conversation_id_conversations; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requests
    ADD CONSTRAINT fk_requests_conversation_id_conversations FOREIGN KEY (conversation_id) REFERENCES public.conversations(id) ON DELETE SET NULL;


--
-- Name: requests fk_requests_message_id_messages; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requests
    ADD CONSTRAINT fk_requests_message_id_messages FOREIGN KEY (message_id, conversation_id) REFERENCES public.messages(id, conversation_id) ON DELETE SET NULL;


--
-- Name: requests fk_requests_product_id_products; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requests
    ADD CONSTRAINT fk_requests_product_id_products FOREIGN KEY (product_id) REFERENCES public.products(id);


--
-- Name: requests fk_requests_stock_id_stocks; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requests
    ADD CONSTRAINT fk_requests_stock_id_stocks FOREIGN KEY (stock_id) REFERENCES public.stocks(id) ON DELETE CASCADE;


--
-- Name: requests fk_requests_user_id_users; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requests
    ADD CONSTRAINT fk_requests_user_id_users FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: shopping_list_products fk_shopping_list_products_list_id_shopping_lists; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shopping_list_products
    ADD CONSTRAINT fk_shopping_list_products_list_id_shopping_lists FOREIGN KEY (list_id) REFERENCES public.shopping_lists(id) ON DELETE CASCADE;


--
-- Name: shopping_list_products fk_shopping_list_products_product_id_products; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shopping_list_products
    ADD CONSTRAINT fk_shopping_list_products_product_id_products FOREIGN KEY (product_id) REFERENCES public.products(id);


--
-- Name: shopping_lists fk_shopping_lists_stock_id_stocks; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shopping_lists
    ADD CONSTRAINT fk_shopping_lists_stock_id_stocks FOREIGN KEY (stock_id) REFERENCES public.stocks(id) ON DELETE CASCADE;


--
-- Name: stock_movements fk_stock_movements_stock_product_id_stock_products; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stock_movements
    ADD CONSTRAINT fk_stock_movements_stock_product_id_stock_products FOREIGN KEY (stock_product_id) REFERENCES public.stock_products(id) ON DELETE CASCADE;


--
-- Name: stock_movements fk_stock_movements_user_id_users; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stock_movements
    ADD CONSTRAINT fk_stock_movements_user_id_users FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: stock_products fk_stock_products_product_id_products; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stock_products
    ADD CONSTRAINT fk_stock_products_product_id_products FOREIGN KEY (product_id) REFERENCES public.products(id);


--
-- Name: stock_products fk_stock_products_stock_id_stocks; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stock_products
    ADD CONSTRAINT fk_stock_products_stock_id_stocks FOREIGN KEY (stock_id) REFERENCES public.stocks(id) ON DELETE CASCADE;


--
-- Name: stocks fk_stocks_group_id_groups; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stocks
    ADD CONSTRAINT fk_stocks_group_id_groups FOREIGN KEY (group_id) REFERENCES public.groups(id) ON DELETE CASCADE;


--
-- Name: subscriptions fk_subscriptions_plan_id_plans; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT fk_subscriptions_plan_id_plans FOREIGN KEY (plan_id) REFERENCES public.plans(id);


--
-- Name: subscriptions fk_subscriptions_user_id_users; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT fk_subscriptions_user_id_users FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: transaction_events fk_transaction_events_transaction_id_transactions; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_events
    ADD CONSTRAINT fk_transaction_events_transaction_id_transactions FOREIGN KEY (transaction_id) REFERENCES public.transactions(id) ON DELETE CASCADE;


--
-- Name: transactions fk_transactions_plan_id_plans; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT fk_transactions_plan_id_plans FOREIGN KEY (plan_id) REFERENCES public.plans(id);


--
-- Name: transactions fk_transactions_subscription_id_subscriptions; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT fk_transactions_subscription_id_subscriptions FOREIGN KEY (subscription_id) REFERENCES public.subscriptions(id) ON DELETE CASCADE;


--
-- Name: transactions fk_transactions_user_id_users; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT fk_transactions_user_id_users FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: user_groups fk_user_groups_group_id_groups; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_groups
    ADD CONSTRAINT fk_user_groups_group_id_groups FOREIGN KEY (group_id) REFERENCES public.groups(id) ON DELETE CASCADE;


--
-- Name: user_groups fk_user_groups_user_id_users; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_groups
    ADD CONSTRAINT fk_user_groups_user_id_users FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: food_purchase_lines food_purchase_lines_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.food_purchase_lines
    ADD CONSTRAINT food_purchase_lines_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE SET NULL;


--
-- Name: food_purchase_lines food_purchase_lines_purchase_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.food_purchase_lines
    ADD CONSTRAINT food_purchase_lines_purchase_id_fkey FOREIGN KEY (purchase_id) REFERENCES public.food_purchases(id);


--
-- Name: food_purchase_lines food_purchase_lines_stock_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.food_purchase_lines
    ADD CONSTRAINT food_purchase_lines_stock_product_id_fkey FOREIGN KEY (stock_product_id) REFERENCES public.stock_products(id) ON DELETE SET NULL;


--
-- Name: food_purchase_revisions food_purchase_revisions_changed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.food_purchase_revisions
    ADD CONSTRAINT food_purchase_revisions_changed_by_fkey FOREIGN KEY (changed_by) REFERENCES public.users(id);


--
-- Name: food_purchase_revisions food_purchase_revisions_purchase_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.food_purchase_revisions
    ADD CONSTRAINT food_purchase_revisions_purchase_id_fkey FOREIGN KEY (purchase_id) REFERENCES public.food_purchases(id);


--
-- Name: food_purchases food_purchases_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.food_purchases
    ADD CONSTRAINT food_purchases_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.groups(id);


--
-- Name: group_invitations group_invitations_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_invitations
    ADD CONSTRAINT group_invitations_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.groups(id) ON DELETE CASCADE;


--
-- Name: message_reactions message_reactions_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message_reactions
    ADD CONSTRAINT message_reactions_message_id_fkey FOREIGN KEY (message_id) REFERENCES public.messages(id) ON DELETE CASCADE;


--
-- Name: message_reactions message_reactions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message_reactions
    ADD CONSTRAINT message_reactions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: money_allocations money_allocations_exit_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.money_allocations
    ADD CONSTRAINT money_allocations_exit_id_fkey FOREIGN KEY (exit_id) REFERENCES public.money_exits(id) ON DELETE CASCADE;


--
-- Name: money_allocations money_allocations_supply_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.money_allocations
    ADD CONSTRAINT money_allocations_supply_id_fkey FOREIGN KEY (supply_id) REFERENCES public.money_supplies(id) ON DELETE SET NULL;


--
-- Name: money_exits money_exits_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.money_exits
    ADD CONSTRAINT money_exits_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.groups(id);


--
-- Name: money_exits money_exits_movement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.money_exits
    ADD CONSTRAINT money_exits_movement_id_fkey FOREIGN KEY (movement_id) REFERENCES public.stock_movements(id) ON DELETE SET NULL;


--
-- Name: money_exits money_exits_stock_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.money_exits
    ADD CONSTRAINT money_exits_stock_product_id_fkey FOREIGN KEY (stock_product_id) REFERENCES public.stock_products(id) ON DELETE SET NULL;


--
-- Name: money_supplies money_supplies_purchase_line_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.money_supplies
    ADD CONSTRAINT money_supplies_purchase_line_id_fkey FOREIGN KEY (purchase_line_id) REFERENCES public.food_purchase_lines(id);


--
-- Name: money_supplies money_supplies_stock_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.money_supplies
    ADD CONSTRAINT money_supplies_stock_product_id_fkey FOREIGN KEY (stock_product_id) REFERENCES public.stock_products(id) ON DELETE SET NULL;


--
-- Name: password_reset_tokens password_reset_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.password_reset_tokens
    ADD CONSTRAINT password_reset_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: products products_owner_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_owner_group_id_fkey FOREIGN KEY (owner_group_id) REFERENCES public.groups(id) ON DELETE RESTRICT;


--
-- Name: receipt_draft_lines receipt_draft_lines_matched_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.receipt_draft_lines
    ADD CONSTRAINT receipt_draft_lines_matched_product_id_fkey FOREIGN KEY (matched_product_id) REFERENCES public.products(id);


--
-- Name: receipt_draft_lines receipt_draft_lines_receipt_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.receipt_draft_lines
    ADD CONSTRAINT receipt_draft_lines_receipt_id_fkey FOREIGN KEY (receipt_id) REFERENCES public.receipt_drafts(id) ON DELETE CASCADE;


--
-- Name: receipt_drafts receipt_drafts_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.receipt_drafts
    ADD CONSTRAINT receipt_drafts_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: receipt_drafts receipt_drafts_stock_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.receipt_drafts
    ADD CONSTRAINT receipt_drafts_stock_id_fkey FOREIGN KEY (stock_id) REFERENCES public.stocks(id) ON DELETE CASCADE;


--
-- Name: recipe_favorites recipe_favorites_recipe_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recipe_favorites
    ADD CONSTRAINT recipe_favorites_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES public.recipes(id) ON DELETE CASCADE;


--
-- Name: recipe_favorites recipe_favorites_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recipe_favorites
    ADD CONSTRAINT recipe_favorites_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_preferences user_preferences_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_preferences
    ADD CONSTRAINT user_preferences_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: row_change_log; Type: ROW SECURITY; Schema: audit; Owner: -
--

ALTER TABLE audit.row_change_log ENABLE ROW LEVEL SECURITY;

--
-- Name: row_change_log row_change_log_trigger_insert; Type: POLICY; Schema: audit; Owner: -
--

CREATE POLICY row_change_log_trigger_insert ON audit.row_change_log FOR INSERT TO authenticated WITH CHECK ((current_user_name = (CURRENT_USER)::text));


--
-- Name: conversation_participants; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.conversation_participants ENABLE ROW LEVEL SECURITY;

--
-- Name: conversations; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;

--
-- Name: discard; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.discard ENABLE ROW LEVEL SECURITY;

--
-- Name: groups; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.groups ENABLE ROW LEVEL SECURITY;

--
-- Name: message_attachments; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.message_attachments ENABLE ROW LEVEL SECURITY;

--
-- Name: message_reads; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.message_reads ENABLE ROW LEVEL SECURITY;

--
-- Name: messages; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

--
-- Name: plans; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.plans ENABLE ROW LEVEL SECURITY;

--
-- Name: products; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

--
-- Name: recipe_ingredients; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.recipe_ingredients ENABLE ROW LEVEL SECURITY;

--
-- Name: recipe_suggestions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.recipe_suggestions ENABLE ROW LEVEL SECURITY;

--
-- Name: recipes; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.recipes ENABLE ROW LEVEL SECURITY;

--
-- Name: requests; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.requests ENABLE ROW LEVEL SECURITY;

--
-- Name: shopping_list_products; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.shopping_list_products ENABLE ROW LEVEL SECURITY;

--
-- Name: shopping_lists; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.shopping_lists ENABLE ROW LEVEL SECURITY;

--
-- Name: stock_movements; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.stock_movements ENABLE ROW LEVEL SECURITY;

--
-- Name: stock_products; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.stock_products ENABLE ROW LEVEL SECURITY;

--
-- Name: stocks; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.stocks ENABLE ROW LEVEL SECURITY;

--
-- Name: subscriptions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;

--
-- Name: transaction_events; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.transaction_events ENABLE ROW LEVEL SECURITY;

--
-- Name: transactions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;

--
-- Name: user_groups; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.user_groups ENABLE ROW LEVEL SECURITY;

--
-- Name: users; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

--
-- PostgreSQL database dump complete
--

\unrestrict O2BFD8CNqnkYEKkqC6a75hBRvcdHhjtQqP0FFbBCUyiGFNCbxzE2uoAFeoAvNPT
