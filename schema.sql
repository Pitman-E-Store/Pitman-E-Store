-- Run this entire script in Supabase: SQL Editor -> New query -> Run.
create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category text not null check (category in ('Laptop','Tablet','Computer')),
  condition text not null default 'Pre-owned',
  price numeric(12,2) not null default 0 check (price >= 0),
  description text default '',
  image_url text,
  is_sold boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.products enable row level security;

-- Everyone can view product listings.
drop policy if exists "Public can view products" on public.products;
create policy "Public can view products" on public.products
for select using (true);

-- Only the designated shop-owner email can add, edit or delete products.
-- BEFORE running this script, replace owner@example.com below with the exact
-- email address that you will create for the shop owner in Supabase Auth.
drop policy if exists "Owner can insert products" on public.products;
create policy "Owner can insert products" on public.products
for insert to authenticated
with check ((auth.jwt() ->> 'email') = 'owner@example.com');

drop policy if exists "Owner can update products" on public.products;
create policy "Owner can update products" on public.products
for update to authenticated
using ((auth.jwt() ->> 'email') = 'owner@example.com')
with check ((auth.jwt() ->> 'email') = 'owner@example.com');

drop policy if exists "Owner can delete products" on public.products;
create policy "Owner can delete products" on public.products
for delete to authenticated
using ((auth.jwt() ->> 'email') = 'owner@example.com');

-- Create a public image bucket for product photos.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('product-images', 'product-images', true, 5242880, array['image/jpeg','image/png','image/webp'])
on conflict (id) do nothing;

drop policy if exists "Public can view product images" on storage.objects;
create policy "Public can view product images" on storage.objects
for select using (bucket_id = 'product-images');

drop policy if exists "Owner can upload product images" on storage.objects;
create policy "Owner can upload product images" on storage.objects
for insert to authenticated
with check (bucket_id = 'product-images' and (auth.jwt() ->> 'email') = 'owner@example.com');

drop policy if exists "Owner can update product images" on storage.objects;
create policy "Owner can update product images" on storage.objects
for update to authenticated
using (bucket_id = 'product-images' and (auth.jwt() ->> 'email') = 'owner@example.com')
with check (bucket_id = 'product-images' and (auth.jwt() ->> 'email') = 'owner@example.com');

drop policy if exists "Owner can delete product images" on storage.objects;
create policy "Owner can delete product images" on storage.objects
for delete to authenticated
using (bucket_id = 'product-images' and (auth.jwt() ->> 'email') = 'owner@example.com');
