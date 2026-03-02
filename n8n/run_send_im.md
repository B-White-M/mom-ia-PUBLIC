# Run message MOM (LLM Execution & WhatsApp Dispatch)

## Overview

This workflow is the execution layer of MOM IA.

It receives structured conversational context from the Message Brain and performs:

- LLM response generation
- Strict JSON validation
- Multi-message formatting
- WhatsApp dispatch via Twilio
- Database state update

This module transforms reasoning into real user-facing output.

---

## Architectural Position

Message Brain → Run MOM IA → WhatsApp Response → State Update

If the Message Brain decides what to say,
this workflow is responsible for saying it correctly.

---

## Trigger

### Execute Workflow Trigger

This workflow is invoked programmatically by another workflow.

It assumes that all required fields have already been prepared:
- message_received
- context_summary
- user_intent
- relevant_products
- products_asked
- assistant_tone
- last_2_received
- last_2_send
- rollback_context
- id_unique
- wa_id
- tienda_tel

This separation ensures deterministic orchestration.

<img width="3173" height="852" alt="image" src="https://github.com/user-attachments/assets/9a39fe68-dcc2-4f05-87a1-e64567d970c2" />

---

## Step 1 — Field Structuring

Node: `thread_&_message`

Maps all required conversation fields into a clean internal structure.

This guarantees that the LLM receives a fully controlled prompt schema.

---

## Step 2 — LLM Invocation

Node: `deteccion_de_intencion`  
(OpenAI Responses API)

Model:
`gpt-4.1-mini`

Characteristics:

- Temperature = 0 (deterministic behavior)
- Max tokens controlled
- Strict JSON output enforced

System prompt enforces:

- No hallucination
- No internal system leakage
- No mentioning architecture
- Use only RELEVANT_PRODUCTS
- Maximum 1–2 WhatsApp-style messages
- JSON-only output format

This ensures safe and structured output.

---

## Step 3 — JSON Parsing & Validation

Node: `Code`

- Parses LLM output
- Extracts `messages` array
- Converts into:
  - message1
  - message2
  - message3

This guarantees structure even if LLM returns multiple segments.

No free-text is allowed beyond strict JSON schema.

---

## Step 4 — Message Assembly

Node: `join_final_message`

Merges structured messages with thread metadata.

Node: `Code1`

- Extracts `id_unique`
- Attaches ID tag to outgoing message
- Preserves wa_id and tienda_tel

This enables traceability between:
- Database row
- WhatsApp message

---

## Step 5 — Controlled Message Loop

Node: `Loop Over Items`

Handles multi-message output safely.

Node: `Wait`

Introduces delay between messages to prevent:

- Twilio rate limits
- Spam detection
- Overlapping delivery

This ensures human-like pacing.

---

## Step 6 — WhatsApp Dispatch

Node: `send_whatsapp`

POST request to Twilio API.

Parameters:
- To (customer)
- From (store number)
- Body (LLM-generated message)

No secrets are exposed in repository version.

---

## Step 7 — Database Update

Node: `supabase__send_message`

Updates `Chats_Threads`:

- message_send field
- Preserves thread integrity
- Ensures full conversation audit trail

The database remains the source of truth.

---

# System Role

If Normalization is the ears,
and Message Brain is the cortex,

Run MOM IA is the voice.

It speaks — but only what the brain has carefully decided.
