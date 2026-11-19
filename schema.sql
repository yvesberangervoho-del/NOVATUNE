-- NOVATUNE Supabase schema. Run in Supabase SQL Editor.
create extension if not exists pgcrypto;
create table if not exists public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 display_name text not null default 'Membre NOVATUNE',
 country text,
 bio text,
 role text not null default 'listener' check (role in ('listener','artist','admin')),
 artist_status text not null default 'not_requested' check (artist_status in ('not_requested','pending','approved','rejected')),
 created_at timestamptz not null default now()
);
create table if not exists public.tracks (
 id uuid primary key default gen_random_uuid(),
 artist_id uuid not null references public.profiles(id) on delete cascade,
 title text not null,
 genre text not null,
 audio_path text not null,
 cover_path text,
 status text not null default 'pending' check (status in ('pending','approved','rejected')),
 play_count bigint not null default 0,
 created_at timestamptz not null default now()
);
create table if not exists public.plans (
 id text primary key,
 name text not null,
 price_fcfa integer not null check(price_fcfa >= 0),
 billing_period text not null default 'month',
 active boolean not null default true
);
insert into public.plans(id,name,price_fcfa) values
 ('discovery','Découverte',1000),('premium','Premium',2000),('family','Famille',3500)
on conflict(id) do nothing;

alter table public.profiles enable row level security;
alter table public.tracks enable row level security;
alter table public.plans enable row level security;

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path=public
as $$ select exists(select 1 from public.profiles where id=auth.uid() and role='admin') $$;

create policy "profiles visible to owner and admin" on public.profiles for select
using (id=auth.uid() or public.is_admin());
create policy "user creates own profile" on public.profiles for insert
with check (id=auth.uid() and role<>'admin');
create policy "user updates own nonprivileged profile" on public.profiles for update
using (id=auth.uid() or public.is_admin())
with check ((id=auth.uid() and role<>'admin') or public.is_admin());

create policy "approved tracks public" on public.tracks for select
using (status='approved' or artist_id=auth.uid() or public.is_admin());
create policy "approved artists can submit tracks" on public.tracks for insert
with check (artist_id=auth.uid() and status='pending' and exists(select 1 from public.profiles p where p.id=auth.uid() and p.artist_status='approved'));
create policy "admin moderates tracks" on public.tracks for update
using (public.is_admin()) with check (public.is_admin());

create policy "plans are public" on public.plans for select using(active=true);

-- Create private audio bucket and public cover bucket in Storage dashboard:
-- audio-private: private, max file size e.g. 30MB, allowed audio/mpeg,audio/mp4,audio/wav,audio/aac,audio/ogg
-- covers: public, allowed image/jpeg,image/png,image/webp
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values ('audio-private','audio-private',false,31457280,array['audio/mpeg','audio/mp4','audio/wav','audio/aac','audio/ogg','audio/x-wav']),
       ('covers','covers',true,5242880,array['image/jpeg','image/png','image/webp'])
on conflict(id) do nothing;

create policy "artist uploads own audio" on storage.objects for insert to authenticated
with check (bucket_id='audio-private' and (storage.foldername(name))[1]=auth.uid()::text);
create policy "artist reads own audio or admin" on storage.objects for select to authenticated
using (bucket_id='audio-private' and ((storage.foldername(name))[1]=auth.uid()::text or public.is_admin()));
create policy "artist uploads own covers" on storage.objects for insert to authenticated
with check (bucket_id='covers' and (storage.foldername(name))[1]=auth.uid()::text);
create policy "public reads covers" on storage.objects for select
using (bucket_id='covers');

-- Signed stream URL: only approved tracks can be streamed; admins may inspect pending content.
create or replace function public.get_track_stream_url(track_uuid uuid)
returns text language plpgsql security invoker set search_path=public,storage
as $$
declare p text; s text; result text;
begin
 select audio_path,status into p,s from public.tracks where id=track_uuid;
 if p is null then raise exception 'Track not found'; end if;
 if s<>'approved' and not public.is_admin() then raise exception 'Track not available'; end if;
 select (storage.create_signed_url('audio-private',p,3600)).signed_url into result;
 return result;
end $$;

create or replace function public.record_track_play(track_uuid uuid)
returns void language plpgsql security definer set search_path=public
as $$ begin update public.tracks set play_count=play_count+1 where id=track_uuid and status='approved'; end $$;

-- IMPORTANT: after creating your own account, promote that UUID manually from SQL Editor:
-- update public.profiles set role='admin' where id='YOUR_AUTH_USER_UUID';
-- Also set artist role after artist approval if desired:
-- update public.profiles set role='artist', artist_status='approved' where id='ARTIST_UUID';
