from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from datetime import datetime
from typing import Optional, List
from db_operations import DBManager

app = FastAPI()
db = DBManager("accounts.sqlite")

# 预定义的分类
EXPENSE_CATEGORIES = ["餐饮", "交通", "购物", "娱乐", "其他"]
INCOME_CATEGORIES = ["工资", "生活费", "其他收入"]

class Transaction(BaseModel):
    amount: float
    type: str  # "income" 或 "expense"
    category: str
    description: Optional[str] = None
    date: Optional[str] = None

@app.post("/transaction/")
async def add_transaction(transaction: Transaction):
    # 验证分类是否有效
    if transaction.type == "expense" and transaction.category not in EXPENSE_CATEGORIES:
        raise HTTPException(status_code=400, detail="无效的支出分类")
    if transaction.type == "income" and transaction.category not in INCOME_CATEGORIES:
        raise HTTPException(status_code=400, detail="无效的收入分类")
    
    if transaction.date is None:
        transaction.date = datetime.now().strftime("%Y-%m-%d")
    else:
        # 确保日期格式正确
        try:
            datetime.strptime(transaction.date, "%Y-%m-%d")
        except ValueError:
            raise HTTPException(status_code=400, detail="日期格式无效，应为 YYYY-MM-DD")
    
    try:
        # 将 category 添加到 description 字段中
        description = f"{transaction.category}: {transaction.description}" if transaction.description else transaction.category
        
        db.add_transaction(
            amount=transaction.amount,
            type=transaction.type,
            description=description,
            date=transaction.date
        )
        return {"message": "交易记录添加成功"}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

# 获取所有支持的分类
@app.get("/categories/")
async def get_categories():
    return {
        "expense_categories": EXPENSE_CATEGORIES,
        "income_categories": INCOME_CATEGORIES
    }

@app.delete("/transaction/{transaction_id}")
async def delete_transaction(transaction_id: str):
    try:
        db.delete_transaction(transaction_id)
        return {"message": "交易记录删除成功"}
    except Exception as e:
        raise HTTPException(status_code=404, detail=str(e))

@app.get("/statistics/{period_type}/{period}")
async def get_statistics(period_type: str, period: str):
    try:
        # 根据不同的 period_type 处理日期格式
        if period_type == "year":
            date_format = "%Y"
        elif period_type == "month":
            date_format = "%Y-%m"
        else:  # day
            date_format = "%Y-%m-%d"
            
        # 验证日期格式
        try:
            if period_type == "year":
                datetime.strptime(period, "%Y")
            elif period_type == "month":
                datetime.strptime(period, "%Y-%m")
            else:
                datetime.strptime(period, "%Y-%m-%d")
        except ValueError:
            raise HTTPException(
                status_code=400, 
                detail=f"Invalid date format for {period_type}. Expected format: {date_format}"
            )
            
        stats = db.get_statistics(period_type, period)
        return stats
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e)) 