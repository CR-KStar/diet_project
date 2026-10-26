"""Firestore 보안 규칙 확인 — 에뮬레이터에서 신고 · 차단 목록 · 친구 끊기/요청 취소 · 챌린지 삭제 규칙이 의도대로 열고 막는지 본다.

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

def arr(*v): return {'arrayValue': {'values': [s(x) for x in v]}}
def doc(path, uid, fields): return call('PATCH', path, uid, {'fields': fields})

# 친구 요청 취소 · 친구 끊기 · 챌린지 삭제 · 내 진행 기록 삭제 (앱이 쓰는 기존 규칙)
doc('/friendRequests/r1', 'u1', {'fromUid': s('u1'), 'toUid': s('u2'), 'status': s('pending')})
doc('/friendships/u1_u2', 'u1', {'users': arr('u1', 'u2')})
doc('/challenges/c1', 'u1', {'creatorId': s('u1'), 'title': s('t')})
doc('/challengeProgress/c1_u1', 'u1', {'uid': s('u1'), 'challengeId': s('c1')})
checks += [
 ('보낸 요청 취소 (제3자는 불가)', call('DELETE','/friendRequests/r1','u3'), 403),
 ('보낸 요청 취소 (보낸 사람)', call('DELETE','/friendRequests/r1','u1'), 200),
 ('친구 끊기 (관계 밖 사람은 불가)', call('DELETE','/friendships/u1_u2','u3'), 403),
 ('친구 끊기 (상대방도 가능)', call('DELETE','/friendships/u1_u2','u2'), 200),
 ('챌린지 삭제 (만든 사람이 아니면 불가)', call('DELETE','/challenges/c1','u2'), 403),
 ('챌린지 삭제 (만든 사람)', call('DELETE','/challenges/c1','u1'), 200),
 ('남의 진행 기록 삭제 불가', call('DELETE','/challengeProgress/c1_u1','u2'), 403),
 ('내 진행 기록 삭제', call('DELETE','/challengeProgress/c1_u1','u1'), 200),
]
bad = 0
for name, got, want in checks:
    ok = got == want
    bad += not ok
    print(('OK   ' if ok else 'FAIL ') + f'{name}: {got} (기대 {want})')
print('실패', bad)
