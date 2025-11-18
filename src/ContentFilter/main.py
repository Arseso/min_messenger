import module_api.api as api
from env import Settings

if __name__ == "__main__":
    api.start(Settings.SERVER_HOST, Settings.SERVER_PORT)