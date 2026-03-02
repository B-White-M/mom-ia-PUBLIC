-- =========================================================
-- NOTE:
-- This file was translated to English for public showcase purposes.
-- Original production implementation may use localized naming.
-- =========================================================
-- =========================================================
-- MOM IA — Database Functions (Supabase / PostgreSQL)
-- Purpose: Core orchestration helpers for queue processing,
--          retrieval (RAG), and computed fields.
-- Notes:
--  - Public showcase version (sanitized).
-- =========================================================
-- =========================================================
-- 1) Queue Worker: Move oldest bucket record -> chat_threads
-- Concurrency-safe using FOR UPDATE SKIP LOCKED
-- Idempotent insert using ON CONFLICT to avoid duplicates
-- =========================================================
create or replace function public.move_oldest_bucket_to_chat_threads()
returns jsonb
language plpgsql
as $$
declare
  r record;
  inserted record;
begin
  -- Take oldest row from message bucket (concurrency-safe)
  select *
  into r
  from public.message_bucket
  order by created_at asc
  limit 1
  for update skip locked;

  if not found then
    return jsonb_build_object('moved', false, 'reason', 'bucket_empty');
  end if;

  -- Insert into final table (idempotent)
  insert into public.chat_threads (
    wa_id,
    created_at,
    customer_name,
    message_origin,
    message_received,
    store_phone,
    id_unique,
    embedding,
    assistant_tone,
    user_intent,
    intent_confidence,
    total_tokens,
    inventory_sent,
    context_summary,
    last_2_received,
    last_2_sent,
    products_requested,
    rollback_context,
    human_request,
    force_resend
  )
  values (
    r.wa_id,
    r.created_at,
    r.customer_name,
    r.message_origin,
    r.message_received,
    r.store_phone,
    r.id_unique,
    r.embedding,
    r.assistant_tone,
    r.user_intent,
    r.intent_confidence,
    r.total_tokens,
    r.inventory_sent,
    r.context_summary,
    r.last_2_received,
    r.last_2_sent,
    r.products_requested,
    r.rollback_context,
    r.human_request,
    r.force_resend
  )
  on conflict (id_unique) do nothing
  returning * into inserted;

  -- If not inserted (duplicate), do not delete from bucket
  if inserted is null then
    return jsonb_build_object(
      'moved', false,
      'reason', 'duplicate_id_unique',
      'id_unique', r.id_unique
    );
  end if;

  -- Delete processed item from bucket
  delete from public.message_bucket
  where id_unique = r.id_unique;

  return jsonb_build_object('moved', true, 'chat_threads_row', to_jsonb(inserted));
end;
$$;



-- =========================================================
-- 2) Vector Similarity Search (RAG) — chat_threads
-- Requires pgvector extension and "embedding" vector column.
-- =========================================================
drop function if exists public.rollback_search_chat_threads(
  text, text, text, double precision, integer
);

create function public.rollback_search_chat_threads(
  p_store_phone text,
  p_wa_id text,
  p_query_text text,
  p_match_threshold double precision,
  p_match_count integer
)
returns table (
  id_unique uuid,
  created_at timestamptz,
  context_summary text,
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
    ct.created_at,
    ct.context_summary,
    ct.message_received,
    1 - (ct.embedding <=> q.query_vec) as similarity
  from public.chat_threads ct
  cross join q
  where ct.store_phone = p_store_phone
    and ct.wa_id = p_wa_id
    and ct.embedding is not null
    and 1 - (ct.embedding <=> q.query_vec) >= p_match_threshold
  order by ct.embedding <=> q.query_vec
  limit p_match_count;
$$;



-- =========================================================
-- 3) Vector Similarity Search (RAG) — message_bucket
-- Useful for pre-persistence rollback search.
-- =========================================================
drop function if exists public.rollback_search_message_bucket(
  text, text, text, double precision, integer
);

create function public.rollback_search_message_bucket(
  p_store_phone text,
  p_wa_id text,
  p_query_text text,
  p_match_threshold double precision,
  p_match_count integer
)
returns table (
  id_unique uuid,
  created_at timestamptz,
  context_summary text,
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
    b.created_at,
    b.context_summary,
    b.message_received,
    1 - (b.embedding <=> q.query_vec) as similarity
  from public.message_bucket b
  cross join q
  where b.store_phone = p_store_phone
    and b.wa_id = p_wa_id
    and b.embedding is not null
    and 1 - (b.embedding <=> q.query_vec) >= p_match_threshold
  order by b.embedding <=> q.query_vec
  limit p_match_count;
$$;



-- =========================================================
-- 4) Loyalty Score Trigger Function
-- Keeps loyalty_score consistent based on purchase_count.
-- =========================================================
create or replace function public.set_loyalty_score()
returns trigger
language plpgsql
as $$
begin
  new.loyalty_score :=
    case
      when coalesce(new.purchase_count, 0)::int >= 3 then 'very_high'
      when coalesce(new.purchase_count, 0)::int = 2 then 'high'
      when coalesce(new.purchase_count, 0)::int = 1 then 'medium'
      else 'none'
    end;

  return new;
end;
$$;

-- NOTE:
-- The trigger definition itself should live in supabase/triggers.sql
-- so this file remains focused on functions only.
