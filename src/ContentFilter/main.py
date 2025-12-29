import threading
import time
import signal
import sys

from module_api import run_api
from module_nn import run_nn

if __name__ == "__main__":
    print("Starting application...")
    
    nn_thread = threading.Thread(target=run_nn, name="nn_worker")
    nn_thread.daemon = True
    nn_thread.start()
    
    api_thread = threading.Thread(target=run_api, name="api_server")
    api_thread.daemon = True
    api_thread.start()
    
    print("Both services started")
    
    try:
        while True:
            time.sleep(1)
            if not nn_thread.is_alive():
                print("Neural network thread died!")
                break
            if not api_thread.is_alive():
                print("API thread died!")
                break
                
    except KeyboardInterrupt:
        print("\nShutting down...")
    finally:
        print("Application stopped")
    
    