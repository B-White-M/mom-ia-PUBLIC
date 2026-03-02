# MOM IA — Conversational Commerce Orchestrator

**AI-powered WhatsApp commerce system built on n8n, OpenAI and Supabase (PostgreSQL).**

MOM is an AI-driven orchestration system built around a Retrieval-Augmented Generation (RAG) architecture.  
It integrates real-time messaging, workflow automation, LLM-based reasoning and relational data modeling into a unified event-driven commerce platform.

---

## Overview

MOM operates as a real-time conversational sales assistant.  
It validates customer data, interprets intent, retrieves structured inventory context from Supabase (PostgreSQL), and guides the conversation toward a completed sale using controlled RAG-based responses.

The system ensures that product recommendations and decisions are grounded in structured database state rather than purely generative output.

---

## Architecture

### High-Level Flow

1. **Message Ingestion**  
   A WhatsApp message is received via Twilio webhook and forwarded to the n8n orchestration layer.

2. **Message Normalization Layer**  
   n8n transforms incoming payloads (text, audio or image) into a standardized text format:
   - Audio is transcribed to text
   - Image messages are converted into structured textual context
   - All inputs are normalized into a unified schema

3. **Intent Classification Layer**  
   The workflow evaluates user intent (question, purchase intent, vague inquiry, unknown product, etc.) and routes execution paths dynamically.

4. **Customer & Inventory Lookup**  
   Supabase (PostgreSQL) is queried to:
   - Validate if the customer already exists
   - Retrieve conversation thread metadata
   - Access structured inventory data

5. **Inventory Retrieval (RAG Layer)**  
   A Retrieval-Augmented Generation (RAG) strategy is used to fetch relevant products from Supabase before passing structured context to the language model.

6. **LLM Processing Layer**  
   OpenAI processes the normalized message plus structured inventory context and generates a response aligned with the defined sales strategy.

7. **Response Delivery**  
   The generated response is returned to the user via Twilio.

8. **State Persistence & Logging**  
   Conversations, inventory state changes and system logs are persisted in Supabase to ensure consistency and auditability.

---

## Data Model

MOM relies on a relational PostgreSQL schema (Supabase) designed to preserve state consistency, auditability and multi-tenant scalability.

### Core Entities

- `customers` → customer identity and metadata  
- `threads` → conversation continuity  
- `messages` → normalized inbound and outbound interactions  
- `inventory` → structured product catalog  
- `orders` → finalized purchase records  
- `logs` → system observability and diagnostics  

### Design Principles

- Separation between conversational memory and transactional state  
- Inventory as structured grounding source for RAG  
- Deterministic state updates (inventory adjustments handled outside the LLM layer)  
- Row-Level Security (RLS) policies for tenant isolation  

---

## Security

MOM is deployed on a hardened VPS (Contabo) with layered security controls.

### Infrastructure Security

- Environment variables isolated via `.env`
- No secrets committed to repository
- HTTPS enforced
- Dockerized services with container isolation
- Firewall configuration (UFW)
- Fail2Ban intrusion prevention

### Application-Level Protections

- Rate-limiting and spam mitigation for inbound WhatsApp messages
- Message sanitation to prevent malicious payload injection
- Controlled workflow paths for inventory state changes
- Row-Level Security (RLS) policies in Supabase for tenant isolation

---

## Design Philosophy

MOM separates deterministic business logic from probabilistic LLM reasoning.

- All state transitions (inventory, orders, customers) are handled deterministically.
- The LLM layer is used strictly for reasoning and controlled generation.
- Structured database context is always provided to ground responses.
- The system is designed for scalability, auditability and multi-tenant expansion.

---

## License

This repository is currently provided for architectural showcase and demonstration purposes.
