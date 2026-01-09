from storage import CacheWorker, QueueWorker
from env import Settings

from module_nn import NeuralNet
from models import TextResponse, TextRequest
import logging



def run_nn():

    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(threadName)s - %(message)s'
    )

    queue = QueueWorker(Settings.REDIS_HOST, Settings.REDIS_PORT, Settings.REDIS_PWD)
    cache = CacheWorker(Settings.REDIS_HOST, Settings.REDIS_PORT, Settings.REDIS_PWD)
    nn = NeuralNet(Settings.MODEL_REPO)
    while True:
        if queue.size() == 0:
            continue
        request = queue.pop()
        logging.info(f"Found in queue: {request.id}")
        verdict = nn.predict(request.text)
        response = TextResponse(id= request.id, verdict=verdict)
        cache.append(response)
        logging.info(f"Cached result: {request.id}")
