import threading

from module_api import run_api
from module_nn import run_nn
import module_nn.nn_main as nn
from env import Settings

if __name__ == "__main__":
    neural_net = threading.Thread(target=run_nn)
    neural_net.start()
    
    run_api()
    
    