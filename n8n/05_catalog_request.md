# Catalog Request (PDF + Conversational Continuation)

## Overview

This workflow handles catalog requests.

Its purpose is to:

1. Send the catalog PDF.
2. Confirm naturally that the catalog was sent.
3. Continue the conversation using context.
4. Log the interaction in Supabase.

This module maintains conversational flow while delivering assets.

<img width="3593" height="755" alt="image" src="https://github.com/user-attachments/assets/6effee83-7616-4c13-8553-3ed474cf22fb" />

---

## Trigger

Executed by another workflow with:

- Customer metadata
- Conversation context
- Relevant products
- Assistant tone
- id_unique

---

## Flow Summary

### 1. Retrieve Catalog PDF

Fetches the catalog file from Supabase.

Sends the PDF via WhatsApp with a short confirmation message.

---

### 2. LLM Conversational Continuation

Calls OpenAI (`gpt-4.1-mini`) with strict rules:

- Confirm catalog was sent.
- Continue the conversation naturally.
- Use only provided product data.
- No hallucinated stock, pricing, or policies.
- Maximum 1–2 short WhatsApp messages.
- JSON-only structured output.

---

### 3. Message Formatting

Parses the LLM JSON response into:

- message1
- message2
- message3 (if present)

Adds ID tagging for traceability.

---

### 4. WhatsApp Dispatch

Sends:

- Confirmation message
- Optional follow-up messages
- Controlled delay to avoid spam behavior

---

### 5. Database Update

Updates `Chats_Threads`:

- message_send
- catalog_sent_at

Supabase remains the source of truth.

---

## Responsibilities

This workflow:

- Sends the catalog PDF.
- Confirms delivery.
- Continues conversation naturally.
- Logs the interaction.

It does NOT:

- Detect intent.
- Process payments.
- Update inventory.
- Confirm purchases.

---

