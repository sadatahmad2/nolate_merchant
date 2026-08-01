-- 1. Create a dummy shop owner user
INSERT INTO auth.users (id, email) 
VALUES ('00000000-0000-0000-0000-000000000002', 'merchant@shop.com') 
ON CONFLICT DO NOTHING;

-- 2. Create the Shop for this user (with category)
INSERT INTO public.shops (id, owner_id, shop_name, category, address)
VALUES ('11111111-1111-1111-1111-111111111111', '00000000-0000-0000-0000-000000000002', 'My Nolato Shop', 'Grocery', 'Merchant City')
ON CONFLICT DO NOTHING;
