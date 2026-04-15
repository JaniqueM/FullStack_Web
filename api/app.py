from flask import Flask, request, jsonify
from .db import get_db
from . import models, schemas
from sqlalchemy.orm import Session
from datetime import datetime

app = Flask(__name__)

@app.route("/trips", methods=["GET"])
def get_trips():
    db: Session = next(get_db())
    trips = db.query(models.Trip).limit(50).all()
    return jsonify([schemas.TripResponse.from_orm(t).dict() for t in trips])

@app.route("/trips", methods=["POST"])
def add_trip():
    db: Session = next(get_db())
    data = request.json
    trip_data = schemas.TripCreate(**data)
    trip = models.Trip(**trip_data.dict())
    db.add(trip)
    db.commit()
    db.refresh(trip)
    return jsonify(schemas.TripResponse.from_orm(trip).dict())
