#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Gerador de dataload para o schema Frigus.
Gera um único arquivo .sql com INSERTs em lote, respeitando todas as
FKs, UNIQUEs e CHECKs do schema (enums em inglês, unit_of_measure_enum,
updated_at/deleted_at).

Uso: python3 generate_dataload.py > 08_dataload.sql
"""

import random
import uuid
from datetime import datetime, timedelta, date
from faker import Faker

random.seed(42)
fake = Faker("pt_BR")
Faker.seed(42)

OUT = []


def w(sql):
    OUT.append(sql)


def esc(s):
    if s is None:
        return "NULL"
    return "'" + str(s).replace("'", "''") + "'"


def uid():
    return str(uuid.uuid4())


def rand_ts(start_days_ago=730, end_days_ago=0):
    delta = random.randint(end_days_ago, start_days_ago)
    seconds = random.randint(0, 86399)
    return (datetime.now() - timedelta(days=delta, seconds=-seconds))


def sql_ts(dt):
    return esc(dt.strftime("%Y-%m-%d %H:%M:%S"))


def sql_date(d):
    return esc(d.strftime("%Y-%m-%d"))


def batch_insert(table, columns, rows, batch_size=1000):
    if not rows:
        return
    cols_sql = ", ".join(columns)
    for i in range(0, len(rows), batch_size):
        chunk = rows[i:i + batch_size]
        values_sql = ",\n".join(
            "(" + ", ".join(r) + ")" for r in chunk
        )
        w(f"INSERT INTO {table} ({cols_sql}) VALUES\n{values_sql};")


# ============================================================
# ESCALA
# ============================================================
N_GROUPS = 900
N_USERS = 3000
N_RECIPES = 220
N_RECIPE_SUGGESTIONS = 2000
N_SHOPPING_LISTS = 2000
N_CONVERSATIONS_GROUP_RATIO = 0.55
N_CONVERSATIONS = 1500
N_REQUESTS = 1600

w("BEGIN;")

# ============================================================
# 1) PLANS -> já inseridos no script de schema, só lemos ids fixos
# ============================================================
PLAN_NAMES = ["Frigus Free", "Frigus Família", "Frigus Comercial", "Frigus Empresarial"]
PLAN_IDS = {name: i + 1 for i, name in enumerate(PLAN_NAMES)}
PLAN_PRICE = {
    "Frigus Free": 0.00,
    "Frigus Família": 29.99,
    "Frigus Comercial": 119.99,
    "Frigus Empresarial": 159.99,
}

# ============================================================
# 2) GROUPS
# ============================================================
GROUP_TEMPLATES_HOME = ["Família {}", "República {}", "Casa da {}", "Apto da {}"]
GROUP_TEMPLATES_BIZ = ["Mercadinho {}", "Restaurante {}", "Padaria {}", "Empresa {} Ltda", "Distribuidora {}"]

groups = []  # (id, name, banner_picture, created_at, kind)
for i in range(N_GROUPS):
    is_biz = random.random() < 0.25
    last = fake.last_name()
    if is_biz:
        tmpl = random.choice(GROUP_TEMPLATES_BIZ)
        name = tmpl.format(last)
        kind = "biz"
    else:
        tmpl = random.choice(GROUP_TEMPLATES_HOME)
        name = tmpl.format(last)
        kind = "home"
    gid = uid()
    created = rand_ts(700, 30)
    groups.append((gid, name, None, created, kind))

rows = [(esc(g[0]), esc(g[1]), "NULL", sql_ts(g[3])) for g in groups]
batch_insert("groups", ["id", "name", "banner_picture", "created_at"], rows)

# ============================================================
# 3) USERS
# ============================================================
ACCOUNT_TYPES = ["DOMESTIC", "BUSINESS", "COMMERCIAL"]
users = []  # (id, name, birth_date, account_type, email, hash_password, created_at)
for i in range(N_USERS):
    name = fake.name()
    birth = fake.date_of_birth(minimum_age=16, maximum_age=85)
    acct = random.choices(ACCOUNT_TYPES, weights=[0.7, 0.1, 0.2])[0]
    email = fake.unique.email()
    uidv = uid()
    created = rand_ts(700, 0)
    pwd_hash = fake.sha256()
    users.append((uidv, name, birth, acct, email, pwd_hash, created))

rows = [
    (esc(u[0]), esc(u[1]), sql_date(u[2]), esc(u[3]), esc(u[4]), esc(u[5]), sql_ts(u[6]))
    for u in users
]
batch_insert(
    "users",
    ["id", "name", "birth_date", "account_type", "email", "hash_password", "created_at"],
    rows,
)

# ============================================================
# 4) USER_GROUPS
# ============================================================
user_groups_pairs = set()
user_groups_rows = []
group_members = {g[0]: [] for g in groups}

for u in users:
    primary_group = random.choice(groups)
    user_groups_pairs.add((u[0], primary_group[0]))
    group_members[primary_group[0]].append(u[0])
    if random.random() < 0.15:
        second_group = random.choice(groups)
        if (u[0], second_group[0]) not in user_groups_pairs:
            user_groups_pairs.add((u[0], second_group[0]))
            group_members[second_group[0]].append(u[0])

for (uid_, gid_) in user_groups_pairs:
    user_groups_rows.append((esc(uid_), esc(gid_)))

batch_insert("user_groups", ["user_id", "group_id"], user_groups_rows)

for g in groups:
    if not group_members[g[0]]:
        u = random.choice(users)
        group_members[g[0]].append(u[0])
        batch_insert("user_groups", ["user_id", "group_id"], [(esc(u[0]), esc(g[0]))])

# ============================================================
# 5) STOCKS
# ============================================================
STOCK_NAMES = ["Geladeira Principal", "Freezer", "Despensa", "Armário de Limpeza", "Estoque Secundário"]
stocks = []  # (id, group_id, name)
stock_id_seq = 1
stocks_by_group = {}
for g in groups:
    name = "Geladeira Principal"
    stocks.append((stock_id_seq, g[0], name))
    stocks_by_group.setdefault(g[0], []).append(stock_id_seq)
    stock_id_seq += 1
    if random.random() < 0.2:
        name2 = random.choice(STOCK_NAMES[1:])
        stocks.append((stock_id_seq, g[0], name2))
        stocks_by_group[g[0]].append(stock_id_seq)
        stock_id_seq += 1

rows = [(str(s[0]), esc(s[1]), esc(s[2])) for s in stocks]
batch_insert("stocks", ["id", "group_id", "name"], rows)
w(f"SELECT setval('stocks_id_seq', {stock_id_seq - 1});")

# ============================================================
# 6) PRODUCTS (catálogo curado)
# ============================================================
# (nome, categoria_enum, local_armazenamento_enum, preço, unidade_enum)
PRODUCT_CATALOG = [
    ("Maçã Gala", "FRUIT", "FRIDGE", 0.89, "UNIT"),
    ("Banana Prata", "FRUIT", "PANTRY", 0.59, "UNIT"),
    ("Laranja Pera", "FRUIT", "PANTRY", 0.69, "UNIT"),
    ("Morango", "FRUIT", "FRIDGE", 6.99, "PACKAGE"),
    ("Uva Itália", "FRUIT", "FRIDGE", 8.99, "KILOGRAM"),
    ("Mamão Papaya", "FRUIT", "PANTRY", 4.49, "UNIT"),
    ("Abacaxi", "FRUIT", "PANTRY", 5.99, "UNIT"),
    ("Manga Palmer", "FRUIT", "PANTRY", 3.49, "UNIT"),
    ("Limão Taiti", "FRUIT", "PANTRY", 0.39, "UNIT"),
    ("Pera Williams", "FRUIT", "FRIDGE", 1.29, "UNIT"),
    ("Alface Crespa", "VEGETABLE", "FRIDGE", 2.49, "UNIT"),
    ("Tomate Salada", "VEGETABLE", "FRIDGE", 6.99, "KILOGRAM"),
    ("Cenoura", "VEGETABLE", "FRIDGE", 3.99, "KILOGRAM"),
    ("Batata Inglesa", "VEGETABLE", "PANTRY", 4.99, "KILOGRAM"),
    ("Cebola", "VEGETABLE", "PANTRY", 4.49, "KILOGRAM"),
    ("Brócolis", "VEGETABLE", "FRIDGE", 3.99, "UNIT"),
    ("Pepino", "VEGETABLE", "FRIDGE", 2.99, "UNIT"),
    ("Abobrinha", "VEGETABLE", "FRIDGE", 3.49, "KILOGRAM"),
    ("Pimentão Vermelho", "VEGETABLE", "FRIDGE", 7.99, "KILOGRAM"),
    ("Couve Manteiga", "VEGETABLE", "FRIDGE", 2.99, "UNIT"),
    ("Leite Integral", "DAIRY", "FRIDGE", 4.79, "LITER"),
    ("Queijo Mussarela", "DAIRY", "FRIDGE", 34.90, "KILOGRAM"),
    ("Iogurte Natural", "DAIRY", "FRIDGE", 3.99, "UNIT"),
    ("Manteiga", "DAIRY", "FRIDGE", 8.49, "UNIT"),
    ("Requeijão Cremoso", "DAIRY", "FRIDGE", 6.99, "UNIT"),
    ("Queijo Prato", "DAIRY", "FRIDGE", 32.90, "KILOGRAM"),
    ("Creme de Leite", "DAIRY", "PANTRY", 2.79, "UNIT"),
    ("Leite Condensado", "DAIRY", "PANTRY", 6.49, "UNIT"),
    ("Coalhada", "DAIRY", "FRIDGE", 5.49, "UNIT"),
    ("Iogurte Grego", "DAIRY", "FRIDGE", 4.99, "UNIT"),
    ("Peito de Frango", "MEAT", "FREEZER", 16.90, "KILOGRAM"),
    ("Carne Moída", "MEAT", "FREEZER", 32.90, "KILOGRAM"),
    ("Picanha", "MEAT", "FREEZER", 69.90, "KILOGRAM"),
    ("Filé de Tilápia", "MEAT", "FREEZER", 28.90, "KILOGRAM"),
    ("Linguiça Toscana", "MEAT", "FREEZER", 19.90, "KILOGRAM"),
    ("Costela Bovina", "MEAT", "FREEZER", 39.90, "KILOGRAM"),
    ("Coxa e Sobrecoxa", "MEAT", "FREEZER", 12.90, "KILOGRAM"),
    ("Bacon", "MEAT", "FRIDGE", 24.90, "KILOGRAM"),
    ("Salsicha", "MEAT", "FRIDGE", 14.90, "KILOGRAM"),
    ("Carne Suína", "MEAT", "FREEZER", 22.90, "KILOGRAM"),
    ("Arroz Branco", "GRAIN", "PANTRY", 22.90, "PACKAGE"),
    ("Feijão Carioca", "GRAIN", "PANTRY", 8.49, "KILOGRAM"),
    ("Feijão Preto", "GRAIN", "PANTRY", 8.99, "KILOGRAM"),
    ("Lentilha", "GRAIN", "PANTRY", 9.99, "KILOGRAM"),
    ("Grão de Bico", "GRAIN", "PANTRY", 12.90, "KILOGRAM"),
    ("Farinha de Trigo", "GRAIN", "PANTRY", 5.49, "KILOGRAM"),
    ("Aveia em Flocos", "GRAIN", "PANTRY", 6.99, "PACKAGE"),
    ("Milho de Pipoca", "GRAIN", "PANTRY", 4.99, "PACKAGE"),
    ("Quinoa", "GRAIN", "PANTRY", 18.90, "PACKAGE"),
    ("Macarrão Espaguete", "GRAIN", "PANTRY", 4.49, "PACKAGE"),
    ("Suco de Laranja", "BEVERAGE", "FRIDGE", 7.99, "LITER"),
    ("Refrigerante Cola", "BEVERAGE", "PANTRY", 8.49, "LITER"),
    ("Água Mineral", "BEVERAGE", "PANTRY", 2.49, "LITER"),
    ("Cerveja Pilsen", "BEVERAGE", "FRIDGE", 4.49, "UNIT"),
    ("Café em Pó", "BEVERAGE", "CABINET", 14.90, "PACKAGE"),
    ("Chá Mate", "BEVERAGE", "CABINET", 6.99, "PACKAGE"),
    ("Vinho Tinto Seco", "BEVERAGE", "SHELF", 39.90, "UNIT"),
    ("Suco de Uva Integral", "BEVERAGE", "PANTRY", 12.90, "LITER"),
    ("Achocolatado em Pó", "BEVERAGE", "CABINET", 9.99, "UNIT"),
    ("Energético", "BEVERAGE", "FRIDGE", 8.99, "UNIT"),
    ("Detergente Líquido", "CLEANING", "CABINET", 2.49, "UNIT"),
    ("Sabão em Pó", "CLEANING", "CABINET", 16.90, "PACKAGE"),
    ("Amaciante", "CLEANING", "CABINET", 12.90, "LITER"),
    ("Água Sanitária", "CLEANING", "CABINET", 5.49, "LITER"),
    ("Desinfetante", "CLEANING", "CABINET", 6.99, "LITER"),
    ("Multiuso", "CLEANING", "CABINET", 4.99, "UNIT"),
    ("Esponja de Aço", "CLEANING", "CABINET", 3.49, "PACKAGE"),
    ("Saco de Lixo", "CLEANING", "CABINET", 9.99, "PACKAGE"),
    ("Álcool 70%", "CLEANING", "CABINET", 8.99, "LITER"),
    ("Limpa Vidros", "CLEANING", "CABINET", 7.49, "UNIT"),
    ("Papel Higiênico", "PERSONAL_HYGIENE", "CABINET", 18.90, "PACKAGE"),
    ("Sabonete", "PERSONAL_HYGIENE", "CABINET", 2.49, "UNIT"),
    ("Shampoo", "PERSONAL_HYGIENE", "CABINET", 14.90, "UNIT"),
    ("Condicionador", "PERSONAL_HYGIENE", "CABINET", 15.90, "UNIT"),
    ("Creme Dental", "PERSONAL_HYGIENE", "CABINET", 6.49, "UNIT"),
    ("Escova de Dente", "PERSONAL_HYGIENE", "CABINET", 5.99, "UNIT"),
    ("Desodorante", "PERSONAL_HYGIENE", "CABINET", 12.90, "UNIT"),
    ("Absorvente", "PERSONAL_HYGIENE", "CABINET", 9.99, "PACKAGE"),
    ("Fio Dental", "PERSONAL_HYGIENE", "CABINET", 4.99, "UNIT"),
    ("Lâmina de Barbear", "PERSONAL_HYGIENE", "CABINET", 11.90, "PACKAGE"),
]

products = []  # (id, name, category, storage_place, unit_price, unit_of_measure)
for i, (name, cat, storage, price, unit) in enumerate(PRODUCT_CATALOG, start=1):
    products.append((i, name, cat, storage, price, unit))

rows = [
    (str(p[0]), esc(p[1]), esc(p[2]), esc(p[3]), f"{p[4]:.2f}", esc(p[5]))
    for p in products
]
batch_insert(
    "products",
    ["id", "name", "category", "storage_place", "unit_price", "unit_of_measure"],
    rows,
)
w(f"SELECT setval('products_id_seq', {len(products)});")

# ============================================================
# 7) STOCK_PRODUCTS
# ============================================================
stock_products = []  # (id, product_id, stock_id, quantity, minimal_quantity, expire_date, status, category)
sp_id = 1

for (sid, gid_, sname) in stocks:
    n_products = random.randint(15, 45)
    chosen = random.sample(products, min(n_products, len(products)))
    for p in chosen:
        qty = random.randint(0, 30)
        min_qty = random.choice([None, 1, 2, 3, 5])
        expire_offset = random.randint(-15, 180)
        expire = date.today() + timedelta(days=expire_offset)
        if expire_offset < 0:
            status = "EXPIRED"
        elif expire_offset <= 5:
            status = "NEAR_EXPIRATION"
        else:
            status = "FRESH"
        stock_products.append((sp_id, p[0], sid, qty, min_qty, expire, status, p[2]))
        sp_id += 1

rows = [
    (
        str(sp[0]), str(sp[1]), str(sp[2]), str(sp[3]),
        "NULL" if sp[4] is None else str(sp[4]),
        sql_date(sp[5]), esc(sp[6]), esc(sp[7]),
    )
    for sp in stock_products
]
batch_insert(
    "stock_products",
    ["id", "product_id", "stock_id", "quantity", "minimal_quantity", "expire_date", "product_status", "category"],
    rows,
)
w(f"SELECT setval('stock_products_id_seq', {sp_id - 1});")

# ============================================================
# 8) RECIPES
# ============================================================
RECIPE_NAME_TEMPLATES = [
    "Arroz com {}", "{} Grelhado(a)", "Sopa de {}", "Salada de {}", "{} ao Forno",
    "Refogado de {}", "{} Refogado(a)", "Torta de {}", "Risoto de {}", "{} na Manteiga",
]
recipes = []  # (id, name, description, instructions, domestic_only, active, created_at)
for i in range(1, N_RECIPES + 1):
    base_product = random.choice(products)
    name = random.choice(RECIPE_NAME_TEMPLATES).format(base_product[1])
    desc = fake.sentence(nb_words=12)
    instr = " ".join(fake.sentences(nb=random.randint(3, 6)))
    domestic_only = random.random() < 0.85
    active = random.random() < 0.95
    created = rand_ts(600, 0)
    recipes.append((i, name, desc, instr, domestic_only, active, created))

rows = [
    (
        str(r[0]), esc(r[1]), esc(r[2]), esc(r[3]),
        "TRUE" if r[4] else "FALSE", "TRUE" if r[5] else "FALSE", sql_ts(r[6]),
    )
    for r in recipes
]
batch_insert(
    "recipes",
    ["id", "name", "description", "instructions", "domestic_only", "active", "created_at"],
    rows,
)
w(f"SELECT setval('recipes_id_seq', {len(recipes)});")

# ============================================================
# 9) RECIPE_INGREDIENTS
# ============================================================
ri_id = 1
ri_rows = []
for r in recipes:
    n_ing = random.randint(3, 9)
    chosen = random.sample(products, min(n_ing, len(products)))
    for p in chosen:
        qty = round(random.uniform(0.1, 3.0), 2)
        unit = random.choice(["g", "kg", "ml", "litro", "un", "colher", "xícara"])
        required = random.random() < 0.8
        ri_rows.append((str(ri_id), str(r[0]), str(p[0]), f"{qty}", esc(unit), "TRUE" if required else "FALSE"))
        ri_id += 1

batch_insert(
    "recipe_ingredients",
    ["id", "recipe_id", "product_id", "quantity", "unit", "required"],
    ri_rows,
)
w(f"SELECT setval('recipe_ingredients_id_seq', {ri_id - 1});")

# ============================================================
# 10) RECIPE_SUGGESTIONS
# ============================================================
rs_rows = []
for i in range(1, N_RECIPE_SUGGESTIONS + 1):
    r = random.choice(recipes)
    s = random.choice(stocks)
    matched = random.randint(0, 8)
    missing = random.randint(0, 5)
    nearest_expire = date.today() + timedelta(days=random.randint(-5, 60))
    score = round(random.uniform(0, 1), 4)
    created = rand_ts(120, 0)
    rs_rows.append((
        str(i), str(r[0]), str(s[0]), str(matched), str(missing),
        sql_date(nearest_expire), f"{score}", sql_ts(created),
    ))

batch_insert(
    "recipe_suggestions",
    ["id", "recipe_id", "stock_id", "matched_ingredients", "missing_ingredients", "nearest_expire_date", "score", "created_at"],
    rs_rows,
)
w(f"SELECT setval('recipe_suggestions_id_seq', {N_RECIPE_SUGGESTIONS});")

# ============================================================
# 11) SHOPPING_LISTS
# ============================================================
LIST_STATUSES = ["OPEN", "COMPLETED", "CANCELED"]
shopping_lists = []  # (id, date, stock_id, status, created_at)
for i in range(N_SHOPPING_LISTS):
    s = random.choice(stocks)
    lid = uid()
    d = date.today() - timedelta(days=random.randint(0, 400))
    status = random.choices(LIST_STATUSES, weights=[0.25, 0.65, 0.10])[0]
    created = datetime.combine(d, datetime.min.time()) + timedelta(hours=random.randint(6, 22))
    shopping_lists.append((lid, d, s[0], status, created))

rows = [
    (esc(sl[0]), sql_date(sl[1]), str(sl[2]), esc(sl[3]), sql_ts(sl[4]))
    for sl in shopping_lists
]
batch_insert("shopping_lists", ["id", "date", "stock_id", "status", "created_at"], rows)

# ============================================================
# 12) SHOPPING_LIST_PRODUCTS
# ============================================================
SLP_STATUSES = ["PENDING", "PURCHASED", "REMOVED"]
slp_id = 1
slp_rows = []
for sl in shopping_lists:
    n_items = random.randint(2, 12)
    chosen = random.sample(products, min(n_items, len(products)))
    for p in chosen:
        status = random.choice(SLP_STATUSES)
        qty = random.randint(1, 5)
        slp_rows.append((str(slp_id), esc(sl[0]), str(p[0]), esc(status), str(qty)))
        slp_id += 1

batch_insert(
    "shopping_list_products",
    ["id", "list_id", "product_id", "status", "quantity"],
    slp_rows,
)
w(f"SELECT setval('shopping_list_products_id_seq', {slp_id - 1});")

# ============================================================
# 13) DISCARD
# ============================================================
DISCARD_REASONS = ["Vencido", "Estragado", "Mofado", "Embalagem danificada", "Cheiro alterado", "Sobra descartada"]
n_discard = int(len(stock_products) * 0.12)
discard_sample = random.sample(stock_products, min(n_discard, len(stock_products)))
discard_rows = []
for i, sp in enumerate(discard_sample, start=1):
    reason = random.choice(DISCARD_REASONS)
    dt = rand_ts(60, 0)
    discard_rows.append((str(i), str(sp[0]), esc(reason), sql_ts(dt)))

batch_insert("discard", ["id", "stock_product_id", "reason", "date"], discard_rows)
w(f"SELECT setval('discard_id_seq', {len(discard_rows)});")

# ============================================================
# 14) STOCK_MOVEMENTS
# ============================================================
MOVEMENT_TYPES = ["IN", "OUT", "ADJUSTMENT"]
n_movements = int(len(stock_products) * 1.3)
sm_rows = []
for i in range(1, n_movements + 1):
    sp = random.choice(stock_products)
    u = random.choice(users)
    mtype = random.choices(MOVEMENT_TYPES, weights=[0.45, 0.45, 0.10])[0]
    qty = random.randint(1, 15)
    dt = rand_ts(400, 0)
    sm_rows.append((str(i), str(sp[0]), esc(u[0]), esc(mtype), str(qty), sql_ts(dt)))

batch_insert(
    "stock_movements",
    ["id", "stock_product_id", "user_id", "movement_type", "quantity", "date"],
    sm_rows,
)
w(f"SELECT setval('stock_movements_id_seq', {n_movements});")

# ============================================================
# 15) CONVERSATIONS + CONVERSATION_PARTICIPANTS
# ============================================================
conversations = []  # (id, type, group_id_or_None, name, pair_key_or_None, created_at)
participants_by_conv = {}
used_pair_keys = set()

n_group_conv = int(N_CONVERSATIONS * N_CONVERSATIONS_GROUP_RATIO)
n_priv_conv = N_CONVERSATIONS - n_group_conv

for _ in range(n_group_conv):
    g = random.choice(groups)
    members = group_members[g[0]]
    if len(members) < 1:
        continue
    cid = uid()
    created = rand_ts(500, 0)
    conversations.append((cid, "GROUP", g[0], f"Chat {g[1]}", None, created))
    if len(members) >= 2:
        k = random.randint(2, min(8, len(members)))
    else:
        k = 1
    participants_by_conv[cid] = random.sample(members, k) if len(members) >= k else list(members)
    if not participants_by_conv[cid]:
        participants_by_conv[cid] = [random.choice(users)[0]]

attempts = 0
while len([c for c in conversations if c[1] == "PRIVATE"]) < n_priv_conv and attempts < n_priv_conv * 5:
    attempts += 1
    u1, u2 = random.sample(users, 2)
    pair_key = "-".join(sorted([u1[0], u2[0]]))
    if pair_key in used_pair_keys:
        continue
    used_pair_keys.add(pair_key)
    cid = uid()
    created = rand_ts(500, 0)
    conversations.append((cid, "PRIVATE", None, None, pair_key, created))
    participants_by_conv[cid] = [u1[0], u2[0]]

rows = []
for c in conversations:
    rows.append((
        esc(c[0]), esc(c[1]),
        "NULL" if c[2] is None else esc(c[2]),
        "NULL" if c[3] is None else esc(c[3]),
        "NULL" if c[4] is None else esc(c[4]),
        sql_ts(c[5]),
    ))
batch_insert(
    "conversations",
    ["id", "conversation_type", "group_id", "name", "pair_key", "created_at"],
    rows,
)

cp_rows = []
for cid, members in participants_by_conv.items():
    for m in members:
        joined = rand_ts(500, 0)
        cp_rows.append((esc(cid), esc(m), sql_ts(joined), "NULL"))
batch_insert("conversation_participants", ["conversation_id", "user_id", "joined_at", "left_at"], cp_rows)

# ============================================================
# 16) MESSAGES
# ============================================================
MSG_TYPES_WEIGHTS = [("TEXT", 0.85), ("IMAGE", 0.10), ("SYSTEM", 0.05)]
messages = []  # (id, conversation_id, sender_id, type, content, related_slp_id, created_at)
msg_id = 1
slp_ids_all = [int(r[0]) for r in slp_rows] if slp_rows else []

for cid, members in participants_by_conv.items():
    n_msgs = random.randint(1, 25)
    conv_created = next(c[5] for c in conversations if c[0] == cid)
    for _ in range(n_msgs):
        sender = random.choice(members)
        mtype = random.choices([m[0] for m in MSG_TYPES_WEIGHTS], weights=[m[1] for m in MSG_TYPES_WEIGHTS])[0]
        if mtype == "SYSTEM":
            content = random.choice(["Usuário entrou no grupo.", "Lista de compras atualizada.", "Item marcado como comprado."])
        elif mtype == "IMAGE":
            content = None
        else:
            content = fake.sentence(nb_words=random.randint(3, 15))
        related = None
        if slp_ids_all and random.random() < 0.05:
            related = random.choice(slp_ids_all)
        created = conv_created + timedelta(minutes=random.randint(1, 500000))
        if created > datetime.now():
            created = datetime.now() - timedelta(minutes=random.randint(1, 1000))
        messages.append((msg_id, cid, sender, mtype, content, related, created))
        msg_id += 1

rows = [
    (
        str(m[0]), esc(m[1]), esc(m[2]), esc(m[3]),
        "NULL" if m[4] is None else esc(m[4]),
        "NULL" if m[5] is None else str(m[5]),
        sql_ts(m[6]),
    )
    for m in messages
]
batch_insert(
    "messages",
    ["id", "conversation_id", "sender_id", "message_type", "content", "related_shopping_list_product_id", "created_at"],
    rows,
)
w(f"SELECT setval('messages_id_seq', {msg_id - 1});")

# ============================================================
# 17) MESSAGE_ATTACHMENTS
# ============================================================
img_messages = [m for m in messages if m[3] == "IMAGE"]
ma_rows = []
for i, m in enumerate(img_messages, start=1):
    fname = f"foto_{i}.jpg"
    url = f"https://cdn.frigus.app/uploads/{fname}"
    ma_rows.append((str(i), str(m[0]), esc(url), esc(fname), esc("image/jpeg"), str(random.randint(50_000, 4_000_000))))

batch_insert(
    "message_attachments",
    ["id", "message_id", "file_url", "file_name", "mime_type", "file_size"],
    ma_rows,
)
if ma_rows:
    w(f"SELECT setval('message_attachments_id_seq', {len(ma_rows)});")

# ============================================================
# 18) MESSAGE_READS
# ============================================================
mr_rows = []
seen_pairs = set()
for m in messages:
    cid = m[1]
    members = participants_by_conv.get(cid, [])
    readers = [u for u in members if u != m[2] and random.random() < 0.7]
    for r in readers:
        key = (m[0], r)
        if key in seen_pairs:
            continue
        seen_pairs.add(key)
        read_at = m[6] + timedelta(minutes=random.randint(1, 4000))
        if read_at > datetime.now():
            read_at = datetime.now()
        mr_rows.append((str(m[0]), esc(cid), esc(r), sql_ts(read_at)))

batch_insert("message_reads", ["message_id", "conversation_id", "user_id", "read_at"], mr_rows)

# ============================================================
# 19) SUBSCRIPTIONS + TRANSACTIONS
# ============================================================
subscriptions = []  # (id, user_id, plan_name, status, started_at, period_start, period_end, canceled_at)
for u in users:
    plan_name = random.choices(PLAN_NAMES, weights=[0.45, 0.30, 0.15, 0.10])[0]
    status = random.choices(["TRIAL", "ACTIVE", "DELINQUENT"], weights=[0.10, 0.80, 0.10])[0]
    started = rand_ts(500, 0)
    period_start = started
    period_end = period_start + timedelta(days=30)
    sid = uid()
    subscriptions.append((sid, u[0], plan_name, status, started, period_start, period_end, None))
    if random.random() < 0.15:
        old_plan = random.choice(PLAN_NAMES)
        old_started = started - timedelta(days=random.randint(60, 400))
        old_end = old_started + timedelta(days=30)
        canceled_at = old_end
        sid_old = uid()
        subscriptions.append((sid_old, u[0], old_plan, "CANCELED", old_started, old_started, old_end, canceled_at))

rows = []
for s in subscriptions:
    rows.append((
        esc(s[0]), esc(s[1]), str(PLAN_IDS[s[2]]), esc(s[3]),
        sql_ts(s[4]), sql_ts(s[5]), sql_ts(s[6]),
        "NULL" if s[7] is None else sql_ts(s[7]),
    ))
batch_insert(
    "subscriptions",
    ["id", "user_id", "plan_id", "status", "started_at", "current_period_start", "current_period_end", "canceled_at"],
    rows,
)

# transactions
TXN_STATUS_TERMINAL = ["APPROVED", "APPROVED", "APPROVED", "APPROVED", "REJECTED", "ERROR"]
PAYMENT_METHODS = ["CREDIT_CARD", "DEBIT_CARD", "PIX", "BOLETO"]
txn_rows = []
for s in subscriptions:
    plan_name = s[2]
    price = PLAN_PRICE[plan_name]
    if price == 0:
        continue
    n_charges = random.randint(1, 6)
    charge_date = s[4]
    for _ in range(n_charges):
        tid = uid()
        method = random.choice(PAYMENT_METHODS)
        last4 = f"{random.randint(0, 9999):04d}" if "CARD" in method else None
        pix_key = fake.email() if method == "PIX" else None
        status = random.choices(
            ["PENDING", "PROCESSING"] + TXN_STATUS_TERMINAL,
            weights=[0.02, 0.02, 0.55, 0.55, 0.55, 0.55, 0.20, 0.10],
        )[0]
        attempts = 1 if status != "ERROR" else random.randint(1, 3)
        processed_at = None if status in ("PENDING", "PROCESSING") else charge_date + timedelta(minutes=random.randint(1, 30))
        queued_at = charge_date + timedelta(seconds=random.randint(1, 30))
        error_msg = "Falha simulada ao validar pagamento." if status == "ERROR" else None
        txn_rows.append((
            esc(tid), esc(s[1]), esc(s[0]), str(PLAN_IDS[plan_name]),
            f"{price:.2f}", esc(method),
            "NULL" if last4 is None else esc(last4),
            "NULL" if pix_key is None else esc(pix_key),
            esc(status), "NULL", str(attempts), "3",
            "NULL" if error_msg is None else esc(error_msg),
            sql_ts(charge_date), sql_ts(queued_at),
            "NULL" if processed_at is None else sql_ts(processed_at),
        ))
        charge_date = charge_date + timedelta(days=30)
        if charge_date > datetime.now():
            break

batch_insert(
    "transactions",
    [
        "id", "user_id", "subscription_id", "plan_id", "amount", "payment_method",
        "fake_card_last4", "fake_pix_key", "status", "queue_job_id", "attempts", "max_attempts",
        "error_message", "created_at", "queued_at", "processed_at",
    ],
    txn_rows,
    batch_size=500,
)

# ============================================================
# 20) REQUESTS
# ============================================================
req_rows = []
for i in range(1, N_REQUESTS + 1):
    u = random.choice(users)
    p = random.choice(products)
    s = random.choice(stocks)
    qty = random.randint(1, 10)
    desc = fake.sentence(nb_words=8) if random.random() < 0.6 else None
    d = date.today() - timedelta(days=random.randint(0, 300))

    conv_id = None
    msg_id_ref = None
    if random.random() < 0.25:
        candidate_convs = [c for c in conversations if c[2] == s[1]]
        if candidate_convs:
            chosen_conv = random.choice(candidate_convs)
            conv_msgs = [m for m in messages if m[1] == chosen_conv[0]]
            if conv_msgs:
                chosen_msg = random.choice(conv_msgs)
                conv_id = chosen_conv[0]
                msg_id_ref = chosen_msg[0]

    req_rows.append((
        str(i), esc(u[0]), str(p[0]), str(s[0]), str(qty),
        "NULL" if desc is None else esc(desc), "NULL", sql_date(d),
        "NULL" if conv_id is None else esc(conv_id),
        "NULL" if msg_id_ref is None else str(msg_id_ref),
    ))

batch_insert(
    "requests",
    ["id", "user_id", "product_id", "stock_id", "quantity", "description", "picture", "date", "conversation_id", "message_id"],
    req_rows,
)
w(f"SELECT setval('requests_id_seq', {N_REQUESTS});")

w("COMMIT;")

print("\n\n".join(OUT))