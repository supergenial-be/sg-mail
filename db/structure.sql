SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: unaccent; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA public;


--
-- Name: EXTENSION unaccent; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION unaccent IS 'text search dictionary that removes accents';


--
-- Name: sg_mail_unaccent(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.sg_mail_unaccent(text) RETURNS text
    LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE
    AS $_$ SELECT public.unaccent('public.unaccent'::regdictionary, $1) $_$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: access_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.access_logs (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    user_id bigint NOT NULL,
    conversation_id bigint,
    message_id bigint,
    action character varying NOT NULL,
    via character varying NOT NULL,
    detail character varying,
    created_at timestamp(6) without time zone NOT NULL
);

ALTER TABLE ONLY public.access_logs FORCE ROW LEVEL SECURITY;


--
-- Name: access_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.access_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: access_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.access_logs_id_seq OWNED BY public.access_logs.id;


--
-- Name: accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounts (
    id bigint NOT NULL,
    name character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    agent_enabled boolean DEFAULT false NOT NULL,
    agent_monthly_budget_cents integer DEFAULT 2000 NOT NULL,
    color character varying
);


--
-- Name: accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accounts_id_seq OWNED BY public.accounts.id;


--
-- Name: active_storage_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_attachments (
    id bigint NOT NULL,
    name character varying NOT NULL,
    record_type character varying NOT NULL,
    record_id bigint NOT NULL,
    blob_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_attachments_id_seq OWNED BY public.active_storage_attachments.id;


--
-- Name: active_storage_blobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_blobs (
    id bigint NOT NULL,
    key character varying NOT NULL,
    filename character varying NOT NULL,
    content_type character varying,
    metadata text,
    service_name character varying NOT NULL,
    byte_size bigint NOT NULL,
    checksum character varying,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_blobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_blobs_id_seq OWNED BY public.active_storage_blobs.id;


--
-- Name: active_storage_variant_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_variant_records (
    id bigint NOT NULL,
    blob_id bigint NOT NULL,
    variation_digest character varying NOT NULL
);


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_variant_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_variant_records_id_seq OWNED BY public.active_storage_variant_records.id;


--
-- Name: agent_actions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agent_actions (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    agent_chat_id bigint NOT NULL,
    agent_message_id bigint NOT NULL,
    tool_use_id character varying NOT NULL,
    tool_name character varying NOT NULL,
    input jsonb DEFAULT '{}'::jsonb NOT NULL,
    writes boolean DEFAULT false NOT NULL,
    status character varying DEFAULT 'pending'::character varying NOT NULL,
    result jsonb,
    decided_by_id bigint,
    decided_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);

ALTER TABLE ONLY public.agent_actions FORCE ROW LEVEL SECURITY;


--
-- Name: agent_actions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.agent_actions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: agent_actions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.agent_actions_id_seq OWNED BY public.agent_actions.id;


--
-- Name: agent_chats; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agent_chats (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    user_id bigint NOT NULL,
    conversation_id bigint,
    title character varying,
    status character varying DEFAULT 'idle'::character varying NOT NULL,
    error text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);

ALTER TABLE ONLY public.agent_chats FORCE ROW LEVEL SECURITY;


--
-- Name: agent_chats_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.agent_chats_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: agent_chats_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.agent_chats_id_seq OWNED BY public.agent_chats.id;


--
-- Name: agent_messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agent_messages (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    agent_chat_id bigint NOT NULL,
    role character varying NOT NULL,
    content jsonb DEFAULT '[]'::jsonb NOT NULL,
    model character varying,
    input_tokens integer DEFAULT 0 NOT NULL,
    output_tokens integer DEFAULT 0 NOT NULL,
    cost_micros integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);

ALTER TABLE ONLY public.agent_messages FORCE ROW LEVEL SECURITY;


--
-- Name: agent_messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.agent_messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: agent_messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.agent_messages_id_seq OWNED BY public.agent_messages.id;


--
-- Name: agents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agents (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    name character varying NOT NULL,
    color character varying NOT NULL,
    style character varying NOT NULL,
    instructions text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: agents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.agents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: agents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.agents_id_seq OWNED BY public.agents.id;


--
-- Name: api_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.api_tokens (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    account_id bigint NOT NULL,
    name character varying NOT NULL,
    token_digest character varying NOT NULL,
    last_used_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: api_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.api_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: api_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.api_tokens_id_seq OWNED BY public.api_tokens.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: conversation_states; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.conversation_states (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    conversation_id bigint NOT NULL,
    user_id bigint NOT NULL,
    reply_later_at timestamp(6) without time zone,
    set_aside_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    archived_at timestamp(6) without time zone
);

ALTER TABLE ONLY public.conversation_states FORCE ROW LEVEL SECURITY;


--
-- Name: conversation_states_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.conversation_states_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: conversation_states_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.conversation_states_id_seq OWNED BY public.conversation_states.id;


--
-- Name: conversations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.conversations (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    mailbox_id bigint NOT NULL,
    thread_key character varying NOT NULL,
    subject character varying,
    last_sender character varying,
    snippet text,
    last_message_at timestamp(6) without time zone,
    messages_count integer DEFAULT 0 NOT NULL,
    in_inbox boolean DEFAULT false NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    assignee_id bigint,
    sender_address character varying,
    sender_name character varying,
    root_message_id character varying
);

ALTER TABLE ONLY public.conversations FORCE ROW LEVEL SECURITY;


--
-- Name: conversations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.conversations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: conversations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.conversations_id_seq OWNED BY public.conversations.id;


--
-- Name: drafts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.drafts (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    mailbox_id bigint NOT NULL,
    user_id bigint NOT NULL,
    conversation_id bigint,
    source_message_id bigint,
    kind character varying DEFAULT 'new'::character varying NOT NULL,
    to_addresses jsonb DEFAULT '[]'::jsonb NOT NULL,
    cc_addresses jsonb DEFAULT '[]'::jsonb NOT NULL,
    bcc_addresses jsonb DEFAULT '[]'::jsonb NOT NULL,
    subject character varying,
    body text,
    status character varying DEFAULT 'draft'::character varying NOT NULL,
    error text,
    sent_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    send_at timestamp(6) without time zone
);

ALTER TABLE ONLY public.drafts FORCE ROW LEVEL SECURITY;


--
-- Name: drafts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.drafts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: drafts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.drafts_id_seq OWNED BY public.drafts.id;


--
-- Name: integration_connections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.integration_connections (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    integration_id bigint NOT NULL,
    user_id bigint NOT NULL,
    remote_identity character varying,
    oauth text,
    instructions text,
    tools jsonb DEFAULT '[]'::jsonb NOT NULL,
    tools_fetched_at timestamp(6) without time zone,
    connected_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);

ALTER TABLE ONLY public.integration_connections FORCE ROW LEVEL SECURITY;


--
-- Name: integration_connections_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.integration_connections_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: integration_connections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.integration_connections_id_seq OWNED BY public.integration_connections.id;


--
-- Name: integrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.integrations (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    name character varying NOT NULL,
    slug character varying NOT NULL,
    mcp_url character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);

ALTER TABLE ONLY public.integrations FORCE ROW LEVEL SECURITY;


--
-- Name: integrations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.integrations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: integrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.integrations_id_seq OWNED BY public.integrations.id;


--
-- Name: invitations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.invitations (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    invited_by_id bigint NOT NULL,
    email_address character varying NOT NULL,
    role character varying DEFAULT 'member'::character varying NOT NULL,
    token character varying NOT NULL,
    accepted_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: invitations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.invitations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: invitations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.invitations_id_seq OWNED BY public.invitations.id;


--
-- Name: mail_folders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mail_folders (
    id bigint NOT NULL,
    mailbox_id bigint NOT NULL,
    name character varying NOT NULL,
    uidvalidity bigint,
    last_uid bigint DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    account_id bigint NOT NULL
);

ALTER TABLE ONLY public.mail_folders FORCE ROW LEVEL SECURITY;


--
-- Name: mail_folders_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mail_folders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mail_folders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.mail_folders_id_seq OWNED BY public.mail_folders.id;


--
-- Name: mailbox_accesses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mailbox_accesses (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    mailbox_id bigint NOT NULL,
    user_id bigint NOT NULL,
    level character varying DEFAULT 'send'::character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    signature text,
    sender_name character varying
);

ALTER TABLE ONLY public.mailbox_accesses FORCE ROW LEVEL SECURITY;


--
-- Name: mailbox_accesses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mailbox_accesses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mailbox_accesses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.mailbox_accesses_id_seq OWNED BY public.mailbox_accesses.id;


--
-- Name: mailboxes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mailboxes (
    id bigint NOT NULL,
    provider character varying NOT NULL,
    address character varying NOT NULL,
    credentials text,
    sync_state jsonb DEFAULT '{}'::jsonb NOT NULL,
    last_synced_at timestamp(6) without time zone,
    last_sync_error text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    account_id bigint NOT NULL,
    connected_by_id bigint,
    label character varying
);

ALTER TABLE ONLY public.mailboxes FORCE ROW LEVEL SECURITY;


--
-- Name: mailboxes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mailboxes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mailboxes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.mailboxes_id_seq OWNED BY public.mailboxes.id;


--
-- Name: memberships; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.memberships (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    user_id bigint NOT NULL,
    role character varying DEFAULT 'member'::character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: memberships_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.memberships_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: memberships_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.memberships_id_seq OWNED BY public.memberships.id;


--
-- Name: messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.messages (
    id bigint NOT NULL,
    mailbox_id bigint NOT NULL,
    mail_folder_id bigint,
    provider_uid character varying NOT NULL,
    thread_key character varying,
    message_id_header character varying,
    subject character varying,
    from_address character varying,
    from_name character varying,
    to_addresses jsonb DEFAULT '[]'::jsonb NOT NULL,
    cc_addresses jsonb DEFAULT '[]'::jsonb NOT NULL,
    sent_at timestamp(6) without time zone,
    snippet text,
    body_text text,
    body_html text,
    labels jsonb DEFAULT '[]'::jsonb NOT NULL,
    size integer,
    has_attachments boolean DEFAULT false NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    account_id bigint NOT NULL,
    conversation_id bigint,
    attachments jsonb DEFAULT '[]'::jsonb NOT NULL,
    search_vector tsvector GENERATED ALWAYS AS (((((setweight(to_tsvector('simple'::regconfig, public.sg_mail_unaccent((COALESCE(subject, ''::character varying))::text)), 'A'::"char") || setweight(to_tsvector('simple'::regconfig, public.sg_mail_unaccent((((COALESCE(from_name, ''::character varying))::text || ' '::text) || (COALESCE(from_address, ''::character varying))::text))), 'B'::"char")) || setweight(to_tsvector('simple'::regconfig, public.sg_mail_unaccent((((to_addresses)::text || ' '::text) || (cc_addresses)::text))), 'C'::"char")) || setweight(to_tsvector('simple'::regconfig, regexp_replace(public.sg_mail_unaccent((jsonb_path_query_array(attachments, '$[*]."filename"'::jsonpath))::text), '[^[:alnum:]]+'::text, ' '::text, 'g'::text)), 'C'::"char")) || setweight(to_tsvector('simple'::regconfig, public.sg_mail_unaccent("left"(COALESCE(body_text, regexp_replace("left"(body_html, 400000), '<[^>]*>'::text, ' '::text, 'g'::text), ''::text), 200000))), 'D'::"char"))) STORED
);

ALTER TABLE ONLY public.messages FORCE ROW LEVEL SECURITY;


--
-- Name: messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.messages_id_seq OWNED BY public.messages.id;


--
-- Name: notes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notes (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    conversation_id bigint NOT NULL,
    user_id bigint NOT NULL,
    body text NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);

ALTER TABLE ONLY public.notes FORCE ROW LEVEL SECURITY;


--
-- Name: notes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notes_id_seq OWNED BY public.notes.id;


--
-- Name: oauth_authorization_codes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.oauth_authorization_codes (
    id bigint NOT NULL,
    oauth_client_id bigint NOT NULL,
    user_id bigint NOT NULL,
    account_id bigint,
    code_digest character varying NOT NULL,
    redirect_uri character varying NOT NULL,
    code_challenge character varying NOT NULL,
    resource character varying,
    expires_at timestamp(6) without time zone NOT NULL,
    used_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: oauth_authorization_codes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.oauth_authorization_codes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: oauth_authorization_codes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.oauth_authorization_codes_id_seq OWNED BY public.oauth_authorization_codes.id;


--
-- Name: oauth_clients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.oauth_clients (
    id bigint NOT NULL,
    uid character varying NOT NULL,
    name character varying NOT NULL,
    redirect_uris jsonb DEFAULT '[]'::jsonb NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: oauth_clients_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.oauth_clients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: oauth_clients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.oauth_clients_id_seq OWNED BY public.oauth_clients.id;


--
-- Name: oauth_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.oauth_tokens (
    id bigint NOT NULL,
    oauth_client_id bigint NOT NULL,
    user_id bigint NOT NULL,
    account_id bigint,
    access_token_digest character varying NOT NULL,
    refresh_token_digest character varying NOT NULL,
    access_expires_at timestamp(6) without time zone NOT NULL,
    refresh_expires_at timestamp(6) without time zone NOT NULL,
    revoked_at timestamp(6) without time zone,
    last_used_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: oauth_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.oauth_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: oauth_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.oauth_tokens_id_seq OWNED BY public.oauth_tokens.id;


--
-- Name: passkeys; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.passkeys (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    external_id character varying NOT NULL,
    public_key character varying NOT NULL,
    sign_count bigint DEFAULT 0 NOT NULL,
    name character varying NOT NULL,
    last_used_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: passkeys_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.passkeys_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: passkeys_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.passkeys_id_seq OWNED BY public.passkeys.id;


--
-- Name: push_subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.push_subscriptions (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    endpoint text NOT NULL,
    p256dh character varying NOT NULL,
    auth character varying NOT NULL,
    name character varying NOT NULL,
    last_used_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: push_subscriptions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.push_subscriptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: push_subscriptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.push_subscriptions_id_seq OWNED BY public.push_subscriptions.id;


--
-- Name: readings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.readings (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    message_id bigint NOT NULL,
    user_id bigint NOT NULL,
    read_at timestamp(6) without time zone NOT NULL
);

ALTER TABLE ONLY public.readings FORCE ROW LEVEL SECURITY;


--
-- Name: readings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.readings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: readings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.readings_id_seq OWNED BY public.readings.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: screenings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.screenings (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    user_id bigint NOT NULL,
    address character varying NOT NULL,
    decision character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    bucket character varying DEFAULT 'imbox'::character varying NOT NULL
);

ALTER TABLE ONLY public.screenings FORCE ROW LEVEL SECURITY;


--
-- Name: screenings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.screenings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: screenings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.screenings_id_seq OWNED BY public.screenings.id;


--
-- Name: sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sessions (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    ip_address character varying,
    user_agent character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sessions_id_seq OWNED BY public.sessions.id;


--
-- Name: solid_cable_messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_cable_messages (
    id bigint NOT NULL,
    channel bytea NOT NULL,
    payload bytea NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    channel_hash bigint NOT NULL
);


--
-- Name: solid_cable_messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_cable_messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_cable_messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_cable_messages_id_seq OWNED BY public.solid_cable_messages.id;


--
-- Name: solid_cache_entries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_cache_entries (
    id bigint NOT NULL,
    key bytea NOT NULL,
    value bytea NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    key_hash bigint NOT NULL,
    byte_size integer NOT NULL
);


--
-- Name: solid_cache_entries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_cache_entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_cache_entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_cache_entries_id_seq OWNED BY public.solid_cache_entries.id;


--
-- Name: solid_queue_batch_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_batch_executions (
    id bigint NOT NULL,
    job_id bigint NOT NULL,
    batch_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_batch_executions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_batch_executions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_batch_executions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_batch_executions_id_seq OWNED BY public.solid_queue_batch_executions.id;


--
-- Name: solid_queue_batches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_batches (
    id bigint NOT NULL,
    active_job_batch_id character varying,
    description character varying,
    on_finish text,
    on_success text,
    on_failure text,
    metadata text,
    total_jobs integer DEFAULT 0 NOT NULL,
    completed_jobs integer DEFAULT 0 NOT NULL,
    failed_jobs integer DEFAULT 0 NOT NULL,
    enqueued_at timestamp(6) without time zone,
    finished_at timestamp(6) without time zone,
    failed_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_batches_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_batches_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_batches_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_batches_id_seq OWNED BY public.solid_queue_batches.id;


--
-- Name: solid_queue_blocked_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_blocked_executions (
    id bigint NOT NULL,
    job_id bigint NOT NULL,
    queue_name character varying NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    concurrency_key character varying NOT NULL,
    expires_at timestamp(6) without time zone NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_blocked_executions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_blocked_executions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_blocked_executions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_blocked_executions_id_seq OWNED BY public.solid_queue_blocked_executions.id;


--
-- Name: solid_queue_claimed_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_claimed_executions (
    id bigint NOT NULL,
    job_id bigint NOT NULL,
    process_id bigint,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_claimed_executions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_claimed_executions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_claimed_executions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_claimed_executions_id_seq OWNED BY public.solid_queue_claimed_executions.id;


--
-- Name: solid_queue_failed_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_failed_executions (
    id bigint NOT NULL,
    job_id bigint NOT NULL,
    error text,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_failed_executions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_failed_executions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_failed_executions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_failed_executions_id_seq OWNED BY public.solid_queue_failed_executions.id;


--
-- Name: solid_queue_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_jobs (
    id bigint NOT NULL,
    queue_name character varying NOT NULL,
    class_name character varying NOT NULL,
    arguments text,
    priority integer DEFAULT 0 NOT NULL,
    active_job_id character varying,
    scheduled_at timestamp(6) without time zone,
    finished_at timestamp(6) without time zone,
    concurrency_key character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    batch_id bigint
);


--
-- Name: solid_queue_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_jobs_id_seq OWNED BY public.solid_queue_jobs.id;


--
-- Name: solid_queue_pauses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_pauses (
    id bigint NOT NULL,
    queue_name character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_pauses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_pauses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_pauses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_pauses_id_seq OWNED BY public.solid_queue_pauses.id;


--
-- Name: solid_queue_processes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_processes (
    id bigint NOT NULL,
    kind character varying NOT NULL,
    last_heartbeat_at timestamp(6) without time zone NOT NULL,
    supervisor_id bigint,
    pid integer NOT NULL,
    hostname character varying,
    metadata text,
    created_at timestamp(6) without time zone NOT NULL,
    name character varying NOT NULL
);


--
-- Name: solid_queue_processes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_processes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_processes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_processes_id_seq OWNED BY public.solid_queue_processes.id;


--
-- Name: solid_queue_ready_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_ready_executions (
    id bigint NOT NULL,
    job_id bigint NOT NULL,
    queue_name character varying NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_ready_executions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_ready_executions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_ready_executions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_ready_executions_id_seq OWNED BY public.solid_queue_ready_executions.id;


--
-- Name: solid_queue_recurring_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_recurring_executions (
    id bigint NOT NULL,
    job_id bigint NOT NULL,
    task_key character varying NOT NULL,
    run_at timestamp(6) without time zone NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_recurring_executions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_recurring_executions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_recurring_executions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_recurring_executions_id_seq OWNED BY public.solid_queue_recurring_executions.id;


--
-- Name: solid_queue_recurring_tasks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_recurring_tasks (
    id bigint NOT NULL,
    key character varying NOT NULL,
    schedule character varying NOT NULL,
    command character varying(2048),
    class_name character varying,
    arguments text,
    queue_name character varying,
    priority integer DEFAULT 0,
    static boolean DEFAULT true NOT NULL,
    description text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_recurring_tasks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_recurring_tasks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_recurring_tasks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_recurring_tasks_id_seq OWNED BY public.solid_queue_recurring_tasks.id;


--
-- Name: solid_queue_scheduled_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_scheduled_executions (
    id bigint NOT NULL,
    job_id bigint NOT NULL,
    queue_name character varying NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    scheduled_at timestamp(6) without time zone NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_scheduled_executions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_scheduled_executions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_scheduled_executions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_scheduled_executions_id_seq OWNED BY public.solid_queue_scheduled_executions.id;


--
-- Name: solid_queue_semaphores; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_semaphores (
    id bigint NOT NULL,
    key character varying NOT NULL,
    value integer DEFAULT 1 NOT NULL,
    expires_at timestamp(6) without time zone NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_semaphores_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_semaphores_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_semaphores_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_semaphores_id_seq OWNED BY public.solid_queue_semaphores.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    email_address character varying NOT NULL,
    password_digest character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    name character varying DEFAULT ''::character varying NOT NULL,
    staff boolean DEFAULT false NOT NULL,
    webauthn_id character varying
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: access_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.access_logs ALTER COLUMN id SET DEFAULT nextval('public.access_logs_id_seq'::regclass);


--
-- Name: accounts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts ALTER COLUMN id SET DEFAULT nextval('public.accounts_id_seq'::regclass);


--
-- Name: active_storage_attachments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments ALTER COLUMN id SET DEFAULT nextval('public.active_storage_attachments_id_seq'::regclass);


--
-- Name: active_storage_blobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs ALTER COLUMN id SET DEFAULT nextval('public.active_storage_blobs_id_seq'::regclass);


--
-- Name: active_storage_variant_records id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records ALTER COLUMN id SET DEFAULT nextval('public.active_storage_variant_records_id_seq'::regclass);


--
-- Name: agent_actions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_actions ALTER COLUMN id SET DEFAULT nextval('public.agent_actions_id_seq'::regclass);


--
-- Name: agent_chats id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_chats ALTER COLUMN id SET DEFAULT nextval('public.agent_chats_id_seq'::regclass);


--
-- Name: agent_messages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_messages ALTER COLUMN id SET DEFAULT nextval('public.agent_messages_id_seq'::regclass);


--
-- Name: agents id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agents ALTER COLUMN id SET DEFAULT nextval('public.agents_id_seq'::regclass);


--
-- Name: api_tokens id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_tokens ALTER COLUMN id SET DEFAULT nextval('public.api_tokens_id_seq'::regclass);


--
-- Name: conversation_states id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversation_states ALTER COLUMN id SET DEFAULT nextval('public.conversation_states_id_seq'::regclass);


--
-- Name: conversations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversations ALTER COLUMN id SET DEFAULT nextval('public.conversations_id_seq'::regclass);


--
-- Name: drafts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.drafts ALTER COLUMN id SET DEFAULT nextval('public.drafts_id_seq'::regclass);


--
-- Name: integration_connections id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integration_connections ALTER COLUMN id SET DEFAULT nextval('public.integration_connections_id_seq'::regclass);


--
-- Name: integrations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integrations ALTER COLUMN id SET DEFAULT nextval('public.integrations_id_seq'::regclass);


--
-- Name: invitations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invitations ALTER COLUMN id SET DEFAULT nextval('public.invitations_id_seq'::regclass);


--
-- Name: mail_folders id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mail_folders ALTER COLUMN id SET DEFAULT nextval('public.mail_folders_id_seq'::regclass);


--
-- Name: mailbox_accesses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mailbox_accesses ALTER COLUMN id SET DEFAULT nextval('public.mailbox_accesses_id_seq'::regclass);


--
-- Name: mailboxes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mailboxes ALTER COLUMN id SET DEFAULT nextval('public.mailboxes_id_seq'::regclass);


--
-- Name: memberships id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.memberships ALTER COLUMN id SET DEFAULT nextval('public.memberships_id_seq'::regclass);


--
-- Name: messages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages ALTER COLUMN id SET DEFAULT nextval('public.messages_id_seq'::regclass);


--
-- Name: notes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notes ALTER COLUMN id SET DEFAULT nextval('public.notes_id_seq'::regclass);


--
-- Name: oauth_authorization_codes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_authorization_codes ALTER COLUMN id SET DEFAULT nextval('public.oauth_authorization_codes_id_seq'::regclass);


--
-- Name: oauth_clients id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_clients ALTER COLUMN id SET DEFAULT nextval('public.oauth_clients_id_seq'::regclass);


--
-- Name: oauth_tokens id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_tokens ALTER COLUMN id SET DEFAULT nextval('public.oauth_tokens_id_seq'::regclass);


--
-- Name: passkeys id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.passkeys ALTER COLUMN id SET DEFAULT nextval('public.passkeys_id_seq'::regclass);


--
-- Name: push_subscriptions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.push_subscriptions ALTER COLUMN id SET DEFAULT nextval('public.push_subscriptions_id_seq'::regclass);


--
-- Name: readings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.readings ALTER COLUMN id SET DEFAULT nextval('public.readings_id_seq'::regclass);


--
-- Name: screenings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.screenings ALTER COLUMN id SET DEFAULT nextval('public.screenings_id_seq'::regclass);


--
-- Name: sessions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions ALTER COLUMN id SET DEFAULT nextval('public.sessions_id_seq'::regclass);


--
-- Name: solid_cable_messages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_cable_messages ALTER COLUMN id SET DEFAULT nextval('public.solid_cable_messages_id_seq'::regclass);


--
-- Name: solid_cache_entries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_cache_entries ALTER COLUMN id SET DEFAULT nextval('public.solid_cache_entries_id_seq'::regclass);


--
-- Name: solid_queue_batch_executions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_batch_executions ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_batch_executions_id_seq'::regclass);


--
-- Name: solid_queue_batches id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_batches ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_batches_id_seq'::regclass);


--
-- Name: solid_queue_blocked_executions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_blocked_executions ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_blocked_executions_id_seq'::regclass);


--
-- Name: solid_queue_claimed_executions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_claimed_executions ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_claimed_executions_id_seq'::regclass);


--
-- Name: solid_queue_failed_executions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_failed_executions ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_failed_executions_id_seq'::regclass);


--
-- Name: solid_queue_jobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_jobs ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_jobs_id_seq'::regclass);


--
-- Name: solid_queue_pauses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_pauses ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_pauses_id_seq'::regclass);


--
-- Name: solid_queue_processes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_processes ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_processes_id_seq'::regclass);


--
-- Name: solid_queue_ready_executions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_ready_executions ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_ready_executions_id_seq'::regclass);


--
-- Name: solid_queue_recurring_executions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_recurring_executions ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_recurring_executions_id_seq'::regclass);


--
-- Name: solid_queue_recurring_tasks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_recurring_tasks ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_recurring_tasks_id_seq'::regclass);


--
-- Name: solid_queue_scheduled_executions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_scheduled_executions ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_scheduled_executions_id_seq'::regclass);


--
-- Name: solid_queue_semaphores id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_semaphores ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_semaphores_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: access_logs access_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.access_logs
    ADD CONSTRAINT access_logs_pkey PRIMARY KEY (id);


--
-- Name: accounts accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT accounts_pkey PRIMARY KEY (id);


--
-- Name: active_storage_attachments active_storage_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT active_storage_attachments_pkey PRIMARY KEY (id);


--
-- Name: active_storage_blobs active_storage_blobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs
    ADD CONSTRAINT active_storage_blobs_pkey PRIMARY KEY (id);


--
-- Name: active_storage_variant_records active_storage_variant_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT active_storage_variant_records_pkey PRIMARY KEY (id);


--
-- Name: agent_actions agent_actions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_actions
    ADD CONSTRAINT agent_actions_pkey PRIMARY KEY (id);


--
-- Name: agent_chats agent_chats_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_chats
    ADD CONSTRAINT agent_chats_pkey PRIMARY KEY (id);


--
-- Name: agent_messages agent_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_messages
    ADD CONSTRAINT agent_messages_pkey PRIMARY KEY (id);


--
-- Name: agents agents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agents
    ADD CONSTRAINT agents_pkey PRIMARY KEY (id);


--
-- Name: api_tokens api_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_tokens
    ADD CONSTRAINT api_tokens_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: conversation_states conversation_states_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversation_states
    ADD CONSTRAINT conversation_states_pkey PRIMARY KEY (id);


--
-- Name: conversations conversations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT conversations_pkey PRIMARY KEY (id);


--
-- Name: drafts drafts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.drafts
    ADD CONSTRAINT drafts_pkey PRIMARY KEY (id);


--
-- Name: integration_connections integration_connections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integration_connections
    ADD CONSTRAINT integration_connections_pkey PRIMARY KEY (id);


--
-- Name: integrations integrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integrations
    ADD CONSTRAINT integrations_pkey PRIMARY KEY (id);


--
-- Name: invitations invitations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invitations
    ADD CONSTRAINT invitations_pkey PRIMARY KEY (id);


--
-- Name: mail_folders mail_folders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mail_folders
    ADD CONSTRAINT mail_folders_pkey PRIMARY KEY (id);


--
-- Name: mailbox_accesses mailbox_accesses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mailbox_accesses
    ADD CONSTRAINT mailbox_accesses_pkey PRIMARY KEY (id);


--
-- Name: mailboxes mailboxes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mailboxes
    ADD CONSTRAINT mailboxes_pkey PRIMARY KEY (id);


--
-- Name: memberships memberships_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.memberships
    ADD CONSTRAINT memberships_pkey PRIMARY KEY (id);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- Name: notes notes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notes
    ADD CONSTRAINT notes_pkey PRIMARY KEY (id);


--
-- Name: oauth_authorization_codes oauth_authorization_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_authorization_codes
    ADD CONSTRAINT oauth_authorization_codes_pkey PRIMARY KEY (id);


--
-- Name: oauth_clients oauth_clients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_clients
    ADD CONSTRAINT oauth_clients_pkey PRIMARY KEY (id);


--
-- Name: oauth_tokens oauth_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_tokens
    ADD CONSTRAINT oauth_tokens_pkey PRIMARY KEY (id);


--
-- Name: passkeys passkeys_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.passkeys
    ADD CONSTRAINT passkeys_pkey PRIMARY KEY (id);


--
-- Name: push_subscriptions push_subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.push_subscriptions
    ADD CONSTRAINT push_subscriptions_pkey PRIMARY KEY (id);


--
-- Name: readings readings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.readings
    ADD CONSTRAINT readings_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: screenings screenings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.screenings
    ADD CONSTRAINT screenings_pkey PRIMARY KEY (id);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: solid_cable_messages solid_cable_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_cable_messages
    ADD CONSTRAINT solid_cable_messages_pkey PRIMARY KEY (id);


--
-- Name: solid_cache_entries solid_cache_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_cache_entries
    ADD CONSTRAINT solid_cache_entries_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_batch_executions solid_queue_batch_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_batch_executions
    ADD CONSTRAINT solid_queue_batch_executions_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_batches solid_queue_batches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_batches
    ADD CONSTRAINT solid_queue_batches_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_blocked_executions solid_queue_blocked_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_blocked_executions
    ADD CONSTRAINT solid_queue_blocked_executions_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_claimed_executions solid_queue_claimed_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_claimed_executions
    ADD CONSTRAINT solid_queue_claimed_executions_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_failed_executions solid_queue_failed_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_failed_executions
    ADD CONSTRAINT solid_queue_failed_executions_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_jobs solid_queue_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_jobs
    ADD CONSTRAINT solid_queue_jobs_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_pauses solid_queue_pauses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_pauses
    ADD CONSTRAINT solid_queue_pauses_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_processes solid_queue_processes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_processes
    ADD CONSTRAINT solid_queue_processes_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_ready_executions solid_queue_ready_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_ready_executions
    ADD CONSTRAINT solid_queue_ready_executions_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_recurring_executions solid_queue_recurring_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_recurring_executions
    ADD CONSTRAINT solid_queue_recurring_executions_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_recurring_tasks solid_queue_recurring_tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_recurring_tasks
    ADD CONSTRAINT solid_queue_recurring_tasks_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_scheduled_executions solid_queue_scheduled_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_scheduled_executions
    ADD CONSTRAINT solid_queue_scheduled_executions_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_semaphores solid_queue_semaphores_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_semaphores
    ADD CONSTRAINT solid_queue_semaphores_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: index_access_logs_on_account_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_access_logs_on_account_id_and_created_at ON public.access_logs USING btree (account_id, created_at);


--
-- Name: index_access_logs_on_conversation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_access_logs_on_conversation_id ON public.access_logs USING btree (conversation_id);


--
-- Name: index_access_logs_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_access_logs_on_user_id ON public.access_logs USING btree (user_id);


--
-- Name: index_active_storage_attachments_on_blob_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_active_storage_attachments_on_blob_id ON public.active_storage_attachments USING btree (blob_id);


--
-- Name: index_active_storage_attachments_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_attachments_uniqueness ON public.active_storage_attachments USING btree (record_type, record_id, name, blob_id);


--
-- Name: index_active_storage_blobs_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_blobs_on_key ON public.active_storage_blobs USING btree (key);


--
-- Name: index_active_storage_variant_records_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_variant_records_uniqueness ON public.active_storage_variant_records USING btree (blob_id, variation_digest);


--
-- Name: index_agent_actions_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_agent_actions_on_account_id ON public.agent_actions USING btree (account_id);


--
-- Name: index_agent_actions_on_agent_chat_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_agent_actions_on_agent_chat_id ON public.agent_actions USING btree (agent_chat_id);


--
-- Name: index_agent_actions_on_agent_message_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_agent_actions_on_agent_message_id ON public.agent_actions USING btree (agent_message_id);


--
-- Name: index_agent_actions_on_decided_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_agent_actions_on_decided_by_id ON public.agent_actions USING btree (decided_by_id);


--
-- Name: index_agent_chats_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_agent_chats_on_account_id ON public.agent_chats USING btree (account_id);


--
-- Name: index_agent_chats_on_conversation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_agent_chats_on_conversation_id ON public.agent_chats USING btree (conversation_id);


--
-- Name: index_agent_chats_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_agent_chats_on_user_id ON public.agent_chats USING btree (user_id);


--
-- Name: index_agent_chats_on_user_id_and_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_agent_chats_on_user_id_and_updated_at ON public.agent_chats USING btree (user_id, updated_at);


--
-- Name: index_agent_messages_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_agent_messages_on_account_id ON public.agent_messages USING btree (account_id);


--
-- Name: index_agent_messages_on_account_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_agent_messages_on_account_id_and_created_at ON public.agent_messages USING btree (account_id, created_at);


--
-- Name: index_agent_messages_on_agent_chat_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_agent_messages_on_agent_chat_id ON public.agent_messages USING btree (agent_chat_id);


--
-- Name: index_agents_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_agents_on_user_id ON public.agents USING btree (user_id);


--
-- Name: index_api_tokens_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_api_tokens_on_account_id ON public.api_tokens USING btree (account_id);


--
-- Name: index_api_tokens_on_token_digest; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_api_tokens_on_token_digest ON public.api_tokens USING btree (token_digest);


--
-- Name: index_api_tokens_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_api_tokens_on_user_id ON public.api_tokens USING btree (user_id);


--
-- Name: index_conversation_states_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_conversation_states_on_account_id ON public.conversation_states USING btree (account_id);


--
-- Name: index_conversation_states_on_conversation_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_conversation_states_on_conversation_id_and_user_id ON public.conversation_states USING btree (conversation_id, user_id);


--
-- Name: index_conversation_states_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_conversation_states_on_user_id ON public.conversation_states USING btree (user_id);


--
-- Name: index_conversations_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_conversations_on_account_id ON public.conversations USING btree (account_id);


--
-- Name: index_conversations_on_account_id_and_last_message_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_conversations_on_account_id_and_last_message_at ON public.conversations USING btree (account_id, last_message_at);


--
-- Name: index_conversations_on_account_id_and_root_message_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_conversations_on_account_id_and_root_message_id ON public.conversations USING btree (account_id, root_message_id);


--
-- Name: index_conversations_on_assignee_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_conversations_on_assignee_id ON public.conversations USING btree (assignee_id);


--
-- Name: index_conversations_on_mailbox_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_conversations_on_mailbox_id ON public.conversations USING btree (mailbox_id);


--
-- Name: index_conversations_on_mailbox_id_and_sender_address; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_conversations_on_mailbox_id_and_sender_address ON public.conversations USING btree (mailbox_id, sender_address);


--
-- Name: index_conversations_on_mailbox_id_and_thread_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_conversations_on_mailbox_id_and_thread_key ON public.conversations USING btree (mailbox_id, thread_key);


--
-- Name: index_drafts_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_drafts_on_account_id ON public.drafts USING btree (account_id);


--
-- Name: index_drafts_on_conversation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_drafts_on_conversation_id ON public.drafts USING btree (conversation_id);


--
-- Name: index_drafts_on_mailbox_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_drafts_on_mailbox_id ON public.drafts USING btree (mailbox_id);


--
-- Name: index_drafts_on_source_message_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_drafts_on_source_message_id ON public.drafts USING btree (source_message_id);


--
-- Name: index_drafts_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_drafts_on_user_id ON public.drafts USING btree (user_id);


--
-- Name: index_integration_connections_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_integration_connections_on_account_id ON public.integration_connections USING btree (account_id);


--
-- Name: index_integration_connections_on_integration_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_integration_connections_on_integration_id ON public.integration_connections USING btree (integration_id);


--
-- Name: index_integration_connections_on_integration_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_integration_connections_on_integration_id_and_user_id ON public.integration_connections USING btree (integration_id, user_id);


--
-- Name: index_integration_connections_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_integration_connections_on_user_id ON public.integration_connections USING btree (user_id);


--
-- Name: index_integrations_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_integrations_on_account_id ON public.integrations USING btree (account_id);


--
-- Name: index_integrations_on_account_id_and_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_integrations_on_account_id_and_slug ON public.integrations USING btree (account_id, slug);


--
-- Name: index_invitations_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_invitations_on_account_id ON public.invitations USING btree (account_id);


--
-- Name: index_invitations_on_invited_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_invitations_on_invited_by_id ON public.invitations USING btree (invited_by_id);


--
-- Name: index_invitations_on_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_invitations_on_token ON public.invitations USING btree (token);


--
-- Name: index_mail_folders_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_mail_folders_on_account_id ON public.mail_folders USING btree (account_id);


--
-- Name: index_mail_folders_on_mailbox_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_mail_folders_on_mailbox_id ON public.mail_folders USING btree (mailbox_id);


--
-- Name: index_mail_folders_on_mailbox_id_and_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_mail_folders_on_mailbox_id_and_name ON public.mail_folders USING btree (mailbox_id, name);


--
-- Name: index_mailbox_accesses_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_mailbox_accesses_on_account_id ON public.mailbox_accesses USING btree (account_id);


--
-- Name: index_mailbox_accesses_on_mailbox_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_mailbox_accesses_on_mailbox_id ON public.mailbox_accesses USING btree (mailbox_id);


--
-- Name: index_mailbox_accesses_on_mailbox_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_mailbox_accesses_on_mailbox_id_and_user_id ON public.mailbox_accesses USING btree (mailbox_id, user_id);


--
-- Name: index_mailbox_accesses_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_mailbox_accesses_on_user_id ON public.mailbox_accesses USING btree (user_id);


--
-- Name: index_mailboxes_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_mailboxes_on_account_id ON public.mailboxes USING btree (account_id);


--
-- Name: index_mailboxes_on_account_id_and_provider_and_address; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_mailboxes_on_account_id_and_provider_and_address ON public.mailboxes USING btree (account_id, provider, address);


--
-- Name: index_mailboxes_on_connected_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_mailboxes_on_connected_by_id ON public.mailboxes USING btree (connected_by_id);


--
-- Name: index_memberships_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_memberships_on_account_id ON public.memberships USING btree (account_id);


--
-- Name: index_memberships_on_account_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_memberships_on_account_id_and_user_id ON public.memberships USING btree (account_id, user_id);


--
-- Name: index_memberships_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_memberships_on_user_id ON public.memberships USING btree (user_id);


--
-- Name: index_messages_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_messages_on_account_id ON public.messages USING btree (account_id);


--
-- Name: index_messages_on_account_id_and_message_id_header; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_messages_on_account_id_and_message_id_header ON public.messages USING btree (account_id, message_id_header);


--
-- Name: index_messages_on_conversation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_messages_on_conversation_id ON public.messages USING btree (conversation_id);


--
-- Name: index_messages_on_mail_folder_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_messages_on_mail_folder_id ON public.messages USING btree (mail_folder_id);


--
-- Name: index_messages_on_mailbox_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_messages_on_mailbox_id ON public.messages USING btree (mailbox_id);


--
-- Name: index_messages_on_mailbox_id_and_provider_uid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_messages_on_mailbox_id_and_provider_uid ON public.messages USING btree (mailbox_id, provider_uid);


--
-- Name: index_messages_on_mailbox_id_and_sent_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_messages_on_mailbox_id_and_sent_at ON public.messages USING btree (mailbox_id, sent_at);


--
-- Name: index_messages_on_mailbox_id_and_thread_key; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_messages_on_mailbox_id_and_thread_key ON public.messages USING btree (mailbox_id, thread_key);


--
-- Name: index_messages_on_search_vector; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_messages_on_search_vector ON public.messages USING gin (search_vector);


--
-- Name: index_notes_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notes_on_account_id ON public.notes USING btree (account_id);


--
-- Name: index_notes_on_conversation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notes_on_conversation_id ON public.notes USING btree (conversation_id);


--
-- Name: index_notes_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notes_on_user_id ON public.notes USING btree (user_id);


--
-- Name: index_oauth_authorization_codes_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_oauth_authorization_codes_on_account_id ON public.oauth_authorization_codes USING btree (account_id);


--
-- Name: index_oauth_authorization_codes_on_code_digest; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_oauth_authorization_codes_on_code_digest ON public.oauth_authorization_codes USING btree (code_digest);


--
-- Name: index_oauth_authorization_codes_on_oauth_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_oauth_authorization_codes_on_oauth_client_id ON public.oauth_authorization_codes USING btree (oauth_client_id);


--
-- Name: index_oauth_authorization_codes_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_oauth_authorization_codes_on_user_id ON public.oauth_authorization_codes USING btree (user_id);


--
-- Name: index_oauth_clients_on_uid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_oauth_clients_on_uid ON public.oauth_clients USING btree (uid);


--
-- Name: index_oauth_tokens_on_access_token_digest; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_oauth_tokens_on_access_token_digest ON public.oauth_tokens USING btree (access_token_digest);


--
-- Name: index_oauth_tokens_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_oauth_tokens_on_account_id ON public.oauth_tokens USING btree (account_id);


--
-- Name: index_oauth_tokens_on_oauth_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_oauth_tokens_on_oauth_client_id ON public.oauth_tokens USING btree (oauth_client_id);


--
-- Name: index_oauth_tokens_on_refresh_token_digest; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_oauth_tokens_on_refresh_token_digest ON public.oauth_tokens USING btree (refresh_token_digest);


--
-- Name: index_oauth_tokens_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_oauth_tokens_on_user_id ON public.oauth_tokens USING btree (user_id);


--
-- Name: index_passkeys_on_external_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_passkeys_on_external_id ON public.passkeys USING btree (external_id);


--
-- Name: index_passkeys_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_passkeys_on_user_id ON public.passkeys USING btree (user_id);


--
-- Name: index_push_subscriptions_on_endpoint; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_push_subscriptions_on_endpoint ON public.push_subscriptions USING btree (endpoint);


--
-- Name: index_push_subscriptions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_push_subscriptions_on_user_id ON public.push_subscriptions USING btree (user_id);


--
-- Name: index_readings_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_readings_on_account_id ON public.readings USING btree (account_id);


--
-- Name: index_readings_on_message_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_readings_on_message_id_and_user_id ON public.readings USING btree (message_id, user_id);


--
-- Name: index_readings_on_user_id_and_message_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_readings_on_user_id_and_message_id ON public.readings USING btree (user_id, message_id);


--
-- Name: index_screenings_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_screenings_on_account_id ON public.screenings USING btree (account_id);


--
-- Name: index_screenings_on_user_id_and_account_id_and_address; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_screenings_on_user_id_and_account_id_and_address ON public.screenings USING btree (user_id, account_id, address);


--
-- Name: index_sessions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sessions_on_user_id ON public.sessions USING btree (user_id);


--
-- Name: index_solid_cable_messages_on_channel_hash; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_cable_messages_on_channel_hash ON public.solid_cable_messages USING btree (channel_hash);


--
-- Name: index_solid_cable_messages_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_cable_messages_on_created_at ON public.solid_cable_messages USING btree (created_at);


--
-- Name: index_solid_cache_entries_on_byte_size; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_cache_entries_on_byte_size ON public.solid_cache_entries USING btree (byte_size);


--
-- Name: index_solid_cache_entries_on_key_hash; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_cache_entries_on_key_hash ON public.solid_cache_entries USING btree (key_hash);


--
-- Name: index_solid_cache_entries_on_key_hash_and_byte_size; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_cache_entries_on_key_hash_and_byte_size ON public.solid_cache_entries USING btree (key_hash, byte_size);


--
-- Name: index_solid_queue_batch_executions_on_batch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_batch_executions_on_batch_id ON public.solid_queue_batch_executions USING btree (batch_id);


--
-- Name: index_solid_queue_batch_executions_on_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_batch_executions_on_job_id ON public.solid_queue_batch_executions USING btree (job_id);


--
-- Name: index_solid_queue_batches_on_active_job_batch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_batches_on_active_job_batch_id ON public.solid_queue_batches USING btree (active_job_batch_id);


--
-- Name: index_solid_queue_batches_on_finished_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_batches_on_finished_at ON public.solid_queue_batches USING btree (finished_at);


--
-- Name: index_solid_queue_blocked_executions_for_maintenance; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_blocked_executions_for_maintenance ON public.solid_queue_blocked_executions USING btree (expires_at, concurrency_key);


--
-- Name: index_solid_queue_blocked_executions_for_release; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_blocked_executions_for_release ON public.solid_queue_blocked_executions USING btree (concurrency_key, priority, job_id);


--
-- Name: index_solid_queue_blocked_executions_on_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_blocked_executions_on_job_id ON public.solid_queue_blocked_executions USING btree (job_id);


--
-- Name: index_solid_queue_claimed_executions_on_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_claimed_executions_on_job_id ON public.solid_queue_claimed_executions USING btree (job_id);


--
-- Name: index_solid_queue_claimed_executions_on_process_id_and_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_claimed_executions_on_process_id_and_job_id ON public.solid_queue_claimed_executions USING btree (process_id, job_id);


--
-- Name: index_solid_queue_dispatch_all; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_dispatch_all ON public.solid_queue_scheduled_executions USING btree (scheduled_at, priority, job_id);


--
-- Name: index_solid_queue_failed_executions_on_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_failed_executions_on_job_id ON public.solid_queue_failed_executions USING btree (job_id);


--
-- Name: index_solid_queue_jobs_for_alerting; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_jobs_for_alerting ON public.solid_queue_jobs USING btree (scheduled_at, finished_at);


--
-- Name: index_solid_queue_jobs_for_filtering; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_jobs_for_filtering ON public.solid_queue_jobs USING btree (queue_name, finished_at);


--
-- Name: index_solid_queue_jobs_on_active_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_jobs_on_active_job_id ON public.solid_queue_jobs USING btree (active_job_id);


--
-- Name: index_solid_queue_jobs_on_batch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_jobs_on_batch_id ON public.solid_queue_jobs USING btree (batch_id);


--
-- Name: index_solid_queue_jobs_on_class_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_jobs_on_class_name ON public.solid_queue_jobs USING btree (class_name);


--
-- Name: index_solid_queue_jobs_on_finished_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_jobs_on_finished_at ON public.solid_queue_jobs USING btree (finished_at);


--
-- Name: index_solid_queue_pauses_on_queue_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_pauses_on_queue_name ON public.solid_queue_pauses USING btree (queue_name);


--
-- Name: index_solid_queue_poll_all; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_poll_all ON public.solid_queue_ready_executions USING btree (priority, job_id);


--
-- Name: index_solid_queue_poll_by_queue; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_poll_by_queue ON public.solid_queue_ready_executions USING btree (queue_name, priority, job_id);


--
-- Name: index_solid_queue_processes_on_last_heartbeat_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_processes_on_last_heartbeat_at ON public.solid_queue_processes USING btree (last_heartbeat_at);


--
-- Name: index_solid_queue_processes_on_name_and_supervisor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_processes_on_name_and_supervisor_id ON public.solid_queue_processes USING btree (name, supervisor_id);


--
-- Name: index_solid_queue_processes_on_supervisor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_processes_on_supervisor_id ON public.solid_queue_processes USING btree (supervisor_id);


--
-- Name: index_solid_queue_ready_executions_on_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_ready_executions_on_job_id ON public.solid_queue_ready_executions USING btree (job_id);


--
-- Name: index_solid_queue_recurring_executions_on_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_recurring_executions_on_job_id ON public.solid_queue_recurring_executions USING btree (job_id);


--
-- Name: index_solid_queue_recurring_executions_on_task_key_and_run_at; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_recurring_executions_on_task_key_and_run_at ON public.solid_queue_recurring_executions USING btree (task_key, run_at);


--
-- Name: index_solid_queue_recurring_tasks_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_recurring_tasks_on_key ON public.solid_queue_recurring_tasks USING btree (key);


--
-- Name: index_solid_queue_recurring_tasks_on_static; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_recurring_tasks_on_static ON public.solid_queue_recurring_tasks USING btree (static);


--
-- Name: index_solid_queue_scheduled_executions_on_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_scheduled_executions_on_job_id ON public.solid_queue_scheduled_executions USING btree (job_id);


--
-- Name: index_solid_queue_semaphores_on_expires_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_semaphores_on_expires_at ON public.solid_queue_semaphores USING btree (expires_at);


--
-- Name: index_solid_queue_semaphores_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_semaphores_on_key ON public.solid_queue_semaphores USING btree (key);


--
-- Name: index_solid_queue_semaphores_on_key_and_value; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_semaphores_on_key_and_value ON public.solid_queue_semaphores USING btree (key, value);


--
-- Name: index_users_on_email_address; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email_address ON public.users USING btree (email_address);


--
-- Name: index_users_on_webauthn_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_webauthn_id ON public.users USING btree (webauthn_id);


--
-- Name: conversations fk_rails_00afd02cba; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT fk_rails_00afd02cba FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: conversations fk_rails_15ac80a23a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT fk_rails_15ac80a23a FOREIGN KEY (mailbox_id) REFERENCES public.mailboxes(id);


--
-- Name: agent_messages fk_rails_196cac6033; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_messages
    ADD CONSTRAINT fk_rails_196cac6033 FOREIGN KEY (agent_chat_id) REFERENCES public.agent_chats(id) ON DELETE CASCADE;


--
-- Name: drafts fk_rails_1b49dc20e4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.drafts
    ADD CONSTRAINT fk_rails_1b49dc20e4 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: readings fk_rails_22f92bfeac; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.readings
    ADD CONSTRAINT fk_rails_22f92bfeac FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: access_logs fk_rails_26726b0a1b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.access_logs
    ADD CONSTRAINT fk_rails_26726b0a1b FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: conversation_states fk_rails_2674c34b79; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversation_states
    ADD CONSTRAINT fk_rails_2674c34b79 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: agent_chats fk_rails_27e4b7cdff; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_chats
    ADD CONSTRAINT fk_rails_27e4b7cdff FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: oauth_authorization_codes fk_rails_2df019e87a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_authorization_codes
    ADD CONSTRAINT fk_rails_2df019e87a FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: solid_queue_recurring_executions fk_rails_318a5533ed; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_recurring_executions
    ADD CONSTRAINT fk_rails_318a5533ed FOREIGN KEY (job_id) REFERENCES public.solid_queue_jobs(id) ON DELETE CASCADE;


--
-- Name: messages fk_rails_32bdc0a6b3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT fk_rails_32bdc0a6b3 FOREIGN KEY (mail_folder_id) REFERENCES public.mail_folders(id);


--
-- Name: solid_queue_failed_executions fk_rails_39bbc7a631; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_failed_executions
    ADD CONSTRAINT fk_rails_39bbc7a631 FOREIGN KEY (job_id) REFERENCES public.solid_queue_jobs(id) ON DELETE CASCADE;


--
-- Name: oauth_tokens fk_rails_3f041eeead; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_tokens
    ADD CONSTRAINT fk_rails_3f041eeead FOREIGN KEY (oauth_client_id) REFERENCES public.oauth_clients(id) ON DELETE CASCADE;


--
-- Name: push_subscriptions fk_rails_43d43720fc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.push_subscriptions
    ADD CONSTRAINT fk_rails_43d43720fc FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: access_logs fk_rails_4559f39673; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.access_logs
    ADD CONSTRAINT fk_rails_4559f39673 FOREIGN KEY (message_id) REFERENCES public.messages(id) ON DELETE SET NULL;


--
-- Name: integration_connections fk_rails_45a391073d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integration_connections
    ADD CONSTRAINT fk_rails_45a391073d FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: oauth_authorization_codes fk_rails_46f7342106; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_authorization_codes
    ADD CONSTRAINT fk_rails_46f7342106 FOREIGN KEY (oauth_client_id) REFERENCES public.oauth_clients(id) ON DELETE CASCADE;


--
-- Name: drafts fk_rails_4c9796b117; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.drafts
    ADD CONSTRAINT fk_rails_4c9796b117 FOREIGN KEY (source_message_id) REFERENCES public.messages(id) ON DELETE SET NULL;


--
-- Name: solid_queue_blocked_executions fk_rails_4cd34e2228; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_blocked_executions
    ADD CONSTRAINT fk_rails_4cd34e2228 FOREIGN KEY (job_id) REFERENCES public.solid_queue_jobs(id) ON DELETE CASCADE;


--
-- Name: messages fk_rails_51faa60c81; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT fk_rails_51faa60c81 FOREIGN KEY (mailbox_id) REFERENCES public.mailboxes(id);


--
-- Name: agent_chats fk_rails_562185eab8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_chats
    ADD CONSTRAINT fk_rails_562185eab8 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: drafts fk_rails_5a006091c0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.drafts
    ADD CONSTRAINT fk_rails_5a006091c0 FOREIGN KEY (mailbox_id) REFERENCES public.mailboxes(id);


--
-- Name: readings fk_rails_5ed0692eb7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.readings
    ADD CONSTRAINT fk_rails_5ed0692eb7 FOREIGN KEY (message_id) REFERENCES public.messages(id) ON DELETE CASCADE;


--
-- Name: integrations fk_rails_63f87b241e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integrations
    ADD CONSTRAINT fk_rails_63f87b241e FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: screenings fk_rails_69bdf370d7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.screenings
    ADD CONSTRAINT fk_rails_69bdf370d7 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: screenings fk_rails_6c70b198a7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.screenings
    ADD CONSTRAINT fk_rails_6c70b198a7 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: mail_folders fk_rails_6c7fd64bb4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mail_folders
    ADD CONSTRAINT fk_rails_6c7fd64bb4 FOREIGN KEY (mailbox_id) REFERENCES public.mailboxes(id);


--
-- Name: access_logs fk_rails_703d52b5c3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.access_logs
    ADD CONSTRAINT fk_rails_703d52b5c3 FOREIGN KEY (conversation_id) REFERENCES public.conversations(id) ON DELETE SET NULL;


--
-- Name: mailbox_accesses fk_rails_706fcf23f6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mailbox_accesses
    ADD CONSTRAINT fk_rails_706fcf23f6 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: sessions fk_rails_758836b4f0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT fk_rails_758836b4f0 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: conversation_states fk_rails_760afbe916; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversation_states
    ADD CONSTRAINT fk_rails_760afbe916 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: solid_queue_batch_executions fk_rails_7c5e073422; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_batch_executions
    ADD CONSTRAINT fk_rails_7c5e073422 FOREIGN KEY (batch_id) REFERENCES public.solid_queue_batches(id) ON DELETE CASCADE;


--
-- Name: notes fk_rails_7f2323ad43; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notes
    ADD CONSTRAINT fk_rails_7f2323ad43 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: messages fk_rails_7f927086d2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT fk_rails_7f927086d2 FOREIGN KEY (conversation_id) REFERENCES public.conversations(id);


--
-- Name: solid_queue_ready_executions fk_rails_81fcbd66af; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_ready_executions
    ADD CONSTRAINT fk_rails_81fcbd66af FOREIGN KEY (job_id) REFERENCES public.solid_queue_jobs(id) ON DELETE CASCADE;


--
-- Name: conversation_states fk_rails_84e1c78b15; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversation_states
    ADD CONSTRAINT fk_rails_84e1c78b15 FOREIGN KEY (conversation_id) REFERENCES public.conversations(id) ON DELETE CASCADE;


--
-- Name: api_tokens fk_rails_899213cf3b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_tokens
    ADD CONSTRAINT fk_rails_899213cf3b FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: oauth_tokens fk_rails_8bbd4293ae; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_tokens
    ADD CONSTRAINT fk_rails_8bbd4293ae FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: passkeys fk_rails_902db11bce; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.passkeys
    ADD CONSTRAINT fk_rails_902db11bce FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: integration_connections fk_rails_916b4c71ba; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integration_connections
    ADD CONSTRAINT fk_rails_916b4c71ba FOREIGN KEY (integration_id) REFERENCES public.integrations(id) ON DELETE CASCADE;


--
-- Name: notes fk_rails_9259470eb1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notes
    ADD CONSTRAINT fk_rails_9259470eb1 FOREIGN KEY (conversation_id) REFERENCES public.conversations(id) ON DELETE CASCADE;


--
-- Name: agent_actions fk_rails_95da5b8d36; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_actions
    ADD CONSTRAINT fk_rails_95da5b8d36 FOREIGN KEY (agent_message_id) REFERENCES public.agent_messages(id) ON DELETE CASCADE;


--
-- Name: drafts fk_rails_976b64226f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.drafts
    ADD CONSTRAINT fk_rails_976b64226f FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: mailboxes fk_rails_97a2734fe6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mailboxes
    ADD CONSTRAINT fk_rails_97a2734fe6 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: memberships fk_rails_99326fb65d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.memberships
    ADD CONSTRAINT fk_rails_99326fb65d FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: active_storage_variant_records fk_rails_993965df05; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT fk_rails_993965df05 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: solid_queue_claimed_executions fk_rails_9cfe4d4944; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_claimed_executions
    ADD CONSTRAINT fk_rails_9cfe4d4944 FOREIGN KEY (job_id) REFERENCES public.solid_queue_jobs(id) ON DELETE CASCADE;


--
-- Name: access_logs fk_rails_9fac0b39ba; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.access_logs
    ADD CONSTRAINT fk_rails_9fac0b39ba FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: messages fk_rails_a231e55201; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT fk_rails_a231e55201 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: integration_connections fk_rails_ace6b2880f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integration_connections
    ADD CONSTRAINT fk_rails_ace6b2880f FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: conversations fk_rails_b0388c9502; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT fk_rails_b0388c9502 FOREIGN KEY (assignee_id) REFERENCES public.users(id);


--
-- Name: agent_actions fk_rails_b57dcd447e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_actions
    ADD CONSTRAINT fk_rails_b57dcd447e FOREIGN KEY (decided_by_id) REFERENCES public.users(id);


--
-- Name: mailboxes fk_rails_b75b98abc9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mailboxes
    ADD CONSTRAINT fk_rails_b75b98abc9 FOREIGN KEY (connected_by_id) REFERENCES public.users(id);


--
-- Name: solid_queue_batch_executions fk_rails_bc9f981155; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_batch_executions
    ADD CONSTRAINT fk_rails_bc9f981155 FOREIGN KEY (job_id) REFERENCES public.solid_queue_jobs(id) ON DELETE CASCADE;


--
-- Name: active_storage_attachments fk_rails_c3b3935057; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT fk_rails_c3b3935057 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: solid_queue_scheduled_executions fk_rails_c4316f352d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_scheduled_executions
    ADD CONSTRAINT fk_rails_c4316f352d FOREIGN KEY (job_id) REFERENCES public.solid_queue_jobs(id) ON DELETE CASCADE;


--
-- Name: readings fk_rails_c5c96624d2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.readings
    ADD CONSTRAINT fk_rails_c5c96624d2 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: oauth_authorization_codes fk_rails_c65da3b550; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_authorization_codes
    ADD CONSTRAINT fk_rails_c65da3b550 FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: agent_chats fk_rails_ca2df76a1b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_chats
    ADD CONSTRAINT fk_rails_ca2df76a1b FOREIGN KEY (conversation_id) REFERENCES public.conversations(id) ON DELETE SET NULL;


--
-- Name: mailbox_accesses fk_rails_d78c2686fc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mailbox_accesses
    ADD CONSTRAINT fk_rails_d78c2686fc FOREIGN KEY (mailbox_id) REFERENCES public.mailboxes(id);


--
-- Name: invitations fk_rails_d799c974a1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invitations
    ADD CONSTRAINT fk_rails_d799c974a1 FOREIGN KEY (invited_by_id) REFERENCES public.users(id);


--
-- Name: mailbox_accesses fk_rails_dce3c5a45c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mailbox_accesses
    ADD CONSTRAINT fk_rails_dce3c5a45c FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: oauth_tokens fk_rails_dd28cc2ffe; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_tokens
    ADD CONSTRAINT fk_rails_dd28cc2ffe FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: drafts fk_rails_e1fd7770df; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.drafts
    ADD CONSTRAINT fk_rails_e1fd7770df FOREIGN KEY (conversation_id) REFERENCES public.conversations(id) ON DELETE SET NULL;


--
-- Name: mail_folders fk_rails_e8cdd440af; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mail_folders
    ADD CONSTRAINT fk_rails_e8cdd440af FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: agent_actions fk_rails_ea74f5eb2b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_actions
    ADD CONSTRAINT fk_rails_ea74f5eb2b FOREIGN KEY (agent_chat_id) REFERENCES public.agent_chats(id) ON DELETE CASCADE;


--
-- Name: notes fk_rails_ed57cedfc1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notes
    ADD CONSTRAINT fk_rails_ed57cedfc1 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: memberships fk_rails_edbc202c67; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.memberships
    ADD CONSTRAINT fk_rails_edbc202c67 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: agents fk_rails_ef89880eea; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agents
    ADD CONSTRAINT fk_rails_ef89880eea FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: invitations fk_rails_efd7f68691; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invitations
    ADD CONSTRAINT fk_rails_efd7f68691 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: api_tokens fk_rails_f16b5e0447; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_tokens
    ADD CONSTRAINT fk_rails_f16b5e0447 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: agent_actions fk_rails_f2309f5207; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_actions
    ADD CONSTRAINT fk_rails_f2309f5207 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: agent_messages fk_rails_f425e64a5e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_messages
    ADD CONSTRAINT fk_rails_f425e64a5e FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: access_logs; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.access_logs ENABLE ROW LEVEL SECURITY;

--
-- Name: access_logs account_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY account_isolation ON public.access_logs USING (((current_setting('sg_mail.bypass_rls'::text, true) = 'on'::text) OR (account_id = (NULLIF(current_setting('sg_mail.account_id'::text, true), ''::text))::bigint))) WITH CHECK (((current_setting('sg_mail.bypass_rls'::text, true) = 'on'::text) OR (account_id = (NULLIF(current_setting('sg_mail.account_id'::text, true), ''::text))::bigint)));


--
-- Name: agent_actions account_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY account_isolation ON public.agent_actions USING (((current_setting('sg_mail.bypass_rls'::text, true) = 'on'::text) OR (account_id = (NULLIF(current_setting('sg_mail.account_id'::text, true), ''::text))::bigint))) WITH CHECK (((current_setting('sg_mail.bypass_rls'::text, true) = 'on'::text) OR (account_id = (NULLIF(current_setting('sg_mail.account_id'::text, true), ''::text))::bigint)));


--
-- Name: agent_chats account_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY account_isolation ON public.agent_chats USING (((current_setting('sg_mail.bypass_rls'::text, true) = 'on'::text) OR (account_id = (NULLIF(current_setting('sg_mail.account_id'::text, true), ''::text))::bigint))) WITH CHECK (((current_setting('sg_mail.bypass_rls'::text, true) = 'on'::text) OR (account_id = (NULLIF(current_setting('sg_mail.account_id'::text, true), ''::text))::bigint)));


--
-- Name: agent_messages account_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY account_isolation ON public.agent_messages USING (((current_setting('sg_mail.bypass_rls'::text, true) = 'on'::text) OR (account_id = (NULLIF(current_setting('sg_mail.account_id'::text, true), ''::text))::bigint))) WITH CHECK (((current_setting('sg_mail.bypass_rls'::text, true) = 'on'::text) OR (account_id = (NULLIF(current_setting('sg_mail.account_id'::text, true), ''::text))::bigint)));


--
-- Name: conversation_states account_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY account_isolation ON public.conversation_states USING (((current_setting('sg_mail.bypass_rls'::text, true) = 'on'::text) OR (account_id = (NULLIF(current_setting('sg_mail.account_id'::text, true), ''::text))::bigint))) WITH CHECK (((current_setting('sg_mail.bypass_rls'::text, true) = 'on'::text) OR (account_id = (NULLIF(current_setting('sg_mail.account_id'::text, true), ''::text))::bigint)));


--
-- Name: conversations account_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY account_isolation ON public.conversations USING (((current_setting('sg_mail.bypass_rls'::text, true) = 'on'::text) OR (account_id = (NULLIF(current_setting('sg_mail.account_id'::text, true), ''::text))::bigint))) WITH CHECK (((current_setting('sg_mail.bypass_rls'::text, true) = 'on'::text) OR (account_id = (NULLIF(current_setting('sg_mail.account_id'::text, true), ''::text))::bigint)));


--
-- Name: drafts account_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY account_isolation ON public.drafts USING (((current_setting('sg_mail.bypass_rls'::text, true) = 'on'::text) OR (account_id = (NULLIF(current_setting('sg_mail.account_id'::text, true), ''::text))::bigint))) WITH CHECK (((current_setting('sg_mail.bypass_rls'::text, true) = 'on'::text) OR (account_id = (NULLIF(current_setting('sg_mail.account_id'::text, true), ''::text))::bigint)));


--
-- Name: integration_connections account_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY account_isolation ON public.integration_connections USING (((current_setting('sg_mail.bypass_rls'::text, true) = 'on'::text) OR (account_id = (NULLIF(current_setting('sg_mail.account_id'::text, true), ''::text))::bigint))) WITH CHECK (((current_setting('sg_mail.bypass_rls'::text, true) = 'on'::text) OR (account_id = (NULLIF(current_setting('sg_mail.account_id'::text, true), ''::text))::bigint)));


--
-- Name: integrations account_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY account_isolation ON public.integrations USING (((current_setting('sg_mail.bypass_rls'::text, true) = 'on'::text) OR (account_id = (NULLIF(current_setting('sg_mail.account_id'::text, true), ''::text))::bigint))) WITH CHECK (((current_setting('sg_mail.bypass_rls'::text, true) = 'on'::text) OR (account_id = (NULLIF(current_setting('sg_mail.account_id'::text, true), ''::text))::bigint)));


--
-- Name: mail_folders account_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY account_isolation ON public.mail_folders USING (((current_setting('sg_mail.bypass_rls'::text, true) = 'on'::text) OR (account_id = (NULLIF(current_setting('sg_mail.account_id'::text, true), ''::text))::bigint))) WITH CHECK (((current_setting('sg_mail.bypass_rls'::text, true) = 'on'::text) OR (account_id = (NULLIF(current_setting('sg_mail.account_id'::text, true), ''::text))::bigint)));


--
-- Name: mailbox_accesses account_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY account_isolation ON public.mailbox_accesses USING (((current_setting('sg_mail.bypass_rls'::text, true) = 'on'::text) OR (account_id = (NULLIF(current_setting('sg_mail.account_id'::text, true), ''::text))::bigint))) WITH CHECK (((current_setting('sg_mail.bypass_rls'::text, true) = 'on'::text) OR (account_id = (NULLIF(current_setting('sg_mail.account_id'::text, true), ''::text))::bigint)));


--
-- Name: mailboxes account_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY account_isolation ON public.mailboxes USING (((current_setting('sg_mail.bypass_rls'::text, true) = 'on'::text) OR (account_id = (NULLIF(current_setting('sg_mail.account_id'::text, true), ''::text))::bigint))) WITH CHECK (((current_setting('sg_mail.bypass_rls'::text, true) = 'on'::text) OR (account_id = (NULLIF(current_setting('sg_mail.account_id'::text, true), ''::text))::bigint)));


--
-- Name: messages account_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY account_isolation ON public.messages USING (((current_setting('sg_mail.bypass_rls'::text, true) = 'on'::text) OR (account_id = (NULLIF(current_setting('sg_mail.account_id'::text, true), ''::text))::bigint))) WITH CHECK (((current_setting('sg_mail.bypass_rls'::text, true) = 'on'::text) OR (account_id = (NULLIF(current_setting('sg_mail.account_id'::text, true), ''::text))::bigint)));


--
-- Name: notes account_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY account_isolation ON public.notes USING (((current_setting('sg_mail.bypass_rls'::text, true) = 'on'::text) OR (account_id = (NULLIF(current_setting('sg_mail.account_id'::text, true), ''::text))::bigint))) WITH CHECK (((current_setting('sg_mail.bypass_rls'::text, true) = 'on'::text) OR (account_id = (NULLIF(current_setting('sg_mail.account_id'::text, true), ''::text))::bigint)));


--
-- Name: readings account_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY account_isolation ON public.readings USING (((current_setting('sg_mail.bypass_rls'::text, true) = 'on'::text) OR (account_id = (NULLIF(current_setting('sg_mail.account_id'::text, true), ''::text))::bigint))) WITH CHECK (((current_setting('sg_mail.bypass_rls'::text, true) = 'on'::text) OR (account_id = (NULLIF(current_setting('sg_mail.account_id'::text, true), ''::text))::bigint)));


--
-- Name: screenings account_isolation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY account_isolation ON public.screenings USING (((current_setting('sg_mail.bypass_rls'::text, true) = 'on'::text) OR (account_id = (NULLIF(current_setting('sg_mail.account_id'::text, true), ''::text))::bigint))) WITH CHECK (((current_setting('sg_mail.bypass_rls'::text, true) = 'on'::text) OR (account_id = (NULLIF(current_setting('sg_mail.account_id'::text, true), ''::text))::bigint)));


--
-- Name: agent_actions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.agent_actions ENABLE ROW LEVEL SECURITY;

--
-- Name: agent_chats; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.agent_chats ENABLE ROW LEVEL SECURITY;

--
-- Name: agent_messages; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.agent_messages ENABLE ROW LEVEL SECURITY;

--
-- Name: conversation_states; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.conversation_states ENABLE ROW LEVEL SECURITY;

--
-- Name: conversations; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;

--
-- Name: drafts; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.drafts ENABLE ROW LEVEL SECURITY;

--
-- Name: integration_connections; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.integration_connections ENABLE ROW LEVEL SECURITY;

--
-- Name: integrations; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.integrations ENABLE ROW LEVEL SECURITY;

--
-- Name: mail_folders; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.mail_folders ENABLE ROW LEVEL SECURITY;

--
-- Name: mailbox_accesses; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.mailbox_accesses ENABLE ROW LEVEL SECURITY;

--
-- Name: mailboxes; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.mailboxes ENABLE ROW LEVEL SECURITY;

--
-- Name: messages; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

--
-- Name: notes; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.notes ENABLE ROW LEVEL SECURITY;

--
-- Name: readings; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.readings ENABLE ROW LEVEL SECURITY;

--
-- Name: screenings; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.screenings ENABLE ROW LEVEL SECURITY;

--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20261031230000'),
('20261030230000'),
('20261030180000'),
('20261030170000'),
('20261030160000'),
('20261030080000'),
('20261029230000'),
('20261029220247'),
('20261029220000'),
('20261029200000'),
('20261028220000'),
('20261028150000'),
('20261028140000'),
('20261028130000'),
('20261028120000'),
('20261028110000'),
('20261028100000'),
('20261028090000'),
('20261028080000'),
('20261027230000'),
('20261027224500'),
('20261027223000'),
('20261027220000'),
('20261027213000'),
('20261027210000'),
('20261027203000'),
('20261027200000'),
('20261027194405'),
('20261027194404'),
('20261027194403'),
('20261027194402'),
('20261027194401'),
('20261027194400'),
('20261027102329'),
('20261027102327'),
('20261027102326');

