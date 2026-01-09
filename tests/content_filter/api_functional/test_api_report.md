Precondition: service is reachable

Section: POST /check/
Test: C1: valid request
  Result: PASSED
  HTTP: 200
  Body: {"id":"c1","status":"working"}

Test: C2: simple text
  Result: PASSED
  HTTP: 200
  Body: {"id":"c2","status":"working"}

Test: C3: another text
  Result: PASSED
  HTTP: 200
  Body: {"id":"c3","status":"working"}

Test: C4: empty id
  Result: PASSED
  HTTP: 422
  Body: {"detail":[{"type":"string_too_short","loc":["body","id"],"msg":"String should have at least 1 character","input":"","ctx":{"min_length":1}}]}

Test: C5: empty text
  Result: PASSED
  HTTP: 422
  Body: {"detail":[{"type":"string_too_short","loc":["body","text"],"msg":"String should have at least 1 character","input":"","ctx":{"min_length":1}}]}

Test: C6: missing text
  Result: PASSED
  HTTP: 422
  Body: {"detail":[{"type":"missing","loc":["body","text"],"msg":"Field required","input":{"id":"x"}}]}

Test: C7: missing id
  Result: PASSED
  HTTP: 422
  Body: {"detail":[{"type":"missing","loc":["body","id"],"msg":"Field required","input":{"text":"x"}}]}

Test: C8: empty JSON
  Result: PASSED
  HTTP: 422
  Body: {"detail":[{"type":"missing","loc":["body","text"],"msg":"Field required","input":{}},{"type":"missing","loc":["body","id"],"msg":"Field required","input":{}}]}

Test: C9: id as integer
  Result: PASSED
  HTTP: 422
  Body: {"detail":[{"type":"string_type","loc":["body","id"],"msg":"Input should be a valid string","input":123}]}

Waiting for processing
Section: GET /status/
Test: S1: existing id
  Result: PASSED
  HTTP: 200
  Body: {"id":"c1","status":"ready"}

Test: S2: non-existent id
  Result: PASSED
  HTTP: 200
  Body: {"id":"xyz","status":"working"}

Test: S3: empty id
  Result: PASSED
  HTTP: 200
  Body: {"id":"","status":"working"}

Test: S4: missing id
  Result: PASSED
  HTTP: 422
  Body: {"detail":[{"type":"missing","loc":["body","id"],"msg":"Field required","input":{}}]}

Section: GET /verdict/
Test: V1: verdict ready (first read)
  Result: PASSED
  HTTP: 200
  Body: {"id":"c1","verdict":"OK"}

Test: V2: repeat request (cache emptied)
  Result: PASSED
  HTTP: 200
  Body: {"error_message":"Verdict not ready yet / Incorrect id"}

Test: V3: non-existent id
  Result: PASSED
  HTTP: 200
  Body: {"error_message":"Verdict not ready yet / Incorrect id"}

Test: V4: verdict ready (c3, first read)
  Result: PASSED
  HTTP: 200
  Body: {"id":"c3","verdict":"OK"}

Test: V5: empty id
  Result: PASSED
  HTTP: 200
  Body: {"error_message":"Verdict not ready yet / Incorrect id"}

Test: V6: missing id
  Result: PASSED
  HTTP: 422
  Body: {"detail":[{"type":"missing","loc":["body","id"],"msg":"Field required","input":{}}]}

Summary:
  Passed: 19
  Failed: 0

Overall result: SUCCESS
