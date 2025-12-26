from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
import requests
import json

# --- CONFIGURATION ---
DATABASE_URL = "postgresql://postgres.zlqfcvssghaulumymtgn:Dev_Duel%4012345@aws-1-ap-south-1.pooler.supabase.com:6543/postgres"
ORS_API_KEY = "eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6ImE4MzRjMTUyMmM1YTQxYTU4MDg2MDQ5NzllNGYyNDZmIiwiaCI6Im11cm11cjY0In0="

app = FastAPI()
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(bind=engine)

# --- DATA MODELS ---
class RideOffer(BaseModel):
    driver_id: str
    start_lat: float
    start_lon: float
    end_lat: float
    end_lon: float
    # New Fields
    departure_time: str
    available_seats: int
    price: float

class RideSearch(BaseModel):
    pickup_lat: float
    pickup_lon: float
    drop_lat: float
    drop_lon: float
    user_domain: str 

# --- 1. CREATE RIDE (DRIVER) ---
@app.post("/create_ride")
def create_ride(offer: RideOffer):
    session = SessionLocal()
    
    try:
        # A. Fetch Route from Map Service
        headers = {'Authorization': ORS_API_KEY}
        body = {
            "coordinates": [[offer.start_lon, offer.start_lat], [offer.end_lon, offer.end_lat]],
            "radiuses": [5000, 5000] # Look for roads within 5km (Fixes Airport issue)
        }
        
        response = requests.post(
            'https://api.openrouteservice.org/v2/directions/driving-car/geojson', 
            json=body, 
            headers=headers
        )

        if response.status_code != 200:
            print(f"MAP ERROR: {response.text}")
            raise HTTPException(status_code=400, detail=f"Map Service Error: {response.text}")
            
        geojson = response.json()
        geometry_json = json.dumps(geojson['features'][0]['geometry'])
        
        # B. Save to Database
        insert_query = text("""
        INSERT INTO rides (
            driver_id, start_lat, start_lon, end_lat, end_lon, route_path, 
            departure_time, available_seats, price
        )
        VALUES (
            :did, :slat, :slon, :elat, :elon, ST_GeomFromGeoJSON(:geom),
            :time, :seats, :price
        )
        RETURNING id
        """)

        # Execute once with ALL parameters
        result = session.execute(insert_query, {
            "did": offer.driver_id, 
            "slat": offer.start_lat, 
            "slon": offer.start_lon,
            "elat": offer.end_lat, 
            "elon": offer.end_lon, 
            "geom": geometry_json,
            "time": offer.departure_time,
            "seats": offer.available_seats,
            "price": offer.price
        })
        
        session.commit()
        new_ride_id = result.fetchone()[0]
        
        return {
            "status": "success", 
            "ride_id": str(new_ride_id),
            "route_geometry": json.loads(geometry_json)
        }
        
    except Exception as e:
        session.rollback()
        print(f"Error: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        session.close()

# --- 2. FIND MATCH (PASSENGER) ---
@app.post("/find_matches")
def find_matches(search: RideSearch):
    session = SessionLocal()
    
    try:
        query = text("""
        SELECT rides.id, users.full_name, users.phone, rides.departure_time, rides.available_seats, rides.price
        FROM rides
        JOIN users ON rides.driver_id = users.id
        WHERE 
            users.organization_domain = :domain
            AND
            ST_DWithin(rides.route_path::geography, ST_SetSRID(ST_MakePoint(:p_lon, :p_lat), 4326)::geography, 5000)
            AND
            ST_DWithin(rides.route_path::geography, ST_SetSRID(ST_MakePoint(:d_lon, :d_lat), 4326)::geography, 5000)
        """)
        
        # Execute FIRST
        result = session.execute(query, {
            "domain": search.user_domain,
            "p_lon": search.pickup_lon, "p_lat": search.pickup_lat,
            "d_lon": search.drop_lon, "d_lat": search.drop_lat
        }).fetchall()
        
        # THEN create the list
        matches = [
            {
                "ride_id": str(row[0]), 
                "driver": row[1],
                "phone": row[2],
                "time": row[3],
                "seats": row[4],
                "price": row[5]
            } 
            for row in result
        ]
        
        return {"matches": matches}
        
    except Exception as e:
        print(f"Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        session.close()