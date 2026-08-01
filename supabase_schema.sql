-- 1. Create Customers Table
CREATE TABLE IF NOT EXISTS public.customers (
    id UUID REFERENCES auth.users(id) PRIMARY KEY,
    name TEXT NOT NULL,
    phone TEXT,
    address TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- 2. Create Orders Table
CREATE TABLE IF NOT EXISTS public.orders (
    id UUID DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
    shop_id UUID REFERENCES public.shops(id) ON DELETE CASCADE,
    customer_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    total_amount NUMERIC NOT NULL,
    status TEXT DEFAULT 'pending', -- pending, accepted, preparing, out_for_delivery, delivered, cancelled
    delivery_address TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- 3. Create Order Items Table (kaunsa product kitna order hua)
CREATE TABLE IF NOT EXISTS public.order_items (
    id UUID DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
    order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE,
    product_id UUID REFERENCES public.products(id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL,
    price_at_time NUMERIC NOT NULL
);

-- 4. Disable RLS for testing
ALTER TABLE public.customers DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items DISABLE ROW LEVEL SECURITY;
