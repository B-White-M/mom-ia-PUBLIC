# Purchase Intent Detected

## Overview

This workflow executes after a purchase intent has been identified.

Its purpose is to:

1. Confirm the purchase to the customer.
2. Generate an internal sales summary.
3. Send the confirmation via WhatsApp.
4. Persist the interaction in Supabase.

This is where conversation becomes commerce.

<img width="3163" height="1416" alt="image" src="https://github.com/user-attachments/assets/27083e98-7f1f-4c32-8ab1-bd230a02093a" />

---

## Trigger

Executed by another workflow with:

- wa_id  
- thread_id  
- customer metadata  
- relevant_products  
- intencion_compra  

---

## Flow Summary

### 1. Read Conversation Thread

Retrieves the full OpenAI thread history and reconstructs a clean conversation log (customer + assistant messages).

---

### 2. Dual LLM Execution

**Customer Confirmation**
- Short, positive, human confirmation message.
- Acknowledges the purchase and takes ownership of the sale.

**Internal Sales Summary**
- Max 4 lines.
- Includes:
  - Customer name
  - Selected products
  - Purchase intention
  - Suggested action

This separates customer-facing communication from operational reporting.

---

### 3. WhatsApp Dispatch

Sends confirmation message through Twilio:

- To: Customer
- From: Store number

---

### 4. Database Logging

Writes:

- Customer confirmation
- Internal sales summary

Supabase remains the source of truth.

---
