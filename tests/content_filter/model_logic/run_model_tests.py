import csv
import time
import requests
import redis

CSV_FILE = "test_messages.csv"
REPORT_FILE = "test_model_report.md"

def clear_redis():
    try:
        r = redis.Redis(host="localhost", port=6379, password="admin123", socket_connect_timeout=2)
        r.flushdb()
        print("Redis cleared")
    except Exception as e:
        print(f"Warning: could not clear Redis: {e}")

def send_check(id_, text):
    try:
        requests.post(
            "http://localhost:8000/check/",
            json={"id": id_, "text": text},
            timeout=5
        )
    except Exception as e:
        print(f"[POST ERR] {id_}: {e}")

def wait_for_ready(id_, timeout=40):
    print(f"  → Waiting for '{id_}' to be ready...", end="", flush=True)
    for i in range(timeout):
        try:
            r = requests.get(
                "http://localhost:8000/status/",
                json={"id": id_},
                timeout=3
            )
            if r.status_code == 200:
                data = r.json()
                if data.get("status") == "ready":
                    print("Ready")
                    return True
        except:
            pass
        print(".", end="", flush=True)
        time.sleep(1)
    print("TIMEOUT")
    return False

def get_verdict(id_):
    try:
        r = requests.get(
            "http://localhost:8000/verdict/",
            json={"id": id_},
            timeout=5
        )
        if r.status_code == 200:
            data = r.json()
            if "verdict" in data:
                return data["verdict"]
            elif "error_message" in data:
                return f"ERROR: {data['error_message']}"
        return f"HTTP {r.status_code}"
    except Exception as e:
        return f"EXCEPTION: {e}"

def main():
    clear_redis()
    
    cases = []
    with open(CSV_FILE, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            cases.append({
                "id": row["id"],
                "text": row["text"],
                "expected": row["expected"]
            })

    with open(REPORT_FILE, "w", encoding="utf-8") as f:
        f.write("# Тестирование логики модели ContentFilter\n\n")
        f.write("| ID | Текст | Ожидаемо | Фактически | Результат |\n")
        f.write("|----|-------|----------|-------------|-----------|\n")

    print(f"Запуск тестов: {len(cases)} кейсов (последовательно)")
    passed = 0

    for i, case in enumerate(cases, 1):
        print(f"\n[{i}/{len(cases)}] {case['id']}: '{case['text']}'")
        
        send_check(case["id"], case["text"])
        
        if wait_for_ready(case["id"]):
            actual = get_verdict(case["id"])
        else:
            actual = "TIMEOUT"

        result = "PASSED" if actual == case["expected"] else "FAILED"
        if actual.startswith(("ERROR", "EXCEPTION", "HTTP", "TIMEOUT")):
            result = "ERROR"

        if result == "PASSED":
            passed += 1

        display_text = (case["text"][:25] + "...") if len(case["text"]) > 25 else case["text"]
        with open(REPORT_FILE, "a", encoding="utf-8") as f:
            f.write(f"| `{case['id']}` | `{display_text}` | `{case['expected']}` | `{actual}` | {result} |\n")

    accuracy = passed * 100 // len(cases) if cases else 0
    with open(REPORT_FILE, "a", encoding="utf-8") as f:
        f.write(f"\nИтого: {passed} / {len(cases)}\n")
        f.write(f"Точность: {accuracy}%\n")
        if passed == len(cases):
            f.write("Результат: все сообщения классифицированы верно.\n")
        else:
            f.write("Результат: требуется анализ ошибок.\n")

    print(f"\nГотово. Отчёт: {REPORT_FILE}")
    print(f"Точность: {accuracy}%")

if __name__ == "__main__":
    main()