--
-- PostgreSQL database dump
--

-- Dumped from database version 17.5
-- Dumped by pg_dump version 17.5

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: cost_client_app
--

-- *not* creating schema, since initdb creates it


ALTER SCHEMA public OWNER TO cost_client_app;

--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: cost_client_app
--

COMMENT ON SCHEMA public IS '';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: app_operations_log; Type: TABLE; Schema: public; Owner: cost_client_app
--

CREATE TABLE public.app_operations_log (
    id integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    operation_type character varying(100) NOT NULL,
    description text NOT NULL,
    amount numeric(14,2),
    details text
);


ALTER TABLE public.app_operations_log OWNER TO cost_client_app;

--
-- Data for Name: app_operations_log; Type: TABLE DATA; Schema: public; Owner: cost_client_app
--

COPY public.app_operations_log (id, created_at, operation_type, description, amount, details) FROM stdin;
\.


--
-- Name: idx_app_operations_log_created_at; Type: INDEX; Schema: public; Owner: cost_client_app
--

CREATE INDEX idx_app_operations_log_created_at ON public.app_operations_log USING btree (created_at DESC);


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: cost_client_app
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

