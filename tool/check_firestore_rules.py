"""Firestore 보안 규칙 확인 — 에뮬레이터에서 신고(reports) · 차단 목록(users/{uid}/blocks) 규칙이 의도대로 열고 막는지 본다.

실행: firebase emulators:exec --only firestore --project demo-test "python3 tool/check_firestore_rules.py"
"""
import json, base64, urllib.request, urllib.error, os
host = os.environ.get('FIRESTORE_EMULATOR_HOST', 'localhost:8080')
base = f'http://{host}/v1/projects/demo-test/databases/(default)/documents'

def jwt(uid):
    b = lambda d: base64.urlsafe_b64encode(json.dumps(d).encode()).rstrip(b'=').decode()
    return f"{b({'alg':'none','typ':'JWT'})}.{b({'user_id':uid,'sub':uid,'aud':'demo-test','iss':'x'})}."

def call(method, path, uid=None, body=None):
    req = urllib.request.Request(base + path, method=method, data=json.dumps(body).encode() if body else None)
    req.add_header('Content-Type', 'application/json')
    if uid: req.add_header('Authorization', 'Bearer ' + jwt(uid))
    try:
        with urllib.request.urlopen(req) as r: return r.status
    except urllib.error.HTTPError as e: return e.code

def s(v): return {'stringValue': v}
def report(reporter, detail='문제가 있어요', extra=None):
    f = {'reporterUid': s(reporter), 'targetUid': s('bob'), 'targetNickname': s('밥'),
         'reason': s('spam'), 'detail': s(detail), 'createdAt': {'timestampValue': '2026-10-26T00:00:00Z'}}
    if extra: f.update(extra)
    return {'fields': f}

checks = [
 ('본인 uid로 신고 만들기', call('POST','/reports','u1',report('u1')), 200),
 ('남의 uid로 신고 만들기', call('POST','/reports','u1',report('u2')), 403),
 ('로그인 없이 신고 만들기', call('POST','/reports',None,report('u1')), 403),
 ('정해지지 않은 필드가 섞인 신고', call('POST','/reports','u1',report('u1',extra={'admin':s('x')})), 403),
 ('설명이 300자를 넘는 신고', call('POST','/reports','u1',report('u1',detail='가'*301)), 403),
 ('설명이 300자인 신고', call('POST','/reports','u1',report('u1',detail='가'*300)), 200),
 ('신고 읽기 (본인도 불가)', call('GET','/reports/abc','u1'), 403),
 ('차단 목록 쓰기 (본인)', call('PATCH','/users/u1/blocks/bob','u1',{'fields':{'nickname':s('밥')}}), 200),
 ('차단 목록 읽기 (본인)', call('GET','/users/u1/blocks/bob','u1'), 200),
 ('차단 목록 읽기 (다른 사람)', call('GET','/users/u1/blocks/bob','u2'), 403),
 ('차단 목록 쓰기 (다른 사람)', call('PATCH','/users/u1/blocks/eve','u2',{'fields':{'nickname':s('x')}}), 403),
]
bad = 0
for name, got, want in checks:
    ok = got == want
    bad += not ok
    print(('OK   ' if ok else 'FAIL ') + f'{name}: {got} (기대 {want})')
print('실패', bad)
