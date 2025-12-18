import json
import requests

# URL вашего API
BASE_URL = "http://localhost:8000"

# Путь к файлу с тестовыми данными
TEST_DATA_FILE = "test_data.json"

def test_check_endpoint():
    # Загружаем тестовые данные
    with open(TEST_DATA_FILE, "r", encoding="utf-8") as f:
        test_data = json.load(f)

    print(f"Запущено тестов: {len(test_data)}\n")

    for record in test_data:
        try:
            resp = requests.post(f"{BASE_URL}/check/", json=record)
            status = resp.status_code

            if status == 200:
                print(f"ID: {record['id']} | Status: {status} | Response: {resp.json()}")
            else:
                print(f"ID: {record['id']} | Status: {status} | Response is not JSON or error occurred")
        except requests.exceptions.RequestException as e:
            print(f"ID: {record['id']} | Request failed: {e}")

if __name__ == "__main__":
    test_check_endpoint()
