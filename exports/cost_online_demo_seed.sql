BEGIN;

INSERT INTO material_types (name) VALUES
('Metal'), ('Electronics'), ('Composite'), ('Fasteners')
ON CONFLICT (name) DO NOTHING;

INSERT INTO plate_material_types (id, name) VALUES
(1, 'Textolite'),
(2, 'Aluminium'),
(3, 'Plywood'),
(4, 'Polycarbonate')
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;

INSERT INTO suppliers (name) VALUES
('North Supply'),
('Vector Components'),
('TechnoSteel')
ON CONFLICT (name) DO NOTHING;

INSERT INTO employees (name, hourly_rate, position, active) VALUES
('Ivan Petrov', 850, 'Assembler', true),
('Anna Sidorova', 920, 'Engineer', true),
('Pavel Orlov', 780, 'Operator', true),
('Nikita Smirnov', 650, 'Storekeeper', true)
ON CONFLICT DO NOTHING;

INSERT INTO work_types (name, description) VALUES
('Assembly', 'Machine assembly'),
('Wiring', 'Electrical installation'),
('Testing', 'Functional testing')
ON CONFLICT DO NOTHING;

INSERT INTO materials (name, unit, type_id, source, notes, updated_date, is_plate, plate_material_type_id, low_stock_threshold, enough_stock_threshold, category) VALUES
('Steel frame set', 'pcs', (SELECT id FROM material_types WHERE name='Metal' LIMIT 1), 'Warehouse import', 'Main frame kit', CURRENT_DATE - 20, false, NULL, 2, 6, 'Materials'),
('Servo motor 2kW', 'pcs', (SELECT id FROM material_types WHERE name='Electronics' LIMIT 1), 'Warehouse import', 'Drive motor', CURRENT_DATE - 15, false, NULL, 1, 3, 'Materials'),
('Control board X1', 'pcs', (SELECT id FROM material_types WHERE name='Electronics' LIMIT 1), 'Warehouse import', 'Controller board', CURRENT_DATE - 10, false, NULL, 2, 4, 'Materials'),
('Fastener set M8', 'set', (SELECT id FROM material_types WHERE name='Fasteners' LIMIT 1), 'Warehouse import', 'Bolts and nuts', CURRENT_DATE - 8, false, NULL, 5, 12, 'Materials'),
('Aluminium sheet 4mm', 'sqm', (SELECT id FROM material_types WHERE name='Metal' LIMIT 1), 'Plate storage', 'For panels and covers', CURRENT_DATE - 5, true, 2, 1, 3, 'Plate cutting'),
('Polycarbonate clear 3mm', 'sqm', (SELECT id FROM material_types WHERE name='Composite' LIMIT 1), 'Plate storage', 'Protective screens', CURRENT_DATE - 4, true, 4, 1, 2, 'Plate cutting')
ON CONFLICT (name) DO NOTHING;

INSERT INTO material_inventory (material_id, quantity)
SELECT id,
       CASE name
         WHEN 'Steel frame set' THEN 12
         WHEN 'Servo motor 2kW' THEN 7
         WHEN 'Control board X1' THEN 9
         WHEN 'Fastener set M8' THEN 25
         WHEN 'Aluminium sheet 4mm' THEN 18
         WHEN 'Polycarbonate clear 3mm' THEN 10
         ELSE 0
       END
FROM materials
ON CONFLICT (material_id) DO UPDATE SET quantity = EXCLUDED.quantity;

INSERT INTO purchases (material_id, supplier_id, purchase_date, price_per_unit, quantity, remaining_quantity, purchased_by, notes, is_cash)
SELECT m.id,
       (SELECT id FROM suppliers WHERE name='TechnoSteel' LIMIT 1),
       CURRENT_DATE - 30,
       12500,
       10,
       8,
       'Ivan Petrov',
       'Initial stock purchase',
       false
FROM materials m WHERE m.name='Steel frame set'
UNION ALL
SELECT m.id,
       (SELECT id FROM suppliers WHERE name='Vector Components' LIMIT 1),
       CURRENT_DATE - 28,
       18400,
       8,
       5,
       'Anna Sidorova',
       'Motor batch',
       false
FROM materials m WHERE m.name='Servo motor 2kW'
UNION ALL
SELECT m.id,
       (SELECT id FROM suppliers WHERE name='Vector Components' LIMIT 1),
       CURRENT_DATE - 25,
       9600,
       10,
       7,
       'Anna Sidorova',
       'Controller purchase',
       false
FROM materials m WHERE m.name='Control board X1'
UNION ALL
SELECT m.id,
       (SELECT id FROM suppliers WHERE name='North Supply' LIMIT 1),
       CURRENT_DATE - 22,
       1800,
       30,
       24,
       'Nikita Smirnov',
       'Fastener stock',
       true
FROM materials m WHERE m.name='Fastener set M8'
UNION ALL
SELECT m.id,
       (SELECT id FROM suppliers WHERE name='TechnoSteel' LIMIT 1),
       CURRENT_DATE - 18,
       4200,
       20,
       16,
       'Nikita Smirnov',
       'Aluminium plates',
       false
FROM materials m WHERE m.name='Aluminium sheet 4mm'
UNION ALL
SELECT m.id,
       (SELECT id FROM suppliers WHERE name='North Supply' LIMIT 1),
       CURRENT_DATE - 16,
       2600,
       12,
       9,
       'Nikita Smirnov',
       'Polycarbonate batch',
       true
FROM materials m WHERE m.name='Polycarbonate clear 3mm';

INSERT INTO machines (model, total_cost) VALUES
('MC-Pro 100', 145000),
('MC-Pro 200', 198000),
('LaserCut Mini', 121000)
ON CONFLICT DO NOTHING;

INSERT INTO machine_materials (machine_id, material_id, quantity)
SELECT mach.id, mat.id, qty
FROM (
    VALUES
    ('MC-Pro 100', 'Steel frame set', 1.0),
    ('MC-Pro 100', 'Servo motor 2kW', 1.0),
    ('MC-Pro 100', 'Control board X1', 1.0),
    ('MC-Pro 100', 'Fastener set M8', 2.0),
    ('MC-Pro 200', 'Steel frame set', 1.0),
    ('MC-Pro 200', 'Servo motor 2kW', 2.0),
    ('MC-Pro 200', 'Control board X1', 1.0),
    ('MC-Pro 200', 'Fastener set M8', 3.0),
    ('LaserCut Mini', 'Aluminium sheet 4mm', 1.5),
    ('LaserCut Mini', 'Polycarbonate clear 3mm', 1.0),
    ('LaserCut Mini', 'Control board X1', 1.0)
) AS src(model_name, material_name, qty)
JOIN machines mach ON mach.model = src.model_name
JOIN materials mat ON mat.name = src.material_name
ON CONFLICT (machine_id, material_id) DO UPDATE SET quantity = EXCLUDED.quantity;

INSERT INTO finished_goods (machine_model, machine_id, cost_price, produced_date, status, inventory_number, buyer, sale_date, notes, start_date, indirect_cost, misc_expense_cost, production_status) VALUES
('MC-Pro 100', (SELECT id FROM machines WHERE model='MC-Pro 100' LIMIT 1), 176500, CURRENT_DATE - 20, 'in_stock', 'FG-1001', NULL, NULL, 'Demo stock machine', CURRENT_DATE - 32, 8500, 1200, 'completed'),
('MC-Pro 200', (SELECT id FROM machines WHERE model='MC-Pro 200' LIMIT 1), 232000, CURRENT_DATE - 12, 'sold', 'FG-1002', 'OOO Vector', CURRENT_DATE - 5, 'Sold to demo customer', CURRENT_DATE - 24, 11200, 1800, 'completed'),
('LaserCut Mini', (SELECT id FROM machines WHERE model='LaserCut Mini' LIMIT 1), 98000, NULL, 'in_progress', 'FG-1003', NULL, NULL, 'In assembly', CURRENT_DATE - 7, 2400, 600, 'in_progress');

INSERT INTO sales (finished_good_id, sale_date, sale_price, profit) VALUES
((SELECT id FROM finished_goods WHERE inventory_number='FG-1002' LIMIT 1), CURRENT_DATE - 5, 289000, 57000)
ON CONFLICT DO NOTHING;

INSERT INTO work_logs (employee_id, work_type_id, machine_id, date, hours, notes) VALUES
((SELECT id FROM employees WHERE name='Ivan Petrov' LIMIT 1), (SELECT id FROM work_types WHERE name='Assembly' LIMIT 1), (SELECT id FROM machines WHERE model='MC-Pro 100' LIMIT 1), CURRENT_DATE - 29, 6.5, 'Frame assembly'),
((SELECT id FROM employees WHERE name='Anna Sidorova' LIMIT 1), (SELECT id FROM work_types WHERE name='Wiring' LIMIT 1), (SELECT id FROM machines WHERE model='MC-Pro 200' LIMIT 1), CURRENT_DATE - 18, 4.0, 'Controller wiring'),
((SELECT id FROM employees WHERE name='Pavel Orlov' LIMIT 1), (SELECT id FROM work_types WHERE name='Testing' LIMIT 1), (SELECT id FROM machines WHERE model='MC-Pro 200' LIMIT 1), CURRENT_DATE - 11, 3.5, 'Acceptance tests'),
((SELECT id FROM employees WHERE name='Ivan Petrov' LIMIT 1), (SELECT id FROM work_types WHERE name='Assembly' LIMIT 1), (SELECT id FROM machines WHERE model='LaserCut Mini' LIMIT 1), CURRENT_DATE - 2, 5.0, 'Current assembly work');

INSERT INTO finished_good_labor (finished_good_id, work_log_id)
SELECT fg.id, wl.id
FROM finished_goods fg
JOIN machines m ON m.id = fg.machine_id
JOIN work_logs wl ON wl.machine_id = m.id
WHERE (fg.inventory_number='FG-1001' AND wl.notes='Frame assembly')
   OR (fg.inventory_number='FG-1002' AND wl.notes IN ('Controller wiring', 'Acceptance tests'))
   OR (fg.inventory_number='FG-1003' AND wl.notes='Current assembly work');

INSERT INTO tools (name, inventory_number, purchase_date, purchase_cost, useful_life_months, monthly_depreciation, residual_value, status, notes) VALUES
('Torque wrench', 'TL-001', CURRENT_DATE - 180, 12000, 36, 333.33, 9200, 'active', 'Assembly tool'),
('Diagnostic laptop', 'TL-002', CURRENT_DATE - 240, 54000, 48, 1125.00, 36000, 'active', 'Testing workstation')
ON CONFLICT DO NOTHING;

INSERT INTO tool_depreciation (tool_id, depreciation_date, amount, finished_good_id, notes) VALUES
((SELECT id FROM tools WHERE inventory_number='TL-001' LIMIT 1), CURRENT_DATE - 20, 333.33, (SELECT id FROM finished_goods WHERE inventory_number='FG-1001' LIMIT 1), 'Monthly depreciation'),
((SELECT id FROM tools WHERE inventory_number='TL-002' LIMIT 1), CURRENT_DATE - 12, 1125.00, (SELECT id FROM finished_goods WHERE inventory_number='FG-1002' LIMIT 1), 'Testing equipment depreciation');

INSERT INTO indirect_expense_categories (name, monthly_amount, is_active, notes, is_cash) VALUES
('Rent', 85000, true, 'Workshop rent', false),
('Electricity', 26000, true, 'Monthly power usage', false),
('Domain and hosting', 4500, true, 'Service subscriptions', true)
ON CONFLICT DO NOTHING;

INSERT INTO balance (date, income, expense, notes, is_cash) VALUES
(CURRENT_DATE - 30, 0, 125000, 'Material purchases', false),
(CURRENT_DATE - 5, 289000, 0, 'Machine sale FG-1002', false),
(CURRENT_DATE - 2, 0, 4500, 'Domain payment', true);

INSERT INTO tax_payments (payment_date, period_start, period_end, tax_rate, tax_base, tax_amount, notes) VALUES
(CURRENT_DATE - 1, date_trunc('month', CURRENT_DATE - INTERVAL '1 month')::date, (date_trunc('month', CURRENT_DATE) - INTERVAL '1 day')::date, 6.00, 289000, 17340, 'Demo tax payment');

INSERT INTO app_operations_log (operation_type, description, amount, details) VALUES
('purchase', 'Created initial demo stock purchases', 176500, 'Auto-generated for online demo database'),
('production', 'Finished machine FG-1001', 176500, 'Demo completed machine'),
('sale', 'Sold machine FG-1002', 289000, 'Demo sale record'),
('production', 'Started machine FG-1003', 98000, 'Demo in-progress machine');

GRANT CONNECT ON DATABASE cost_online_demo TO cost_online_user;
GRANT USAGE ON SCHEMA public TO cost_online_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO cost_online_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO cost_online_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON TABLES TO cost_online_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON SEQUENCES TO cost_online_user;

COMMIT;
