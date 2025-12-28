from module_api import run_api
import module_nn.nn_main as nn
from env import Settings

if __name__ == "__main__":
    run_api(Settings.SERVER_HOST, Settings.SERVER_PORT)
    