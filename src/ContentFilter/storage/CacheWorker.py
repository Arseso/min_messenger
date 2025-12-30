from models import TextResponse
from pydantic_core import from_json

from redis import Redis
import logging


class CacheWorker:
    def __init__(self, redis_host: str, redis_port: int, redis_pwd: str) -> None:
        self.redis = Redis(
            host=redis_host,
            port=redis_port,
            password=redis_pwd,
            db= 0
        )

        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(threadName)s - %(message)s'
        )
        logging.info("CacheWorker connected to Redis")
        
    def append(self, obj: TextResponse):
        status = self.redis.append(obj.id, obj.model_dump_json())
        if not status:
            raise Exception("Error while adding an object to queue")
    
    def has_key(self, id: str) -> bool:
        if self.redis.get(id):
            return True
        return False
    
    def get(self, key: str) -> TextResponse | None:
        value = self.redis.get(key)
        if not value:
            return None
        self.redis.delete(key)
        return TextResponse.model_validate(from_json(value))
    

if __name__ == "__main__":
    from env import Settings

    redis = CacheWorker("localhost", Settings.REDIS_PORT, Settings.REDIS_PWD)
    value = TextResponse(id= 'aaaddd', verdict = "SPAM")

    assert redis.append(value) == None
    assert redis.has_key(value.id) == True
    assert redis.get(value.id) == value
    assert redis.has_key(value.id) == False
    assert redis.get(value.id) == None
    print("---- ALL TESTS SUCCESSFULLY ----")
    