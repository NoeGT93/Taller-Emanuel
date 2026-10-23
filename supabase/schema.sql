-- Taller Emanuel POS — Supabase PostgreSQL
-- Ejecutar en el SQL Editor del proyecto Supabase.
create extension if not exists pgcrypto;
create table if not exists public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 name text not null default 'Usuario',
 role text not null default 'seller' check(role in ('admin','seller')),
 active boolean not null default true,
 created_at timestamptz not null default now()
);
create or replace function public.new_user_profile() returns trigger language plpgsql security definer set search_path='' as $$
begin insert into public.profiles(id,name,role) values(new.id,coalesce(nullif(new.raw_user_meta_data->>'name',''),'Usuario'),'seller') on conflict(id) do nothing;return new;end $$;
drop trigger if exists create_profile on auth.users;
create trigger create_profile after insert on auth.users for each row execute function public.new_user_profile();
insert into public.profiles(id,name) select id, coalesce(raw_user_meta_data->>'name','Usuario') from auth.users on conflict(id) do nothing;
create or replace function public.is_admin() returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.profiles where id=auth.uid() and role='admin' and active);
$$;
create or replace function public.is_active() returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.profiles where id=auth.uid() and active);
$$;
create table if not exists public.products(
 id bigint generated always as identity primary key,
 code text not null unique,
 name text not null,
 category text not null default 'Otros',
 type text not null check(type in ('tuctuc','moto','auto')),
 compat text not null default '',
 cost numeric(12,2) not null default 0 check(cost>=0),
 price numeric(12,2) not null check(price>=0),
 stock integer not null default 0 check(stock>=0),
 min integer not null default 3 check(min>=0),
 active boolean not null default true,
 created_at timestamptz not null default now()
);
create table if not exists public.customers(
 id bigint generated always as identity primary key,
 name text not null,
 type text not null default 'Particular',
 phone text not null default '',
 credit_limit numeric(12,2) not null default 0 check(credit_limit>=0),
 balance numeric(12,2) not null default 0 check(balance>=0),
 created_at timestamptz not null default now()
);
create table if not exists public.sales(
 id bigint generated always as identity primary key,
 created_at timestamptz not null default now(),
 seller_id uuid not null references public.profiles(id),
 customer_id bigint references public.customers(id),
 method text not null check(method in ('Efectivo','Tarjeta','Transferencia','Crédito')),
 subtotal numeric(12,2) not null,
 discount numeric(12,2) not null default 0,
 total numeric(12,2) not null,
 received numeric(12,2),
 change_due numeric(12,2) not null default 0
);
create table if not exists public.sale_items(
 id bigint generated always as identity primary key,
 sale_id bigint not null references public.sales(id) on delete cascade,
 product_id bigint not null references public.products(id),
 qty integer not null check(qty>0),
 unit_price numeric(12,2) not null,
 unit_cost numeric(12,2) not null
);
create table if not exists public.purchases(
 id bigint generated always as identity primary key,
 product_id bigint not null references public.products(id),
 supplier text not null,
 qty integer not null check(qty>0),
 unit_cost numeric(12,2) not null check(unit_cost>=0),
 created_by uuid not null references public.profiles(id),
 created_at timestamptz not null default now()
);
create table if not exists public.expenses(
 id bigint generated always as identity primary key,
 description text not null,
 category text not null,
 method text not null,
 amount numeric(12,2) not null check(amount>0),
 created_by uuid not null references public.profiles(id),
 created_at timestamptz not null default now()
);
create table if not exists public.cash_sessions(
 id bigint generated always as identity primary key,
 cashier_id uuid not null references public.profiles(id),
 opened_at timestamptz not null default now(),
 opening numeric(12,2) not null check(opening>=0),
 closed_at timestamptz,
 counted numeric(12,2),
 expected numeric(12,2)
);
create unique index if not exists unique_open_cash_per_cashier on public.cash_sessions(cashier_id) where closed_at is null;
create table if not exists public.cash_movements(
 id bigint generated always as identity primary key,
 session_id bigint not null references public.cash_sessions(id),
 created_by uuid not null references public.profiles(id),
 direction text not null check(direction in ('in','out')),
 reason text not null,
 amount numeric(12,2) not null check(amount>0),
 created_at timestamptz not null default now()
);
alter table public.profiles enable row level security;
alter table public.products enable row level security;
alter table public.customers enable row level security;
alter table public.sales enable row level security;
alter table public.sale_items enable row level security;
alter table public.purchases enable row level security;
alter table public.expenses enable row level security;
alter table public.cash_sessions enable row level security;
alter table public.cash_movements enable row level security;
drop policy if exists profiles_read on public.profiles;
create policy profiles_read on public.profiles for select to authenticated using (id=auth.uid() or public.is_admin());
drop policy if exists profiles_admin_edit on public.profiles;
create policy profiles_admin_edit on public.profiles for update to authenticated using(public.is_admin()) with check(public.is_admin());
drop policy if exists products_read on public.products;
create policy products_read on public.products for select to authenticated using(public.is_active());
drop policy if exists products_admin_insert on public.products;
create policy products_admin_insert on public.products for insert to authenticated with check(public.is_admin());
drop policy if exists products_admin_update on public.products;
create policy products_admin_update on public.products for update to authenticated using(public.is_admin()) with check(public.is_admin());
drop policy if exists customers_read on public.customers;
create policy customers_read on public.customers for select to authenticated using(public.is_active());
drop policy if exists customers_insert on public.customers;
create policy customers_insert on public.customers for insert to authenticated with check(public.is_active());
drop policy if exists customers_update on public.customers;
create policy customers_update on public.customers for update to authenticated using(public.is_admin()) with check(public.is_admin());
drop policy if exists sales_read on public.sales;
create policy sales_read on public.sales for select to authenticated using(public.is_active() and (public.is_admin() or seller_id=auth.uid()));
drop policy if exists items_read on public.sale_items;
create policy items_read on public.sale_items for select to authenticated using(public.is_active() and exists(select 1 from public.sales s where s.id=sale_id and (public.is_admin() or s.seller_id=auth.uid())));
drop policy if exists purchases_read on public.purchases;
create policy purchases_read on public.purchases for select to authenticated using(public.is_admin());
drop policy if exists expenses_read on public.expenses;
create policy expenses_read on public.expenses for select to authenticated using(public.is_admin() or created_by=auth.uid());
drop policy if exists sessions_read on public.cash_sessions;
create policy sessions_read on public.cash_sessions for select to authenticated using(public.is_admin() or cashier_id=auth.uid());
drop policy if exists movements_read on public.cash_movements;
create policy movements_read on public.cash_movements for select to authenticated using(public.is_admin() or created_by=auth.uid());

-- Privileged writes only through validated RPC functions.
create or replace function public.complete_sale(p_items jsonb,p_method text,p_customer bigint default null,p_discount numeric default 0,p_received numeric default null)
returns bigint language plpgsql security definer set search_path='' as $$
declare x jsonb; prod public.products%rowtype; amount numeric(12,2):=0; total_amount numeric(12,2); sale_id bigint; customer public.customers%rowtype; quantity int;
begin
 if not public.is_active() then raise exception 'Usuario no autorizado'; end if;
 if not exists(select 1 from public.cash_sessions where cashier_id=auth.uid() and closed_at is null) then raise exception 'Debes abrir caja'; end if;
 if p_method not in ('Efectivo','Tarjeta','Transferencia','Crédito') then raise exception 'Método inválido'; end if;
 if jsonb_typeof(p_items)<>'array' or jsonb_array_length(p_items)=0 or jsonb_array_length(p_items)>100 then raise exception 'Ticket inválido'; end if;
 if p_discount is null or p_discount<0 then raise exception 'Descuento inválido'; end if;
 for x in select value from jsonb_array_elements(p_items) loop
  quantity:=coalesce((x->>'qty')::int,0);
  if quantity<=0 then raise exception 'Cantidad inválida'; end if;
  select * into prod from public.products where id=(x->>'id')::bigint and active for update;
  if not found or prod.stock<quantity then raise exception 'Existencia insuficiente para %',coalesce(prod.name,'producto'); end if;
  amount:=amount+prod.price*quantity;
 end loop;
 if p_discount>amount then raise exception 'El descuento supera el subtotal'; end if;
 total_amount:=amount-p_discount;
 if p_method='Efectivo' and (p_received is null or p_received<total_amount) then raise exception 'Pago en efectivo insuficiente'; end if;
 if p_method='Crédito' then
  if p_customer is null then raise exception 'Selecciona un cliente'; end if;
  select * into customer from public.customers where id=p_customer for update;
  if not found or customer.balance+total_amount>customer.credit_limit then raise exception 'Límite de crédito insuficiente'; end if;
  update public.customers set balance=balance+total_amount where id=p_customer;
 end if;
 insert into public.sales(seller_id,customer_id,method,subtotal,discount,total,received,change_due)
 values(auth.uid(),p_customer,p_method,amount,p_discount,total_amount,p_received,case when p_method='Efectivo' then p_received-total_amount else 0 end) returning id into sale_id;
 for x in select value from jsonb_array_elements(p_items) loop
  quantity:=(x->>'qty')::int;
  select * into prod from public.products where id=(x->>'id')::bigint for update;
  update public.products set stock=stock-quantity where id=prod.id;
  insert into public.sale_items(sale_id,product_id,qty,unit_price,unit_cost) values(sale_id,prod.id,quantity,prod.price,prod.cost);
 end loop;
 return sale_id;
end $$;
create or replace function public.register_purchase(p_product bigint,p_supplier text,p_qty integer,p_cost numeric)
returns bigint language plpgsql security definer set search_path='' as $$
declare new_id bigint;
begin
 if not public.is_admin() then raise exception 'Solo administradores'; end if;
 if p_qty<=0 or p_cost<0 or length(trim(p_supplier))=0 then raise exception 'Datos inválidos'; end if;
 update public.products set stock=stock+p_qty,cost=p_cost where id=p_product;
 if not found then raise exception 'Producto inexistente'; end if;
 insert into public.purchases(product_id,supplier,qty,unit_cost,created_by) values(p_product,p_supplier,p_qty,p_cost,auth.uid()) returning id into new_id;
 return new_id;
end $$;
create or replace function public.open_cash(p_opening numeric) returns bigint language plpgsql security definer set search_path='' as $$
declare new_id bigint;
begin
 if not public.is_active() or p_opening is null or p_opening<0 then raise exception 'No autorizado o fondo inválido'; end if;
 insert into public.cash_sessions(cashier_id,opening) values(auth.uid(),p_opening) returning id into new_id;return new_id;
end $$;
create or replace function public.cash_movement(p_direction text,p_reason text,p_amount numeric) returns bigint language plpgsql security definer set search_path='' as $$
declare sid bigint; new_id bigint;
begin
 if not public.is_active() or p_direction not in ('in','out') or p_amount<=0 or length(trim(p_reason))=0 then raise exception 'Movimiento inválido'; end if;
 select id into sid from public.cash_sessions where cashier_id=auth.uid() and closed_at is null;
 if sid is null then raise exception 'Caja cerrada'; end if;
 insert into public.cash_movements(session_id,created_by,direction,reason,amount) values(sid,auth.uid(),p_direction,p_reason,p_amount) returning id into new_id;return new_id;
end $$;
create or replace function public.register_expense(p_description text,p_category text,p_method text,p_amount numeric) returns bigint language plpgsql security definer set search_path='' as $$
declare new_id bigint;
begin
 if not public.is_active() or p_amount<=0 or length(trim(p_description))=0 then raise exception 'Gasto inválido'; end if;
 insert into public.expenses(description,category,method,amount,created_by) values(p_description,p_category,p_method,p_amount,auth.uid()) returning id into new_id;return new_id;
end $$;
create or replace function public.close_cash(p_counted numeric) returns bigint language plpgsql security definer set search_path='' as $$
declare s public.cash_sessions%rowtype; expected_total numeric(12,2); in_total numeric(12,2); out_total numeric(12,2);
begin
 if not public.is_active() or p_counted<0 then raise exception 'Cierre inválido'; end if;
 select * into s from public.cash_sessions where cashier_id=auth.uid() and closed_at is null for update;
 if not found then raise exception 'No hay caja abierta'; end if;
 select coalesce(sum(total),0) into in_total from public.sales where seller_id=auth.uid() and method='Efectivo' and created_at>=s.opened_at;
 select coalesce(sum(amount*(case when direction='in' then 1 else -1 end)),0) into out_total from public.cash_movements where session_id=s.id;
 expected_total:=s.opening+in_total+out_total;
 select expected_total-coalesce(sum(amount),0) into expected_total from public.expenses where created_by=auth.uid() and method='Efectivo' and created_at>=s.opened_at;
 update public.cash_sessions set closed_at=now(),counted=p_counted,expected=expected_total where id=s.id;
 return s.id;
end $$;
revoke all on function public.complete_sale(jsonb,text,bigint,numeric,numeric), public.register_purchase(bigint,text,integer,numeric), public.open_cash(numeric),public.cash_movement(text,text,numeric),public.register_expense(text,text,text,numeric),public.close_cash(numeric) from public;
grant execute on function public.complete_sale(jsonb,text,bigint,numeric,numeric), public.register_purchase(bigint,text,integer,numeric), public.open_cash(numeric),public.cash_movement(text,text,numeric),public.register_expense(text,text,text,numeric),public.close_cash(numeric) to authenticated;
-- Primer admin: crear primero el usuario en Authentication > Users, luego ejecutar:
-- update public.profiles set role='admin' where id=(select id from auth.users where email='TU_CORREO_ADMIN');
-- Los demás usuarios se crean desde Authentication > Users (por invitación), rol seller automáticamente.
-- Catálogo DE EJEMPLO, precios ficticios editables. No ejecutar sobre inventario comercial existente.
insert into public.products(code,name,category,type,compat,cost,price,stock,min) values
('740000001101','Pastillas de freno RX','Frenos','moto','Yamaha YBR / Suzuki GN',42,75,18,8),
('740000001102','Filtro de aceite 15410','Motor','moto','Honda CB / XR',27,55,30,10),
('740000001103','Cable clutch universal','Transmisión','tuctuc','TVS King / Bajaj RE',25,55,22,12),
('740000001104','Bombillo LED H4 12V','Eléctrico','auto','Universal / Toyota',48,80,24,6),
('740000001105','Kit cadena y sprocket','Transmisión','moto','Honda CG / Yamaha YBR',138,225,12,5),
('740000001106','Zapatas traseras Bajaj','Frenos','tuctuc','Bajaj RE 4S',62,110,18,8),
('740000001107','Bujía C7HSA compatible','Motor','moto','Moto / Tuc tuc',14,28,36,15),
('740000001108','Filtro de aire Corolla','Motor','auto','Toyota Corolla 2009-2019',55,95,9,5),
('740000001109','Retenedor de llanta TVS','Suspensión','tuctuc','TVS King',18,38,15,6),
('740000001110','Aceite 4T 20W50 1L','Lubricantes','moto','Moto 4 tiempos',32,55,40,12),
('740000001111','Batería 12V 7Ah','Eléctrico','moto','Motocicletas 12V',125,195,10,4),
('740000001112','Espejo lateral universal','Carrocería','tuctuc','Bajaj RE / TVS King',28,50,16,6),
('740000001113','Pastillas de freno Corolla','Frenos','auto','Toyota Corolla',115,190,12,4),
('740000001114','Cable acelerador Bajaj','Transmisión','tuctuc','Bajaj RE',22,42,28,8),
('740000001115','Rodamiento de rueda 6202','Suspensión','moto','Universal 6202',16,35,30,10)
on conflict(code) do nothing;
