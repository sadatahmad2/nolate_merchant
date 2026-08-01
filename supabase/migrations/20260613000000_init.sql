-- Zoodo Platform Supabase Schema

-- Enable pgcrypto for UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 1. SHOPS TABLE
CREATE TABLE shops (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  shop_name VARCHAR(255) NOT NULL,
  category VARCHAR(100) NOT NULL,
  address TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  phone VARCHAR(20),
  logo_url TEXT,
  status VARCHAR(50) DEFAULT 'open', -- open, closed, suspended
  rating DOUBLE PRECISION DEFAULT 5.0,
  delivery_time_minutes INT DEFAULT 15,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. PRODUCTS TABLE
CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  image_url TEXT,
  category VARCHAR(100),
  price DOUBLE PRECISION NOT NULL,
  discount_price DOUBLE PRECISION,
  stock INT DEFAULT 0,
  status VARCHAR(50) DEFAULT 'available', -- available, out_of_stock
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. ORDERS TABLE
CREATE TABLE orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  customer_id UUID NOT NULL, -- Assuming customers also use Supabase Auth
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  delivery_partner_id UUID,
  total_amount DOUBLE PRECISION NOT NULL,
  delivery_fee DOUBLE PRECISION DEFAULT 0.0,
  tax DOUBLE PRECISION DEFAULT 0.0,
  status VARCHAR(50) DEFAULT 'placed', -- placed, accepted, preparing, packed, out_for_delivery, delivered, cancelled
  payment_status VARCHAR(50) DEFAULT 'pending', -- pending, paid, failed
  customer_location JSONB, -- {x: float, y: float} or PostGIS POINT
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. ORDER ITEMS TABLE
CREATE TABLE order_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id),
  quantity INT NOT NULL DEFAULT 1,
  price DOUBLE PRECISION NOT NULL -- Price at the time of order
);

-- 5. DELIVERIES TABLE
CREATE TABLE deliveries (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  partner_id UUID NOT NULL,
  status VARCHAR(50) DEFAULT 'assigned', -- assigned, reached_shop, picked_up, reached_customer, delivered
  pickup_time TIMESTAMP WITH TIME ZONE,
  delivery_time TIMESTAMP WITH TIME ZONE
);

-- 6. PAYMENTS (SETTLEMENTS) TABLE
CREATE TABLE payments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  amount DOUBLE PRECISION NOT NULL,
  commission DOUBLE PRECISION NOT NULL,
  settlement_status VARCHAR(50) DEFAULT 'pending', -- pending, processing, settled
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- SETUP ROW LEVEL SECURITY (RLS)
-- Note: These are basic policies. You should refine them based on your exact security needs.

ALTER TABLE shops ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

-- Shops: Merchants can read/update their own shops. Everyone can read open shops.
CREATE POLICY "Merchants can manage their own shops" ON shops FOR ALL USING (auth.uid() = owner_id);
CREATE POLICY "Public can view shops" ON shops FOR SELECT USING (true);

-- Products: Merchants can manage products of their shops. Everyone can read products.
CREATE POLICY "Merchants can manage their products" ON products FOR ALL USING (
  shop_id IN (SELECT id FROM shops WHERE owner_id = auth.uid())
);
CREATE POLICY "Public can view products" ON products FOR SELECT USING (true);

-- Orders: Merchants can read/update orders for their shops. Customers can read/create their own orders.
CREATE POLICY "Merchants can manage their orders" ON orders FOR ALL USING (
  shop_id IN (SELECT id FROM shops WHERE owner_id = auth.uid())
);
CREATE POLICY "Customers can view their orders" ON orders FOR SELECT USING (auth.uid() = customer_id);
CREATE POLICY "Customers can create orders" ON orders FOR INSERT WITH CHECK (auth.uid() = customer_id);

-- Enable Realtime for orders and products
ALTER PUBLICATION supabase_realtime ADD TABLE orders;
ALTER PUBLICATION supabase_realtime ADD TABLE products;
