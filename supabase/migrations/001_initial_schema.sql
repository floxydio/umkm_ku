-- ============================================================
-- UMKM KU — Initial Schema Migration
-- Jalankan di: Supabase Dashboard → SQL Editor → New Query
-- ============================================================

-- Helper: auto-update updated_at on every UPDATE
CREATE OR REPLACE FUNCTION trigger_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- ============================================================
-- 1. CATEGORIES
-- ============================================================
CREATE TABLE IF NOT EXISTS categories (
  id            TEXT        PRIMARY KEY,
  name          TEXT        NOT NULL,
  is_deleted    BOOLEAN     NOT NULL DEFAULT FALSE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER set_updated_at_categories
  BEFORE UPDATE ON categories
  FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();

ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
CREATE POLICY "auth users full access" ON categories
  FOR ALL TO authenticated USING (true) WITH CHECK (true);


-- ============================================================
-- 2. APP USERS  (kasir/owner — bukan Supabase auth)
-- ============================================================
CREATE TABLE IF NOT EXISTS app_users (
  id            TEXT        PRIMARY KEY,
  name          TEXT        NOT NULL,
  role          TEXT        NOT NULL CHECK (role IN ('owner', 'cashier')),
  pin           TEXT,
  is_active     BOOLEAN     NOT NULL DEFAULT TRUE,
  is_deleted    BOOLEAN     NOT NULL DEFAULT FALSE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER set_updated_at_app_users
  BEFORE UPDATE ON app_users
  FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();

ALTER TABLE app_users ENABLE ROW LEVEL SECURITY;
CREATE POLICY "auth users full access" ON app_users
  FOR ALL TO authenticated USING (true) WITH CHECK (true);


-- ============================================================
-- 3. PRODUCTS
-- ============================================================
CREATE TABLE IF NOT EXISTS products (
  id            TEXT        PRIMARY KEY,
  name          TEXT        NOT NULL,
  price         BIGINT      NOT NULL,   -- harga jual (Rupiah)
  cost_price    BIGINT      NOT NULL,   -- harga beli
  stock         INTEGER     NOT NULL DEFAULT 0,
  min_stock     INTEGER     NOT NULL DEFAULT 0,
  category_id   TEXT        NOT NULL REFERENCES categories(id),
  image_url     TEXT,
  is_deleted    BOOLEAN     NOT NULL DEFAULT FALSE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_products_category ON products(category_id);
CREATE INDEX IF NOT EXISTS idx_products_is_deleted ON products(is_deleted);

CREATE TRIGGER set_updated_at_products
  BEFORE UPDATE ON products
  FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();

ALTER TABLE products ENABLE ROW LEVEL SECURITY;
CREATE POLICY "auth users full access" ON products
  FOR ALL TO authenticated USING (true) WITH CHECK (true);


-- ============================================================
-- 4. CUSTOMERS
-- ============================================================
CREATE TABLE IF NOT EXISTS customers (
  id            TEXT        PRIMARY KEY,
  name          TEXT        NOT NULL,
  phone         TEXT        NOT NULL DEFAULT '',
  total_debt    BIGINT      NOT NULL DEFAULT 0,
  is_deleted    BOOLEAN     NOT NULL DEFAULT FALSE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_customers_is_deleted ON customers(is_deleted);

CREATE TRIGGER set_updated_at_customers
  BEFORE UPDATE ON customers
  FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();

ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "auth users full access" ON customers
  FOR ALL TO authenticated USING (true) WITH CHECK (true);


-- ============================================================
-- 5. TRANSACTIONS
-- ============================================================
CREATE TABLE IF NOT EXISTS transactions (
  id              TEXT        PRIMARY KEY,
  total_amount    BIGINT      NOT NULL,
  discount_amount BIGINT      NOT NULL DEFAULT 0,
  paid_amount     BIGINT      NOT NULL,
  change_amount   BIGINT      NOT NULL,
  cashier_id      TEXT        NOT NULL REFERENCES app_users(id),
  note            TEXT,
  is_deleted      BOOLEAN     NOT NULL DEFAULT FALSE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_transactions_cashier    ON transactions(cashier_id);
CREATE INDEX IF NOT EXISTS idx_transactions_created_at ON transactions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_is_deleted ON transactions(is_deleted);

CREATE TRIGGER set_updated_at_transactions
  BEFORE UPDATE ON transactions
  FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();

ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "auth users full access" ON transactions
  FOR ALL TO authenticated USING (true) WITH CHECK (true);


-- ============================================================
-- 6. TRANSACTION ITEMS
-- ============================================================
CREATE TABLE IF NOT EXISTS transaction_items (
  id              TEXT        PRIMARY KEY,
  transaction_id  TEXT        NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
  product_id      TEXT        NOT NULL REFERENCES products(id),
  product_name    TEXT        NOT NULL,  -- snapshot saat transaksi
  quantity        INTEGER     NOT NULL,
  unit_price      BIGINT      NOT NULL,
  subtotal        BIGINT      NOT NULL,
  is_deleted      BOOLEAN     NOT NULL DEFAULT FALSE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_txn_items_transaction ON transaction_items(transaction_id);
CREATE INDEX IF NOT EXISTS idx_txn_items_product     ON transaction_items(product_id);

CREATE TRIGGER set_updated_at_transaction_items
  BEFORE UPDATE ON transaction_items
  FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();

ALTER TABLE transaction_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "auth users full access" ON transaction_items
  FOR ALL TO authenticated USING (true) WITH CHECK (true);


-- ============================================================
-- 7. DEBTS  (hutang pelanggan)
-- ============================================================
CREATE TABLE IF NOT EXISTS debts (
  id               TEXT        PRIMARY KEY,
  customer_id      TEXT        NOT NULL REFERENCES customers(id),
  amount           BIGINT      NOT NULL,
  paid_amount      BIGINT      NOT NULL DEFAULT 0,
  remaining_amount BIGINT      NOT NULL,
  due_date         TIMESTAMPTZ,
  note             TEXT,
  is_deleted       BOOLEAN     NOT NULL DEFAULT FALSE,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_debts_customer    ON debts(customer_id);
CREATE INDEX IF NOT EXISTS idx_debts_is_deleted  ON debts(is_deleted);

CREATE TRIGGER set_updated_at_debts
  BEFORE UPDATE ON debts
  FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();

ALTER TABLE debts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "auth users full access" ON debts
  FOR ALL TO authenticated USING (true) WITH CHECK (true);


-- ============================================================
-- 8. DEBT PAYMENTS  (riwayat pembayaran hutang)
-- ============================================================
CREATE TABLE IF NOT EXISTS debt_payments (
  id          TEXT        PRIMARY KEY,
  debt_id     TEXT        NOT NULL REFERENCES debts(id) ON DELETE CASCADE,
  amount      BIGINT      NOT NULL,
  paid_at     TIMESTAMPTZ NOT NULL,
  is_deleted  BOOLEAN     NOT NULL DEFAULT FALSE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_debt_payments_debt ON debt_payments(debt_id);

CREATE TRIGGER set_updated_at_debt_payments
  BEFORE UPDATE ON debt_payments
  FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();

ALTER TABLE debt_payments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "auth users full access" ON debt_payments
  FOR ALL TO authenticated USING (true) WITH CHECK (true);


-- ============================================================
-- 9. STOCK LOGS  (riwayat stok masuk/keluar)
-- ============================================================
CREATE TABLE IF NOT EXISTS stock_logs (
  id          TEXT        PRIMARY KEY,
  product_id  TEXT        NOT NULL REFERENCES products(id),
  type        TEXT        NOT NULL CHECK (type IN ('in', 'out')),
  quantity    INTEGER     NOT NULL,
  note        TEXT,
  is_deleted  BOOLEAN     NOT NULL DEFAULT FALSE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_stock_logs_product    ON stock_logs(product_id);
CREATE INDEX IF NOT EXISTS idx_stock_logs_created_at ON stock_logs(created_at DESC);

CREATE TRIGGER set_updated_at_stock_logs
  BEFORE UPDATE ON stock_logs
  FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();

ALTER TABLE stock_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "auth users full access" ON stock_logs
  FOR ALL TO authenticated USING (true) WITH CHECK (true);


-- ============================================================
-- 10. PURCHASED FEATURES  (fitur premium yang dibeli)
-- ============================================================
CREATE TABLE IF NOT EXISTS purchased_features (
  id           TEXT        PRIMARY KEY,
  feature_key  TEXT        NOT NULL UNIQUE,
  purchased_at TIMESTAMPTZ NOT NULL,
  expires_at   TIMESTAMPTZ,            -- NULL = lifetime
  is_deleted   BOOLEAN     NOT NULL DEFAULT FALSE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER set_updated_at_purchased_features
  BEFORE UPDATE ON purchased_features
  FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();

ALTER TABLE purchased_features ENABLE ROW LEVEL SECURITY;
CREATE POLICY "auth users full access" ON purchased_features
  FOR ALL TO authenticated USING (true) WITH CHECK (true);


-- ============================================================
-- SELESAI
-- ============================================================
