-- PostgreSQL Bulk Data Loader Script
-- Usage: psql -U postgres -d sales_warehouse -f load_data.sql

\copy regions(region_id, region_name, country, city, state, postal_code) FROM 'data/regions.csv' WITH (FORMAT csv, HEADER true);
\copy categories FROM 'data/categories.csv' WITH (FORMAT csv, HEADER true);
\copy products(product_id, sku, product_name, category_id, base_price, cost_price, is_active) FROM 'data/products.csv' WITH (FORMAT csv, HEADER true);
\copy customers FROM 'data/customers.csv' WITH (FORMAT csv, HEADER true);
\copy orders FROM 'data/orders.csv' WITH (FORMAT csv, HEADER true);
\copy order_items(order_item_id, order_id, product_id, quantity, unit_price, discount_amount) FROM 'data/order_items.csv' WITH (FORMAT csv, HEADER true);
\copy payments FROM 'data/payments.csv' WITH (FORMAT csv, HEADER true);

SELECT 'Data Loading Completed Successfully!' AS status;
