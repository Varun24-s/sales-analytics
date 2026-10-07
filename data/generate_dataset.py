#!/usr/bin/env python3
"""
NexCart E-Commerce Data Generator & Database Seeder
=====================================================
Generates realistic 3-year retail transaction data (2023-2025):
- 10 Regions
- 15 Product Categories (hierarchical)
- 500 Products with realistic margins
- 50,000 Customers with geographic distributions
- 100,000 Orders with seasonal monthly patterns & repeat customers
- 250,000 Order Line Items
- 100,000 Payment Records

Generates CSV files + PostgreSQL import scripts + local SQLite db for testing.
"""

import os
import csv
import random
import datetime
import sqlite3

DATA_DIR = os.path.dirname(os.path.abspath(__file__))
DB_FILE = os.path.join(DATA_DIR, "sales_warehouse.db")

# Seed for reproducible realistic data
random.seed(42)

def generate_data():
    print("🚀 Starting dataset generation...")

    # 1. REGIONS
    regions_data = [
        (1, 'North America East', 'USA', 'New York', 'NY', '10001'),
        (2, 'North America West', 'USA', 'Los Angeles', 'CA', '90001'),
        (3, 'North America Central', 'USA', 'Chicago', 'IL', '60601'),
        (4, 'North America South', 'USA', 'Houston', 'TX', '77001'),
        (5, 'Europe West', 'UK', 'London', 'ENG', 'EC1A 1BB'),
        (6, 'Europe Central', 'Germany', 'Berlin', 'BE', '10115'),
        (7, 'Europe South', 'France', 'Paris', 'IDF', '75001'),
        (8, 'Asia Pacific East', 'Japan', 'Tokyo', 'TK', '100-0001'),
        (9, 'Asia Pacific South', 'India', 'Mumbai', 'MH', '400001'),
        (10, 'Asia Pacific SE', 'Singapore', 'Singapore', 'SG', '018989'),
    ]

    # 2. CATEGORIES
    categories_data = [
        # Top-level (parent = None/0)
        (1, 'Electronics', None, 'Consumer electronic devices and gadgets'),
        (2, 'Apparel', None, 'Clothing, footwear, and accessories'),
        (3, 'Home & Kitchen', None, 'Furniture, cookware, and appliances'),
        (4, 'Beauty & Personal Care', None, 'Cosmetics and skincare products'),
        (5, 'Sports & Outdoors', None, 'Fitness gear and outdoor equipment'),
        # Sub-categories
        (6, 'Smartphones & Tablets', 1, 'Mobile phones and tablets'),
        (7, 'Laptops & Computers', 1, 'Desktop and laptop computers'),
        (8, 'Audio & Headphones', 1, 'Headphones and speakers'),
        (9, 'Men\'s Clothing', 2, 'Shirts, pants, jackets for men'),
        (10, 'Women\'s Clothing', 2, 'Dresses, tops, outerwear for women'),
        (11, 'Kitchen Appliances', 3, 'Coffee makers, blenders, air fryers'),
        (12, 'Home Decor', 3, 'Lamps, wall art, rugs'),
        (13, 'Skincare', 4, 'Moisturizers, serums, cleansers'),
        (14, 'Fitness Equipment', 5, 'Dumbbells, yoga mats, treadmills'),
        (15, 'Footwear', 2, 'Running shoes, boots, sneakers'),
    ]

    # 3. PRODUCTS (500 Products)
    adjectives = ['Premium', 'Pro', 'Ultra', 'Essential', 'Wireless', 'Smart', 'Eco', 'Classic', 'Compact', 'Luxury', 'Ergonomic', 'Digital']
    nouns = ['Phone', 'Laptop', 'Headphones', 'Speaker', 'Watch', 'Shirt', 'Jacket', 'Shoes', 'Coffee Maker', 'Air Fryer', 'Backpack', 'Mat', 'Lamp', 'Serum', 'Blender']
    
    products_data = []
    product_id = 1
    for cat_id in range(1, 16):
        cat_name = [c[1] for c in categories_data if c[0] == cat_id][0]
        # Generate ~33 products per category
        for i in range(33):
            sku = f"SKU-{cat_id:02d}-{i+1:04d}"
            name = f"{random.choice(adjectives)} {cat_name.split()[0]} {random.choice(nouns)} {i+1}"
            
            # Category pricing ranges
            if cat_id in (1, 6, 7): # Electronics/Laptops
                base_price = round(random.uniform(199.99, 1499.99), 2)
            elif cat_id in (8, 11, 14): # Mid range
                base_price = round(random.uniform(49.99, 399.99), 2)
            else: # Apparel/Beauty/Decor
                base_price = round(random.uniform(9.99, 120.00), 2)
                
            cost_price = round(base_price * random.uniform(0.40, 0.70), 2) # 30-60% margin
            products_data.append((product_id, sku, name, cat_id, base_price, cost_price, True))
            product_id += 1

    # 4. CUSTOMERS (50,000 Customers)
    first_names = ['James', 'Mary', 'John', 'Patricia', 'Robert', 'Jennifer', 'Michael', 'Linda', 'William', 'Elizabeth', 
                   'David', 'Barbara', 'Richard', 'Susan', 'Joseph', 'Jessica', 'Thomas', 'Sarah', 'Charles', 'Karen',
                   'Aarav', 'Ananya', 'Hiroshi', 'Yuki', 'Lucas', 'Emma', 'Mateo', 'Sofia', 'Oliver', 'Amelia']
    last_names = ['Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis', 'Rodriguez', 'Martinez',
                  'Hernandez', 'Lopez', 'Gonzalez', 'Wilson', 'Anderson', 'Thomas', 'Taylor', 'Moore', 'Jackson', 'Martin',
                  'Sharma', 'Patel', 'Tanaka', 'Sato', 'Müller', 'Schmidt', 'Dubois', 'Bernard', 'Kim', 'Lee']

    start_signup = datetime.date(2023, 1, 1)
    end_signup = datetime.date(2025, 12, 1)
    date_range_days = (end_signup - start_signup).days

    customers_data = []
    print("  ... Generating 50,000 customers")
    for cid in range(1, 50001):
        fn = random.choice(first_names)
        ln = random.choice(last_names)
        email = f"{fn.lower()}.{ln.lower()}{cid}@example.com"
        phone = f"+1-{random.randint(200,999)}-{random.randint(100,999)}-{random.randint(1000,9999)}"
        signup_dt = start_signup + datetime.timedelta(days=random.randint(0, date_range_days), hours=random.randint(0, 23))
        region_id = random.choices(range(1, 11), weights=[20, 18, 12, 10, 10, 8, 7, 5, 6, 4])[0]
        segment = random.choices(['Consumer', 'Corporate', 'Home Office'], weights=[70, 20, 10])[0]
        customers_data.append((cid, fn, ln, email, phone, signup_dt.strftime("%Y-%m-%d %H:%M:%S+00"), region_id, segment))

    # 5. ORDERS (100,000 Orders across 2023-2025)
    print("  ... Generating 100,000 orders & order items")
    orders_data = []
    order_items_data = []
    payments_data = []

    order_item_id = 1
    payment_id = 1

    # Pre-select repeat customer distribution (20% heavy buyers, 40% occasional, 40% one-timers)
    customer_order_counts = {}
    for cid in range(1, 50001):
        r = random.random()
        if r < 0.40:
            customer_order_counts[cid] = 1
        elif r < 0.80:
            customer_order_counts[cid] = random.randint(2, 4)
        else:
            customer_order_counts[cid] = random.randint(5, 12)

    # Order dates distributed over 3 years with Q4 holiday surges
    order_id = 1
    statuses = ['Completed', 'Completed', 'Completed', 'Completed', 'Completed', 'Completed', 'Completed', 'Completed', 'Returned', 'Cancelled']
    payment_methods = ['Credit Card', 'Debit Card', 'PayPal', 'UPI', 'Net Banking']

    # Sample order dates realistically
    active_customers = list(range(1, 50001))
    random.shuffle(active_customers)

    for cid in active_customers:
        num_orders = customer_order_counts[cid]
        cust_signup = datetime.datetime.strptime(customers_data[cid-1][5], "%Y-%m-%d %H:%M:%S+00")
        
        last_order_dt = cust_signup
        for o_idx in range(num_orders):
            if order_id > 100000:
                break
                
            # Days after signup or previous order
            gap_days = random.randint(1, 120) if o_idx > 0 else random.randint(0, 30)
            order_dt = last_order_dt + datetime.timedelta(days=gap_days, hours=random.randint(1, 12))
            
            if order_dt.year > 2025:
                order_dt = datetime.datetime(2025, random.randint(1, 12), random.randint(1, 28), random.randint(0, 23))
            
            last_order_dt = order_dt
            status = random.choice(statuses)
            ship_region = customers_data[cid-1][6]
            shipping_fee = 0.00 if random.random() < 0.4 else round(random.uniform(4.99, 15.00), 2)
            
            # Generate 1 to 5 items per order
            num_items = random.choices([1, 2, 3, 4, 5], weights=[45, 30, 15, 7, 3])[0]
            items_total = 0.00
            
            selected_products = random.sample(products_data, num_items)
            for prod in selected_products:
                p_id = prod[0]
                unit_price = prod[4]
                qty = random.choices([1, 2, 3, 4], weights=[70, 20, 7, 3])[0]
                discount = round(unit_price * qty * (random.choice([0, 0, 0, 0.05, 0.10, 0.15])), 2)
                item_price_tot = (unit_price * qty) - discount
                items_total += item_price_tot
                
                order_items_data.append((order_item_id, order_id, p_id, qty, unit_price, discount, round(item_price_tot, 2)))
                order_item_id += 1
                
            tax_amount = round(items_total * 0.08, 2)
            total_amount = round(items_total + shipping_fee + tax_amount, 2)
            
            orders_data.append((order_id, cid, order_dt.strftime("%Y-%m-%d %H:%M:%S+00"), status, shipping_fee, tax_amount, total_amount, ship_region))
            
            # Payment record
            pmt_status = 'Success' if status in ('Completed', 'Returned') else ('Refunded' if status == 'Cancelled' else 'Failed')
            pmt_method = random.choice(payment_methods)
            payments_data.append((payment_id, order_id, order_dt.strftime("%Y-%m-%d %H:%M:%S+00"), pmt_method, pmt_status, total_amount, f"TXN-{order_id:08d}"))
            payment_id += 1
            
            order_id += 1

    print(f"  Generated {len(customers_data)} Customers, {len(orders_data)} Orders, {len(order_items_data)} Order Items.")

    # 6. WRITE CSV FILES
    print("💾 Writing CSV datasets to file system...")
    def write_csv(filename, headers, rows):
        filepath = os.path.join(DATA_DIR, filename)
        with open(filepath, 'w', newline='', encoding='utf-8') as f:
            writer = csv.writer(f)
            writer.writerow(headers)
            writer.writerows(rows)

    write_csv('regions.csv', ['region_id', 'region_name', 'country', 'city', 'state', 'postal_code'], [r[:6] for r in regions_data])
    write_csv('categories.csv', ['category_id', 'category_name', 'parent_category_id', 'description'], categories_data)
    write_csv('products.csv', ['product_id', 'sku', 'product_name', 'category_id', 'base_price', 'cost_price', 'is_active'], products_data)
    write_csv('customers.csv', ['customer_id', 'first_name', 'last_name', 'email', 'phone', 'signup_date', 'region_id', 'customer_segment'], customers_data)
    write_csv('orders.csv', ['order_id', 'customer_id', 'order_date', 'order_status', 'shipping_fee', 'tax_amount', 'total_amount', 'shipping_region_id'], orders_data)
    write_csv('order_items.csv', ['order_item_id', 'order_id', 'product_id', 'quantity', 'unit_price', 'discount_amount', 'total_price'], order_items_data)
    write_csv('payments.csv', ['payment_id', 'order_id', 'payment_date', 'payment_method', 'payment_status', 'amount', 'transaction_ref'], payments_data)

    # 7. POPULATE LOCAL SQLITE DATABASE FOR IMMEDIATE LOCAL QUERY VERIFICATION
    print("⚙️ Seed SQLite local database for instant query testing & verification...")
    if os.path.exists(DB_FILE):
        os.remove(DB_FILE)
        
    conn = sqlite3.connect(DB_FILE)
    cur = conn.cursor()
    
    cur.execute("""
    CREATE TABLE regions (region_id INT PRIMARY KEY, region_name TEXT, country TEXT, city TEXT, state TEXT, postal_code TEXT);
    """)
    cur.execute("""
    CREATE TABLE categories (category_id INT PRIMARY KEY, category_name TEXT, parent_category_id INT, description TEXT);
    """)
    cur.execute("""
    CREATE TABLE products (product_id INT PRIMARY KEY, sku TEXT, product_name TEXT, category_id INT, base_price REAL, cost_price REAL, is_active INT);
    """)
    cur.execute("""
    CREATE TABLE customers (customer_id INT PRIMARY KEY, first_name TEXT, last_name TEXT, email TEXT, phone TEXT, signup_date TEXT, region_id INT, customer_segment TEXT);
    """)
    cur.execute("""
    CREATE TABLE orders (order_id INT PRIMARY KEY, customer_id INT, order_date TEXT, order_status TEXT, shipping_fee REAL, tax_amount REAL, total_amount REAL, shipping_region_id INT);
    """)
    cur.execute("""
    CREATE TABLE order_items (order_item_id INT PRIMARY KEY, order_id INT, product_id INT, quantity INT, unit_price REAL, discount_amount REAL, total_price REAL);
    """)
    cur.execute("""
    CREATE TABLE payments (payment_id INT PRIMARY KEY, order_id INT, payment_date TEXT, payment_method TEXT, payment_status TEXT, amount REAL, transaction_ref TEXT);
    """)

    cur.executemany("INSERT INTO regions VALUES (?,?,?,?,?,?)", [r[:6] for r in regions_data])
    cur.executemany("INSERT INTO categories VALUES (?,?,?,?)", categories_data)
    cur.executemany("INSERT INTO products VALUES (?,?,?,?,?,?,?)", products_data)
    cur.executemany("INSERT INTO customers VALUES (?,?,?,?,?,?,?,?)", customers_data)
    cur.executemany("INSERT INTO orders VALUES (?,?,?,?,?,?,?,?)", orders_data)
    cur.executemany("INSERT INTO order_items VALUES (?,?,?,?,?,?,?)", order_items_data)
    cur.executemany("INSERT INTO payments VALUES (?,?,?,?,?,?,?)", payments_data)

    conn.commit()
    conn.close()
    
    # 8. GENERATE POSTGRES LOAD SCRIPT
    postgres_load_script = """-- PostgreSQL Bulk Data Loader Script
-- Usage: psql -U postgres -d sales_warehouse -f load_data.sql

\\copy regions FROM 'data/regions.csv' WITH (FORMAT csv, HEADER true);
\\copy categories FROM 'data/categories.csv' WITH (FORMAT csv, HEADER true);
\\copy products FROM 'data/products.csv' WITH (FORMAT csv, HEADER true);
\\copy customers FROM 'data/customers.csv' WITH (FORMAT csv, HEADER true);
\\copy orders FROM 'data/orders.csv' WITH (FORMAT csv, HEADER true);
\\copy order_items FROM 'data/order_items.csv' WITH (FORMAT csv, HEADER true);
\\copy payments FROM 'data/payments.csv' WITH (FORMAT csv, HEADER true);

SELECT 'Data Loading Completed Successfully!' AS status;
"""
    with open(os.path.join(DATA_DIR, "load_data.sql"), "w") as f:
        f.write(postgres_load_script)

    print("✅ Dataset Generation Complete! Saved to data/ directory.")

if __name__ == '__main__':
    generate_data()
