-- =========================================================
-- MOM IA — Database Functions (Supabase / PostgreSQL)
-- Purpose: core orchestration helpers for queue processing,
--          retrieval (RAG), and computed fields.
-- Notes:
--  - Public showcase version (sanitized).
-- =========================================================
-- =========================================================
-- 1) Queue Worker: Move oldest bucket record -> chats_threads
-- Concurrency-safe using FOR UPDATE SKIP LOCKED
-- Idempotent insert using ON CONFLICT to avoid duplicates
-- =========================================================
create or replace function public.move_oldest_bucket_to_chats_threads()
returns jsonb
language plpgsql
as $$
declare
  r record;
  inserted record;
begin
  -- Take oldest row from bucket (concurrency-safe)
  select *
  into r
  from public.bucket_im_clientes
  order by fecha_creacion asc
  limit 1
  for update skip locked;

  if not found then
    return jsonb_build_object('moved', false, 'reason', 'bucket_empty');
  end if;

  -- Insert into final table (idempotent)
  insert into public.chats_threads (
    wa_id,
    fecha_creacion,
    nombre_cliente,
    origen_mensaje,
    message_received,
    tienda_tel,
    id_unique,
    embedding,
    assistant_tone,
    user_intent,
    intent_confidence,
    total_tokens,
    inventory_send,
    resumen_contexto,
    last_2_received,
    last_2_send,
    products_asked,
    rollback_context,
    human_request,
    force_re_send
  )
  values (
    r.wa_id,
    r.fecha_creacion,
    r.nombre_cliente,
    r.origen_mensaje,
    r.message_received,
    r.tienda_tel,
    r.id_unique,
    r.embedding,
    r.assistant_tone,
    r.user_intent,
    r.intent_confidence,
    r.total_tokens,
    r.inventory_send,
    r.resumen_contexto,
    r.last_2_received,
    r.last_2_send,
    r.products_asked,
    r.rollback_context,
    r.human_request,
    r.force_re_send
  )
  on conflict (id_unique) do nothing
  returning * into inserted;

  -- If it didn't insert (duplicate), do not delete from bucket
  if inserted is null then
    return jsonb_build_object(
      'moved', false,
      'reason', 'duplicate_id_unique',
      'id_unique', r.id_unique
    );
  end if;

  -- Delete processed item from bucket
  delete from public.bucket_im_clientes
  where id_unique = r.id_unique;

  return jsonb_build_object('moved', true, 'chats_threads_row', to_jsonb(inserted));
end;
$$;


-- =========================================================
-- 2) Vector Similarity Search (RAG) — chats_threads
-- Requires pgvector extension and "embedding" vector column.
-- =========================================================
drop function if exists public.rollback_search_chats_threads(
  text, text, text, double precision, integer
);

create function public.rollback_search_chats_threads(
  p_tienda_tel text,
  p_wa_id text,
  p_query_text text,
  p_match_threshold double precision,
  p_match_count integer
)
returns table (
  id_unique uuid,
  fecha_creacion timestamptz,
  resumen_contexto text,
  message_received text,
  similarity double precision
)
language sql stable
as $$
  with q as (
    select (p_query_text)::vector as query_vec
  )
  select
    ct.id_unique,
    ct.fecha_creacion,
    ct.resumen_contexto,
    ct.message_received,
    1 - (ct.embedding <=> q.query_vec) as similarity
  from public.chats_threads ct
  cross join q
  where ct.tienda_tel = p_tienda_tel
    and ct.wa_id = p_wa_id
    and ct.embedding is not null
    and 1 - (ct.embedding <=> q.query_vec) >= p_match_threshold
  order by ct.embedding <=> q.query_vec
  limit p_match_count;
$$;


-- =========================================================
-- 3) Vector Similarity Search (RAG) — bucket_im_clientes
-- Useful for "pre-commit" rollback search before persistence.
-- =========================================================
drop function if exists public.rollback_search_bucket_im(
  text, text, text, double precision, integer
);

create function public.rollback_search_bucket_im(
  p_tienda_tel text,
  p_wa_id text,
  p_query_text text,
  p_match_threshold double precision,
  p_match_count integer
)
returns table (
  id_unique uuid,
  fecha_creacion timestamptz,
  resumen_contexto text,
  message_received text,
  similarity double precision
)
language sql stable
as $$
  with q as (
    select (p_query_text)::vector as query_vec
  )
  select
    b.id_unique,
    b.fecha_creacion,
    b.resumen_contexto,
    b.message_received,
    1 - (b.embedding <=> q.query_vec) as similarity
  from public.bucket_im_clientes b
  cross join q
  where b.tienda_tel = p_tienda_tel
    and b.wa_id = p_wa_id
    and b.embedding is not null
    and 1 - (b.embedding <=> q.query_vec) >= p_match_threshold
  order by b.embedding <=> q.query_vec
  limit p_match_count;
$$;


-- =========================================================
-- 4) Loyalty Score (Trigger Function)
-- Keeps "loyalty_score" consistent from "compras_realizadas".
-- =========================================================
create or replace function public.set_loyalty_score()
returns trigger
language plpgsql
as $$
begin
  new.loyalty_score :=
    case
      when coalesce(new.compras_realizadas, 0)::int >= 3 then 'muy alta'
      when coalesce(new.compras_realizadas, 0)::int = 2 then 'alta'
      when coalesce(new.compras_realizadas, 0)::int = 1 then 'media'
      else 'ninguna'
    end;

  return new;
end;
$$;

-- NOTE: The trigger itself should live in supabase/triggers.sql
-- so this file remains "functions only".
