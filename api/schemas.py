from pydantic import BaseModel
from datetime import datetime

class TripBase(BaseModel):
    pickup_datetime: datetime
    dropoff_datetime: datetime
    pickup_latitude: float
    pickup_longitude: float
    dropoff_latitude: float
    dropoff_longitude: float
    trip_distance: float
    fare_amount: float
    tip_amount: float
    passenger_count: int
    payment_type: str

class TripCreate(TripBase):
    pass

class TripResponse(TripBase):
    id: int
    trip_duration_minutes: float
    speed_kmh: float

    class Config:
        orm_mode = True
