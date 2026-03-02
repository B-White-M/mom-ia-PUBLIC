# Complaint Handling (Escalation & Reassurance Layer)

## Overview

This workflow activates when a complaint intention is detected.

Its purpose is to:

1. Confirm the presence of a complaint.
2. Respond calmly and reassuringly to the customer.
3. Generate an internal complaint summary.
4. Log everything in Supabase.
5. Send the response via WhatsApp.

This module protects trust and prevents escalation.

<img width="3282" height="1490" alt="image" src="https://github.com/user-attachments/assets/fa9d5eb1-3282-45ec-8741-baacee70212b" />

---

## Trigger

Executed by another workflow with:

- wa_id  
- thread_id  
- customer metadata  
- conversation context  

---

## Flow Summary

### 1. Read Full Conversation

Retrieves the full OpenAI thread history and reconstructs a clean customer–assistant conversation log.

---

### 2. Dual LLM Execution

**Customer Response**
- Detects if the message expresses a clear complaint.
- Sends a calm, empathetic response.
- Explains that the situation will be escalated for review.

**Internal Complaint Summary**
- Max 4 lines.
- Includes:
  - Customer name
  - Relevant products
  - Number of messages
  - Reason for complaint

This separates emotional handling from operational tracking.

---

### 3. WhatsApp Dispatch

Sends the reassurance message to the customer via Twilio.

---

### 4. Database Logging

Writes:

- Complaint response
- Structured internal summary

Supabase remains the source of truth.

---
