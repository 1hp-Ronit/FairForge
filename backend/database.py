from motor.motor_asyncio import AsyncIOMotorClient
import os
import certifi

# Create a module-level variable to hold the database connection
client = None

def get_db():
    global client
    if client is None:
        uri = os.getenv("MONGODB_URI")
        if not uri:
            print("Warning: MONGODB_URI missing. Using local db for testing.")
            uri = "mongodb://localhost:27017"
        # Using certifi for Atlas connections
        try:
            client = AsyncIOMotorClient(uri, tlsCAFile=certifi.where())
        except Exception as e:
            print(f"Failed to connect to Mongo: {e}")
            client = AsyncIOMotorClient("mongodb://localhost:27017")
    return client.fairforge_db
