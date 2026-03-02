# 01 — WhatsApp Ingestion & Normalization Layer

## Overview

This workflow is the entry point of MOM IA.

It receives inbound WhatsApp messages from Twilio and normalizes all input types (text, audio, image) into a single structured format before persisting into the message bucket.

This module ensures:

- Multi-modal input support (text / audio / image)
- Format standardization
- Security sanitization
- Country validation
- Duplicate prevention
- Structured persistence in Supabase

It acts as the ingestion + normalization boundary before intent routing and RAG processing.

<img width="3650" height="1207" alt="image" src="https://github.com/user-attachments/assets/cc7f256b-2f56-4d7b-a856-5d3245f57d61" />

---

## Trigger

### Webhook: `whatsapp-in`

Receives POST requests from Twilio when a WhatsApp message is delivered.

---

## Step 1 — Source Validation

### Twilio Account Verification
Ensures the message originates from the expected Twilio account.

### Country Filter (Costa Rica only)
Checks if `WaId` starts with `506`.

If not:
- Sends a rejection message.
- Stops execution.

Purpose:
Prevent unwanted international traffic and reduce abuse.

---

## Step 2 — Data Extraction

Node: `extract_data`

Extracted fields:

- numero_cliente
- wa_id
- mensaje_texto_final
- mensaje_tipo (text/audio/image)
- media_url
- timestamp (Costa Rica timezone)
- profile_name
- message_sid
- origin source
- account_sid

This step converts Twilio payload into structured internal fields.

---

## Step 3 — Input Type Routing

Node: `input_type` (Switch)

Routes based on:

- text
- audio
- image

This ensures modality-specific processing.

<img width="2587" height="1700" alt="image" src="https://github.com/user-attachments/assets/288b6507-5792-4b2a-90bf-1d19fbe0aa1e" />

---

# TEXT PATH

Node: `from_text_path`

- Directly assigns message body to `mensaje_texto_final`
- No transformation required

---

# AUDIO PATH

1. `download_audio`
   - Fetches media from Twilio

2. `switch_audio_to_text`
   - Sends audio to OpenAI Whisper API
   - Returns transcription

3. `merge_audio_text`
   - Ensures consistent output structure

4. `from_audio_path`
   - Sets final normalized text

Purpose:
Convert audio into text before further processing.

---

# IMAGE PATH

1. `download_image`
2. `save_low_cost_data`
   - Converts binary file to base64
3. `make_image_data_uri`
   - Creates data URI for OpenAI Vision
4. `openai_vision`
   - Performs OCR
   - Returns JSON with:
     - texto
     - resumen
5. `parseo_image`
6. `image_trim_code`
7. `image_txt_output`
8. `parseo_code`
9. `merge_image_text`

If image + text are both present:
- They are merged into a unified normalized message.

Purpose:
Extract textual meaning from images and standardize it.

---

## Step 4 — Duplicate Removal

Node: `Remove_duplicates`

Prevents:

- Repeated webhook retries
- Double inserts
- Duplicate customer events

---

## Step 5 — Sanitization Layer

Node: `sanitize_input`

Removes:

- Curly brackets
- HTML tags
- Potential injection characters
- Excessive length (limit 500 chars)

Purpose:
Reduce prompt injection risk and malicious payloads.

---

## Step 6 — Output Preparation

Node: `prepare_output`

Final structured payload:

- numero_cliente
- mensaje_texto_final
- timestamp
- mensaje_tipo
- nombre_perfil
- tienda_tel

---

## Step 7 — Persistence (Message Bucket)

Node: `obtain_bucket` (Supabase)

Stores normalized message in:

`bucket_messages`

Fields persisted:

- wa_id
- fecha_creacion
- nombre_cliente
- origen_mensaje
- message_received
- tienda_tel

This table acts as a queue layer before:
- Intent detection
- Embedding generation
- Chat thread persistence

<img width="1346" height="414" alt="image" src="https://github.com/user-attachments/assets/15f3ced0-7012-4b3a-8d30-941dfba7d41d" />

---

# Architectural Role

This workflow acts as:

> Multi-modal ingestion boundary for MOM IA

Responsibilities:

- Input normalization
- Multi-format handling
- Security filtering
- Deduplication
- Pre-persistence buffering

It does NOT:

- Perform intent classification
- Perform RAG
- Execute sales logic

Those belong to downstream workflows.

---

# Design Decisions

- Audio is transcribed before intent detection to maintain single text pipeline.
- Image OCR returns structured JSON to maintain deterministic parsing.
- Sanitization occurs before DB write to reduce risk.
- Country validation prevents resource misuse.
- Bucket table separates ingestion from persistence logic.

---

# Future Improvements

- Rate limiting per wa_id
- Message batching (1.5 minute window aggregation)
- Automated language detection
- Enhanced spam pattern recognition

---

## Position in Overall Architecture

Twilio → n8n (Normalization) → Supabase Bucket → Intent Router → RAG → LLM → Response


<img width="3650" height="1207" alt="image" src="https://github.com/user-attachments/assets/cc7f256b-2f56-4d7b-a856-5d3245f57d61" />
