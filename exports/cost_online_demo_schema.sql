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
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

-- *not* creating schema, since initdb creates it


--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS '';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: app_operations_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.app_operations_log (
    id integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    operation_type character varying(100) NOT NULL,
    description text NOT NULL,
    amount numeric(14,2),
    details text
);


--
-- Name: app_operations_log_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.app_operations_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: app_operations_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.app_operations_log_id_seq OWNED BY public.app_operations_log.id;


--
-- Name: balance; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.balance (
    id integer NOT NULL,
    date date DEFAULT CURRENT_DATE,
    income numeric(12,2) DEFAULT 0,
    expense numeric(12,2) DEFAULT 0,
    notes text,
    is_cash boolean DEFAULT false
);


--
-- Name: balance_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.balance_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: balance_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.balance_id_seq OWNED BY public.balance.id;


--
-- Name: composite_material_recipe_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.composite_material_recipe_items (
    id integer NOT NULL,
    recipe_id integer NOT NULL,
    material_id integer NOT NULL,
    quantity numeric(12,4) DEFAULT 0 NOT NULL
);


--
-- Name: composite_material_recipe_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.composite_material_recipe_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: composite_material_recipe_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.composite_material_recipe_items_id_seq OWNED BY public.composite_material_recipe_items.id;


--
-- Name: composite_material_recipes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.composite_material_recipes (
    id integer NOT NULL,
    output_material_id integer NOT NULL,
    output_quantity numeric(12,4) DEFAULT 1 NOT NULL,
    notes text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: composite_material_recipes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.composite_material_recipes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: composite_material_recipes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.composite_material_recipes_id_seq OWNED BY public.composite_material_recipes.id;


--
-- Name: employee_bonus_payments; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: employee_bonus_payments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.employee_bonus_payments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: employee_bonus_payments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.employee_bonus_payments_id_seq OWNED BY public.employee_bonus_payments.id;


--
-- Name: employee_settlements; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: employee_settlements_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.employee_settlements_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: employee_settlements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.employee_settlements_id_seq OWNED BY public.employee_settlements.id;


--
-- Name: employees; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.employees (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    hourly_rate numeric(10,2),
    "position" character varying(100),
    active boolean DEFAULT true
);


--
-- Name: employees_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.employees_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: employees_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.employees_id_seq OWNED BY public.employees.id;


--
-- Name: finished_good_labor; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.finished_good_labor (
    id integer NOT NULL,
    finished_good_id integer,
    work_log_id integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: finished_good_labor_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.finished_good_labor_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: finished_good_labor_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.finished_good_labor_id_seq OWNED BY public.finished_good_labor.id;


--
-- Name: finished_good_material_consumptions; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: finished_good_material_consumptions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.finished_good_material_consumptions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: finished_good_material_consumptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.finished_good_material_consumptions_id_seq OWNED BY public.finished_good_material_consumptions.id;


--
-- Name: finished_good_material_reservations; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: finished_good_material_reservations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.finished_good_material_reservations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: finished_good_material_reservations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.finished_good_material_reservations_id_seq OWNED BY public.finished_good_material_reservations.id;


--
-- Name: finished_goods; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: finished_goods_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.finished_goods_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: finished_goods_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.finished_goods_id_seq OWNED BY public.finished_goods.id;


--
-- Name: indirect_cost_allocations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.indirect_cost_allocations (
    id integer NOT NULL,
    category_id integer,
    finished_good_id integer,
    allocation_date date NOT NULL,
    amount numeric(12,4) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: indirect_cost_allocations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.indirect_cost_allocations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: indirect_cost_allocations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.indirect_cost_allocations_id_seq OWNED BY public.indirect_cost_allocations.id;


--
-- Name: indirect_expense_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.indirect_expense_categories (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    monthly_amount numeric(12,2) NOT NULL,
    is_active boolean DEFAULT true,
    notes text,
    is_cash boolean DEFAULT false
);


--
-- Name: indirect_expense_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.indirect_expense_categories_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: indirect_expense_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.indirect_expense_categories_id_seq OWNED BY public.indirect_expense_categories.id;


--
-- Name: inventory_adjustments; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: inventory_adjustments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.inventory_adjustments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: inventory_adjustments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.inventory_adjustments_id_seq OWNED BY public.inventory_adjustments.id;


--
-- Name: machine_labor_costs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.machine_labor_costs (
    machine_id integer NOT NULL,
    work_type_id integer NOT NULL,
    fixed_cost numeric(12,2),
    estimated_hours numeric(10,2)
);


--
-- Name: machine_materials; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.machine_materials (
    machine_id integer NOT NULL,
    material_id integer NOT NULL,
    quantity numeric(12,4) NOT NULL
);


--
-- Name: machine_tools; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.machine_tools (
    machine_id integer NOT NULL,
    tool_id integer NOT NULL,
    usage_per_unit numeric(10,4)
);


--
-- Name: machines; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.machines (
    id integer NOT NULL,
    model character varying(255) NOT NULL,
    total_cost numeric(12,2) DEFAULT 0
);


--
-- Name: machines_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.machines_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: machines_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.machines_id_seq OWNED BY public.machines.id;


--
-- Name: material_conversions; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: material_conversions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.material_conversions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: material_conversions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.material_conversions_id_seq OWNED BY public.material_conversions.id;


--
-- Name: material_inventory; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.material_inventory (
    material_id integer NOT NULL,
    quantity numeric(12,4) DEFAULT 0 NOT NULL
);


--
-- Name: material_transactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.material_transactions (
    id integer NOT NULL,
    material_id integer,
    quantity_change numeric(12,4),
    transaction_type character varying(20),
    reference_id integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: material_transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.material_transactions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: material_transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.material_transactions_id_seq OWNED BY public.material_transactions.id;


--
-- Name: material_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.material_types (
    id integer NOT NULL,
    name character varying(100) NOT NULL
);


--
-- Name: material_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.material_types_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: material_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.material_types_id_seq OWNED BY public.material_types.id;


--
-- Name: materials; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: materials_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.materials_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: materials_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.materials_id_seq OWNED BY public.materials.id;


--
-- Name: misc_expense_machine_links; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.misc_expense_machine_links (
    expense_id integer NOT NULL,
    finished_good_id integer NOT NULL,
    allocated_amount numeric(12,2) DEFAULT 0 NOT NULL
);


--
-- Name: misc_expenses; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: misc_expenses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.misc_expenses_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: misc_expenses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.misc_expenses_id_seq OWNED BY public.misc_expenses.id;


--
-- Name: plate_material_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.plate_material_types (
    id integer NOT NULL,
    name character varying(100) NOT NULL
);


--
-- Name: plate_part_templates; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: plate_part_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.plate_part_templates_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: plate_part_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.plate_part_templates_id_seq OWNED BY public.plate_part_templates.id;


--
-- Name: purchases; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: purchases_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.purchases_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: purchases_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.purchases_id_seq OWNED BY public.purchases.id;


--
-- Name: sales; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sales (
    id integer NOT NULL,
    finished_good_id integer,
    sale_date date DEFAULT CURRENT_DATE,
    sale_price numeric(12,2) NOT NULL,
    profit numeric(12,2)
);


--
-- Name: sales_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sales_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sales_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sales_id_seq OWNED BY public.sales.id;


--
-- Name: suppliers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.suppliers (
    id integer NOT NULL,
    name character varying(255) NOT NULL
);


--
-- Name: suppliers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.suppliers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: suppliers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.suppliers_id_seq OWNED BY public.suppliers.id;


--
-- Name: tax_payments; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: tax_payments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tax_payments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tax_payments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tax_payments_id_seq OWNED BY public.tax_payments.id;


--
-- Name: tool_depreciation; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tool_depreciation (
    id integer NOT NULL,
    tool_id integer,
    depreciation_date date DEFAULT CURRENT_DATE,
    amount numeric(12,2) NOT NULL,
    finished_good_id integer,
    notes text
);


--
-- Name: tool_depreciation_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tool_depreciation_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tool_depreciation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tool_depreciation_id_seq OWNED BY public.tool_depreciation.id;


--
-- Name: tools; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: tools_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tools_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tools_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tools_id_seq OWNED BY public.tools.id;


--
-- Name: work_logs; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: work_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.work_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: work_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.work_logs_id_seq OWNED BY public.work_logs.id;


--
-- Name: work_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.work_types (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    description text
);


--
-- Name: work_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.work_types_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: work_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.work_types_id_seq OWNED BY public.work_types.id;


--
-- Name: app_operations_log id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.app_operations_log ALTER COLUMN id SET DEFAULT nextval('public.app_operations_log_id_seq'::regclass);


--
-- Name: balance id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.balance ALTER COLUMN id SET DEFAULT nextval('public.balance_id_seq'::regclass);


--
-- Name: composite_material_recipe_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.composite_material_recipe_items ALTER COLUMN id SET DEFAULT nextval('public.composite_material_recipe_items_id_seq'::regclass);


--
-- Name: composite_material_recipes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.composite_material_recipes ALTER COLUMN id SET DEFAULT nextval('public.composite_material_recipes_id_seq'::regclass);


--
-- Name: employee_bonus_payments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employee_bonus_payments ALTER COLUMN id SET DEFAULT nextval('public.employee_bonus_payments_id_seq'::regclass);


--
-- Name: employee_settlements id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employee_settlements ALTER COLUMN id SET DEFAULT nextval('public.employee_settlements_id_seq'::regclass);


--
-- Name: employees id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employees ALTER COLUMN id SET DEFAULT nextval('public.employees_id_seq'::regclass);


--
-- Name: finished_good_labor id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.finished_good_labor ALTER COLUMN id SET DEFAULT nextval('public.finished_good_labor_id_seq'::regclass);


--
-- Name: finished_good_material_consumptions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.finished_good_material_consumptions ALTER COLUMN id SET DEFAULT nextval('public.finished_good_material_consumptions_id_seq'::regclass);


--
-- Name: finished_good_material_reservations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.finished_good_material_reservations ALTER COLUMN id SET DEFAULT nextval('public.finished_good_material_reservations_id_seq'::regclass);


--
-- Name: finished_goods id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.finished_goods ALTER COLUMN id SET DEFAULT nextval('public.finished_goods_id_seq'::regclass);


--
-- Name: indirect_cost_allocations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.indirect_cost_allocations ALTER COLUMN id SET DEFAULT nextval('public.indirect_cost_allocations_id_seq'::regclass);


--
-- Name: indirect_expense_categories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.indirect_expense_categories ALTER COLUMN id SET DEFAULT nextval('public.indirect_expense_categories_id_seq'::regclass);


--
-- Name: inventory_adjustments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_adjustments ALTER COLUMN id SET DEFAULT nextval('public.inventory_adjustments_id_seq'::regclass);


--
-- Name: machines id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.machines ALTER COLUMN id SET DEFAULT nextval('public.machines_id_seq'::regclass);


--
-- Name: material_conversions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.material_conversions ALTER COLUMN id SET DEFAULT nextval('public.material_conversions_id_seq'::regclass);


--
-- Name: material_transactions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.material_transactions ALTER COLUMN id SET DEFAULT nextval('public.material_transactions_id_seq'::regclass);


--
-- Name: material_types id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.material_types ALTER COLUMN id SET DEFAULT nextval('public.material_types_id_seq'::regclass);


--
-- Name: materials id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materials ALTER COLUMN id SET DEFAULT nextval('public.materials_id_seq'::regclass);


--
-- Name: misc_expenses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.misc_expenses ALTER COLUMN id SET DEFAULT nextval('public.misc_expenses_id_seq'::regclass);


--
-- Name: plate_part_templates id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plate_part_templates ALTER COLUMN id SET DEFAULT nextval('public.plate_part_templates_id_seq'::regclass);


--
-- Name: purchases id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchases ALTER COLUMN id SET DEFAULT nextval('public.purchases_id_seq'::regclass);


--
-- Name: sales id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales ALTER COLUMN id SET DEFAULT nextval('public.sales_id_seq'::regclass);


--
-- Name: suppliers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.suppliers ALTER COLUMN id SET DEFAULT nextval('public.suppliers_id_seq'::regclass);


--
-- Name: tax_payments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tax_payments ALTER COLUMN id SET DEFAULT nextval('public.tax_payments_id_seq'::regclass);


--
-- Name: tool_depreciation id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tool_depreciation ALTER COLUMN id SET DEFAULT nextval('public.tool_depreciation_id_seq'::regclass);


--
-- Name: tools id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tools ALTER COLUMN id SET DEFAULT nextval('public.tools_id_seq'::regclass);


--
-- Name: work_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.work_logs ALTER COLUMN id SET DEFAULT nextval('public.work_logs_id_seq'::regclass);


--
-- Name: work_types id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.work_types ALTER COLUMN id SET DEFAULT nextval('public.work_types_id_seq'::regclass);


--
-- Name: app_operations_log app_operations_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.app_operations_log
    ADD CONSTRAINT app_operations_log_pkey PRIMARY KEY (id);


--
-- Name: balance balance_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.balance
    ADD CONSTRAINT balance_pkey PRIMARY KEY (id);


--
-- Name: composite_material_recipe_items composite_material_recipe_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.composite_material_recipe_items
    ADD CONSTRAINT composite_material_recipe_items_pkey PRIMARY KEY (id);


--
-- Name: composite_material_recipes composite_material_recipes_output_material_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.composite_material_recipes
    ADD CONSTRAINT composite_material_recipes_output_material_id_key UNIQUE (output_material_id);


--
-- Name: composite_material_recipes composite_material_recipes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.composite_material_recipes
    ADD CONSTRAINT composite_material_recipes_pkey PRIMARY KEY (id);


--
-- Name: employee_bonus_payments employee_bonus_payments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employee_bonus_payments
    ADD CONSTRAINT employee_bonus_payments_pkey PRIMARY KEY (id);


--
-- Name: employee_settlements employee_settlements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employee_settlements
    ADD CONSTRAINT employee_settlements_pkey PRIMARY KEY (id);


--
-- Name: employees employees_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT employees_pkey PRIMARY KEY (id);


--
-- Name: finished_good_labor finished_good_labor_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.finished_good_labor
    ADD CONSTRAINT finished_good_labor_pkey PRIMARY KEY (id);


--
-- Name: finished_good_material_consumptions finished_good_material_consumptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.finished_good_material_consumptions
    ADD CONSTRAINT finished_good_material_consumptions_pkey PRIMARY KEY (id);


--
-- Name: finished_good_material_reservations finished_good_material_reservations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.finished_good_material_reservations
    ADD CONSTRAINT finished_good_material_reservations_pkey PRIMARY KEY (id);


--
-- Name: finished_goods finished_goods_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.finished_goods
    ADD CONSTRAINT finished_goods_pkey PRIMARY KEY (id);


--
-- Name: indirect_cost_allocations indirect_cost_allocations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.indirect_cost_allocations
    ADD CONSTRAINT indirect_cost_allocations_pkey PRIMARY KEY (id);


--
-- Name: indirect_expense_categories indirect_expense_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.indirect_expense_categories
    ADD CONSTRAINT indirect_expense_categories_pkey PRIMARY KEY (id);


--
-- Name: inventory_adjustments inventory_adjustments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_adjustments
    ADD CONSTRAINT inventory_adjustments_pkey PRIMARY KEY (id);


--
-- Name: machine_labor_costs machine_labor_costs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.machine_labor_costs
    ADD CONSTRAINT machine_labor_costs_pkey PRIMARY KEY (machine_id, work_type_id);


--
-- Name: machine_materials machine_materials_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.machine_materials
    ADD CONSTRAINT machine_materials_pkey PRIMARY KEY (machine_id, material_id);


--
-- Name: machine_tools machine_tools_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.machine_tools
    ADD CONSTRAINT machine_tools_pkey PRIMARY KEY (machine_id, tool_id);


--
-- Name: machines machines_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.machines
    ADD CONSTRAINT machines_pkey PRIMARY KEY (id);


--
-- Name: material_conversions material_conversions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.material_conversions
    ADD CONSTRAINT material_conversions_pkey PRIMARY KEY (id);


--
-- Name: material_inventory material_inventory_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.material_inventory
    ADD CONSTRAINT material_inventory_pkey PRIMARY KEY (material_id);


--
-- Name: material_transactions material_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.material_transactions
    ADD CONSTRAINT material_transactions_pkey PRIMARY KEY (id);


--
-- Name: material_types material_types_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.material_types
    ADD CONSTRAINT material_types_name_key UNIQUE (name);


--
-- Name: material_types material_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.material_types
    ADD CONSTRAINT material_types_pkey PRIMARY KEY (id);


--
-- Name: materials materials_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materials
    ADD CONSTRAINT materials_name_key UNIQUE (name);


--
-- Name: materials materials_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materials
    ADD CONSTRAINT materials_pkey PRIMARY KEY (id);


--
-- Name: misc_expense_machine_links misc_expense_machine_links_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.misc_expense_machine_links
    ADD CONSTRAINT misc_expense_machine_links_pkey PRIMARY KEY (expense_id, finished_good_id);


--
-- Name: misc_expenses misc_expenses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.misc_expenses
    ADD CONSTRAINT misc_expenses_pkey PRIMARY KEY (id);


--
-- Name: plate_material_types plate_material_types_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plate_material_types
    ADD CONSTRAINT plate_material_types_name_key UNIQUE (name);


--
-- Name: plate_material_types plate_material_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plate_material_types
    ADD CONSTRAINT plate_material_types_pkey PRIMARY KEY (id);


--
-- Name: plate_part_templates plate_part_templates_name_plate_material_type_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plate_part_templates
    ADD CONSTRAINT plate_part_templates_name_plate_material_type_id_key UNIQUE (name, plate_material_type_id);


--
-- Name: plate_part_templates plate_part_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plate_part_templates
    ADD CONSTRAINT plate_part_templates_pkey PRIMARY KEY (id);


--
-- Name: purchases purchases_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchases
    ADD CONSTRAINT purchases_pkey PRIMARY KEY (id);


--
-- Name: sales sales_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales
    ADD CONSTRAINT sales_pkey PRIMARY KEY (id);


--
-- Name: suppliers suppliers_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.suppliers
    ADD CONSTRAINT suppliers_name_key UNIQUE (name);


--
-- Name: suppliers suppliers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.suppliers
    ADD CONSTRAINT suppliers_pkey PRIMARY KEY (id);


--
-- Name: tax_payments tax_payments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tax_payments
    ADD CONSTRAINT tax_payments_pkey PRIMARY KEY (id);


--
-- Name: tool_depreciation tool_depreciation_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tool_depreciation
    ADD CONSTRAINT tool_depreciation_pkey PRIMARY KEY (id);


--
-- Name: tools tools_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tools
    ADD CONSTRAINT tools_pkey PRIMARY KEY (id);


--
-- Name: work_logs work_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.work_logs
    ADD CONSTRAINT work_logs_pkey PRIMARY KEY (id);


--
-- Name: work_types work_types_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.work_types
    ADD CONSTRAINT work_types_name_key UNIQUE (name);


--
-- Name: work_types work_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.work_types
    ADD CONSTRAINT work_types_pkey PRIMARY KEY (id);


--
-- Name: idx_app_operations_log_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_app_operations_log_created_at ON public.app_operations_log USING btree (created_at DESC);


--
-- Name: idx_misc_expense_machine_links_fg; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_misc_expense_machine_links_fg ON public.misc_expense_machine_links USING btree (finished_good_id);


--
-- Name: idx_misc_expenses_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_misc_expenses_date ON public.misc_expenses USING btree (expense_date DESC, id DESC);


--
-- Name: composite_material_recipe_items composite_material_recipe_items_material_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.composite_material_recipe_items
    ADD CONSTRAINT composite_material_recipe_items_material_id_fkey FOREIGN KEY (material_id) REFERENCES public.materials(id);


--
-- Name: composite_material_recipe_items composite_material_recipe_items_recipe_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.composite_material_recipe_items
    ADD CONSTRAINT composite_material_recipe_items_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES public.composite_material_recipes(id) ON DELETE CASCADE;


--
-- Name: composite_material_recipes composite_material_recipes_output_material_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.composite_material_recipes
    ADD CONSTRAINT composite_material_recipes_output_material_id_fkey FOREIGN KEY (output_material_id) REFERENCES public.materials(id) ON DELETE CASCADE;


--
-- Name: employee_settlements employee_settlements_employee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employee_settlements
    ADD CONSTRAINT employee_settlements_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES public.employees(id) ON DELETE CASCADE;


--
-- Name: finished_good_labor finished_good_labor_finished_good_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.finished_good_labor
    ADD CONSTRAINT finished_good_labor_finished_good_id_fkey FOREIGN KEY (finished_good_id) REFERENCES public.finished_goods(id) ON DELETE CASCADE;


--
-- Name: finished_good_labor finished_good_labor_work_log_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.finished_good_labor
    ADD CONSTRAINT finished_good_labor_work_log_id_fkey FOREIGN KEY (work_log_id) REFERENCES public.work_logs(id) ON DELETE CASCADE;


--
-- Name: finished_good_material_consumptions finished_good_material_consumptions_finished_good_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.finished_good_material_consumptions
    ADD CONSTRAINT finished_good_material_consumptions_finished_good_id_fkey FOREIGN KEY (finished_good_id) REFERENCES public.finished_goods(id) ON DELETE CASCADE;


--
-- Name: finished_good_material_consumptions finished_good_material_consumptions_material_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.finished_good_material_consumptions
    ADD CONSTRAINT finished_good_material_consumptions_material_id_fkey FOREIGN KEY (material_id) REFERENCES public.materials(id);


--
-- Name: finished_good_material_consumptions finished_good_material_consumptions_purchase_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.finished_good_material_consumptions
    ADD CONSTRAINT finished_good_material_consumptions_purchase_id_fkey FOREIGN KEY (purchase_id) REFERENCES public.purchases(id);


--
-- Name: finished_good_material_reservations finished_good_material_reservations_finished_good_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.finished_good_material_reservations
    ADD CONSTRAINT finished_good_material_reservations_finished_good_id_fkey FOREIGN KEY (finished_good_id) REFERENCES public.finished_goods(id) ON DELETE CASCADE;


--
-- Name: finished_good_material_reservations finished_good_material_reservations_material_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.finished_good_material_reservations
    ADD CONSTRAINT finished_good_material_reservations_material_id_fkey FOREIGN KEY (material_id) REFERENCES public.materials(id);


--
-- Name: finished_good_material_reservations finished_good_material_reservations_purchase_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.finished_good_material_reservations
    ADD CONSTRAINT finished_good_material_reservations_purchase_id_fkey FOREIGN KEY (purchase_id) REFERENCES public.purchases(id);


--
-- Name: finished_goods finished_goods_machine_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.finished_goods
    ADD CONSTRAINT finished_goods_machine_id_fkey FOREIGN KEY (machine_id) REFERENCES public.machines(id);


--
-- Name: indirect_cost_allocations indirect_cost_allocations_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.indirect_cost_allocations
    ADD CONSTRAINT indirect_cost_allocations_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.indirect_expense_categories(id) ON DELETE CASCADE;


--
-- Name: indirect_cost_allocations indirect_cost_allocations_finished_good_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.indirect_cost_allocations
    ADD CONSTRAINT indirect_cost_allocations_finished_good_id_fkey FOREIGN KEY (finished_good_id) REFERENCES public.finished_goods(id) ON DELETE CASCADE;


--
-- Name: inventory_adjustments inventory_adjustments_material_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_adjustments
    ADD CONSTRAINT inventory_adjustments_material_id_fkey FOREIGN KEY (material_id) REFERENCES public.materials(id);


--
-- Name: machine_labor_costs machine_labor_costs_machine_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.machine_labor_costs
    ADD CONSTRAINT machine_labor_costs_machine_id_fkey FOREIGN KEY (machine_id) REFERENCES public.machines(id);


--
-- Name: machine_labor_costs machine_labor_costs_work_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.machine_labor_costs
    ADD CONSTRAINT machine_labor_costs_work_type_id_fkey FOREIGN KEY (work_type_id) REFERENCES public.work_types(id);


--
-- Name: machine_materials machine_materials_machine_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.machine_materials
    ADD CONSTRAINT machine_materials_machine_id_fkey FOREIGN KEY (machine_id) REFERENCES public.machines(id) ON DELETE CASCADE;


--
-- Name: machine_materials machine_materials_material_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.machine_materials
    ADD CONSTRAINT machine_materials_material_id_fkey FOREIGN KEY (material_id) REFERENCES public.materials(id) ON DELETE RESTRICT;


--
-- Name: machine_tools machine_tools_machine_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.machine_tools
    ADD CONSTRAINT machine_tools_machine_id_fkey FOREIGN KEY (machine_id) REFERENCES public.machines(id);


--
-- Name: machine_tools machine_tools_tool_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.machine_tools
    ADD CONSTRAINT machine_tools_tool_id_fkey FOREIGN KEY (tool_id) REFERENCES public.tools(id);


--
-- Name: material_conversions material_conversions_source_material_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.material_conversions
    ADD CONSTRAINT material_conversions_source_material_id_fkey FOREIGN KEY (source_material_id) REFERENCES public.materials(id);


--
-- Name: material_conversions material_conversions_source_purchase_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.material_conversions
    ADD CONSTRAINT material_conversions_source_purchase_id_fkey FOREIGN KEY (source_purchase_id) REFERENCES public.purchases(id);


--
-- Name: material_conversions material_conversions_target_material_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.material_conversions
    ADD CONSTRAINT material_conversions_target_material_id_fkey FOREIGN KEY (target_material_id) REFERENCES public.materials(id);


--
-- Name: material_conversions material_conversions_template_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.material_conversions
    ADD CONSTRAINT material_conversions_template_id_fkey FOREIGN KEY (template_id) REFERENCES public.plate_part_templates(id);


--
-- Name: material_inventory material_inventory_material_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.material_inventory
    ADD CONSTRAINT material_inventory_material_id_fkey FOREIGN KEY (material_id) REFERENCES public.materials(id) ON DELETE CASCADE;


--
-- Name: material_transactions material_transactions_material_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.material_transactions
    ADD CONSTRAINT material_transactions_material_id_fkey FOREIGN KEY (material_id) REFERENCES public.materials(id);


--
-- Name: materials materials_plate_material_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materials
    ADD CONSTRAINT materials_plate_material_type_id_fkey FOREIGN KEY (plate_material_type_id) REFERENCES public.plate_material_types(id);


--
-- Name: materials materials_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.materials
    ADD CONSTRAINT materials_type_id_fkey FOREIGN KEY (type_id) REFERENCES public.material_types(id) ON DELETE SET NULL;


--
-- Name: misc_expense_machine_links misc_expense_machine_links_expense_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.misc_expense_machine_links
    ADD CONSTRAINT misc_expense_machine_links_expense_id_fkey FOREIGN KEY (expense_id) REFERENCES public.misc_expenses(id) ON DELETE CASCADE;


--
-- Name: misc_expense_machine_links misc_expense_machine_links_finished_good_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.misc_expense_machine_links
    ADD CONSTRAINT misc_expense_machine_links_finished_good_id_fkey FOREIGN KEY (finished_good_id) REFERENCES public.finished_goods(id) ON DELETE CASCADE;


--
-- Name: misc_expenses misc_expenses_balance_entry_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.misc_expenses
    ADD CONSTRAINT misc_expenses_balance_entry_id_fkey FOREIGN KEY (balance_entry_id) REFERENCES public.balance(id) ON DELETE SET NULL;


--
-- Name: plate_part_templates plate_part_templates_plate_material_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plate_part_templates
    ADD CONSTRAINT plate_part_templates_plate_material_type_id_fkey FOREIGN KEY (plate_material_type_id) REFERENCES public.plate_material_types(id);


--
-- Name: purchases purchases_material_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchases
    ADD CONSTRAINT purchases_material_id_fkey FOREIGN KEY (material_id) REFERENCES public.materials(id) ON DELETE CASCADE;


--
-- Name: purchases purchases_supplier_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchases
    ADD CONSTRAINT purchases_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES public.suppliers(id) ON DELETE SET NULL;


--
-- Name: sales sales_finished_good_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales
    ADD CONSTRAINT sales_finished_good_id_fkey FOREIGN KEY (finished_good_id) REFERENCES public.finished_goods(id);


--
-- Name: tool_depreciation tool_depreciation_finished_good_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tool_depreciation
    ADD CONSTRAINT tool_depreciation_finished_good_id_fkey FOREIGN KEY (finished_good_id) REFERENCES public.finished_goods(id);


--
-- Name: tool_depreciation tool_depreciation_tool_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tool_depreciation
    ADD CONSTRAINT tool_depreciation_tool_id_fkey FOREIGN KEY (tool_id) REFERENCES public.tools(id);


--
-- Name: work_logs work_logs_employee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.work_logs
    ADD CONSTRAINT work_logs_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES public.employees(id);


--
-- Name: work_logs work_logs_machine_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.work_logs
    ADD CONSTRAINT work_logs_machine_id_fkey FOREIGN KEY (machine_id) REFERENCES public.machines(id);


--
-- Name: work_logs work_logs_work_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.work_logs
    ADD CONSTRAINT work_logs_work_type_id_fkey FOREIGN KEY (work_type_id) REFERENCES public.work_types(id);


--
-- PostgreSQL database dump complete
--

