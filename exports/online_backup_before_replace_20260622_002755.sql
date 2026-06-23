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
-- Data for Name: app_operations_log; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.app_operations_log (id, created_at, operation_type, description, amount, details) FROM stdin;
1	2026-06-21 17:25:00.166682	purchase	Created initial demo stock purchases	176500.00	Auto-generated for online demo database
2	2026-06-21 17:25:00.166682	production	Finished machine FG-1001	176500.00	Demo completed machine
3	2026-06-21 17:25:00.166682	sale	Sold machine FG-1002	289000.00	Demo sale record
4	2026-06-21 17:25:00.166682	production	Started machine FG-1003	98000.00	Demo in-progress machine
5	2026-06-21 17:37:11.309882	Производство	Зарезервированы материалы для станка ID 3	\N	Модель: LaserCut Mini; Aluminium sheet 4mm: 1.5000; Control board X1: 1.0000; Polycarbonate clear 3mm: 1.0000
6	2026-06-21 17:37:15.199909	Indirect costs	Indirect costs recalculated for 2026-06	\N	Period: 2026-06-01 - 2026-06-30
7	2026-06-21 17:37:15.293796	Производство	Завершено производство станка ID 3	\N	Инвентарный номер: -
8	2026-06-22 00:25:14.222126	Материалы	Добавлен материал: jgh	529.00	Количество: 23.0 23, источник: -
\.


--
-- Data for Name: balance; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.balance (id, date, income, expense, notes, is_cash) FROM stdin;
1	2026-05-22	0.00	125000.00	Material purchases	f
2	2026-06-16	289000.00	0.00	Machine sale FG-1002	f
3	2026-06-19	0.00	4500.00	Domain payment	t
4	2026-06-22	0.00	529.00	Покупка материала: jgh (23.0 23 x 23.0)	f
\.


--
-- Data for Name: composite_material_recipe_items; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.composite_material_recipe_items (id, recipe_id, material_id, quantity) FROM stdin;
\.


--
-- Data for Name: composite_material_recipes; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.composite_material_recipes (id, output_material_id, output_quantity, notes, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: employee_bonus_payments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.employee_bonus_payments (id, period_start, period_end, bonus_percent, base_amount, bonus_amount, paid_until, created_at) FROM stdin;
\.


--
-- Data for Name: employee_settlements; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.employee_settlements (id, employee_id, settlement_type, settlement_date, title, amount, notes, created_at) FROM stdin;
\.


--
-- Data for Name: employees; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.employees (id, name, hourly_rate, "position", active) FROM stdin;
1	Ivan Petrov	850.00	Assembler	t
2	Anna Sidorova	920.00	Engineer	t
3	Pavel Orlov	780.00	Operator	t
4	Nikita Smirnov	650.00	Storekeeper	t
\.


--
-- Data for Name: finished_good_labor; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.finished_good_labor (id, finished_good_id, work_log_id, created_at) FROM stdin;
1	1	1	2026-06-21 17:25:00.166682
2	2	2	2026-06-21 17:25:00.166682
3	2	3	2026-06-21 17:25:00.166682
4	3	4	2026-06-21 17:25:00.166682
\.


--
-- Data for Name: finished_good_material_consumptions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.finished_good_material_consumptions (id, finished_good_id, material_id, purchase_id, quantity, amount, is_cash, created_at) FROM stdin;
1	3	5	5	1.5000	6300.00	f	2026-06-21 17:37:14.902307
2	3	3	3	1.0000	9600.00	f	2026-06-21 17:37:14.902307
3	3	6	6	1.0000	2600.00	t	2026-06-21 17:37:14.902307
\.


--
-- Data for Name: finished_good_material_reservations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.finished_good_material_reservations (id, finished_good_id, material_id, purchase_id, quantity, amount, is_cash, created_at) FROM stdin;
\.


--
-- Data for Name: finished_goods; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.finished_goods (id, machine_model, machine_id, cost_price, produced_date, status, inventory_number, buyer, sale_date, notes, start_date, indirect_cost, misc_expense_cost, production_status) FROM stdin;
1	MC-Pro 100	1	169925.00	2026-06-01	in_stock	FG-1001	\N	\N	Demo stock machine	2026-05-20	1925.00	1200.00	completed
2	MC-Pro 200	2	253525.00	2026-06-09	sold	FG-1002	OOO Vector	2026-06-16	Sold to demo customer	2026-05-28	32725.00	1800.00	completed
3	LaserCut Mini	3	51150.00	2026-06-21	completed		\N	\N	In assembly	2026-06-14	30800.00	600.00	in_progress
\.


--
-- Data for Name: indirect_cost_allocations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.indirect_cost_allocations (id, category_id, finished_good_id, allocation_date, amount, created_at) FROM stdin;
1	1	1	2026-06-01	1416.6667	2026-06-21 17:37:15.074289
2	1	2	2026-06-01	1416.6667	2026-06-21 17:37:15.074289
3	1	2	2026-06-02	2833.3333	2026-06-21 17:37:15.074289
4	1	2	2026-06-03	2833.3333	2026-06-21 17:37:15.074289
5	1	2	2026-06-04	2833.3333	2026-06-21 17:37:15.074289
6	1	2	2026-06-05	2833.3333	2026-06-21 17:37:15.074289
7	1	2	2026-06-06	2833.3333	2026-06-21 17:37:15.074289
8	1	2	2026-06-07	2833.3333	2026-06-21 17:37:15.074289
9	1	2	2026-06-08	2833.3333	2026-06-21 17:37:15.074289
10	1	2	2026-06-09	2833.3333	2026-06-21 17:37:15.074289
11	1	3	2026-06-14	2833.3333	2026-06-21 17:37:15.074289
12	1	3	2026-06-15	2833.3333	2026-06-21 17:37:15.074289
13	1	3	2026-06-16	2833.3333	2026-06-21 17:37:15.074289
14	1	3	2026-06-17	2833.3333	2026-06-21 17:37:15.074289
15	1	3	2026-06-18	2833.3333	2026-06-21 17:37:15.074289
16	1	3	2026-06-19	2833.3333	2026-06-21 17:37:15.074289
17	1	3	2026-06-20	2833.3333	2026-06-21 17:37:15.074289
18	1	3	2026-06-21	2833.3333	2026-06-21 17:37:15.074289
19	2	1	2026-06-01	433.3333	2026-06-21 17:37:15.074289
20	2	2	2026-06-01	433.3333	2026-06-21 17:37:15.074289
21	2	2	2026-06-02	866.6667	2026-06-21 17:37:15.074289
22	2	2	2026-06-03	866.6667	2026-06-21 17:37:15.074289
23	2	2	2026-06-04	866.6667	2026-06-21 17:37:15.074289
24	2	2	2026-06-05	866.6667	2026-06-21 17:37:15.074289
25	2	2	2026-06-06	866.6667	2026-06-21 17:37:15.074289
26	2	2	2026-06-07	866.6667	2026-06-21 17:37:15.074289
27	2	2	2026-06-08	866.6667	2026-06-21 17:37:15.074289
28	2	2	2026-06-09	866.6667	2026-06-21 17:37:15.074289
29	2	3	2026-06-14	866.6667	2026-06-21 17:37:15.074289
30	2	3	2026-06-15	866.6667	2026-06-21 17:37:15.074289
31	2	3	2026-06-16	866.6667	2026-06-21 17:37:15.074289
32	2	3	2026-06-17	866.6667	2026-06-21 17:37:15.074289
33	2	3	2026-06-18	866.6667	2026-06-21 17:37:15.074289
34	2	3	2026-06-19	866.6667	2026-06-21 17:37:15.074289
35	2	3	2026-06-20	866.6667	2026-06-21 17:37:15.074289
36	2	3	2026-06-21	866.6667	2026-06-21 17:37:15.074289
37	3	1	2026-06-01	75.0000	2026-06-21 17:37:15.074289
38	3	2	2026-06-01	75.0000	2026-06-21 17:37:15.074289
39	3	2	2026-06-02	150.0000	2026-06-21 17:37:15.074289
40	3	2	2026-06-03	150.0000	2026-06-21 17:37:15.074289
41	3	2	2026-06-04	150.0000	2026-06-21 17:37:15.074289
42	3	2	2026-06-05	150.0000	2026-06-21 17:37:15.074289
43	3	2	2026-06-06	150.0000	2026-06-21 17:37:15.074289
44	3	2	2026-06-07	150.0000	2026-06-21 17:37:15.074289
45	3	2	2026-06-08	150.0000	2026-06-21 17:37:15.074289
46	3	2	2026-06-09	150.0000	2026-06-21 17:37:15.074289
47	3	3	2026-06-14	150.0000	2026-06-21 17:37:15.074289
48	3	3	2026-06-15	150.0000	2026-06-21 17:37:15.074289
49	3	3	2026-06-16	150.0000	2026-06-21 17:37:15.074289
50	3	3	2026-06-17	150.0000	2026-06-21 17:37:15.074289
51	3	3	2026-06-18	150.0000	2026-06-21 17:37:15.074289
52	3	3	2026-06-19	150.0000	2026-06-21 17:37:15.074289
53	3	3	2026-06-20	150.0000	2026-06-21 17:37:15.074289
54	3	3	2026-06-21	150.0000	2026-06-21 17:37:15.074289
\.


--
-- Data for Name: indirect_expense_categories; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.indirect_expense_categories (id, name, monthly_amount, is_active, notes, is_cash) FROM stdin;
1	Rent	85000.00	t	Workshop rent	f
2	Electricity	26000.00	t	Monthly power usage	f
3	Domain and hosting	4500.00	t	Service subscriptions	t
\.


--
-- Data for Name: inventory_adjustments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.inventory_adjustments (id, material_id, old_quantity, new_quantity, difference, reason, created_at) FROM stdin;
\.


--
-- Data for Name: machine_labor_costs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.machine_labor_costs (machine_id, work_type_id, fixed_cost, estimated_hours) FROM stdin;
\.


--
-- Data for Name: machine_materials; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.machine_materials (machine_id, material_id, quantity) FROM stdin;
1	4	2.0000
1	3	1.0000
1	2	1.0000
1	1	1.0000
2	4	3.0000
2	3	1.0000
2	2	2.0000
2	1	1.0000
3	6	1.0000
3	5	1.5000
3	3	1.0000
\.


--
-- Data for Name: machine_tools; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.machine_tools (machine_id, tool_id, usage_per_unit) FROM stdin;
\.


--
-- Data for Name: machines; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.machines (id, model, total_cost) FROM stdin;
1	MC-Pro 100	145000.00
2	MC-Pro 200	198000.00
3	LaserCut Mini	121000.00
\.


--
-- Data for Name: material_conversions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.material_conversions (id, source_material_id, source_purchase_id, target_material_id, source_quantity, target_quantity, total_cost, notes, created_at, template_id) FROM stdin;
\.


--
-- Data for Name: material_inventory; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.material_inventory (material_id, quantity) FROM stdin;
1	12.0000
2	7.0000
4	25.0000
5	16.5000
3	8.0000
6	9.0000
7	23.0000
\.


--
-- Data for Name: material_transactions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.material_transactions (id, material_id, quantity_change, transaction_type, reference_id, created_at) FROM stdin;
1	5	-1.5000	reservation	3	2026-06-21 17:37:11.214213
2	3	-1.0000	reservation	3	2026-06-21 17:37:11.214213
3	6	-1.0000	reservation	3	2026-06-21 17:37:11.214213
4	5	-1.5000	production	3	2026-06-21 17:37:14.902307
5	3	-1.0000	production	3	2026-06-21 17:37:14.902307
6	6	-1.0000	production	3	2026-06-21 17:37:14.902307
\.


--
-- Data for Name: material_types; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.material_types (id, name) FROM stdin;
1	Metal
2	Electronics
3	Composite
4	Fasteners
\.


--
-- Data for Name: materials; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.materials (id, name, unit, type_id, product_url, notes, source, updated_date, is_plate, plate_material_type_id, low_stock_threshold, enough_stock_threshold, category) FROM stdin;
1	Steel frame set	pcs	1	\N	Main frame kit	Warehouse import	2026-06-01	f	\N	2.000	6.000	Materials
2	Servo motor 2kW	pcs	2	\N	Drive motor	Warehouse import	2026-06-06	f	\N	1.000	3.000	Materials
3	Control board X1	pcs	2	\N	Controller board	Warehouse import	2026-06-11	f	\N	2.000	4.000	Materials
4	Fastener set M8	set	4	\N	Bolts and nuts	Warehouse import	2026-06-13	f	\N	5.000	12.000	Materials
5	Aluminium sheet 4mm	sqm	1	\N	For panels and covers	Plate storage	2026-06-16	t	2	1.000	3.000	Plate cutting
6	Polycarbonate clear 3mm	sqm	3	\N	Protective screens	Plate storage	2026-06-17	t	4	1.000	2.000	Plate cutting
7	jgh	23	\N	\N	\N	\N	2026-06-21	f	\N	1.000	3.000	Материалы
\.


--
-- Data for Name: misc_expense_machine_links; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.misc_expense_machine_links (expense_id, finished_good_id, allocated_amount) FROM stdin;
\.


--
-- Data for Name: misc_expenses; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.misc_expenses (id, expense_date, title, amount, notes, is_cash, person_name, allocation_mode, balance_entry_id, created_at) FROM stdin;
\.


--
-- Data for Name: plate_material_types; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.plate_material_types (id, name) FROM stdin;
1	Текстолит
2	Алюминий
3	Фанера
4	Поликарбонат
\.


--
-- Data for Name: plate_part_templates; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.plate_part_templates (id, name, plate_material_type_id, part_unit, production_minutes, drawing_file_path, process_file_path, notes, created_at, updated_at, drawing_file_name, drawing_file_data, process_file_name, process_file_data, is_active) FROM stdin;
\.


--
-- Data for Name: purchases; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.purchases (id, material_id, supplier_id, purchase_date, price_per_unit, quantity, remaining_quantity, purchased_by, notes, created_at, is_cash) FROM stdin;
1	1	3	2026-05-22	12500.00	10.0000	8.0000	Ivan Petrov	Initial stock purchase	2026-06-21 17:25:00.166682	f
2	2	2	2026-05-24	18400.00	8.0000	5.0000	Anna Sidorova	Motor batch	2026-06-21 17:25:00.166682	f
4	4	1	2026-05-30	1800.00	30.0000	24.0000	Nikita Smirnov	Fastener stock	2026-06-21 17:25:00.166682	t
5	5	3	2026-06-03	4200.00	20.0000	14.5000	Nikita Smirnov	Aluminium plates	2026-06-21 17:25:00.166682	f
3	3	2	2026-05-27	9600.00	10.0000	6.0000	Anna Sidorova	Controller purchase	2026-06-21 17:25:00.166682	f
6	6	1	2026-06-05	2600.00	12.0000	8.0000	Nikita Smirnov	Polycarbonate batch	2026-06-21 17:25:00.166682	t
7	7	\N	2026-06-22	23.00	23.0000	23.0000	\N	\N	2026-06-22 00:25:13.465484	f
\.


--
-- Data for Name: sales; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sales (id, finished_good_id, sale_date, sale_price, profit) FROM stdin;
1	2	2026-06-16	289000.00	57000.00
\.


--
-- Data for Name: suppliers; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.suppliers (id, name) FROM stdin;
1	North Supply
2	Vector Components
3	TechnoSteel
\.


--
-- Data for Name: tax_payments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.tax_payments (id, payment_date, period_start, period_end, tax_rate, tax_base, tax_amount, notes, created_at) FROM stdin;
1	2026-06-20	2026-05-01	2026-05-31	6.00	289000.00	17340.00	Demo tax payment	2026-06-21 17:25:00.166682
\.


--
-- Data for Name: tool_depreciation; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.tool_depreciation (id, tool_id, depreciation_date, amount, finished_good_id, notes) FROM stdin;
1	1	2026-06-01	333.33	1	Monthly depreciation
2	2	2026-06-09	1125.00	2	Testing equipment depreciation
\.


--
-- Data for Name: tools; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.tools (id, name, inventory_number, purchase_date, purchase_cost, useful_life_months, monthly_depreciation, residual_value, status, notes) FROM stdin;
1	Torque wrench	TL-001	2025-12-23	12000.00	36	333.33	9200.00	active	Assembly tool
2	Diagnostic laptop	TL-002	2025-10-24	54000.00	48	1125.00	36000.00	active	Testing workstation
\.


--
-- Data for Name: work_logs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.work_logs (id, employee_id, work_type_id, machine_id, date, hours, notes) FROM stdin;
1	1	1	1	2026-05-23	6.50	Frame assembly
2	2	2	2	2026-06-03	4.00	Controller wiring
3	3	3	2	2026-06-10	3.50	Acceptance tests
4	1	1	3	2026-06-19	5.00	Current assembly work
\.


--
-- Data for Name: work_types; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.work_types (id, name, description) FROM stdin;
1	Assembly	Machine assembly
2	Wiring	Electrical installation
3	Testing	Functional testing
\.


--
-- Name: app_operations_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.app_operations_log_id_seq', 8, true);


--
-- Name: balance_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.balance_id_seq', 4, true);


--
-- Name: composite_material_recipe_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.composite_material_recipe_items_id_seq', 1, false);


--
-- Name: composite_material_recipes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.composite_material_recipes_id_seq', 1, false);


--
-- Name: employee_bonus_payments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.employee_bonus_payments_id_seq', 1, false);


--
-- Name: employee_settlements_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.employee_settlements_id_seq', 1, false);


--
-- Name: employees_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.employees_id_seq', 4, true);


--
-- Name: finished_good_labor_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.finished_good_labor_id_seq', 4, true);


--
-- Name: finished_good_material_consumptions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.finished_good_material_consumptions_id_seq', 3, true);


--
-- Name: finished_good_material_reservations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.finished_good_material_reservations_id_seq', 3, true);


--
-- Name: finished_goods_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.finished_goods_id_seq', 3, true);


--
-- Name: indirect_cost_allocations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.indirect_cost_allocations_id_seq', 54, true);


--
-- Name: indirect_expense_categories_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.indirect_expense_categories_id_seq', 3, true);


--
-- Name: inventory_adjustments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.inventory_adjustments_id_seq', 1, false);


--
-- Name: machines_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.machines_id_seq', 3, true);


--
-- Name: material_conversions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.material_conversions_id_seq', 1, false);


--
-- Name: material_transactions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.material_transactions_id_seq', 6, true);


--
-- Name: material_types_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.material_types_id_seq', 4, true);


--
-- Name: materials_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.materials_id_seq', 7, true);


--
-- Name: misc_expenses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.misc_expenses_id_seq', 1, false);


--
-- Name: plate_part_templates_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.plate_part_templates_id_seq', 1, false);


--
-- Name: purchases_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.purchases_id_seq', 7, true);


--
-- Name: sales_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.sales_id_seq', 1, true);


--
-- Name: suppliers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.suppliers_id_seq', 3, true);


--
-- Name: tax_payments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tax_payments_id_seq', 1, true);


--
-- Name: tool_depreciation_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tool_depreciation_id_seq', 2, true);


--
-- Name: tools_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tools_id_seq', 2, true);


--
-- Name: work_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.work_logs_id_seq', 4, true);


--
-- Name: work_types_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.work_types_id_seq', 3, true);


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

