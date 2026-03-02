# 02 — Message Brain (Intent, Memory & RAG Orchestration)

## Overview

This workflow is the cognitive core of MOM IA.

It processes normalized messages stored in the bucket layer and performs:

- Customer state resolution
- Thread lifecycle management
- Intent detection
- Embedding generation
- Vector similarity search (RAG)
- Context enrichment
- LLM reasoning
- Structured persistence of conversation state

It transforms raw normalized input into contextual, memory-aware responses.

---

## Architectural Position

Normalization Layer → Message Brain → Response Dispatch

This module is responsible for reasoning and state evolution.

---

## Step 1 — Retrieve Oldest Message from Bucket

Database Function:
`move_oldest_bucket_to_chats_threads()`

Purpose:
- Concurrency-safe queue processing
- Moves oldest message into persistent thread table
- Prevents duplicate processing
- Ensures idempotency

This acts as a worker mechanism using:
`FOR UPDATE SKIP LOCKED`

---

## Step 2 — Customer & Thread Resolution

Checks:

- Does the customer already exist?
- Is there an active thread?
- Has 24h window expired?

If needed:
- Creates new thread
- Resets memory context

This ensures deterministic conversation lifecycle control.

<img width="3575" height="750" alt="image" src="https://github.com/user-attachments/assets/0c2cd25c-b442-4f1e-9afd-699a051ae9e0" />

---

## Step 3 — Intent Detection

Intent categories may include:

- Question
- Purchase intent
- Confirm purchase
- Unknown product
- Human escalation
- Spam attempt

Design Decision:
Intent detection may be partially rule-based before LLM reasoning to improve determinism.

Intent confidence is persisted.

---

## Step 4 — Embedding Generation

For each normalized message:

- Generates vector embedding
- Stores in database
- Enables similarity search

Technology:
pgvector extension in Supabase (PostgreSQL)

<img width="2808" height="928" alt="image" src="https://github.com/user-attachments/assets/0967c6bf-4c03-4414-b723-fc8e556ec3cf" />

---

## Step 5 — Vector Similarity Search (RAG)

Functions used:

- `rollback_search_chats_threads`
- `rollback_search_bucket_im`

Purpose:

- Retrieve semantically similar past messages
- Maintain contextual continuity
- Support rollback memory mechanism
- Enhance LLM grounding

Similarity threshold applied.

---

## Step 6 — Context Construction

Builds structured prompt:

- Latest user message
- Last 2 exchanges
- Inventory context
- Similar past embeddings
- Assistant tone
- Detected intent

This becomes the LLM input.

<img width="2711" height="660" alt="image" src="https://github.com/user-attachments/assets/67c3f974-d0d9-4505-8cf9-be651f8409da" />

---

## Step 7 — LLM Processing

OpenAI API is invoked with:

- Structured system role
- Context window
- Inventory RAG injection
- Intent-aware framing

Returns assistant response.

---

## Step 8 — State Persistence

Updates:

- chats_threads
- embedding
- intent
- total_tokens
- context summary
- rollback context
- sales indicators

This ensures stateful conversation modeling.

---

## Step 9 — Sales Handling (If Triggered)

If intent == purchase:

- Calculates total
- Prepares payment instructions
- Flags human confirmation if needed
- Logs transaction metadata

This module does not dispatch payment confirmation — that belongs to downstream flow.

<img width="1599" height="1267" alt="image" src="https://github.com/user-attachments/assets/3e1cfb25-819a-4845-b2fa-c2f0b6e2d3bb" />

---

# Architectural Responsibilities

The Message Brain is responsible for:

- Deterministic state transitions
- Memory persistence
- Vector-based retrieval
- Intent modeling
- Context compression
- Conversation lifecycle management

It does NOT:

- Handle webhook ingestion
- Handle Twilio response dispatch
- Handle infrastructure concerns

---

## System Role

If normalization is the "ears",
the Message Brain is the "cortex".

It decides what the message means,
what memory matters,
and how the assistant should respond.

<img width="3727" height="948" alt="image" src="https://github.com/user-attachments/assets/4a48ec92-c7ec-4a5c-841f-3328125e0f0f" />
