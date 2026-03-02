-- =========================================================
-- MOM IA — Database Schema (Supabase / PostgreSQL)
-- NOTE:
-- This schema file is written in English for public showcase purposes.
-- It was generated from live Supabase metadata.
-- Column names and casing are preserved exactly as in production.
-- =========================================================
-- ---------------------------------------------------------
-- Table: Chats_Threads
-- Purpose: Persisted conversation + memory state per customer.
-- ---------------------------------------------------------
create table if not exists public."Chats_Threads" (
  wa_id text not null,
  fecha_creacion timestamptz not null,
  nombre_cliente text null,
  origen_mensaje text null,
  message_received text null,
  message_send text null,
  tienda_tel text null,
  embedding vector null,
  assistant_tone text null,
  user_intent text null,
  intent_confidence numeric null,
  catalog_sent_at timestamp null,
  total_sales_value numeric null,
  payment_confirmed boolean null,
  resumen_contexto text null,
  "Inventory_send" text null,
  products_asked text null,
  force_re_send boolean null,
  last_2_received text null,
  last_2_send text null,
  total_tokens numeric null,
  id_unique text not null,
  rollback_context text null,
  human_request boolean null,

  constraint chats_threads_pk primary key (id_unique)
);
