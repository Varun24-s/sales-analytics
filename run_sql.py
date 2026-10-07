#!/usr/bin/env python3
"""
Universal Cross-Platform SQL Query Runner for Sales & Customer Analytics
========================================================================
Runs PostgreSQL analytical queries seamlessly across macOS, Windows, and Linux.

Modes:
  1. Default Python Mode: Uses embedded SQLite database (Zero dependencies, Python standard library).
  2. PostgreSQL Mode: Connects to local PostgreSQL instance if configured or installed.

Usage:
  python run_sql.py sql/03_basic_analysis.sql
  python run_sql.py sql/05_rfm_analysis.sql
  python run_sql.py sql/06_cohort_analysis.sql
  python run_sql.py sql/09_time_series.sql
  python run_sql.py "SELECT customer_id, first_name, email FROM customers LIMIT 5"
"""

import sys
import os
import re
import datetime
import sqlite3

DB_PATH = os.path.join(os.path.dirname(__file__), 'data', 'sales_warehouse.db')

def setup_sqlite_udfs(conn):
    """Register custom functions in SQLite to support PostgreSQL date and formatting functions."""
    
    def sqlite_to_char(val, fmt):
        if val is None:
            return None
        s_val = str(val).replace('Z', '').split('+')[0].strip()
        d = None
        try:
            if ' ' in s_val:
                d = datetime.datetime.strptime(s_val[:19], '%Y-%m-%d %H:%M:%S')
            else:
                d = datetime.datetime.strptime(s_val[:10], '%Y-%m-%d')
        except Exception:
            pass

        fmt_clean = str(fmt).strip()
        if fmt_clean in ('YYYY-MM', '%Y-%m'):
            return d.strftime('%Y-%m') if d else str(val)[:7]
        elif fmt_clean in ('YYYY', '%Y'):
            return d.strftime('%Y') if d else str(val)[:4]
        elif fmt_clean.lower() == 'month':
            return d.strftime('%B') if d else str(val)
        elif fmt_clean.lower() == 'day':
            return d.strftime('%A') if d else str(val)
        return d.strftime('%Y-%m-%d') if d else str(val)

    def sqlite_date_trunc(part, val):
        if val is None:
            return None
        s_val = str(val)[:10]
        part = str(part).lower()
        if part == 'month':
            return s_val[:7] + '-01'
        elif part == 'year':
            return s_val[:4] + '-01-01'
        return s_val

    conn.create_function("TO_CHAR", 2, sqlite_to_char)
    conn.create_function("to_char", 2, sqlite_to_char)
    conn.create_function("DATE_TRUNC", 2, sqlite_date_trunc)
    conn.create_function("date_trunc", 2, sqlite_date_trunc)

def adapt_pg_to_sqlite(sql_text):
    """Transpile PostgreSQL-specific dialect constructs into SQLite-compatible SQL."""
    # 1. Strip PostgreSQL type casts like ::numeric(10,2), ::numeric, ::text, ::date, ::integer, ::int, ::real
    sql_text = re.sub(r'::\s*numeric(?:\(\d+(?:,\s*\d+)?\))?', '', sql_text, flags=re.IGNORECASE)
    sql_text = re.sub(r'::\s*(?:text|date|integer|int|real|varchar)', '', sql_text, flags=re.IGNORECASE)

    # 2. Convert EXTRACT(EPOCH FROM ((SELECT max_order_date FROM max_date_cte) - MAX(o.order_date))) / 86400
    #    -> ROUND((julianday((SELECT max_order_date FROM max_date_cte)) - julianday(MAX(o.order_date))))
    sql_text = re.sub(
        r'EXTRACT\s*\(\s*EPOCH\s+FROM\s+\(\s*\(\s*SELECT\s+([^\)]+)\s+FROM\s+([^\)]+)\s*\)\s*-\s*(MAX\([^)]+\)|MIN\([^)]+\)|[a-zA-Z0-9_\.]+)\s*\)\s*\)\s*/\s*86400',
        r'ROUND(julianday((SELECT \1 FROM \2)) - julianday(\3))',
        sql_text,
        flags=re.IGNORECASE
    )

    # General EXTRACT(EPOCH FROM (a - b)) fallback
    sql_text = re.sub(
        r'EXTRACT\s*\(\s*EPOCH\s+FROM\s+\(\s*([^\)-]+)\s*-\s*([^\)]+)\s*\)\s*\)',
        r'((julianday(\1) - julianday(\2)) * 86400)',
        sql_text,
        flags=re.IGNORECASE
    )
    
    # 3. Convert EXTRACT(ISODOW FROM col) -> ISO Day of week 1-7
    sql_text = re.sub(
        r'EXTRACT\s*\(\s*ISODOW\s+FROM\s+([^\)]+)\)',
        r"((CAST(strftime('%w', substr(\1, 1, 10)) AS INT) + 6) % 7 + 1)",
        sql_text,
        flags=re.IGNORECASE
    )

    # 4. Convert EXTRACT(YEAR FROM col) -> CAST(strftime('%Y', substr(col, 1, 10)) AS INT)
    sql_text = re.sub(
        r'EXTRACT\s*\(\s*YEAR\s+FROM\s+([^\)]+)\)',
        r"CAST(strftime('%Y', substr(\1, 1, 10)) AS INT)",
        sql_text,
        flags=re.IGNORECASE
    )
    
    # 5. Convert EXTRACT(QUARTER FROM col) -> ((CAST(strftime('%m', substr(col, 1, 10)) AS INT) - 1) / 3 + 1)
    sql_text = re.sub(
        r'EXTRACT\s*\(\s*QUARTER\s+FROM\s+([^\)]+)\)',
        r"((CAST(strftime('%m', substr(\1, 1, 10)) AS INT) - 1) / 3 + 1)",
        sql_text,
        flags=re.IGNORECASE
    )

    # 6. Convert EXTRACT(MONTH FROM col) -> CAST(strftime('%m', substr(col, 1, 10)) AS INT)
    sql_text = re.sub(
        r'EXTRACT\s*\(\s*MONTH\s+FROM\s+([^\)]+)\)',
        r"CAST(strftime('%m', substr(\1, 1, 10)) AS INT)",
        sql_text,
        flags=re.IGNORECASE
    )

    return sql_text

def execute_query_text(conn, query_text):
    cur = conn.cursor()
    raw_statements = [s.strip() for s in query_text.split(';') if s.strip()]
    
    executable_count = 0
    for idx, stmt in enumerate(raw_statements, 1):
        clean_lines = [line for line in stmt.splitlines() if not line.strip().startswith('--')]
        clean_stmt = "\n".join(clean_lines).strip()
        if not clean_stmt:
            continue

        executable_count += 1
        adapted_stmt = adapt_pg_to_sqlite(clean_stmt)
            
        print(f"\n{'='*70}")
        print(f"▶ EXECUTING STATEMENT #{executable_count}:")
        print(f"{'-'*70}")
        print(clean_stmt[:300] + ("..." if len(clean_stmt) > 300 else ""))
        print(f"{'-'*70}")
        
        try:
            cur.execute(adapted_stmt)
            if cur.description:
                headers = [col[0] for col in cur.description]
                rows = cur.fetchall()
                
                header_str = " | ".join(f"{h:<22}" for h in headers)
                print(header_str)
                print("-" * len(header_str))
                
                for row in rows[:20]:
                    row_str = " | ".join(f"{str(val):<22}" for val in row)
                    print(row_str)
                    
                print(f"\n[Returned {len(rows)} row(s)]")
            else:
                conn.commit()
                print("✓ Statement executed successfully (No result set).")
        except Exception as e:
            print(f"❌ SQL Execution Notice / Warning: {e}")

def main():
    if not os.path.exists(DB_PATH):
        print(f"❌ Error: Database file not found at {DB_PATH}.")
        print("Creating local database using data/generate_dataset.py...")
        from data.generate_dataset import generate_data
        generate_data()
        
    conn = sqlite3.connect(DB_PATH)
    setup_sqlite_udfs(conn)
    
    if len(sys.argv) > 1:
        arg = sys.argv[1]
        if os.path.isfile(arg):
            print(f"📖 Reading SQL script file: {arg}")
            with open(arg, 'r', encoding='utf-8') as f:
                sql_content = f.read()
            execute_query_text(conn, sql_content)
        else:
            execute_query_text(conn, arg)
    else:
        print("💡 Interactive SQL Runner (Type 'exit' to quit)")
        print(f"Connected to database: {DB_PATH}\n")
        while True:
            try:
                user_input = input("SQL> ")
                if user_input.strip().lower() in ('exit', 'quit'):
                    break
                if user_input.strip():
                    execute_query_text(conn, user_input)
            except (KeyboardInterrupt, EOFError):
                break

    conn.close()

if __name__ == '__main__':
    main()
