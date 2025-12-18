import requests
import json

BASE_URL = "http://localhost:8000"

def test_root():
    try:
        resp = requests.get(f"{BASE_URL}/")
        print("GET /")
        print("Status:", resp.status_code)
        try:
            print("Response:", resp.json())
        except json.JSONDecodeError:
            print("Response is not JSON:", resp.text)
    except requests.RequestException as e:
        print("Request failed:", e)
    print("-" * 40)

def test_health():
    try:
        resp = requests.get(f"{BASE_URL}/health")
        print("GET /health")
        print("Status:", resp.status_code)
        try:
            print("Response:", resp.json())
        except json.JSONDecodeError:
            print("Response is not JSON:", resp.text)
    except requests.RequestException as e:
        print("Request failed:", e)
    print("-" * 40)

def test_check():
    payload = {
        "id": 1,
        "text": "Пример текста для обработки"
    }
    try:
        resp = requests.post(f"{BASE_URL}/check/", json=payload)
        print("POST /check/")
        print("Status:", resp.status_code)
        try:
            print("Response:", resp.json())
        except json.JSONDecodeError:
            print("Response is not JSON:", resp.text)
    except requests.RequestException as e:
        print("Request failed:", e)
    print("-" * 40)

if __name__ == "__main__":
    test_root()
    test_health()
    test_check()
