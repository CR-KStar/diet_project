import {HttpsError, CallableRequest} from "firebase-functions/v2/https";
import {getFirestore, FieldValue} from "firebase-admin/firestore";

// AI 함수 앞에서 하는 검사 — 로그인한 사용자만, 하루 호출 횟수 안에서만 통과시킨다.

/**
 * 로그인한 사용자의 uid. 로그인하지 않았으면 unauthenticated 오류를 던진다.
 * @param {CallableRequest} request 호출 요청
 * @return {string} 호출한 사용자의 uid
 */
export function requireUid(request: CallableRequest): string {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "로그인이 필요해요.");
  }
  return uid;
}

/**
 * 한국 시간 기준 날짜 키(yyyy-MM-dd) — 하루 한도는 한국 자정에 초기화된다.
 * @param {Date} now 기준 시각
 * @return {string} yyyy-MM-dd
 */
export function kstDayKey(now: Date): string {
  const kst = new Date(now.getTime() + 9 * 60 * 60 * 1000);
  return kst.toISOString().slice(0, 10);
}

/**
 * 오늘 kind 호출 횟수를 1 올린다. 이미 limit번 썼으면 resource-exhausted 오류를 던진다.
 * 횟수는 서버(Admin SDK)만 aiUsage 컬렉션에 쓴다 — 보안 규칙에 열어 둔 경로가 없어
 * 앱에서는 읽거나 고칠 수 없다.
 * @param {string} uid 호출한 사용자
 * @param {string} kind 기능 이름 (analyze · recommend)
 * @param {number} limit 하루 허용 횟수
 * @param {Date} now 기준 시각
 * @return {Promise<void>} 한도 안이면 정상 종료
 */
export async function consumeDailyQuota(
  uid: string,
  kind: string,
  limit: number,
  now: Date = new Date()
): Promise<void> {
  const db = getFirestore();
  const day = kstDayKey(now);
  const ref = db.collection("aiUsage").doc(`${uid}_${kind}_${day}`);

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const used = snap.exists ? Number(snap.get("count") ?? 0) : 0;
    if (used >= limit) {
      throw new HttpsError(
        "resource-exhausted",
        `오늘 사용할 수 있는 횟수(${limit}회)를 모두 썼어요.`
      );
    }
    tx.set(ref, {
      uid,
      kind,
      day,
      count: used + 1,
      updatedAt: FieldValue.serverTimestamp(),
    });
  });
}
