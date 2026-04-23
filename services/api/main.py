import os
from fastapi import FastAPI, Depends
import redis
from sqlalchemy import create_engine, Column, Integer
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session

app = FastAPI()

# ENV Variables to be injected by K8s later
REDIS_HOST = os.getenv("REDIS_HOST", "localhost")
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:ReliabilityPass123@localhost/reliabilitydb")

# Setup Redis
r = redis.Redis(host=REDIS_HOST, port=6379, decode_responses=True)

# Setup Postgres
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

class DBVisit(Base):
    __tablename__ = "visits"
    id = Column(Integer, primary_key=True, index=True)

Base.metadata.create_all(bind=engine)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@app.get("/")
def read_root(db: Session = Depends(get_db)):
    # 1. Redis logic
    hits = r.incr("hits")

    # 2. Postgres logic
    new_visit = DBVisit()
    db.add(new_visit)
    db.commit()
    db_count = db.query(DBVisit).count()

    return {
        "status": "Production-Ready",
        "redis_hits": hits,
        "postgres_total_records": db_count
    }

@app.get("/health")
def health():
    return {"status": "ok"}
