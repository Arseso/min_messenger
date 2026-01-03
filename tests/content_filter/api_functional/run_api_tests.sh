#!/bin/sh

REPORT="$HOME/test_api_report"
PASS=0
FAIL=0

log() {
    echo "$1" >> "$REPORT"
    echo "$1"
}

log_result() {
    name="$1"
    exp_code="$2"
    act_code="$3"
    exp_body="$4"
    act_body="$5"

    if [ "$act_code" = "$exp_code" ]; then
        if [ -z "$exp_body" ] || echo "$act_body" | grep -q "$exp_body"; then
            log "Test: $name"
            log "  Result: PASSED"
            log "  HTTP: $act_code"
            log "  Body: $act_body"
            log ""
            PASS=$((PASS + 1))
            return
        fi
    fi

    log "Test: $name"
    log "  Result: FAILED"
    log "  Expected HTTP: $exp_code"
    [ -n "$exp_body" ] && log "  Expected body contains: $exp_body"
    log "  Actual HTTP: $act_code"
    log "  Actual body: $act_body"
    log ""
    FAIL=$((FAIL + 1))
}

call_api() {
    method="$1"
    endpoint="$2"
    json="$3"
    tmp=$(mktemp)
    code=$(curl -s -w "%{http_code}" -o "$tmp" -X "$method" \
        "http://localhost:8000$endpoint" -H "Content-Type: application/json" -d "$json")
    body=$(cat "$tmp" 2>/dev/null | tr -d '\0')
    rm -f "$tmp"
    printf "%s\n%s" "$code" "$body"
}

# ——— Проверка доступности ———
if ! curl -s --fail http://localhost:8000/health >/dev/null; then
    log "Precondition failed: service unreachable"
    exit 1
fi
log "Precondition: service is reachable"
log ""

# ——— POST /check/ ———
log "Section: POST /check/"

res=$(call_api POST /check/ '{"id":"c1","text":"ok"}')
log_result "C1: valid request" "200" "$(echo "$res" | head -n1)" '"status":"working"' "$(echo "$res" | sed '1d')"

res=$(call_api POST /check/ '{"id":"c2","text":"hi"}')
log_result "C2: simple text" "200" "$(echo "$res" | head -n1)" '"status":"working"' "$(echo "$res" | sed '1d')"

res=$(call_api POST /check/ '{"id":"c3","text":"yes"}')
log_result "C3: another text" "200" "$(echo "$res" | head -n1)" '"status":"working"' "$(echo "$res" | sed '1d')"

res=$(call_api POST /check/ '{"id":"","text":"x"}')
log_result "C4: empty id" "422" "$(echo "$res" | head -n1)" 'String should have at least 1 character' "$(echo "$res" | sed '1d')"

res=$(call_api POST /check/ '{"id":"x","text":""}')
log_result "C5: empty text" "422" "$(echo "$res" | head -n1)" 'String should have at least 1 character' "$(echo "$res" | sed '1d')"

res=$(call_api POST /check/ '{"id":"x"}')
log_result "C6: missing text" "422" "$(echo "$res" | head -n1)" 'Field required' "$(echo "$res" | sed '1d')"

res=$(call_api POST /check/ '{"text":"x"}')
log_result "C7: missing id" "422" "$(echo "$res" | head -n1)" 'Field required' "$(echo "$res" | sed '1d')"

res=$(call_api POST /check/ '{}')
log_result "C8: empty JSON" "422" "$(echo "$res" | head -n1)" 'Field required' "$(echo "$res" | sed '1d')"

res=$(call_api POST /check/ '{"id":123,"text":"x"}')
log_result "C9: id as integer" "422" "$(echo "$res" | head -n1)" 'Input should be a valid string' "$(echo "$res" | sed '1d')"

# ——— Ожидание ———
log "Waiting for processing"
sleep 12

# ——— GET /status/ ———
log "Section: GET /status/"

res=$(call_api GET /status/ '{"id":"c1"}')
log_result "S1: existing id" "200" "$(echo "$res" | head -n1)" '"status":"ready"' "$(echo "$res" | sed '1d')"

res=$(call_api GET /status/ '{"id":"xyz"}')
log_result "S2: non-existent id" "200" "$(echo "$res" | head -n1)" '"status":"working"' "$(echo "$res" | sed '1d')"

res=$(call_api GET /status/ '{"id":""}')
log_result "S3: empty id" "200" "$(echo "$res" | head -n1)" '"status":"working"' "$(echo "$res" | sed '1d')"

res=$(call_api GET /status/ '{}')
log_result "S4: missing id" "422" "$(echo "$res" | head -n1)" 'Field required' "$(echo "$res" | sed '1d')"

# ——— GET /verdict/ ———
log "Section: GET /verdict/"

# V1: первый запрос — должен быть verdict
res=$(call_api GET /verdict/ '{"id":"c1"}')
log_result "V1: verdict ready (first read)" "200" "$(echo "$res" | head -n1)" '"verdict"' "$(echo "$res" | sed '1d')"

# V2: повторный — значение удалено → ожидаем error_message
res=$(call_api GET /verdict/ '{"id":"c1"}')
log_result "V2: repeat request (cache emptied)" "200" "$(echo "$res" | head -n1)" '"error_message"' "$(echo "$res" | sed '1d')"

# V3: несуществующий
res=$(call_api GET /verdict/ '{"id":"xyz"}')
log_result "V3: non-existent id" "200" "$(echo "$res" | head -n1)" '"error_message"' "$(echo "$res" | sed '1d')"

# V4: c3 — первый запрос
res=$(call_api GET /verdict/ '{"id":"c3"}')
log_result "V4: verdict ready (c3, first read)" "200" "$(echo "$res" | head -n1)" '"verdict"' "$(echo "$res" | sed '1d')"

# V5: пустой id
res=$(call_api GET /verdict/ '{"id":""}')
log_result "V5: empty id" "200" "$(echo "$res" | head -n1)" '"error_message"' "$(echo "$res" | sed '1d')"

# V6: отсутствует id
res=$(call_api GET /verdict/ '{}')
log_result "V6: missing id" "422" "$(echo "$res" | head -n1)" 'Field required' "$(echo "$res" | sed '1d')"

# ——— Итог ———
log "Summary:"
log "  Passed: $PASS"
log "  Failed: $FAIL"
log ""

if [ "$FAIL" -eq 0 ]; then
    log "Overall result: SUCCESS"
else
    log "Overall result: FAILURE"
fi