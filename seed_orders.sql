-- Note: This requires the shop to have products. 
-- We will insert a dummy customer, and then dummy orders.

-- 1. Create a dummy customer
INSERT INTO auth.users (id, email) VALUES ('00000000-0000-0000-0000-000000000001', 'dummy@customer.com') ON CONFLICT DO NOTHING;

-- 2. Create Dummy Orders for the first shop we find
DO $$
DECLARE 
    first_shop_id UUID;
BEGIN
    SELECT id INTO first_shop_id FROM public.shops LIMIT 1;
    
    IF first_shop_id IS NOT NULL THEN
        -- Insert a "pending" order
        INSERT INTO public.orders (shop_id, customer_id, total_amount, status, customer_location)
        VALUES (first_shop_id, '00000000-0000-0000-0000-000000000001', 540, 'pending', '{"address": "123 Nolato Street, Tech City"}');

        -- Insert a "preparing" order
        INSERT INTO public.orders (shop_id, customer_id, total_amount, status, customer_location)
        VALUES (first_shop_id, '00000000-0000-0000-0000-000000000001', 1200, 'preparing', '{"address": "456 Business Park, Tech City"}');

        -- Insert a "ready" order
        INSERT INTO public.orders (shop_id, customer_id, total_amount, status, customer_location)
        VALUES (first_shop_id, '00000000-0000-0000-0000-000000000001', 350, 'ready', '{"address": "789 Apartment Complex, Tech City"}');
        
        -- Insert a "delivered" order
        INSERT INTO public.orders (shop_id, customer_id, total_amount, status, customer_location)
        VALUES (first_shop_id, '00000000-0000-0000-0000-000000000001', 890, 'delivered', '{"address": "321 Residential Area, Tech City"}');
    END IF;
END $$;
