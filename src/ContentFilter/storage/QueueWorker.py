from typing import Optional

from redis import Redis

from pydantic_core import from_json
from models import TextRequest

import logging

class QueueWorker:
    def __init__(self, 
                 host: str = "localhost",
                 port: int = 6379,
                 password: str = "",
                 db: int = 1,
                 queue_name: str = "string_queue"):
        self.redis = Redis(
            host=host,
            port=port,
            password=password,
            db=db,
            decode_responses=True
        )
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(threadName)s - %(message)s'
        )
        logging.info("QueueWorker connected to Redis")
        self.queue_name = queue_name
    
    def append(self, item: TextRequest) -> bool:
        item_json = item.model_dump_json()
        return self.redis.rpush(self.queue_name, item_json) > 0
    
    def pop(self) -> TextRequest:
        json = self.redis.lpop(self.queue_name)
        return TextRequest(**from_json(json))
    
    def size(self) -> int:
        return self.redis.llen(self.queue_name)
    
    def clear(self) -> None:
        self.redis.delete(self.queue_name)

if __name__ == "__main__":
    from env import Settings

    queue = QueueWorker("localhost", Settings.REDIS_PORT, Settings.REDIS_PWD)
    value1 = TextRequest(id= 'aaaddd', text = "lol")
    value2 = TextRequest(id= 'dddaaa', text = "olo")

    assert queue.clear() == None
    assert queue.size() == 0
    assert queue.append(value1) == True
    assert queue.append(value2) == True
    assert queue.size() == 2
    assert queue.pop() == value1
    assert queue.pop() == value2
    assert queue.size() == 0
    print("---- ALL TESTS SUCCESSFULLY ----")