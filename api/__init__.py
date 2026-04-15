from flask import Flask
from .db import Base, engine
from . import models

def create_app():
    app = Flask(__name__)

    # Create database tables
    Base.metadata.create_all(bind=engine)

    return app
