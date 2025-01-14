import sqlite3
from datetime import datetime
import uuid

class DBManager:
    def __init__(self, db_name):
        self.db_name = db_name
        self._init_db()

    def _init_db(self):
        """初始化数据库表"""
        with sqlite3.connect(self.db_name) as conn:
            cursor = conn.cursor()
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS transactions (
                    id TEXT PRIMARY KEY,
                    amount REAL NOT NULL,
                    type TEXT NOT NULL,
                    category TEXT NOT NULL,
                    description TEXT,
                    date TEXT NOT NULL
                )
            ''')
            conn.commit()

    def add_transaction(self, amount: float, type: str, description: str, date: str):
        with sqlite3.connect(self.db_name) as conn:
            cursor = conn.cursor()
            transaction_id = str(uuid.uuid4())
            cursor.execute('''
                INSERT INTO transactions (id, amount, type, category, description, date)
                VALUES (?, ?, ?, ?, ?, ?)
            ''', (transaction_id, amount, type, description.split(":")[0].strip(), description, date))
            conn.commit()

    def delete_transaction(self, transaction_id: str):
        with sqlite3.connect(self.db_name) as conn:
            cursor = conn.cursor()
            cursor.execute('DELETE FROM transactions WHERE id = ?', (transaction_id,))
            if cursor.rowcount == 0:
                raise Exception("交易记录不存在")
            conn.commit()

    def get_statistics(self, period_type: str, period: str):
        total_income = 0
        total_expense = 0
        transactions = []

        with sqlite3.connect(self.db_name) as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.cursor()
            
            # 根据不同的时间周期构建查询条件
            if period_type == "year":
                date_condition = "strftime('%Y', date) = ?"
            elif period_type == "month":
                date_condition = "strftime('%Y-%m', date) = ?"
            else:  # day
                date_condition = "date = ?"

            # 查询符合条件的交易记录
            cursor.execute(f'''
                SELECT * FROM transactions 
                WHERE {date_condition}
                ORDER BY date DESC
            ''', (period,))

            for row in cursor.fetchall():
                transaction = dict(row)
                if transaction['type'] == 'income':
                    total_income += transaction['amount']
                else:
                    total_expense += transaction['amount']
                transactions.append(transaction)

        return {
            "total_income": total_income,
            "total_expense": total_expense,
            "net": total_income - total_expense,
            "transactions": transactions
        } 