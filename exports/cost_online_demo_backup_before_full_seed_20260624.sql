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
-- Name: app_operations_log_id_seq; Type: SEQUENCE; Schema: public; Owner: cost_client_app
--

CREATE SEQUENCE public.app_operations_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.app_operations_log_id_seq OWNER TO cost_client_app;

--
-- Name: app_operations_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: cost_client_app
--

ALTER SEQUENCE public.app_operations_log_id_seq OWNED BY public.app_operations_log.id;


--
-- Name: balance; Type: TABLE; Schema: public; Owner: cost_client_app
--

CREATE TABLE public.balance (
    id integer NOT NULL,
    date date DEFAULT CURRENT_DATE,
    income numeric(12,2) DEFAULT 0,
    expense numeric(12,2) DEFAULT 0,
    notes text,
    is_cash boolean DEFAULT false
);


ALTER TABLE public.balance OWNER TO cost_client_app;

--
-- Name: balance_id_seq; Type: SEQUENCE; Schema: public; Owner: cost_client_app
--

CREATE SEQUENCE public.balance_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.balance_id_seq OWNER TO cost_client_app;

--
-- Name: balance_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: cost_client_app
--

ALTER SEQUENCE public.balance_id_seq OWNED BY public.balance.id;


--
-- Name: composite_material_recipe_items; Type: TABLE; Schema: public; Owner: cost_client_app
--

CREATE TABLE public.composite_material_recipe_items (
    id integer NOT NULL,
    recipe_id integer NOT NULL,
    material_id integer NOT NULL,
    quantity numeric(12,4) DEFAULT 0 NOT NULL
);


ALTER TABLE public.composite_material_recipe_items OWNER TO cost_client_app;

--
-- Name: composite_material_recipe_items_id_seq; Type: SEQUENCE; Schema: public; Owner: cost_client_app
--

CREATE SEQUENCE public.composite_material_recipe_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.composite_material_recipe_items_id_seq OWNER TO cost_client_app;

--
-- Name: composite_material_recipe_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: cost_client_app
--

ALTER SEQUENCE public.composite_material_recipe_items_id_seq OWNED BY public.composite_material_recipe_items.id;


--
-- Name: composite_material_recipes; Type: TABLE; Schema: public; Owner: cost_client_app
--

CREATE TABLE public.composite_material_recipes (
    id integer NOT NULL,
    output_material_id integer NOT NULL,
    output_quantity numeric(12,4) DEFAULT 1 NOT NULL,
    notes text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.composite_material_recipes OWNER TO cost_client_app;

--
-- Name: composite_material_recipes_id_seq; Type: SEQUENCE; Schema: public; Owner: cost_client_app
--

CREATE SEQUENCE public.composite_material_recipes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.composite_material_recipes_id_seq OWNER TO cost_client_app;

--
-- Name: composite_material_recipes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: cost_client_app
--

ALTER SEQUENCE public.composite_material_recipes_id_seq OWNED BY public.composite_material_recipes.id;


--
-- Name: employee_bonus_payments; Type: TABLE; Schema: public; Owner: cost_client_app
--

CREATE TABLE public.employee_bonus_payments (
    id integer NOT NULL,
    period_start date NOT NULL,
    period_end date NOT NULL,
    bonus_percent numeric(8,2) NOT NULL,
    base_amount numeric(12,2) DEFAULT 0 NOT NULL,
    bonus_amount numeric(12,2) DEFAULT 0 NOT NULL,
    paid_until date NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.employee_bonus_payments OWNER TO cost_client_app;

--
-- Name: employee_bonus_payments_id_seq; Type: SEQUENCE; Schema: public; Owner: cost_client_app
--

CREATE SEQUENCE public.employee_bonus_payments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.employee_bonus_payments_id_seq OWNER TO cost_client_app;

--
-- Name: employee_bonus_payments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: cost_client_app
--

ALTER SEQUENCE public.employee_bonus_payments_id_seq OWNED BY public.employee_bonus_payments.id;


--
-- Name: employee_settlements; Type: TABLE; Schema: public; Owner: cost_client_app
--

CREATE TABLE public.employee_settlements (
    id integer NOT NULL,
    employee_id integer,
    settlement_type character varying(20) NOT NULL,
    settlement_date date DEFAULT CURRENT_DATE NOT NULL,
    title character varying(255) NOT NULL,
    amount numeric(12,2) DEFAULT 0 NOT NULL,
    notes text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.employee_settlements OWNER TO cost_client_app;

--
-- Name: employee_settlements_id_seq; Type: SEQUENCE; Schema: public; Owner: cost_client_app
--

CREATE SEQUENCE public.employee_settlements_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.employee_settlements_id_seq OWNER TO cost_client_app;

--
-- Name: employee_settlements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: cost_client_app
--

ALTER SEQUENCE public.employee_settlements_id_seq OWNED BY public.employee_settlements.id;


--
-- Name: employees; Type: TABLE; Schema: public; Owner: cost_client_app
--

CREATE TABLE public.employees (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    hourly_rate numeric(10,2),
    "position" character varying(100),
    active boolean DEFAULT true
);


ALTER TABLE public.employees OWNER TO cost_client_app;

--
-- Name: employees_id_seq; Type: SEQUENCE; Schema: public; Owner: cost_client_app
--

CREATE SEQUENCE public.employees_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.employees_id_seq OWNER TO cost_client_app;

--
-- Name: employees_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: cost_client_app
--

ALTER SEQUENCE public.employees_id_seq OWNED BY public.employees.id;


--
-- Name: finished_good_labor; Type: TABLE; Schema: public; Owner: cost_client_app
--

CREATE TABLE public.finished_good_labor (
    id integer NOT NULL,
    finished_good_id integer,
    work_log_id integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.finished_good_labor OWNER TO cost_client_app;

--
-- Name: finished_good_labor_id_seq; Type: SEQUENCE; Schema: public; Owner: cost_client_app
--

CREATE SEQUENCE public.finished_good_labor_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.finished_good_labor_id_seq OWNER TO cost_client_app;

--
-- Name: finished_good_labor_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: cost_client_app
--

ALTER SEQUENCE public.finished_good_labor_id_seq OWNED BY public.finished_good_labor.id;


--
-- Name: finished_good_material_consumptions; Type: TABLE; Schema: public; Owner: cost_client_app
--

CREATE TABLE public.finished_good_material_consumptions (
    id integer NOT NULL,
    finished_good_id integer,
    material_id integer,
    purchase_id integer,
    quantity numeric(12,4) DEFAULT 0 NOT NULL,
    amount numeric(12,2) DEFAULT 0 NOT NULL,
    is_cash boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.finished_good_material_consumptions OWNER TO cost_client_app;

--
-- Name: finished_good_material_consumptions_id_seq; Type: SEQUENCE; Schema: public; Owner: cost_client_app
--

CREATE SEQUENCE public.finished_good_material_consumptions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.finished_good_material_consumptions_id_seq OWNER TO cost_client_app;

--
-- Name: finished_good_material_consumptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: cost_client_app
--

ALTER SEQUENCE public.finished_good_material_consumptions_id_seq OWNED BY public.finished_good_material_consumptions.id;


--
-- Name: finished_good_material_reservations; Type: TABLE; Schema: public; Owner: cost_client_app
--

CREATE TABLE public.finished_good_material_reservations (
    id integer NOT NULL,
    finished_good_id integer,
    material_id integer,
    purchase_id integer,
    quantity numeric(12,4) DEFAULT 0 NOT NULL,
    amount numeric(12,2) DEFAULT 0 NOT NULL,
    is_cash boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.finished_good_material_reservations OWNER TO cost_client_app;

--
-- Name: finished_good_material_reservations_id_seq; Type: SEQUENCE; Schema: public; Owner: cost_client_app
--

CREATE SEQUENCE public.finished_good_material_reservations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.finished_good_material_reservations_id_seq OWNER TO cost_client_app;

--
-- Name: finished_good_material_reservations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: cost_client_app
--

ALTER SEQUENCE public.finished_good_material_reservations_id_seq OWNED BY public.finished_good_material_reservations.id;


--
-- Name: finished_goods; Type: TABLE; Schema: public; Owner: cost_client_app
--

CREATE TABLE public.finished_goods (
    id integer NOT NULL,
    machine_model character varying(255) NOT NULL,
    machine_id integer,
    cost_price numeric(12,2) NOT NULL,
    produced_date date DEFAULT CURRENT_DATE,
    status character varying(20) DEFAULT 'in_stock'::character varying,
    inventory_number character varying(50),
    buyer character varying(255),
    sale_date date,
    notes text,
    start_date date,
    indirect_cost numeric(12,2) DEFAULT 0,
    misc_expense_cost numeric(12,2) DEFAULT 0,
    production_status character varying(20) DEFAULT 'in_progress'::character varying
);


ALTER TABLE public.finished_goods OWNER TO cost_client_app;

--
-- Name: finished_goods_id_seq; Type: SEQUENCE; Schema: public; Owner: cost_client_app
--

CREATE SEQUENCE public.finished_goods_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.finished_goods_id_seq OWNER TO cost_client_app;

--
-- Name: finished_goods_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: cost_client_app
--

ALTER SEQUENCE public.finished_goods_id_seq OWNED BY public.finished_goods.id;


--
-- Name: indirect_cost_allocations; Type: TABLE; Schema: public; Owner: cost_client_app
--

CREATE TABLE public.indirect_cost_allocations (
    id integer NOT NULL,
    category_id integer,
    finished_good_id integer,
    allocation_date date NOT NULL,
    amount numeric(12,4) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.indirect_cost_allocations OWNER TO cost_client_app;

--
-- Name: indirect_cost_allocations_id_seq; Type: SEQUENCE; Schema: public; Owner: cost_client_app
--

CREATE SEQUENCE public.indirect_cost_allocations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.indirect_cost_allocations_id_seq OWNER TO cost_client_app;

--
-- Name: indirect_cost_allocations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: cost_client_app
--

ALTER SEQUENCE public.indirect_cost_allocations_id_seq OWNED BY public.indirect_cost_allocations.id;


--
-- Name: indirect_expense_categories; Type: TABLE; Schema: public; Owner: cost_client_app
--

CREATE TABLE public.indirect_expense_categories (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    monthly_amount numeric(12,2) NOT NULL,
    is_active boolean DEFAULT true,
    notes text,
    is_cash boolean DEFAULT false
);


ALTER TABLE public.indirect_expense_categories OWNER TO cost_client_app;

--
-- Name: indirect_expense_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: cost_client_app
--

CREATE SEQUENCE public.indirect_expense_categories_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.indirect_expense_categories_id_seq OWNER TO cost_client_app;

--
-- Name: indirect_expense_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: cost_client_app
--

ALTER SEQUENCE public.indirect_expense_categories_id_seq OWNED BY public.indirect_expense_categories.id;


--
-- Name: inventory_adjustments; Type: TABLE; Schema: public; Owner: cost_client_app
--

CREATE TABLE public.inventory_adjustments (
    id integer NOT NULL,
    material_id integer,
    old_quantity numeric(12,4),
    new_quantity numeric(12,4),
    difference numeric(12,4),
    reason text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.inventory_adjustments OWNER TO cost_client_app;

--
-- Name: inventory_adjustments_id_seq; Type: SEQUENCE; Schema: public; Owner: cost_client_app
--

CREATE SEQUENCE public.inventory_adjustments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.inventory_adjustments_id_seq OWNER TO cost_client_app;

--
-- Name: inventory_adjustments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: cost_client_app
--

ALTER SEQUENCE public.inventory_adjustments_id_seq OWNED BY public.inventory_adjustments.id;


--
-- Name: machine_labor_costs; Type: TABLE; Schema: public; Owner: cost_client_app
--

CREATE TABLE public.machine_labor_costs (
    machine_id integer NOT NULL,
    work_type_id integer NOT NULL,
    fixed_cost numeric(12,2),
    estimated_hours numeric(10,2)
);


ALTER TABLE public.machine_labor_costs OWNER TO cost_client_app;

--
-- Name: machine_materials; Type: TABLE; Schema: public; Owner: cost_client_app
--

CREATE TABLE public.machine_materials (
    machine_id integer NOT NULL,
    material_id integer NOT NULL,
    quantity numeric(12,4) NOT NULL
);


ALTER TABLE public.machine_materials OWNER TO cost_client_app;

--
-- Name: machine_tools; Type: TABLE; Schema: public; Owner: cost_client_app
--

CREATE TABLE public.machine_tools (
    machine_id integer NOT NULL,
    tool_id integer NOT NULL,
    usage_per_unit numeric(10,4)
);


ALTER TABLE public.machine_tools OWNER TO cost_client_app;

--
-- Name: machines; Type: TABLE; Schema: public; Owner: cost_client_app
--

CREATE TABLE public.machines (
    id integer NOT NULL,
    model character varying(255) NOT NULL,
    total_cost numeric(12,2) DEFAULT 0
);


ALTER TABLE public.machines OWNER TO cost_client_app;

--
-- Name: machines_id_seq; Type: SEQUENCE; Schema: public; Owner: cost_client_app
--

CREATE SEQUENCE public.machines_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.machines_id_seq OWNER TO cost_client_app;

--
-- Name: machines_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: cost_client_app
--

ALTER SEQUENCE public.machines_id_seq OWNED BY public.machines.id;


--
-- Name: material_conversions; Type: TABLE; Schema: public; Owner: cost_client_app
--

CREATE TABLE public.material_conversions (
    id integer NOT NULL,
    source_material_id integer,
    source_purchase_id integer,
    target_material_id integer,
    source_quantity numeric(12,4) DEFAULT 0 NOT NULL,
    target_quantity numeric(12,4) DEFAULT 0 NOT NULL,
    total_cost numeric(12,2) DEFAULT 0 NOT NULL,
    notes text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    template_id integer
);


ALTER TABLE public.material_conversions OWNER TO cost_client_app;

--
-- Name: material_conversions_id_seq; Type: SEQUENCE; Schema: public; Owner: cost_client_app
--

CREATE SEQUENCE public.material_conversions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.material_conversions_id_seq OWNER TO cost_client_app;

--
-- Name: material_conversions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: cost_client_app
--

ALTER SEQUENCE public.material_conversions_id_seq OWNED BY public.material_conversions.id;


--
-- Name: material_inventory; Type: TABLE; Schema: public; Owner: cost_client_app
--

CREATE TABLE public.material_inventory (
    material_id integer NOT NULL,
    quantity numeric(12,4) DEFAULT 0 NOT NULL
);


ALTER TABLE public.material_inventory OWNER TO cost_client_app;

--
-- Name: material_transactions; Type: TABLE; Schema: public; Owner: cost_client_app
--

CREATE TABLE public.material_transactions (
    id integer NOT NULL,
    material_id integer,
    quantity_change numeric(12,4),
    transaction_type character varying(20),
    reference_id integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.material_transactions OWNER TO cost_client_app;

--
-- Name: material_transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: cost_client_app
--

CREATE SEQUENCE public.material_transactions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.material_transactions_id_seq OWNER TO cost_client_app;

--
-- Name: material_transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: cost_client_app
--

ALTER SEQUENCE public.material_transactions_id_seq OWNED BY public.material_transactions.id;


--
-- Name: material_types; Type: TABLE; Schema: public; Owner: cost_client_app
--

CREATE TABLE public.material_types (
    id integer NOT NULL,
    name character varying(100) NOT NULL
);


ALTER TABLE public.material_types OWNER TO cost_client_app;

--
-- Name: material_types_id_seq; Type: SEQUENCE; Schema: public; Owner: cost_client_app
--

CREATE SEQUENCE public.material_types_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.material_types_id_seq OWNER TO cost_client_app;

--
-- Name: material_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: cost_client_app
--

ALTER SEQUENCE public.material_types_id_seq OWNED BY public.material_types.id;


--
-- Name: materials; Type: TABLE; Schema: public; Owner: cost_client_app
--

CREATE TABLE public.materials (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    unit character varying(50),
    type_id integer,
    product_url text,
    notes text,
    source text,
    updated_date date DEFAULT CURRENT_DATE,
    is_plate boolean DEFAULT false,
    plate_material_type_id integer,
    low_stock_threshold numeric(12,3) DEFAULT 1,
    enough_stock_threshold numeric(12,3) DEFAULT 3,
    category character varying(100) DEFAULT 'Материалы'::character varying
);


ALTER TABLE public.materials OWNER TO cost_client_app;

--
-- Name: materials_id_seq; Type: SEQUENCE; Schema: public; Owner: cost_client_app
--

CREATE SEQUENCE public.materials_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.materials_id_seq OWNER TO cost_client_app;

--
-- Name: materials_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: cost_client_app
--

ALTER SEQUENCE public.materials_id_seq OWNED BY public.materials.id;


--
-- Name: misc_expense_machine_links; Type: TABLE; Schema: public; Owner: cost_client_app
--

CREATE TABLE public.misc_expense_machine_links (
    expense_id integer NOT NULL,
    finished_good_id integer NOT NULL,
    allocated_amount numeric(12,2) DEFAULT 0 NOT NULL
);


ALTER TABLE public.misc_expense_machine_links OWNER TO cost_client_app;

--
-- Name: misc_expenses; Type: TABLE; Schema: public; Owner: cost_client_app
--

CREATE TABLE public.misc_expenses (
    id integer NOT NULL,
    expense_date date DEFAULT CURRENT_DATE NOT NULL,
    title character varying(255) NOT NULL,
    amount numeric(12,2) NOT NULL,
    notes text,
    is_cash boolean DEFAULT false,
    person_name character varying(255),
    allocation_mode character varying(20) DEFAULT 'none'::character varying NOT NULL,
    balance_entry_id integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.misc_expenses OWNER TO cost_client_app;

--
-- Name: misc_expenses_id_seq; Type: SEQUENCE; Schema: public; Owner: cost_client_app
--

CREATE SEQUENCE public.misc_expenses_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.misc_expenses_id_seq OWNER TO cost_client_app;

--
-- Name: misc_expenses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: cost_client_app
--

ALTER SEQUENCE public.misc_expenses_id_seq OWNED BY public.misc_expenses.id;


--
-- Name: plate_material_types; Type: TABLE; Schema: public; Owner: cost_client_app
--

CREATE TABLE public.plate_material_types (
    id integer NOT NULL,
    name character varying(100) NOT NULL
);


ALTER TABLE public.plate_material_types OWNER TO cost_client_app;

--
-- Name: plate_part_templates; Type: TABLE; Schema: public; Owner: cost_client_app
--

CREATE TABLE public.plate_part_templates (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    plate_material_type_id integer NOT NULL,
    part_unit character varying(50) DEFAULT 'шт'::character varying NOT NULL,
    production_minutes integer DEFAULT 0 NOT NULL,
    drawing_file_path text,
    process_file_path text,
    notes text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    drawing_file_name text,
    drawing_file_data bytea,
    process_file_name text,
    process_file_data bytea,
    is_active boolean DEFAULT true
);


ALTER TABLE public.plate_part_templates OWNER TO cost_client_app;

--
-- Name: plate_part_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: cost_client_app
--

CREATE SEQUENCE public.plate_part_templates_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.plate_part_templates_id_seq OWNER TO cost_client_app;

--
-- Name: plate_part_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: cost_client_app
--

ALTER SEQUENCE public.plate_part_templates_id_seq OWNED BY public.plate_part_templates.id;


--
-- Name: purchases; Type: TABLE; Schema: public; Owner: cost_client_app
--

CREATE TABLE public.purchases (
    id integer NOT NULL,
    material_id integer,
    supplier_id integer,
    purchase_date date,
    price_per_unit numeric(12,2),
    quantity numeric(12,4),
    remaining_quantity numeric(12,4),
    purchased_by character varying(100),
    notes text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    is_cash boolean DEFAULT false
);


ALTER TABLE public.purchases OWNER TO cost_client_app;

--
-- Name: purchases_id_seq; Type: SEQUENCE; Schema: public; Owner: cost_client_app
--

CREATE SEQUENCE public.purchases_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.purchases_id_seq OWNER TO cost_client_app;

--
-- Name: purchases_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: cost_client_app
--

ALTER SEQUENCE public.purchases_id_seq OWNED BY public.purchases.id;


--
-- Name: sales; Type: TABLE; Schema: public; Owner: cost_client_app
--

CREATE TABLE public.sales (
    id integer NOT NULL,
    finished_good_id integer,
    sale_date date DEFAULT CURRENT_DATE,
    sale_price numeric(12,2) NOT NULL,
    profit numeric(12,2)
);


ALTER TABLE public.sales OWNER TO cost_client_app;

--
-- Name: sales_id_seq; Type: SEQUENCE; Schema: public; Owner: cost_client_app
--

CREATE SEQUENCE public.sales_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sales_id_seq OWNER TO cost_client_app;

--
-- Name: sales_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: cost_client_app
--

ALTER SEQUENCE public.sales_id_seq OWNED BY public.sales.id;


--
-- Name: suppliers; Type: TABLE; Schema: public; Owner: cost_client_app
--

CREATE TABLE public.suppliers (
    id integer NOT NULL,
    name character varying(255) NOT NULL
);


ALTER TABLE public.suppliers OWNER TO cost_client_app;

--
-- Name: suppliers_id_seq; Type: SEQUENCE; Schema: public; Owner: cost_client_app
--

CREATE SEQUENCE public.suppliers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.suppliers_id_seq OWNER TO cost_client_app;

--
-- Name: suppliers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: cost_client_app
--

ALTER SEQUENCE public.suppliers_id_seq OWNED BY public.suppliers.id;


--
-- Name: tax_payments; Type: TABLE; Schema: public; Owner: cost_client_app
--

CREATE TABLE public.tax_payments (
    id integer NOT NULL,
    payment_date date DEFAULT CURRENT_DATE NOT NULL,
    period_start date NOT NULL,
    period_end date NOT NULL,
    tax_rate numeric(8,2) DEFAULT 0 NOT NULL,
    tax_base numeric(12,2) DEFAULT 0 NOT NULL,
    tax_amount numeric(12,2) DEFAULT 0 NOT NULL,
    notes text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.tax_payments OWNER TO cost_client_app;

--
-- Name: tax_payments_id_seq; Type: SEQUENCE; Schema: public; Owner: cost_client_app
--

CREATE SEQUENCE public.tax_payments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tax_payments_id_seq OWNER TO cost_client_app;

--
-- Name: tax_payments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: cost_client_app
--

ALTER SEQUENCE public.tax_payments_id_seq OWNED BY public.tax_payments.id;


--
-- Name: tool_depreciation; Type: TABLE; Schema: public; Owner: cost_client_app
--

CREATE TABLE public.tool_depreciation (
    id integer NOT NULL,
    tool_id integer,
    depreciation_date date DEFAULT CURRENT_DATE,
    amount numeric(12,2) NOT NULL,
    finished_good_id integer,
    notes text
);


ALTER TABLE public.tool_depreciation OWNER TO cost_client_app;

--
-- Name: tool_depreciation_id_seq; Type: SEQUENCE; Schema: public; Owner: cost_client_app
--

CREATE SEQUENCE public.tool_depreciation_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tool_depreciation_id_seq OWNER TO cost_client_app;

--
-- Name: tool_depreciation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: cost_client_app
--

ALTER SEQUENCE public.tool_depreciation_id_seq OWNED BY public.tool_depreciation.id;


--
-- Name: tools; Type: TABLE; Schema: public; Owner: cost_client_app
--

CREATE TABLE public.tools (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    inventory_number character varying(50),
    purchase_date date,
    purchase_cost numeric(12,2) NOT NULL,
    useful_life_months integer,
    monthly_depreciation numeric(12,2),
    residual_value numeric(12,2),
    status character varying(20) DEFAULT 'active'::character varying,
    notes text
);


ALTER TABLE public.tools OWNER TO cost_client_app;

--
-- Name: tools_id_seq; Type: SEQUENCE; Schema: public; Owner: cost_client_app
--

CREATE SEQUENCE public.tools_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tools_id_seq OWNER TO cost_client_app;

--
-- Name: tools_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: cost_client_app
--

ALTER SEQUENCE public.tools_id_seq OWNED BY public.tools.id;


--
-- Name: work_logs; Type: TABLE; Schema: public; Owner: cost_client_app
--

CREATE TABLE public.work_logs (
    id integer NOT NULL,
    employee_id integer,
    work_type_id integer,
    machine_id integer,
    date date DEFAULT CURRENT_DATE,
    hours numeric(10,2) NOT NULL,
    notes text
);


ALTER TABLE public.work_logs OWNER TO cost_client_app;

--
-- Name: work_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: cost_client_app
--

CREATE SEQUENCE public.work_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.work_logs_id_seq OWNER TO cost_client_app;

--
-- Name: work_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: cost_client_app
--

ALTER SEQUENCE public.work_logs_id_seq OWNED BY public.work_logs.id;


--
-- Name: work_types; Type: TABLE; Schema: public; Owner: cost_client_app
--

CREATE TABLE public.work_types (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    description text
);


ALTER TABLE public.work_types OWNER TO cost_client_app;

--
-- Name: work_types_id_seq; Type: SEQUENCE; Schema: public; Owner: cost_client_app
--

CREATE SEQUENCE public.work_types_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.work_types_id_seq OWNER TO cost_client_app;

--
-- Name: work_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: cost_client_app
--

ALTER SEQUENCE public.work_types_id_seq OWNED BY public.work_types.id;


--
-- Name: app_operations_log id; Type: DEFAULT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.app_operations_log ALTER COLUMN id SET DEFAULT nextval('public.app_operations_log_id_seq'::regclass);


--
-- Name: balance id; Type: DEFAULT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.balance ALTER COLUMN id SET DEFAULT nextval('public.balance_id_seq'::regclass);


--
-- Name: composite_material_recipe_items id; Type: DEFAULT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.composite_material_recipe_items ALTER COLUMN id SET DEFAULT nextval('public.composite_material_recipe_items_id_seq'::regclass);


--
-- Name: composite_material_recipes id; Type: DEFAULT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.composite_material_recipes ALTER COLUMN id SET DEFAULT nextval('public.composite_material_recipes_id_seq'::regclass);


--
-- Name: employee_bonus_payments id; Type: DEFAULT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.employee_bonus_payments ALTER COLUMN id SET DEFAULT nextval('public.employee_bonus_payments_id_seq'::regclass);


--
-- Name: employee_settlements id; Type: DEFAULT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.employee_settlements ALTER COLUMN id SET DEFAULT nextval('public.employee_settlements_id_seq'::regclass);


--
-- Name: employees id; Type: DEFAULT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.employees ALTER COLUMN id SET DEFAULT nextval('public.employees_id_seq'::regclass);


--
-- Name: finished_good_labor id; Type: DEFAULT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.finished_good_labor ALTER COLUMN id SET DEFAULT nextval('public.finished_good_labor_id_seq'::regclass);


--
-- Name: finished_good_material_consumptions id; Type: DEFAULT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.finished_good_material_consumptions ALTER COLUMN id SET DEFAULT nextval('public.finished_good_material_consumptions_id_seq'::regclass);


--
-- Name: finished_good_material_reservations id; Type: DEFAULT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.finished_good_material_reservations ALTER COLUMN id SET DEFAULT nextval('public.finished_good_material_reservations_id_seq'::regclass);


--
-- Name: finished_goods id; Type: DEFAULT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.finished_goods ALTER COLUMN id SET DEFAULT nextval('public.finished_goods_id_seq'::regclass);


--
-- Name: indirect_cost_allocations id; Type: DEFAULT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.indirect_cost_allocations ALTER COLUMN id SET DEFAULT nextval('public.indirect_cost_allocations_id_seq'::regclass);


--
-- Name: indirect_expense_categories id; Type: DEFAULT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.indirect_expense_categories ALTER COLUMN id SET DEFAULT nextval('public.indirect_expense_categories_id_seq'::regclass);


--
-- Name: inventory_adjustments id; Type: DEFAULT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.inventory_adjustments ALTER COLUMN id SET DEFAULT nextval('public.inventory_adjustments_id_seq'::regclass);


--
-- Name: machines id; Type: DEFAULT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.machines ALTER COLUMN id SET DEFAULT nextval('public.machines_id_seq'::regclass);


--
-- Name: material_conversions id; Type: DEFAULT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.material_conversions ALTER COLUMN id SET DEFAULT nextval('public.material_conversions_id_seq'::regclass);


--
-- Name: material_transactions id; Type: DEFAULT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.material_transactions ALTER COLUMN id SET DEFAULT nextval('public.material_transactions_id_seq'::regclass);


--
-- Name: material_types id; Type: DEFAULT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.material_types ALTER COLUMN id SET DEFAULT nextval('public.material_types_id_seq'::regclass);


--
-- Name: materials id; Type: DEFAULT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.materials ALTER COLUMN id SET DEFAULT nextval('public.materials_id_seq'::regclass);


--
-- Name: misc_expenses id; Type: DEFAULT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.misc_expenses ALTER COLUMN id SET DEFAULT nextval('public.misc_expenses_id_seq'::regclass);


--
-- Name: plate_part_templates id; Type: DEFAULT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.plate_part_templates ALTER COLUMN id SET DEFAULT nextval('public.plate_part_templates_id_seq'::regclass);


--
-- Name: purchases id; Type: DEFAULT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.purchases ALTER COLUMN id SET DEFAULT nextval('public.purchases_id_seq'::regclass);


--
-- Name: sales id; Type: DEFAULT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.sales ALTER COLUMN id SET DEFAULT nextval('public.sales_id_seq'::regclass);


--
-- Name: suppliers id; Type: DEFAULT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.suppliers ALTER COLUMN id SET DEFAULT nextval('public.suppliers_id_seq'::regclass);


--
-- Name: tax_payments id; Type: DEFAULT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.tax_payments ALTER COLUMN id SET DEFAULT nextval('public.tax_payments_id_seq'::regclass);


--
-- Name: tool_depreciation id; Type: DEFAULT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.tool_depreciation ALTER COLUMN id SET DEFAULT nextval('public.tool_depreciation_id_seq'::regclass);


--
-- Name: tools id; Type: DEFAULT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.tools ALTER COLUMN id SET DEFAULT nextval('public.tools_id_seq'::regclass);


--
-- Name: work_logs id; Type: DEFAULT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.work_logs ALTER COLUMN id SET DEFAULT nextval('public.work_logs_id_seq'::regclass);


--
-- Name: work_types id; Type: DEFAULT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.work_types ALTER COLUMN id SET DEFAULT nextval('public.work_types_id_seq'::regclass);


--
-- Data for Name: app_operations_log; Type: TABLE DATA; Schema: public; Owner: cost_client_app
--

COPY public.app_operations_log (id, created_at, operation_type, description, amount, details) FROM stdin;
1	2026-06-22 22:02:04.056011	Сотрудники	Добавлен сотрудник: пипа	9000.00	Должность: -
2	2026-06-24 00:51:55.041931	Employees	Deleted employee: пипа	\N	ID 1
\.


--
-- Data for Name: balance; Type: TABLE DATA; Schema: public; Owner: cost_client_app
--

COPY public.balance (id, date, income, expense, notes, is_cash) FROM stdin;
\.


--
-- Data for Name: composite_material_recipe_items; Type: TABLE DATA; Schema: public; Owner: cost_client_app
--

COPY public.composite_material_recipe_items (id, recipe_id, material_id, quantity) FROM stdin;
\.


--
-- Data for Name: composite_material_recipes; Type: TABLE DATA; Schema: public; Owner: cost_client_app
--

COPY public.composite_material_recipes (id, output_material_id, output_quantity, notes, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: employee_bonus_payments; Type: TABLE DATA; Schema: public; Owner: cost_client_app
--

COPY public.employee_bonus_payments (id, period_start, period_end, bonus_percent, base_amount, bonus_amount, paid_until, created_at) FROM stdin;
\.


--
-- Data for Name: employee_settlements; Type: TABLE DATA; Schema: public; Owner: cost_client_app
--

COPY public.employee_settlements (id, employee_id, settlement_type, settlement_date, title, amount, notes, created_at) FROM stdin;
\.


--
-- Data for Name: employees; Type: TABLE DATA; Schema: public; Owner: cost_client_app
--

COPY public.employees (id, name, hourly_rate, "position", active) FROM stdin;
\.


--
-- Data for Name: finished_good_labor; Type: TABLE DATA; Schema: public; Owner: cost_client_app
--

COPY public.finished_good_labor (id, finished_good_id, work_log_id, created_at) FROM stdin;
\.


--
-- Data for Name: finished_good_material_consumptions; Type: TABLE DATA; Schema: public; Owner: cost_client_app
--

COPY public.finished_good_material_consumptions (id, finished_good_id, material_id, purchase_id, quantity, amount, is_cash, created_at) FROM stdin;
\.


--
-- Data for Name: finished_good_material_reservations; Type: TABLE DATA; Schema: public; Owner: cost_client_app
--

COPY public.finished_good_material_reservations (id, finished_good_id, material_id, purchase_id, quantity, amount, is_cash, created_at) FROM stdin;
\.


--
-- Data for Name: finished_goods; Type: TABLE DATA; Schema: public; Owner: cost_client_app
--

COPY public.finished_goods (id, machine_model, machine_id, cost_price, produced_date, status, inventory_number, buyer, sale_date, notes, start_date, indirect_cost, misc_expense_cost, production_status) FROM stdin;
\.


--
-- Data for Name: indirect_cost_allocations; Type: TABLE DATA; Schema: public; Owner: cost_client_app
--

COPY public.indirect_cost_allocations (id, category_id, finished_good_id, allocation_date, amount, created_at) FROM stdin;
\.


--
-- Data for Name: indirect_expense_categories; Type: TABLE DATA; Schema: public; Owner: cost_client_app
--

COPY public.indirect_expense_categories (id, name, monthly_amount, is_active, notes, is_cash) FROM stdin;
\.


--
-- Data for Name: inventory_adjustments; Type: TABLE DATA; Schema: public; Owner: cost_client_app
--

COPY public.inventory_adjustments (id, material_id, old_quantity, new_quantity, difference, reason, created_at) FROM stdin;
\.


--
-- Data for Name: machine_labor_costs; Type: TABLE DATA; Schema: public; Owner: cost_client_app
--

COPY public.machine_labor_costs (machine_id, work_type_id, fixed_cost, estimated_hours) FROM stdin;
\.


--
-- Data for Name: machine_materials; Type: TABLE DATA; Schema: public; Owner: cost_client_app
--

COPY public.machine_materials (machine_id, material_id, quantity) FROM stdin;
1	1	1.0000
1	2	1.0000
1	171	1.0000
1	5	1.0000
1	6	3.0000
1	7	1.0000
1	8	1.0000
1	9	1.0000
1	10	1.0000
1	11	1.0000
1	12	1.0000
1	13	1.0000
1	14	1.0000
1	15	2.0000
1	16	1.0000
1	17	1.0000
1	18	3.0000
1	19	1.0000
1	20	15.0000
1	21	3.0000
1	22	1.0000
1	23	2.0000
1	172	23617.0000
1	173	4.0000
1	25	2.0000
1	26	1.0000
1	27	1.0000
1	28	1.0000
1	30	2.0000
1	31	2.0000
1	32	1.0000
1	33	2.0000
1	34	2.0000
1	35	1.0000
1	37	2.0000
1	38	2.0000
1	39	5.0000
1	40	5.0000
1	41	2.0000
1	42	1.0000
1	43	1.0000
1	44	1.0000
1	45	1.0000
1	46	1.0000
1	47	1.0000
1	48	1.0000
1	50	2.0000
1	51	4.0000
1	52	1.0000
1	53	12.0000
1	54	1.0000
1	55	1.0000
1	56	1.0000
1	57	1.0000
1	58	2.0000
1	59	1.0000
1	60	1.0000
1	61	1.0000
1	62	1.0000
1	63	1.0000
1	64	2.0000
1	65	1.0000
1	66	1.0000
1	67	1.0000
1	69	1.0000
1	70	1.0000
1	71	1.0000
1	72	1.0000
1	73	1.0000
1	74	1.0000
1	75	1.0000
1	76	1.0000
1	77	1.0000
1	78	1.0000
1	174	4.0000
1	85	4.0000
1	86	2.0000
1	87	5.0000
1	88	1.0000
1	89	2.0000
1	90	2.0000
1	91	1.0000
1	92	1.0000
1	93	1.0000
1	94	1.0000
1	95	2.0000
1	96	1.0000
1	97	1.0000
1	98	1.0000
1	99	1.0000
1	100	1.0000
1	102	1.0000
1	103	1.0000
1	104	1.0000
1	105	2.0000
1	106	2.0000
1	107	4.0000
1	108	2.0000
1	109	2.0000
1	110	1.0000
1	111	4.0000
1	112	2.0000
1	113	1.0000
1	114	1.0000
1	115	1.0000
1	116	1.0000
1	117	1.0000
1	118	1.0000
1	119	4.0000
1	120	1.0000
1	175	1.0000
1	123	3.0000
1	124	3.0000
1	125	7.0000
1	127	4.0000
1	128	4.0000
1	129	2.0000
1	130	1.0000
1	131	5.0000
1	132	1.0000
1	133	1.0000
1	134	4.0000
1	135	4.0000
1	136	2.0000
1	137	5.0000
1	138	8.0000
1	139	8.0000
1	140	3.0000
1	141	5.0000
1	142	1.0000
1	143	4.0000
1	144	2.0000
1	145	5.0000
1	146	8.0000
1	147	10.0000
1	148	18.0000
1	149	1.0000
1	150	1.0000
1	151	1.0000
1	152	1.0000
1	153	1.0000
1	154	1.0000
1	155	1.0000
1	156	1.0000
1	157	1.0000
1	158	1.0000
1	159	1.0000
1	160	1.0000
1	161	1.0000
1	162	2.0000
1	176	2.0000
2	167	6.0000
2	168	0.2500
2	169	2.0000
2	177	1.0000
2	178	1.0000
3	179	1.0000
3	180	1.0000
3	181	1.0000
3	182	1.0000
3	183	1.0000
3	184	1.0000
3	185	2.0000
3	186	2.0000
3	187	2.0000
3	189	1.0000
3	190	1.0000
3	191	1.0000
3	192	1.0000
3	193	1.0000
3	194	2.0000
3	195	2.0000
3	196	1.0000
3	197	1.0000
3	198	1.0000
3	199	1.0000
3	200	1.0000
3	201	1.0000
3	202	1.0000
3	203	4.0000
3	204	1.0000
3	205	1.0000
3	206	1.0000
3	207	1.0000
3	208	1.0000
3	209	1.0000
3	210	2.0000
3	211	2.0000
3	212	1.0000
3	213	1.0000
3	214	2.0000
3	215	1.0000
3	216	1.0000
3	217	2.0000
3	218	1.0000
3	219	1.0000
3	220	1.0000
3	221	2.0000
3	222	1.0000
3	223	1.0000
3	224	1.0000
3	225	1.0000
3	226	1.0000
3	227	1.0000
3	228	1.0000
3	229	2.0000
3	230	1.0000
3	231	1.0000
3	232	1.0000
3	233	1.0000
3	234	1.0000
3	235	1.0000
3	236	1.0000
3	237	2.0000
3	238	7.0000
3	239	2.0000
3	240	1.0000
3	241	1.0000
3	242	1.0000
3	117	1.0000
3	243	1.0000
3	244	6.0000
3	245	4.0000
3	246	2.0000
3	247	2.0000
3	248	4.0000
3	249	8.0000
3	250	6.0000
3	251	4.0000
3	252	4.0000
3	253	4.0000
3	254	6.0000
3	255	6.0000
3	256	1.0000
3	257	1.0000
3	258	1.0000
3	259	1.0000
3	260	1.0000
3	261	1.0000
3	262	1.0000
3	188	1.0000
\.


--
-- Data for Name: machine_tools; Type: TABLE DATA; Schema: public; Owner: cost_client_app
--

COPY public.machine_tools (machine_id, tool_id, usage_per_unit) FROM stdin;
\.


--
-- Data for Name: machines; Type: TABLE DATA; Schema: public; Owner: cost_client_app
--

COPY public.machines (id, model, total_cost) FROM stdin;
1	СНО-3П	0.00
2	ШП.11-300	0.00
3	СНПО.5-150	0.00
\.


--
-- Data for Name: material_conversions; Type: TABLE DATA; Schema: public; Owner: cost_client_app
--

COPY public.material_conversions (id, source_material_id, source_purchase_id, target_material_id, source_quantity, target_quantity, total_cost, notes, created_at, template_id) FROM stdin;
\.


--
-- Data for Name: material_inventory; Type: TABLE DATA; Schema: public; Owner: cost_client_app
--

COPY public.material_inventory (material_id, quantity) FROM stdin;
1	1.0000
2	0.0000
3	0.0000
4	1.0000
5	0.0000
6	0.0000
7	3.0000
8	1.0000
9	2.0000
10	2.0000
11	19.0000
12	16.0000
13	4.0000
14	6.0000
15	109.0000
16	16.0000
17	10.0000
18	0.0000
19	0.0000
20	0.0000
21	0.0000
22	0.0000
23	12.0000
24	24.0000
25	5.0000
26	3.0000
27	3.0000
28	3.0000
29	5.0000
30	6.0000
31	7.0000
32	3.0000
33	4.0000
34	4.0000
35	1.0000
36	5.0000
37	20.0000
38	13.0000
39	31.0000
40	26.0000
41	22.0000
42	1.0000
43	0.0000
44	0.0000
45	1.0000
46	0.0000
47	0.0000
48	0.0000
49	3.0000
50	50.0000
51	10.0000
52	9.0000
53	24.0000
54	10.0000
55	10.0000
56	10.0000
57	5.0000
58	6.0000
59	22.0000
60	6.0000
61	6.0000
62	0.0000
63	2.0000
64	10.0000
65	3.0000
66	4.0000
67	4.0000
68	12.0000
69	3.0000
70	3.0000
71	11.0000
72	9.0000
73	9.0000
74	9.0000
75	4.0000
76	4.0000
77	4.0000
78	4.0000
79	3.0000
80	3.0000
81	3.0000
82	3.0000
83	1.0000
84	20.0000
85	20.0000
86	2.0000
87	15.0000
88	1.0000
89	2.0000
90	8.0000
91	4.0000
92	4.0000
93	4.0000
94	0.0000
95	0.0000
96	8.0000
97	0.0000
98	3.0000
99	6.0000
100	13.0000
101	6.0000
102	0.0000
103	0.0000
104	0.0000
105	6.0000
106	7.0000
107	12.0000
108	10.0000
109	0.0000
110	0.0000
111	20.0000
112	18.0000
113	3.0000
114	1.0000
115	0.0000
116	0.0000
117	5.0000
118	3.0000
119	0.0000
120	0.0000
121	9.0000
122	7.0000
123	97.0000
124	99.0000
125	137.0000
126	7.0000
127	0.0000
128	0.0000
129	0.0000
130	0.0000
131	0.0000
132	0.0000
133	0.0000
134	0.0000
135	0.0000
136	0.0000
137	0.0000
138	0.0000
139	0.0000
140	0.0000
141	0.0000
142	0.0000
143	0.0000
144	0.0000
145	0.0000
146	0.0000
147	0.0000
148	0.0000
149	0.0000
150	0.0000
151	0.0000
152	0.0000
153	17.0000
154	19.0000
155	0.0000
156	0.0000
157	0.0000
158	0.0000
159	0.0000
160	0.0000
161	0.0000
162	11.0000
163	11.0000
164	0.0000
165	0.0000
166	13.0000
167	80.0000
168	2.5000
169	0.0000
170	1.0000
171	0.0000
172	0.0000
173	0.0000
174	0.0000
175	0.0000
176	0.0000
177	0.0000
178	0.0000
179	0.0000
180	0.0000
181	0.0000
182	0.0000
183	0.0000
184	0.0000
185	0.0000
186	0.0000
187	0.0000
188	0.0000
189	0.0000
190	0.0000
191	0.0000
192	0.0000
193	0.0000
194	0.0000
195	0.0000
196	0.0000
197	0.0000
198	0.0000
199	0.0000
200	0.0000
201	0.0000
202	0.0000
203	0.0000
204	0.0000
205	0.0000
206	0.0000
207	0.0000
208	0.0000
209	0.0000
210	0.0000
211	0.0000
212	0.0000
213	0.0000
214	0.0000
215	0.0000
216	0.0000
217	0.0000
218	0.0000
219	0.0000
220	0.0000
221	0.0000
222	0.0000
223	0.0000
224	0.0000
225	0.0000
226	0.0000
227	0.0000
228	0.0000
229	0.0000
230	0.0000
231	0.0000
232	0.0000
233	0.0000
234	0.0000
235	0.0000
236	0.0000
237	0.0000
238	0.0000
239	0.0000
240	0.0000
241	0.0000
242	0.0000
243	0.0000
244	0.0000
245	0.0000
246	0.0000
247	0.0000
248	0.0000
249	0.0000
250	0.0000
251	0.0000
252	0.0000
253	0.0000
254	0.0000
255	0.0000
256	0.0000
257	0.0000
258	0.0000
259	0.0000
260	0.0000
261	0.0000
262	0.0000
\.


--
-- Data for Name: material_transactions; Type: TABLE DATA; Schema: public; Owner: cost_client_app
--

COPY public.material_transactions (id, material_id, quantity_change, transaction_type, reference_id, created_at) FROM stdin;
\.


--
-- Data for Name: material_types; Type: TABLE DATA; Schema: public; Owner: cost_client_app
--

COPY public.material_types (id, name) FROM stdin;
\.


--
-- Data for Name: materials; Type: TABLE DATA; Schema: public; Owner: cost_client_app
--

COPY public.materials (id, name, unit, type_id, product_url, notes, source, updated_date, is_plate, plate_material_type_id, low_stock_threshold, enough_stock_threshold, category) FROM stdin;
5	Щит ЩМП	шт	\N	\N	\N	ЭТМ	\N	f	\N	1.000	3.000	\N
6	Кабель КГ 3х1,5	м	\N	\N	\N	ЭТМ	\N	f	\N	1.000	3.000	\N
7	Вилка	шт	\N	\N	\N	ЭТМ	\N	f	\N	1.000	3.000	\N
8	DIN рейка	шт	\N	\N	\N	ЭТМ	\N	f	\N	1.000	3.000	\N
9	автомат 16А	шт	\N	\N	\N	ЭТМ	\N	f	\N	1.000	3.000	\N
10	Шина заземления	шт	\N	\N	\N	ЭТМ	\N	f	\N	1.000	3.000	\N
11	Выключатель клавишный KCD4	шт	\N	\N	\N	Алиэкспресс	2023-01-11	f	\N	1.000	3.000	\N
12	Колпачок для клавишного выключателя	шт	\N	\N	\N	Алиэкспресс	2023-01-15	f	\N	1.000	3.000	\N
13	Кнопка красная 22мм	шт	\N	\N	\N	ЭТМ	\N	f	\N	1.000	3.000	\N
14	Кнопка зеленая 22мм	шт	\N	\N	\N	ЭТМ	\N	f	\N	1.000	3.000	\N
15	колпачок круглый для кнопки	шт	\N	\N	\N	ЭТМ	2023-01-09	f	\N	1.000	3.000	\N
16	потенциометр 5 КОМ	шт	\N	\N	\N	Алиэкспресс	\N	f	\N	1.000	3.000	\N
17	ручка потенциометра	шт	\N	\N	\N	Алиэкспресс	\N	f	\N	1.000	3.000	\N
18	провод монтажный ПУГВ белый	м	\N	\N	\N	ЭТМ	\N	f	\N	1.000	3.000	\N
19	провод монтажный ПУГВ желто-зеленый	м	\N	\N	\N	ЭТМ	\N	f	\N	1.000	3.000	\N
20	гильза обжимная НШВИ	шт	\N	\N	\N	ЭТМ	\N	f	\N	1.000	3.000	\N
21	Наконечник под винт М4	шт	\N	\N	\N	ЭТМ	\N	f	\N	1.000	3.000	\N
22	Наконечник под винт М8	шт	\N	\N	\N	ЭТМ	\N	f	\N	1.000	3.000	\N
23	кабельный ввод RG-11	м	\N	\N	\N	ЭТМ	\N	f	\N	1.000	3.000	\N
24	заглушка ножки	шт	\N	\N	\N	промэкс	2023-08-14	f	\N	1.000	3.000	\N
25	Уголок полки СНО-3	шт	\N	\N	\N	промэкс	2023-08-14	f	\N	1.000	3.000	\N
26	Фальшдно	шт	\N	\N	\N	промэкс	2023-08-14	f	\N	1.000	3.000	\N
27	Кронштейн мотора внутренний	шт	\N	\N	\N	промэкс	2022-12-20	f	\N	1.000	3.000	\N
28	Кронштейн мотора наружний	шт	\N	\N	\N	промэкс	2022-12-20	f	\N	1.000	3.000	\N
29	Кронштейн мотора СНО-4	шт	\N	\N	\N	промэкс	2022-09-08	f	\N	1.000	3.000	\N
30	опорная планка	шт	\N	\N	неокраш, не обраб	промэкс	2022-09-08	f	\N	1.000	3.000	\N
31	накладка опорной планки	шт	\N	\N	\N	промэкс	2022-09-08	f	\N	1.000	3.000	\N
32	Перемычка СНО	шт	\N	\N	\N	промэкс	2022-12-20	f	\N	1.000	3.000	\N
33	уголок крепления направляющей короткий СНО	шт	\N	\N	\N	промэкс	2022-09-08	f	\N	1.000	3.000	\N
34	уголок крепления направляющей длинный СНО	шт	\N	\N	\N	промэкс	2022-12-20	f	\N	1.000	3.000	\N
35	Стол СНО-3	шт	\N	\N	\N	промэкс	2022-09-26	f	\N	1.000	3.000	\N
36	Стол СНО-4	шт	\N	\N	\N	промэкс	2022-12-20	f	\N	1.000	3.000	\N
37	Петля стола СНО	шт	\N	\N	2 окр + 16 заготовок	промэкс	2022-12-20	f	\N	1.000	3.000	\N
38	Основание петли СНО	шт	\N	\N	\N	промэкс	2022-12-20	f	\N	1.000	3.000	\N
39	основание защелки СНО	шт	\N	\N	\N	промэкс	2022-12-20	f	\N	1.000	3.000	\N
40	ручка защелки СНО	шт	\N	\N	\N	промэкс	2022-12-20	f	\N	1.000	3.000	\N
41	Площадка штифта СНО	шт	\N	\N	\N	промэкс	2022-12-20	f	\N	1.000	3.000	\N
42	Пластина задняя вертикальная СНО	шт	\N	\N	\N	промэкс	2022-12-20	f	\N	1.000	3.000	\N
43	Пластина задняя горизонтальная СНО	шт	\N	\N	\N	промэкс	2022-12-20	f	\N	1.000	3.000	\N
44	Пластина передняя вертикальная СНО	шт	\N	\N	\N	промэкс	2022-12-20	f	\N	1.000	3.000	\N
45	Пластина передняя горизонтальная СНО	шт	\N	\N	\N	промэкс	2022-12-20	f	\N	1.000	3.000	\N
46	Пластина нажимная СНО	шт	\N	\N	\N	промэкс	2022-12-20	f	\N	1.000	3.000	\N
47	Ребро жесткости заднее СНО	шт	\N	\N	\N	промэкс	2022-12-20	f	\N	1.000	3.000	\N
48	Ребро жесткости переднее СНО	шт	\N	\N	\N	промэкс	2022-12-20	f	\N	1.000	3.000	\N
49	Тиски СНО компл	шт	\N	\N	неокр	\N	\N	f	\N	1.000	3.000	\N
50	уголок ролика СНО	шт	\N	\N	\N	промэкс	2022-12-20	f	\N	1.000	3.000	\N
51	Щека блока СНО	шт	\N	\N	\N	промэкс	2022-12-20	f	\N	1.000	3.000	\N
52	Тройник СНО	шт	\N	\N	\N	промэкс	2022-09-08	f	\N	1.000	3.000	\N
53	гиря СНО	шт	\N	\N	\N	промэкс	2022-12-20	f	\N	1.000	3.000	\N
54	Основание заднего брызговика СНО	шт	\N	\N	\N	промэкс	2022-12-20	f	\N	1.000	3.000	\N
55	Поворотная пластина заднего брызговика	шт	\N	\N	\N	промэкс	2022-12-20	f	\N	1.000	3.000	\N
56	Передний брызговик СНО	шт	\N	\N	\N	промэкс	2022-12-20	f	\N	1.000	3.000	\N
57	Упор СНО	шт	\N	\N	3 окр 3 неокр	промэкс	2022-12-20	f	\N	1.000	3.000	\N
58	Кронштейн упора СНО	шт	\N	\N	\N	промэкс	2022-12-20	f	\N	1.000	3.000	\N
59	Стрелка СНО	шт	\N	\N	\N	промэкс	2022-12-20	f	\N	1.000	3.000	\N
60	Скоба съемника СНО	шт	\N	\N	\N	промэкс	2022-12-20	f	\N	1.000	3.000	\N
61	Крышка съемника СНО	шт	\N	\N	\N	промэкс	2022-12-20	f	\N	1.000	3.000	\N
62	Передняя панель СНО	шт	\N	\N	\N	промэкс	2022-12-20	f	\N	1.000	3.000	\N
63	Кронштейн СНО	шт	\N	\N	\N	промэкс	2022-12-20	f	\N	1.000	3.000	\N
64	Тормоз	шт	\N	\N	\N	промэкс	2022-12-20	f	\N	1.000	3.000	\N
65	Замок СНО	шт	\N	\N	\N	промэкс	\N	f	\N	1.000	3.000	\N
66	Поддон СНО	шт	\N	\N	\N	промэкс	2022-10-17	f	\N	1.000	3.000	\N
67	Вал СНО-3	шт	\N	\N	\N	Володя	\N	f	\N	1.000	3.000	\N
68	Вал СНО-4	шт	\N	\N	\N	Володя	\N	f	\N	1.000	3.000	\N
69	Корпус шпинделя правый СНО	шт	\N	\N	\N	Володя	\N	f	\N	1.000	3.000	\N
70	Корпус шпинделя левый СНО	шт	\N	\N	\N	Володя	\N	f	\N	1.000	3.000	\N
71	кольцо СНО	шт	\N	\N	\N	Володя	\N	f	\N	1.000	3.000	\N
72	Втулка 22,23 мм СНО	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
73	Втулка 25,4 мм СНО	шт	\N	\N	\N	Володя	\N	f	\N	1.000	3.000	\N
74	Втулка 32 мм СНО	шт	\N	\N	\N	Володя	\N	f	\N	1.000	3.000	\N
75	Шайба 22,23 мм СНО-3	шт	\N	\N	\N	Володя	\N	f	\N	1.000	3.000	\N
76	Шайба 25,4 мм СНО-3	шт	\N	\N	\N	Володя	\N	f	\N	1.000	3.000	\N
77	Шайба 32 мм СНО-3	шт	\N	\N	\N	Володя	\N	f	\N	1.000	3.000	\N
78	Шайба 20 мм СНО-3	шт	\N	\N	\N	Володя	\N	f	\N	1.000	3.000	\N
79	Шайба 22,23 мм СНО-4	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
80	Шайба 25,4 мм СНО-4	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
82	Шайба 20 мм СНО-4	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
83	втулка дистанционная СНО-3	шт	\N	\N	\N	Володя	\N	f	\N	1.000	3.000	\N
84	втулка дистанционная СНО-4	шт	\N	\N	\N	Володя	\N	f	\N	1.000	3.000	\N
85	втулка поперечной направляющей СНО	шт	\N	\N	\N	Володя	\N	f	\N	1.000	3.000	\N
86	блок СНО	шт	\N	\N	\N	Володя	\N	f	\N	1.000	3.000	\N
87	Ось защелки СНО	шт	\N	\N	\N	Володя	\N	f	\N	1.000	3.000	\N
88	Ролик В=22 мм	шт	\N	\N	\N	Володя	\N	f	\N	1.000	3.000	\N
89	Ось блока СНО	шт	\N	\N	\N	Володя	\N	f	\N	1.000	3.000	\N
90	Втулка направляющая СНО	шт	\N	\N	\N	Володя	\N	f	\N	1.000	3.000	\N
91	Втулка внутренняя СНО	шт	\N	\N	\N	Володя	\N	f	\N	1.000	3.000	\N
92	Втулка Наружняя СНО	шт	\N	\N	\N	Володя	\N	f	\N	1.000	3.000	\N
93	Втулка центровочная СНО	шт	\N	\N	\N	Володя	\N	f	\N	1.000	3.000	\N
94	Стержень СНО	шт	\N	\N	\N	Толя	\N	f	\N	1.000	3.000	\N
95	Шток	шт	\N	\N	\N	Толя	\N	f	\N	1.000	3.000	\N
96	Винт тисков СНО	шт	\N	\N	\N	Володя	\N	f	\N	1.000	3.000	\N
97	Ось колодки СНО	шт	\N	\N	\N	Володя	\N	f	\N	1.000	3.000	\N
98	Гайка тормозной колодки СНО	шт	\N	\N	\N	Володя	\N	f	\N	1.000	3.000	\N
99	Шкив ведомый 28 зубьев СНО	шт	\N	\N	с расточкой и пазом (+900)	\N	\N	f	\N	1.000	3.000	\N
100	Шкив ведущий 22 зуба СНО-3	шт	\N	\N	с расточкой и пазом (+900)	\N	\N	f	\N	1.000	3.000	\N
101	Шкив ведущий 28 зубьев СНО-4	шт	\N	\N	с расточкой и пазом (+900)	\N	\N	f	\N	1.000	3.000	\N
102	Втулка кронштейна нижняя СНО	шт	\N	\N	\N	Володя	\N	f	\N	1.000	3.000	\N
103	Шайба прижимная СНО-3	шт	\N	\N	\N	Володя	\N	f	\N	1.000	3.000	\N
104	Втулка болтов тормоза Сно	шт	\N	\N	\N	Володя	\N	f	\N	1.000	3.000	\N
105	Вал линейный 800 мм	шт	\N	\N	\N	duxe	2022-12-26	f	\N	1.000	3.000	\N
106	подшипник линейный LM20UU	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
107	Подшипник линейный в корпусе SC20UU	шт	\N	\N	\N	duxe	2022-12-26	f	\N	1.000	3.000	\N
108	Держатель вала 20 мм SF20	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
109	Подшипник шариковый 6203	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
110	Сальник 20х40х10	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
111	заглушка пластиковая 50х50	шт	\N	\N	\N	вест мет	2023-01-09	f	\N	1.000	3.000	\N
112	пруток 10 мм	шт	\N	\N	\N	петрович	2023-01-16	f	\N	1.000	3.000	\N
113	Ключ 22мм	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
114	Ключ L-обр 17мм	шт	\N	\N	\N	все инструменты	2023-01-09	f	\N	1.000	3.000	\N
115	Ключ 13 мм	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
116	Ключ 8 мм	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
117	Ключ имбусовый 4 мм	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
118	Шпатель	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
119	ножка резиновая	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
120	диск отрезной 250 мм	шт	\N	\N	\N	Леня	\N	f	\N	1.000	3.000	\N
121	Ремень приводной 365	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
122	Ремень приводной 425	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
123	Втулка МУВП 10мм	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
124	Кольцо МУВП 10 мм	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
125	Кольцо МУВП 35 мм	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
126	Резинка дл я троса	шт	\N	\N	упор заднего борта ГАЗ 3202	\N	\N	f	\N	1.000	3.000	\N
127	Болт М10х70	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
128	Болт М10х40	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
129	Болт М10х90	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
130	Болт М10х60	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
131	Болт М10х20 нерж	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
133	Болт М8х20	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
134	Винт М5х10 нерж впотай	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
135	Винт М5х8 нерж шестигр	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
136	Болт М6х40 оц неполн	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
137	Винт М5х10 полукруг	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
138	Гайка М10 оц	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
139	Гровер М10 оц	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
140	Гайка М10 самоконтр	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
141	Гайка М8 оц	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
142	Гайка М8 нерж	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
143	Шайба М10 увелич	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
144	шайба М6 нерж	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
145	Гайка М6 самоконтр нерж	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
146	заклепка вытяж сталь 5 мм	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
147	заклепка нерж 4 мм	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
148	заклепка ал 4 мм	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
149	гайка нерж М14	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
150	Шайба М14 нерж	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
151	Гайка М16 соединит	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
152	Трос	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
153	Крюк S-образный	шт	\N	\N	\N	креп комп	2023-01-09	f	\N	1.000	3.000	\N
154	Скоба такелажная	шт	\N	\N	\N	креп комп	2023-01-09	f	\N	1.000	3.000	\N
155	Кольцо стопорное внутр 40 мм	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
156	Кольцо стопорное наруж  16 мм	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
157	Шпонка сегм 5х5х18	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
158	тормоз тисков текстолит	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
159	подставка упора текстолит	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
132	Болт М8х70	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
160	втулка винта тисков	шт	\N	\N	\N	Алиэкспресс	\N	f	\N	1.000	3.000	\N
161	винт тисков	шт	\N	\N	\N	Алиэкспресс	\N	f	\N	1.000	3.000	\N
162	гайка рукоятка затяжки тормоза	шт	\N	\N	\N	Алиэкспресс	\N	f	\N	1.000	3.000	\N
163	Линейка нержавеющая	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
164	Ящик синий	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
165	кран шаровый	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
166	втулка упора СНО	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
167	Болт нержавеющий М6х25	шт	\N	\N	\N	креп комп	2023-01-09	f	\N	1.000	3.000	\N
168	Шланг резиновый внут Д 16 мм	м	\N	\N	\N	резина	2023-01-09	f	\N	1.000	3.000	\N
169	Хомут винтовой 20 мм	шт	\N	\N	\N	резина	2023-01-09	f	\N	1.000	3.000	\N
170	переключатель 3х позиционный для ШП	шт	\N	\N	\N	\N	2023-01-11	f	\N	1.000	3.000	\N
171	Частотник ESQ 210, 5А	шт	\N	\N	Элком	\N	\N	f	\N	1.000	3.000	\N
172	КОМПЛЕКТ ЛАЗЕР СНО	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
173	заглушка ножки СНО-3	шт	\N	\N	промэкс	\N	\N	f	\N	1.000	3.000	\N
174	втулка дистанционная СНО	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
175	Ремень приводной	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
176	Втулка упора СНО	шт	\N	\N	Алиэкспресс	\N	\N	f	\N	1.000	3.000	\N
177	сгон 80 мм	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
178	футорка	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
179	Основание тестолит	м²	\N	\N	Изовольт	\N	\N	t	\N	1.000	3.000	\N
180	Держатель кожуха текстолит	м²	\N	\N	Изовольт	\N	\N	t	\N	1.000	3.000	\N
181	Крыша колпака	м²	\N	\N	Уникумпласт	\N	\N	t	\N	1.000	3.000	\N
182	Правая боковина колпака	м²	\N	\N	Уникумпласт	\N	\N	t	\N	1.000	3.000	\N
183	Левая половина колпака	м²	\N	\N	Уникумпласт	\N	\N	t	\N	1.000	3.000	\N
184	Шторка	м²	\N	\N	Уникумпласт	\N	\N	t	\N	1.000	3.000	\N
185	Держатель вала SH25	шт	\N	\N	duxe, CNC	\N	\N	f	\N	1.000	3.000	\N
186	Держатель вала SH20	шт	\N	\N	duxe, CNC	\N	\N	f	\N	1.000	3.000	\N
187	Втулка скольжения бронзовая 20х25х25	шт	\N	\N	техноберинг	\N	\N	f	\N	1.000	3.000	\N
188	Вал линейный 20 мм, 300 мм	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
189	Горизонтальная пластина СНПО	шт	\N	\N	БВБ Альянс	\N	\N	f	\N	1.000	3.000	\N
190	Вертикальная пластина СНПО	шт	\N	\N	БВБ Альянс	\N	\N	f	\N	1.000	3.000	\N
191	Проставка СНПО	шт	\N	\N	БВБ Альянс	\N	\N	f	\N	1.000	3.000	\N
192	Держатель ручки СНПО	шт	\N	\N	БВБ Альянс	\N	\N	f	\N	1.000	3.000	\N
193	Рукоятка	шт	\N	\N	БВБ Альянс	\N	\N	f	\N	1.000	3.000	\N
194	Ограничитель	шт	\N	\N	БВБ Альянс	\N	\N	f	\N	1.000	3.000	\N
195	Кольцо упорное латунь	шт	\N	\N	Озон	\N	\N	f	\N	1.000	3.000	\N
196	Кольцо дистанцонное дюраль	шт	\N	\N	Виталий	\N	\N	f	\N	1.000	3.000	\N
197	Вынос микрометра	шт	\N	\N	озон	\N	\N	f	\N	1.000	3.000	\N
198	Удлинитель штока микрометра	шт	\N	\N	токарка сами	\N	\N	f	\N	1.000	3.000	\N
199	Электродвигатель АИСЕ71, 220В 3000 об	шт	\N	\N	озон	\N	\N	f	\N	1.000	3.000	\N
200	Выключатель KJD17B	шт	\N	\N	озон	\N	\N	f	\N	1.000	3.000	\N
201	кабель КГХЛ 3х1,5	м	\N	\N	этм	\N	\N	f	\N	1.000	3.000	\N
202	сальник кабельный PG-11	м	\N	\N	этм	\N	\N	f	\N	1.000	3.000	\N
203	клемма плоская мама РПИ 1,5-6,3	шт	\N	\N	этм	\N	\N	f	\N	1.000	3.000	\N
204	Клемма под болт м6 НКИ 6-1,5	шт	\N	\N	этм	\N	\N	f	\N	1.000	3.000	\N
211	Фитинг угловой цанговый 1/2 нар -12 мм	шт	\N	\N	озон	\N	\N	f	\N	1.000	3.000	\N
213	Трубка СОЖ с краном 1/4	м	\N	\N	озон	\N	\N	f	\N	1.000	3.000	\N
214	Хомут сантех с гайкой М8 20 мм	шт	\N	\N	этм	\N	\N	f	\N	1.000	3.000	\N
215	Фланец СНПО	шт	\N	\N	токарка отдаем	\N	\N	f	\N	1.000	3.000	\N
216	Гайка СНПО	шт	\N	\N	токарка отдаем	\N	\N	f	\N	1.000	3.000	\N
217	Боковая накладка расширенная	шт	\N	\N	Промэкс	\N	\N	f	\N	1.000	3.000	\N
218	держатель фильтра	шт	\N	\N	Промэкс	\N	\N	f	\N	1.000	3.000	\N
219	крепежная панель кожуха СНПО	шт	\N	\N	Промэкс	\N	\N	f	\N	1.000	3.000	\N
220	левая стенка кожуха СНПО	шт	\N	\N	Промэкс	\N	\N	f	\N	1.000	3.000	\N
221	Накладка площадки	шт	\N	\N	Промэкс	\N	\N	f	\N	1.000	3.000	\N
222	обечайка кожуха развертка	шт	\N	\N	Промэкс	\N	\N	f	\N	1.000	3.000	\N
223	обечайка постамента тыл	шт	\N	\N	Промэкс	\N	\N	f	\N	1.000	3.000	\N
224	обечайка постамента фасад	шт	\N	\N	Промэкс	\N	\N	f	\N	1.000	3.000	\N
225	Площадка верхняя СНПО	шт	\N	\N	Промэкс	\N	\N	f	\N	1.000	3.000	\N
226	Площадка нижняя СНПО	шт	\N	\N	Промэкс	\N	\N	f	\N	1.000	3.000	\N
227	поддон СНПО.	шт	\N	\N	Промэкс	\N	\N	f	\N	1.000	3.000	\N
228	правая стенка кожуха СНПО	шт	\N	\N	Промэкс	\N	\N	f	\N	1.000	3.000	\N
229	Проставка2 мм	шт	\N	\N	Промэкс	\N	\N	f	\N	1.000	3.000	\N
230	Торцевой упор стойки	шт	\N	\N	Промэкс	\N	\N	f	\N	1.000	3.000	\N
231	компрессор вакуумный	шт	\N	\N	https://aliexpress.ru/item/1005009967468886.html?spm=a2g2w.orderdetail.0.0.2f774aa6OsWIrw&sku_id=12000050714079331&_ga=2.259444298.1786964185.1781109186-685830185.1753387484	\N	\N	f	\N	1.000	3.000	\N
232	микрометрическая головка	шт	\N	\N	https://aliexpress.ru/item/1005004882138043.html?spm=a2g2w.orderdetail.0.0.1a4a4aa6aGJzTN&sku_id=12000031138005621&_ga=2.184520038.1786964185.1781109186-685830185.1753387484	\N	\N	f	\N	1.000	3.000	\N
233	Линейная платформа LGX60  (салазки)	шт	\N	\N	https://aliexpress.ru/item/1005006724279181.html?spm=a2g2w.orderdetail.0.0.37424aa6o1AtU6&sku_id=12000038097369016&_ga=2.259444298.1786964185.1781109186-685830185.1753387484	\N	\N	f	\N	1.000	3.000	\N
234	сепаратор вакуумный AV32-C 1.2	шт	\N	\N	https://aliexpress.ru/item/1005008851468760.html?spm=a2g2w.orderdetail.0.0.c4914aa693gTgm&sku_id=12000046943553702&_ga=2.251052742.1786964185.1781109186-685830185.1753387484	\N	\N	f	\N	1.000	3.000	\N
235	Шар рукоятки М10х35	шт	\N	\N	https://aliexpress.ru/item/1005003370799929.html?spm=a2g2w.orderdetail.0.0.25b24aa6hyPEGD&sku_id=12000025465075052&_ga=2.154438136.1786964185.1781109186-685830185.1753387484	\N	\N	f	\N	1.000	3.000	\N
236	шарик от подшипника	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
237	Боковой ограничитель увеличенный	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
238	магнит 20х7,м4	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
239	Магнит 16х4 м3	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
240	ключ для УШМ 30 мм	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
241	Ключ комбинированный 22 мм	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
242	Ключ имбусовый 3 мм	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
243	Ключ имбусовый 5 мм	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
244	болт М8х25	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
245	Гайка М6 нерж фикс	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
246	Гайка М3 нерж фикс	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
247	Гайка М4 нерж фикс	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
248	Болт М4х40 нерж	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
249	Шайба М6 нерж	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
250	Шайба М8 нерж	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
251	Заклепка резьб М10 нерж	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
252	Заклепка резьб М6 нерж	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
253	винт DIN 912 М5х25	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
254	винт DIN 912 М6х20	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
255	винт DIN 912 М4х12	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
256	винт DIN 912 М4х10	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
257	Круг шлифовальный 6А2 150х10х32Х4	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
258	Трубка полиуретан 12х8 40 см	м	\N	\N	559 за 5 м	\N	\N	f	\N	1.000	3.000	\N
259	Трубка ПВХ сливная 14 мм 1,5 м	м	\N	\N	10м 867 р	\N	\N	f	\N	1.000	3.000	\N
260	Ящик фанерный упаковочный	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
261	Паспорт	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
262	Руководство по экспл	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
1	Рама СНО-3/СНО-4	шт	\N	\N	\N	Толя	2022-12-21	f	\N	1.000	3.000	\N
2	Двигатель 0,55 кВт, 3000 об/мин	шт	\N	\N	\N	Элком	\N	f	\N	1.000	3.000	\N
3	Двигатель 1,1 кВт, 3000 об/мин	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
4	Частотник ESQ 230, 7А	шт	\N	\N	\N	Элком	\N	f	\N	1.000	3.000	\N
81	Шайба 32 мм СНО-4	шт	\N	\N	\N	\N	\N	f	\N	1.000	3.000	\N
205	Клемма под болт м4 НКИ 4-15	шт	\N	\N	этм	\N	\N	f	\N	1.000	3.000	\N
206	Вилка 220В	шт	\N	\N	этм	\N	\N	f	\N	1.000	3.000	\N
207	Бочонок 1/2 100 мм	шт	\N	\N	этм	\N	\N	f	\N	1.000	3.000	\N
208	кран 1/2 вн-вн	шт	\N	\N	этм	\N	\N	f	\N	1.000	3.000	\N
209	штуцер М8 - 8 мм елочка	шт	\N	\N	озон	\N	\N	f	\N	1.000	3.000	\N
210	шланг вакуумный 6х10 мм, метры	м	\N	\N	озон	\N	\N	f	\N	1.000	3.000	\N
212	Заглушка 1/2 латунь	шт	\N	\N	этм	\N	\N	f	\N	1.000	3.000	\N
\.


--
-- Data for Name: misc_expense_machine_links; Type: TABLE DATA; Schema: public; Owner: cost_client_app
--

COPY public.misc_expense_machine_links (expense_id, finished_good_id, allocated_amount) FROM stdin;
\.


--
-- Data for Name: misc_expenses; Type: TABLE DATA; Schema: public; Owner: cost_client_app
--

COPY public.misc_expenses (id, expense_date, title, amount, notes, is_cash, person_name, allocation_mode, balance_entry_id, created_at) FROM stdin;
\.


--
-- Data for Name: plate_material_types; Type: TABLE DATA; Schema: public; Owner: cost_client_app
--

COPY public.plate_material_types (id, name) FROM stdin;
1	Текстолит
2	Алюминий
3	Фанера
4	Поликарбонат
\.


--
-- Data for Name: plate_part_templates; Type: TABLE DATA; Schema: public; Owner: cost_client_app
--

COPY public.plate_part_templates (id, name, plate_material_type_id, part_unit, production_minutes, drawing_file_path, process_file_path, notes, created_at, updated_at, drawing_file_name, drawing_file_data, process_file_name, process_file_data, is_active) FROM stdin;
\.


--
-- Data for Name: purchases; Type: TABLE DATA; Schema: public; Owner: cost_client_app
--

COPY public.purchases (id, material_id, supplier_id, purchase_date, price_per_unit, quantity, remaining_quantity, purchased_by, notes, created_at, is_cash) FROM stdin;
1	1	\N	2022-12-21	12829.00	1.0000	1.0000	\N	\N	2026-06-22 15:18:48.163576	f
2	2	\N	\N	\N	\N	\N	\N	\N	2026-06-22 15:18:48.163576	f
3	4	\N	\N	\N	1.0000	1.0000	\N	\N	2026-06-22 15:18:48.163576	f
4	5	\N	\N	\N	\N	\N	\N	\N	2026-06-22 15:18:48.163576	f
5	6	\N	\N	\N	\N	\N	\N	\N	2026-06-22 15:18:48.163576	f
6	7	\N	\N	\N	3.0000	3.0000	\N	\N	2026-06-22 15:18:48.163576	f
7	8	\N	\N	\N	1.0000	1.0000	\N	\N	2026-06-22 15:18:48.163576	f
8	9	\N	\N	\N	2.0000	2.0000	\N	\N	2026-06-22 15:18:48.163576	f
9	10	\N	\N	\N	2.0000	2.0000	\N	\N	2026-06-22 15:18:48.163576	f
10	11	\N	2023-01-11	76.85	19.0000	19.0000	\N	\N	2026-06-22 15:18:48.163576	f
11	12	\N	\N	\N	2.0000	2.0000	\N	\N	2026-06-22 15:18:48.163576	f
12	12	\N	2023-01-15	25.20	14.0000	14.0000	\N	\N	2026-06-22 15:18:48.163576	f
13	13	\N	\N	\N	4.0000	4.0000	\N	\N	2026-06-22 15:18:48.163576	f
14	14	\N	\N	\N	6.0000	6.0000	\N	\N	2026-06-22 15:18:48.163576	f
15	15	\N	2023-01-09	12.50	10.0000	10.0000	\N	\N	2026-06-22 15:18:48.163576	f
16	15	\N	\N	11.30	99.0000	99.0000	\N	\N	2026-06-22 15:18:48.163576	f
17	16	\N	\N	84.10	16.0000	16.0000	\N	\N	2026-06-22 15:18:48.163576	f
18	17	\N	\N	90.80	10.0000	10.0000	\N	\N	2026-06-22 15:18:48.163576	f
19	18	\N	\N	\N	\N	\N	\N	\N	2026-06-22 15:18:48.163576	f
20	18	\N	\N	\N	\N	\N	\N	\N	2026-06-22 15:18:48.163576	f
21	19	\N	\N	\N	\N	\N	\N	\N	2026-06-22 15:18:48.163576	f
22	20	\N	\N	\N	\N	\N	\N	\N	2026-06-22 15:18:48.163576	f
23	20	\N	\N	\N	\N	\N	\N	\N	2026-06-22 15:18:48.163576	f
24	21	\N	\N	\N	\N	\N	\N	\N	2026-06-22 15:18:48.163576	f
25	22	\N	\N	\N	\N	\N	\N	\N	2026-06-22 15:18:48.163576	f
26	23	\N	\N	\N	12.0000	12.0000	\N	\N	2026-06-22 15:18:48.163576	f
27	24	\N	2023-08-14	14.82	24.0000	24.0000	\N	\N	2026-06-22 15:18:48.163576	f
28	25	\N	2023-08-14	324.72	5.0000	5.0000	\N	\N	2026-06-22 15:18:48.163576	f
29	26	\N	2023-08-14	454.02	3.0000	3.0000	\N	\N	2026-06-22 15:18:48.163576	f
30	27	\N	\N	179.16	\N	\N	\N	\N	2026-06-22 15:18:48.163576	f
31	27	\N	2022-12-20	179.16	3.0000	3.0000	\N	\N	2026-06-22 15:18:48.163576	f
32	28	\N	\N	246.90	\N	\N	\N	\N	2026-06-22 15:18:48.163576	f
33	28	\N	2022-12-20	246.90	3.0000	3.0000	\N	\N	2026-06-22 15:18:48.163576	f
34	29	\N	2022-09-08	239.22	2.0000	2.0000	\N	\N	2026-06-22 15:18:48.163576	f
35	29	\N	2022-09-08	308.46	3.0000	3.0000	\N	\N	2026-06-22 15:18:48.163576	f
36	30	\N	2022-09-08	92.82	\N	\N	\N	\N	2026-06-22 15:18:48.163576	f
37	30	\N	2022-12-20	117.72	6.0000	6.0000	\N	неокраш, не обраб	2026-06-22 15:18:48.163576	f
38	31	\N	2022-09-08	122.70	3.0000	3.0000	\N	\N	2026-06-22 15:18:48.163576	f
39	31	\N	2022-12-20	255.30	4.0000	4.0000	\N	\N	2026-06-22 15:18:48.163576	f
40	32	\N	2022-12-20	498.48	3.0000	3.0000	\N	\N	2026-06-22 15:18:48.163576	f
41	33	\N	2022-09-08	83.58	\N	\N	\N	\N	2026-06-22 15:18:48.163576	f
42	33	\N	2022-12-20	93.19	4.0000	4.0000	\N	\N	2026-06-22 15:18:48.163576	f
43	34	\N	2022-12-20	102.54	4.0000	4.0000	\N	\N	2026-06-22 15:18:48.163576	f
44	34	\N	2022-09-08	91.26	\N	\N	\N	\N	2026-06-22 15:18:48.163576	f
45	35	\N	2022-09-26	4172.76	1.0000	1.0000	\N	\N	2026-06-22 15:18:48.163576	f
46	36	\N	2022-12-20	4324.08	3.0000	3.0000	\N	\N	2026-06-22 15:18:48.163576	f
47	36	\N	2022-09-08	4187.64	\N	\N	\N	\N	2026-06-22 15:18:48.163576	f
48	36	\N	2022-12-20	4326.84	2.0000	2.0000	\N	\N	2026-06-22 15:18:48.163576	f
49	37	\N	\N	78.36	16.0000	16.0000	\N	2 окр + 16 заготовок	2026-06-22 15:18:48.163576	f
50	37	\N	2022-12-20	78.36	4.0000	4.0000	\N	\N	2026-06-22 15:18:48.163576	f
51	38	\N	\N	13.92	9.0000	9.0000	\N	\N	2026-06-22 15:18:48.163576	f
52	38	\N	2022-12-20	13.92	4.0000	4.0000	\N	\N	2026-06-22 15:18:48.163576	f
53	39	\N	\N	69.00	16.0000	16.0000	\N	\N	2026-06-22 15:18:48.163576	f
54	39	\N	2022-12-20	69.00	15.0000	15.0000	\N	\N	2026-06-22 15:18:48.163576	f
55	40	\N	\N	69.42	16.0000	16.0000	\N	\N	2026-06-22 15:18:48.163576	f
56	40	\N	2022-12-20	69.42	10.0000	10.0000	\N	\N	2026-06-22 15:18:48.163576	f
57	41	\N	2022-12-20	10.80	22.0000	22.0000	\N	\N	2026-06-22 15:18:48.163576	f
58	42	\N	2022-12-20	222.90	1.0000	1.0000	\N	\N	2026-06-22 15:18:48.163576	f
59	43	\N	2022-12-20	59.88	\N	\N	\N	\N	2026-06-22 15:18:48.163576	f
60	44	\N	2022-12-20	263.88	\N	\N	\N	\N	2026-06-22 15:18:48.163576	f
61	45	\N	2022-12-20	143.76	1.0000	1.0000	\N	\N	2026-06-22 15:18:48.163576	f
62	46	\N	2022-12-20	175.56	\N	\N	\N	\N	2026-06-22 15:18:48.163576	f
63	47	\N	2022-12-20	31.68	\N	\N	\N	\N	2026-06-22 15:18:48.163576	f
64	48	\N	2022-12-20	32.16	\N	\N	\N	\N	2026-06-22 15:18:48.163576	f
65	49	\N	\N	\N	3.0000	3.0000	\N	неокр	2026-06-22 15:18:48.163576	f
66	50	\N	\N	72.78	46.0000	46.0000	\N	\N	2026-06-22 15:18:48.163576	f
67	50	\N	2022-12-20	72.78	4.0000	4.0000	\N	\N	2026-06-22 15:18:48.163576	f
68	51	\N	2022-12-20	24.18	10.0000	10.0000	\N	\N	2026-06-22 15:18:48.163576	f
69	52	\N	2022-09-08	118.68	3.0000	3.0000	\N	\N	2026-06-22 15:18:48.163576	f
70	52	\N	2022-12-20	127.80	6.0000	6.0000	\N	\N	2026-06-22 15:18:48.163576	f
71	53	\N	2022-12-20	99.18	24.0000	24.0000	\N	\N	2026-06-22 15:18:48.163576	f
72	54	\N	\N	99.54	5.0000	5.0000	\N	\N	2026-06-22 15:18:48.163576	f
73	54	\N	2022-12-20	99.54	5.0000	5.0000	\N	\N	2026-06-22 15:18:48.163576	f
74	55	\N	\N	106.32	5.0000	5.0000	\N	\N	2026-06-22 15:18:48.163576	f
75	55	\N	2022-12-20	106.32	5.0000	5.0000	\N	\N	2026-06-22 15:18:48.163576	f
76	56	\N	\N	119.10	5.0000	5.0000	\N	\N	2026-06-22 15:18:48.163576	f
77	56	\N	2022-12-20	119.10	5.0000	5.0000	\N	\N	2026-06-22 15:18:48.163576	f
78	57	\N	2022-12-20	155.70	5.0000	5.0000	\N	3 окр 3 неокр	2026-06-22 15:18:48.163576	f
79	58	\N	2022-12-20	113.04	\N	\N	\N	\N	2026-06-22 15:18:48.163576	f
80	58	\N	2022-12-20	113.04	6.0000	6.0000	\N	\N	2026-06-22 15:18:48.163576	f
81	59	\N	2022-12-20	23.94	20.0000	20.0000	\N	\N	2026-06-22 15:18:48.163576	f
82	59	\N	2022-12-20	23.94	2.0000	2.0000	\N	\N	2026-06-22 15:18:48.163576	f
83	60	\N	\N	35.22	3.0000	3.0000	\N	\N	2026-06-22 15:18:48.163576	f
84	61	\N	\N	43.32	3.0000	3.0000	\N	\N	2026-06-22 15:18:48.163576	f
85	60	\N	2022-12-20	35.22	3.0000	3.0000	\N	\N	2026-06-22 15:18:48.163576	f
86	61	\N	2022-12-20	43.32	3.0000	3.0000	\N	\N	2026-06-22 15:18:48.163576	f
87	62	\N	2022-12-20	220.20	\N	\N	\N	\N	2026-06-22 15:18:48.163576	f
88	63	\N	\N	270.66	\N	\N	\N	\N	2026-06-22 15:18:48.163576	f
89	63	\N	2022-12-20	270.66	2.0000	2.0000	\N	\N	2026-06-22 15:18:48.163576	f
90	64	\N	\N	660.24	4.0000	4.0000	\N	\N	2026-06-22 15:18:48.163576	f
91	64	\N	2022-12-20	660.24	6.0000	6.0000	\N	\N	2026-06-22 15:18:48.163576	f
92	65	\N	\N	\N	3.0000	3.0000	\N	\N	2026-06-22 15:18:48.163576	f
93	66	\N	2022-10-17	1442.10	1.0000	1.0000	\N	\N	2026-06-22 15:18:48.163576	f
94	66	\N	2022-12-20	1339.68	3.0000	3.0000	\N	\N	2026-06-22 15:18:48.163576	f
95	67	\N	\N	4312.00	4.0000	4.0000	\N	\N	2026-06-22 15:18:48.163576	f
96	68	\N	\N	4312.00	12.0000	12.0000	\N	\N	2026-06-22 15:18:48.163576	f
97	69	\N	\N	3105.00	3.0000	3.0000	\N	\N	2026-06-22 15:18:48.163576	f
98	70	\N	\N	2587.00	3.0000	3.0000	\N	\N	2026-06-22 15:18:48.163576	f
99	71	\N	\N	\N	11.0000	11.0000	\N	\N	2026-06-22 15:18:48.163576	f
100	72	\N	\N	776.00	9.0000	9.0000	\N	\N	2026-06-22 15:18:48.163576	f
101	73	\N	\N	776.00	9.0000	9.0000	\N	\N	2026-06-22 15:18:48.163576	f
102	74	\N	\N	776.00	9.0000	9.0000	\N	\N	2026-06-22 15:18:48.163576	f
103	75	\N	\N	1811.00	4.0000	4.0000	\N	\N	2026-06-22 15:18:48.163576	f
104	76	\N	\N	1811.00	4.0000	4.0000	\N	\N	2026-06-22 15:18:48.163576	f
105	77	\N	\N	1811.00	4.0000	4.0000	\N	\N	2026-06-22 15:18:48.163576	f
106	78	\N	\N	1811.00	4.0000	4.0000	\N	\N	2026-06-22 15:18:48.163576	f
107	79	\N	\N	\N	3.0000	3.0000	\N	\N	2026-06-22 15:18:48.163576	f
108	80	\N	\N	\N	3.0000	3.0000	\N	\N	2026-06-22 15:18:48.163576	f
109	81	\N	\N	\N	3.0000	3.0000	\N	\N	2026-06-22 15:18:48.163576	f
110	82	\N	\N	\N	3.0000	3.0000	\N	\N	2026-06-22 15:18:48.163576	f
111	83	\N	\N	517.00	1.0000	1.0000	\N	\N	2026-06-22 15:18:48.163576	f
112	84	\N	\N	517.00	20.0000	20.0000	\N	\N	2026-06-22 15:18:48.163576	f
113	85	\N	\N	345.00	20.0000	20.0000	\N	\N	2026-06-22 15:18:48.163576	f
114	86	\N	\N	345.00	2.0000	2.0000	\N	\N	2026-06-22 15:18:48.163576	f
115	87	\N	\N	258.00	15.0000	15.0000	\N	\N	2026-06-22 15:18:48.163576	f
116	88	\N	\N	172.00	1.0000	1.0000	\N	\N	2026-06-22 15:18:48.163576	f
117	89	\N	\N	172.00	2.0000	2.0000	\N	\N	2026-06-22 15:18:48.163576	f
118	90	\N	\N	517.00	8.0000	8.0000	\N	\N	2026-06-22 15:18:48.163576	f
119	91	\N	\N	4312.00	4.0000	4.0000	\N	\N	2026-06-22 15:18:48.163576	f
120	92	\N	\N	2070.00	4.0000	4.0000	\N	\N	2026-06-22 15:18:48.163576	f
121	93	\N	\N	431.00	4.0000	4.0000	\N	\N	2026-06-22 15:18:48.163576	f
122	94	\N	\N	\N	\N	\N	\N	\N	2026-06-22 15:18:48.163576	f
123	95	\N	\N	\N	\N	\N	\N	\N	2026-06-22 15:18:48.163576	f
124	96	\N	\N	603.00	8.0000	8.0000	\N	\N	2026-06-22 15:18:48.163576	f
125	97	\N	\N	345.00	\N	\N	\N	\N	2026-06-22 15:18:48.163576	f
126	98	\N	\N	345.00	3.0000	3.0000	\N	\N	2026-06-22 15:18:48.163576	f
127	99	\N	\N	\N	6.0000	6.0000	\N	с расточкой и пазом (+900)	2026-06-22 15:18:48.163576	f
128	100	\N	\N	\N	13.0000	13.0000	\N	с расточкой и пазом (+900)	2026-06-22 15:18:48.163576	f
129	101	\N	\N	\N	6.0000	6.0000	\N	с расточкой и пазом (+900)	2026-06-22 15:18:48.163576	f
130	102	\N	\N	121.00	\N	\N	\N	\N	2026-06-22 15:18:48.163576	f
131	103	\N	\N	121.00	\N	\N	\N	\N	2026-06-22 15:18:48.163576	f
132	104	\N	\N	121.00	\N	\N	\N	\N	2026-06-22 15:18:48.163576	f
133	105	\N	2022-12-26	800.00	6.0000	6.0000	\N	\N	2026-06-22 15:18:48.163576	f
134	106	\N	\N	\N	7.0000	7.0000	\N	\N	2026-06-22 15:18:48.163576	f
135	107	\N	2022-12-26	350.00	12.0000	12.0000	\N	\N	2026-06-22 15:18:48.163576	f
136	108	\N	\N	\N	10.0000	10.0000	\N	\N	2026-06-22 15:18:48.163576	f
137	111	\N	2023-01-09	32.00	20.0000	20.0000	\N	\N	2026-06-22 15:18:48.163576	f
138	112	\N	2023-01-16	40.30	18.0000	18.0000	\N	\N	2026-06-22 15:18:48.163576	f
139	113	\N	\N	\N	3.0000	3.0000	\N	\N	2026-06-22 15:18:48.163576	f
140	114	\N	2023-01-09	348.00	1.0000	1.0000	\N	\N	2026-06-22 15:18:48.163576	f
141	117	\N	\N	\N	5.0000	5.0000	\N	\N	2026-06-22 15:18:48.163576	f
142	118	\N	\N	\N	3.0000	3.0000	\N	\N	2026-06-22 15:18:48.163576	f
143	120	\N	\N	\N	\N	\N	\N	\N	2026-06-22 15:18:48.163576	f
144	121	\N	\N	\N	9.0000	9.0000	\N	\N	2026-06-22 15:18:48.163576	f
145	122	\N	\N	\N	7.0000	7.0000	\N	\N	2026-06-22 15:18:48.163576	f
146	123	\N	\N	\N	97.0000	97.0000	\N	\N	2026-06-22 15:18:48.163576	f
147	124	\N	\N	\N	99.0000	99.0000	\N	\N	2026-06-22 15:18:48.163576	f
148	125	\N	\N	\N	137.0000	137.0000	\N	\N	2026-06-22 15:18:48.163576	f
149	126	\N	\N	\N	7.0000	7.0000	\N	упор заднего борта ГАЗ 3202	2026-06-22 15:18:48.163576	f
150	153	\N	2023-01-09	9.36	17.0000	17.0000	\N	\N	2026-06-22 15:18:48.163576	f
151	154	\N	2023-01-09	24.67	19.0000	19.0000	\N	\N	2026-06-22 15:18:48.163576	f
152	160	\N	\N	\N	\N	\N	\N	\N	2026-06-22 15:18:48.163576	f
153	161	\N	\N	\N	\N	\N	\N	\N	2026-06-22 15:18:48.163576	f
154	162	\N	\N	\N	11.0000	11.0000	\N	\N	2026-06-22 15:18:48.163576	f
155	163	\N	\N	\N	11.0000	11.0000	\N	\N	2026-06-22 15:18:48.163576	f
156	166	\N	\N	\N	13.0000	13.0000	\N	\N	2026-06-22 15:18:48.163576	f
157	167	\N	2023-01-09	10.00	80.0000	80.0000	\N	\N	2026-06-22 15:18:48.163576	f
158	168	\N	2023-01-09	220.00	2.5000	2.5000	\N	\N	2026-06-22 15:18:48.163576	f
159	169	\N	2023-01-09	85.00	\N	\N	\N	\N	2026-06-22 15:18:48.163576	f
160	170	\N	2023-01-11	\N	1.0000	1.0000	\N	\N	2026-06-22 15:18:48.163576	f
\.


--
-- Data for Name: sales; Type: TABLE DATA; Schema: public; Owner: cost_client_app
--

COPY public.sales (id, finished_good_id, sale_date, sale_price, profit) FROM stdin;
\.


--
-- Data for Name: suppliers; Type: TABLE DATA; Schema: public; Owner: cost_client_app
--

COPY public.suppliers (id, name) FROM stdin;
\.


--
-- Data for Name: tax_payments; Type: TABLE DATA; Schema: public; Owner: cost_client_app
--

COPY public.tax_payments (id, payment_date, period_start, period_end, tax_rate, tax_base, tax_amount, notes, created_at) FROM stdin;
\.


--
-- Data for Name: tool_depreciation; Type: TABLE DATA; Schema: public; Owner: cost_client_app
--

COPY public.tool_depreciation (id, tool_id, depreciation_date, amount, finished_good_id, notes) FROM stdin;
\.


--
-- Data for Name: tools; Type: TABLE DATA; Schema: public; Owner: cost_client_app
--

COPY public.tools (id, name, inventory_number, purchase_date, purchase_cost, useful_life_months, monthly_depreciation, residual_value, status, notes) FROM stdin;
\.


--
-- Data for Name: work_logs; Type: TABLE DATA; Schema: public; Owner: cost_client_app
--

COPY public.work_logs (id, employee_id, work_type_id, machine_id, date, hours, notes) FROM stdin;
\.


--
-- Data for Name: work_types; Type: TABLE DATA; Schema: public; Owner: cost_client_app
--

COPY public.work_types (id, name, description) FROM stdin;
\.


--
-- Name: app_operations_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: cost_client_app
--

SELECT pg_catalog.setval('public.app_operations_log_id_seq', 2, true);


--
-- Name: balance_id_seq; Type: SEQUENCE SET; Schema: public; Owner: cost_client_app
--

SELECT pg_catalog.setval('public.balance_id_seq', 1, false);


--
-- Name: composite_material_recipe_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: cost_client_app
--

SELECT pg_catalog.setval('public.composite_material_recipe_items_id_seq', 1, false);


--
-- Name: composite_material_recipes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: cost_client_app
--

SELECT pg_catalog.setval('public.composite_material_recipes_id_seq', 1, false);


--
-- Name: employee_bonus_payments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: cost_client_app
--

SELECT pg_catalog.setval('public.employee_bonus_payments_id_seq', 1, false);


--
-- Name: employee_settlements_id_seq; Type: SEQUENCE SET; Schema: public; Owner: cost_client_app
--

SELECT pg_catalog.setval('public.employee_settlements_id_seq', 1, false);


--
-- Name: employees_id_seq; Type: SEQUENCE SET; Schema: public; Owner: cost_client_app
--

SELECT pg_catalog.setval('public.employees_id_seq', 1, true);


--
-- Name: finished_good_labor_id_seq; Type: SEQUENCE SET; Schema: public; Owner: cost_client_app
--

SELECT pg_catalog.setval('public.finished_good_labor_id_seq', 1, false);


--
-- Name: finished_good_material_consumptions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: cost_client_app
--

SELECT pg_catalog.setval('public.finished_good_material_consumptions_id_seq', 1, false);


--
-- Name: finished_good_material_reservations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: cost_client_app
--

SELECT pg_catalog.setval('public.finished_good_material_reservations_id_seq', 1, false);


--
-- Name: finished_goods_id_seq; Type: SEQUENCE SET; Schema: public; Owner: cost_client_app
--

SELECT pg_catalog.setval('public.finished_goods_id_seq', 1, false);


--
-- Name: indirect_cost_allocations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: cost_client_app
--

SELECT pg_catalog.setval('public.indirect_cost_allocations_id_seq', 1, false);


--
-- Name: indirect_expense_categories_id_seq; Type: SEQUENCE SET; Schema: public; Owner: cost_client_app
--

SELECT pg_catalog.setval('public.indirect_expense_categories_id_seq', 1, false);


--
-- Name: inventory_adjustments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: cost_client_app
--

SELECT pg_catalog.setval('public.inventory_adjustments_id_seq', 1, false);


--
-- Name: machines_id_seq; Type: SEQUENCE SET; Schema: public; Owner: cost_client_app
--

SELECT pg_catalog.setval('public.machines_id_seq', 9, true);


--
-- Name: material_conversions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: cost_client_app
--

SELECT pg_catalog.setval('public.material_conversions_id_seq', 1, false);


--
-- Name: material_transactions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: cost_client_app
--

SELECT pg_catalog.setval('public.material_transactions_id_seq', 6, true);


--
-- Name: material_types_id_seq; Type: SEQUENCE SET; Schema: public; Owner: cost_client_app
--

SELECT pg_catalog.setval('public.material_types_id_seq', 1, false);


--
-- Name: materials_id_seq; Type: SEQUENCE SET; Schema: public; Owner: cost_client_app
--

SELECT pg_catalog.setval('public.materials_id_seq', 281, true);


--
-- Name: misc_expenses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: cost_client_app
--

SELECT pg_catalog.setval('public.misc_expenses_id_seq', 1, false);


--
-- Name: plate_part_templates_id_seq; Type: SEQUENCE SET; Schema: public; Owner: cost_client_app
--

SELECT pg_catalog.setval('public.plate_part_templates_id_seq', 1, false);


--
-- Name: purchases_id_seq; Type: SEQUENCE SET; Schema: public; Owner: cost_client_app
--

SELECT pg_catalog.setval('public.purchases_id_seq', 199, true);


--
-- Name: sales_id_seq; Type: SEQUENCE SET; Schema: public; Owner: cost_client_app
--

SELECT pg_catalog.setval('public.sales_id_seq', 1, false);


--
-- Name: suppliers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: cost_client_app
--

SELECT pg_catalog.setval('public.suppliers_id_seq', 1, false);


--
-- Name: tax_payments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: cost_client_app
--

SELECT pg_catalog.setval('public.tax_payments_id_seq', 1, false);


--
-- Name: tool_depreciation_id_seq; Type: SEQUENCE SET; Schema: public; Owner: cost_client_app
--

SELECT pg_catalog.setval('public.tool_depreciation_id_seq', 1, false);


--
-- Name: tools_id_seq; Type: SEQUENCE SET; Schema: public; Owner: cost_client_app
--

SELECT pg_catalog.setval('public.tools_id_seq', 1, false);


--
-- Name: work_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: cost_client_app
--

SELECT pg_catalog.setval('public.work_logs_id_seq', 1, false);


--
-- Name: work_types_id_seq; Type: SEQUENCE SET; Schema: public; Owner: cost_client_app
--

SELECT pg_catalog.setval('public.work_types_id_seq', 1, false);


--
-- Name: app_operations_log app_operations_log_pkey; Type: CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.app_operations_log
    ADD CONSTRAINT app_operations_log_pkey PRIMARY KEY (id);


--
-- Name: balance balance_pkey; Type: CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.balance
    ADD CONSTRAINT balance_pkey PRIMARY KEY (id);


--
-- Name: composite_material_recipe_items composite_material_recipe_items_pkey; Type: CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.composite_material_recipe_items
    ADD CONSTRAINT composite_material_recipe_items_pkey PRIMARY KEY (id);


--
-- Name: composite_material_recipes composite_material_recipes_output_material_id_key; Type: CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.composite_material_recipes
    ADD CONSTRAINT composite_material_recipes_output_material_id_key UNIQUE (output_material_id);


--
-- Name: composite_material_recipes composite_material_recipes_pkey; Type: CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.composite_material_recipes
    ADD CONSTRAINT composite_material_recipes_pkey PRIMARY KEY (id);


--
-- Name: employee_bonus_payments employee_bonus_payments_pkey; Type: CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.employee_bonus_payments
    ADD CONSTRAINT employee_bonus_payments_pkey PRIMARY KEY (id);


--
-- Name: employee_settlements employee_settlements_pkey; Type: CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.employee_settlements
    ADD CONSTRAINT employee_settlements_pkey PRIMARY KEY (id);


--
-- Name: employees employees_pkey; Type: CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT employees_pkey PRIMARY KEY (id);


--
-- Name: finished_good_labor finished_good_labor_pkey; Type: CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.finished_good_labor
    ADD CONSTRAINT finished_good_labor_pkey PRIMARY KEY (id);


--
-- Name: finished_good_material_consumptions finished_good_material_consumptions_pkey; Type: CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.finished_good_material_consumptions
    ADD CONSTRAINT finished_good_material_consumptions_pkey PRIMARY KEY (id);


--
-- Name: finished_good_material_reservations finished_good_material_reservations_pkey; Type: CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.finished_good_material_reservations
    ADD CONSTRAINT finished_good_material_reservations_pkey PRIMARY KEY (id);


--
-- Name: finished_goods finished_goods_pkey; Type: CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.finished_goods
    ADD CONSTRAINT finished_goods_pkey PRIMARY KEY (id);


--
-- Name: indirect_cost_allocations indirect_cost_allocations_pkey; Type: CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.indirect_cost_allocations
    ADD CONSTRAINT indirect_cost_allocations_pkey PRIMARY KEY (id);


--
-- Name: indirect_expense_categories indirect_expense_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.indirect_expense_categories
    ADD CONSTRAINT indirect_expense_categories_pkey PRIMARY KEY (id);


--
-- Name: inventory_adjustments inventory_adjustments_pkey; Type: CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.inventory_adjustments
    ADD CONSTRAINT inventory_adjustments_pkey PRIMARY KEY (id);


--
-- Name: machine_labor_costs machine_labor_costs_pkey; Type: CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.machine_labor_costs
    ADD CONSTRAINT machine_labor_costs_pkey PRIMARY KEY (machine_id, work_type_id);


--
-- Name: machine_materials machine_materials_pkey; Type: CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.machine_materials
    ADD CONSTRAINT machine_materials_pkey PRIMARY KEY (machine_id, material_id);


--
-- Name: machine_tools machine_tools_pkey; Type: CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.machine_tools
    ADD CONSTRAINT machine_tools_pkey PRIMARY KEY (machine_id, tool_id);


--
-- Name: machines machines_pkey; Type: CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.machines
    ADD CONSTRAINT machines_pkey PRIMARY KEY (id);


--
-- Name: material_conversions material_conversions_pkey; Type: CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.material_conversions
    ADD CONSTRAINT material_conversions_pkey PRIMARY KEY (id);


--
-- Name: material_inventory material_inventory_pkey; Type: CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.material_inventory
    ADD CONSTRAINT material_inventory_pkey PRIMARY KEY (material_id);


--
-- Name: material_transactions material_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.material_transactions
    ADD CONSTRAINT material_transactions_pkey PRIMARY KEY (id);


--
-- Name: material_types material_types_name_key; Type: CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.material_types
    ADD CONSTRAINT material_types_name_key UNIQUE (name);


--
-- Name: material_types material_types_pkey; Type: CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.material_types
    ADD CONSTRAINT material_types_pkey PRIMARY KEY (id);


--
-- Name: materials materials_name_key; Type: CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.materials
    ADD CONSTRAINT materials_name_key UNIQUE (name);


--
-- Name: materials materials_pkey; Type: CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.materials
    ADD CONSTRAINT materials_pkey PRIMARY KEY (id);


--
-- Name: misc_expense_machine_links misc_expense_machine_links_pkey; Type: CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.misc_expense_machine_links
    ADD CONSTRAINT misc_expense_machine_links_pkey PRIMARY KEY (expense_id, finished_good_id);


--
-- Name: misc_expenses misc_expenses_pkey; Type: CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.misc_expenses
    ADD CONSTRAINT misc_expenses_pkey PRIMARY KEY (id);


--
-- Name: plate_material_types plate_material_types_name_key; Type: CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.plate_material_types
    ADD CONSTRAINT plate_material_types_name_key UNIQUE (name);


--
-- Name: plate_material_types plate_material_types_pkey; Type: CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.plate_material_types
    ADD CONSTRAINT plate_material_types_pkey PRIMARY KEY (id);


--
-- Name: plate_part_templates plate_part_templates_name_plate_material_type_id_key; Type: CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.plate_part_templates
    ADD CONSTRAINT plate_part_templates_name_plate_material_type_id_key UNIQUE (name, plate_material_type_id);


--
-- Name: plate_part_templates plate_part_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.plate_part_templates
    ADD CONSTRAINT plate_part_templates_pkey PRIMARY KEY (id);


--
-- Name: purchases purchases_pkey; Type: CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.purchases
    ADD CONSTRAINT purchases_pkey PRIMARY KEY (id);


--
-- Name: sales sales_pkey; Type: CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.sales
    ADD CONSTRAINT sales_pkey PRIMARY KEY (id);


--
-- Name: suppliers suppliers_name_key; Type: CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.suppliers
    ADD CONSTRAINT suppliers_name_key UNIQUE (name);


--
-- Name: suppliers suppliers_pkey; Type: CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.suppliers
    ADD CONSTRAINT suppliers_pkey PRIMARY KEY (id);


--
-- Name: tax_payments tax_payments_pkey; Type: CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.tax_payments
    ADD CONSTRAINT tax_payments_pkey PRIMARY KEY (id);


--
-- Name: tool_depreciation tool_depreciation_pkey; Type: CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.tool_depreciation
    ADD CONSTRAINT tool_depreciation_pkey PRIMARY KEY (id);


--
-- Name: tools tools_pkey; Type: CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.tools
    ADD CONSTRAINT tools_pkey PRIMARY KEY (id);


--
-- Name: work_logs work_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.work_logs
    ADD CONSTRAINT work_logs_pkey PRIMARY KEY (id);


--
-- Name: work_types work_types_name_key; Type: CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.work_types
    ADD CONSTRAINT work_types_name_key UNIQUE (name);


--
-- Name: work_types work_types_pkey; Type: CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.work_types
    ADD CONSTRAINT work_types_pkey PRIMARY KEY (id);


--
-- Name: idx_app_operations_log_created_at; Type: INDEX; Schema: public; Owner: cost_client_app
--

CREATE INDEX idx_app_operations_log_created_at ON public.app_operations_log USING btree (created_at DESC);


--
-- Name: idx_misc_expense_machine_links_fg; Type: INDEX; Schema: public; Owner: cost_client_app
--

CREATE INDEX idx_misc_expense_machine_links_fg ON public.misc_expense_machine_links USING btree (finished_good_id);


--
-- Name: idx_misc_expenses_date; Type: INDEX; Schema: public; Owner: cost_client_app
--

CREATE INDEX idx_misc_expenses_date ON public.misc_expenses USING btree (expense_date DESC, id DESC);


--
-- Name: composite_material_recipe_items composite_material_recipe_items_material_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.composite_material_recipe_items
    ADD CONSTRAINT composite_material_recipe_items_material_id_fkey FOREIGN KEY (material_id) REFERENCES public.materials(id);


--
-- Name: composite_material_recipe_items composite_material_recipe_items_recipe_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.composite_material_recipe_items
    ADD CONSTRAINT composite_material_recipe_items_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES public.composite_material_recipes(id) ON DELETE CASCADE;


--
-- Name: composite_material_recipes composite_material_recipes_output_material_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.composite_material_recipes
    ADD CONSTRAINT composite_material_recipes_output_material_id_fkey FOREIGN KEY (output_material_id) REFERENCES public.materials(id) ON DELETE CASCADE;


--
-- Name: employee_settlements employee_settlements_employee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.employee_settlements
    ADD CONSTRAINT employee_settlements_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES public.employees(id) ON DELETE CASCADE;


--
-- Name: finished_good_labor finished_good_labor_finished_good_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.finished_good_labor
    ADD CONSTRAINT finished_good_labor_finished_good_id_fkey FOREIGN KEY (finished_good_id) REFERENCES public.finished_goods(id) ON DELETE CASCADE;


--
-- Name: finished_good_labor finished_good_labor_work_log_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.finished_good_labor
    ADD CONSTRAINT finished_good_labor_work_log_id_fkey FOREIGN KEY (work_log_id) REFERENCES public.work_logs(id) ON DELETE CASCADE;


--
-- Name: finished_good_material_consumptions finished_good_material_consumptions_finished_good_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.finished_good_material_consumptions
    ADD CONSTRAINT finished_good_material_consumptions_finished_good_id_fkey FOREIGN KEY (finished_good_id) REFERENCES public.finished_goods(id) ON DELETE CASCADE;


--
-- Name: finished_good_material_consumptions finished_good_material_consumptions_material_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.finished_good_material_consumptions
    ADD CONSTRAINT finished_good_material_consumptions_material_id_fkey FOREIGN KEY (material_id) REFERENCES public.materials(id);


--
-- Name: finished_good_material_consumptions finished_good_material_consumptions_purchase_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.finished_good_material_consumptions
    ADD CONSTRAINT finished_good_material_consumptions_purchase_id_fkey FOREIGN KEY (purchase_id) REFERENCES public.purchases(id);


--
-- Name: finished_good_material_reservations finished_good_material_reservations_finished_good_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.finished_good_material_reservations
    ADD CONSTRAINT finished_good_material_reservations_finished_good_id_fkey FOREIGN KEY (finished_good_id) REFERENCES public.finished_goods(id) ON DELETE CASCADE;


--
-- Name: finished_good_material_reservations finished_good_material_reservations_material_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.finished_good_material_reservations
    ADD CONSTRAINT finished_good_material_reservations_material_id_fkey FOREIGN KEY (material_id) REFERENCES public.materials(id);


--
-- Name: finished_good_material_reservations finished_good_material_reservations_purchase_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.finished_good_material_reservations
    ADD CONSTRAINT finished_good_material_reservations_purchase_id_fkey FOREIGN KEY (purchase_id) REFERENCES public.purchases(id);


--
-- Name: finished_goods finished_goods_machine_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.finished_goods
    ADD CONSTRAINT finished_goods_machine_id_fkey FOREIGN KEY (machine_id) REFERENCES public.machines(id);


--
-- Name: indirect_cost_allocations indirect_cost_allocations_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.indirect_cost_allocations
    ADD CONSTRAINT indirect_cost_allocations_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.indirect_expense_categories(id) ON DELETE CASCADE;


--
-- Name: indirect_cost_allocations indirect_cost_allocations_finished_good_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.indirect_cost_allocations
    ADD CONSTRAINT indirect_cost_allocations_finished_good_id_fkey FOREIGN KEY (finished_good_id) REFERENCES public.finished_goods(id) ON DELETE CASCADE;


--
-- Name: inventory_adjustments inventory_adjustments_material_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.inventory_adjustments
    ADD CONSTRAINT inventory_adjustments_material_id_fkey FOREIGN KEY (material_id) REFERENCES public.materials(id);


--
-- Name: machine_labor_costs machine_labor_costs_machine_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.machine_labor_costs
    ADD CONSTRAINT machine_labor_costs_machine_id_fkey FOREIGN KEY (machine_id) REFERENCES public.machines(id);


--
-- Name: machine_labor_costs machine_labor_costs_work_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.machine_labor_costs
    ADD CONSTRAINT machine_labor_costs_work_type_id_fkey FOREIGN KEY (work_type_id) REFERENCES public.work_types(id);


--
-- Name: machine_materials machine_materials_machine_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.machine_materials
    ADD CONSTRAINT machine_materials_machine_id_fkey FOREIGN KEY (machine_id) REFERENCES public.machines(id) ON DELETE CASCADE;


--
-- Name: machine_materials machine_materials_material_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.machine_materials
    ADD CONSTRAINT machine_materials_material_id_fkey FOREIGN KEY (material_id) REFERENCES public.materials(id) ON DELETE RESTRICT;


--
-- Name: machine_tools machine_tools_machine_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.machine_tools
    ADD CONSTRAINT machine_tools_machine_id_fkey FOREIGN KEY (machine_id) REFERENCES public.machines(id);


--
-- Name: machine_tools machine_tools_tool_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.machine_tools
    ADD CONSTRAINT machine_tools_tool_id_fkey FOREIGN KEY (tool_id) REFERENCES public.tools(id);


--
-- Name: material_conversions material_conversions_source_material_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.material_conversions
    ADD CONSTRAINT material_conversions_source_material_id_fkey FOREIGN KEY (source_material_id) REFERENCES public.materials(id);


--
-- Name: material_conversions material_conversions_source_purchase_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.material_conversions
    ADD CONSTRAINT material_conversions_source_purchase_id_fkey FOREIGN KEY (source_purchase_id) REFERENCES public.purchases(id);


--
-- Name: material_conversions material_conversions_target_material_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.material_conversions
    ADD CONSTRAINT material_conversions_target_material_id_fkey FOREIGN KEY (target_material_id) REFERENCES public.materials(id);


--
-- Name: material_conversions material_conversions_template_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.material_conversions
    ADD CONSTRAINT material_conversions_template_id_fkey FOREIGN KEY (template_id) REFERENCES public.plate_part_templates(id);


--
-- Name: material_inventory material_inventory_material_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.material_inventory
    ADD CONSTRAINT material_inventory_material_id_fkey FOREIGN KEY (material_id) REFERENCES public.materials(id) ON DELETE CASCADE;


--
-- Name: material_transactions material_transactions_material_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.material_transactions
    ADD CONSTRAINT material_transactions_material_id_fkey FOREIGN KEY (material_id) REFERENCES public.materials(id);


--
-- Name: materials materials_plate_material_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.materials
    ADD CONSTRAINT materials_plate_material_type_id_fkey FOREIGN KEY (plate_material_type_id) REFERENCES public.plate_material_types(id);


--
-- Name: materials materials_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.materials
    ADD CONSTRAINT materials_type_id_fkey FOREIGN KEY (type_id) REFERENCES public.material_types(id) ON DELETE SET NULL;


--
-- Name: misc_expense_machine_links misc_expense_machine_links_expense_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.misc_expense_machine_links
    ADD CONSTRAINT misc_expense_machine_links_expense_id_fkey FOREIGN KEY (expense_id) REFERENCES public.misc_expenses(id) ON DELETE CASCADE;


--
-- Name: misc_expense_machine_links misc_expense_machine_links_finished_good_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.misc_expense_machine_links
    ADD CONSTRAINT misc_expense_machine_links_finished_good_id_fkey FOREIGN KEY (finished_good_id) REFERENCES public.finished_goods(id) ON DELETE CASCADE;


--
-- Name: misc_expenses misc_expenses_balance_entry_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.misc_expenses
    ADD CONSTRAINT misc_expenses_balance_entry_id_fkey FOREIGN KEY (balance_entry_id) REFERENCES public.balance(id) ON DELETE SET NULL;


--
-- Name: plate_part_templates plate_part_templates_plate_material_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.plate_part_templates
    ADD CONSTRAINT plate_part_templates_plate_material_type_id_fkey FOREIGN KEY (plate_material_type_id) REFERENCES public.plate_material_types(id);


--
-- Name: purchases purchases_material_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.purchases
    ADD CONSTRAINT purchases_material_id_fkey FOREIGN KEY (material_id) REFERENCES public.materials(id) ON DELETE CASCADE;


--
-- Name: purchases purchases_supplier_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.purchases
    ADD CONSTRAINT purchases_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES public.suppliers(id) ON DELETE SET NULL;


--
-- Name: sales sales_finished_good_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.sales
    ADD CONSTRAINT sales_finished_good_id_fkey FOREIGN KEY (finished_good_id) REFERENCES public.finished_goods(id);


--
-- Name: tool_depreciation tool_depreciation_finished_good_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.tool_depreciation
    ADD CONSTRAINT tool_depreciation_finished_good_id_fkey FOREIGN KEY (finished_good_id) REFERENCES public.finished_goods(id);


--
-- Name: tool_depreciation tool_depreciation_tool_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.tool_depreciation
    ADD CONSTRAINT tool_depreciation_tool_id_fkey FOREIGN KEY (tool_id) REFERENCES public.tools(id);


--
-- Name: work_logs work_logs_employee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.work_logs
    ADD CONSTRAINT work_logs_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES public.employees(id);


--
-- Name: work_logs work_logs_machine_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.work_logs
    ADD CONSTRAINT work_logs_machine_id_fkey FOREIGN KEY (machine_id) REFERENCES public.machines(id);


--
-- Name: work_logs work_logs_work_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cost_client_app
--

ALTER TABLE ONLY public.work_logs
    ADD CONSTRAINT work_logs_work_type_id_fkey FOREIGN KEY (work_type_id) REFERENCES public.work_types(id);


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: cost_client_app
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

