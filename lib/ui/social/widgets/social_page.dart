import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../app_state.dart';
import '../../../common.dart';
import '../../core/ui/themes/theme_tokens.dart';

/// 친구 및 챌린지 메인 화면
class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();

    return ScreenScroll(
      children: [
        const TabHeader(emoji: '👥', title: '친구'),
        PillTabs(
          options: const ['활동', '챌린지', '친구 추가'],
          value: s.friendTab,
          onChanged: s.setFriendTab,
        ),
        ...s.friendTab == '활동'
            ? _activityTab(context, s)
            : s.friendTab == '챌린지'
            ? _challengeTab(context, s)
            : _addFriendTab(context, s),
      ],
    );
  }
}

// 활동 탭

Color _progressBarColor(double r) => r >= 0.8
    ? AppColor.primary
    : r >= 0.5
    ? const Color(0xFF9ECB98)
    : r >= 0.3
    ? const Color(0xFFC3D6BC)
    : const Color(0xFFDCE2DC);

List<Widget> _activityTab(BuildContext context, AppState s) => [
  if (s.myChallenges.isNotEmpty) _ActiveChallengeCard(s: s),
  _PrivacyCard(context: context, s: s),
  const Padding(
    padding: EdgeInsets.only(left: AppSpace.s4, bottom: AppSpace.s2),
    child: Text('친구 활동', style: TextStyle(fontWeight: FontWeight.w800)),
  ),
  if (s.friendActivity.isEmpty)
    AppCard(
      child: Text(
        '아직 친구 활동이 없어요',
        style: t(AppFontSize.f12, c: AppColor.textFaint),
      ),
    )
  else
    for (final f in s.friendActivity)
      _FriendRow(
        user: f.user,
        subtitle: '${f.activity} · ${f.time}',
        trailing: _PillButton(
          label: s.cheeredFriends.contains(f.user.id) ? '응원 완료' : '응원 👏',
          active: !s.cheeredFriends.contains(f.user.id),
          onTap: s.cheeredFriends.contains(f.user.id)
              ? null
              : () {
                  s.cheerFriend(f.user.id);
                  toast(context, '${f.user.nickname}님을 응원했어요 👏');
                },
        ),
      ),
];

class _ActiveChallengeCard extends StatelessWidget {
  const _ActiveChallengeCard({required this.s});

  final AppState s;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.activeChallengeName,
                    style: t(AppFontSize.f15, w: FontWeight.w800),
                  ),
                  const SizedBox(height: AppSpace.s4),
                  Text(
                    '참여 ${s.activeChallengeProgress.length}명 · ${s.activeChallengePeriod}',
                    style: t(AppFontSize.f11, c: AppColor.textFaint),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => s.setFriendTab('챌린지'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.s14,
                  vertical: AppSpace.s10,
                ),
                decoration: BoxDecoration(
                  color: AppColor.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '챌린지 보기',
                  style: t(
                    AppFontSize.f12,
                    w: FontWeight.w700,
                    c: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.s18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final f in s.activeChallengeProgress)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.s4),
                  child: Column(
                    children: [
                      Container(
                        height: 24 + 40 * f.ratio,
                        decoration: BoxDecoration(
                          color: _progressBarColor(f.ratio),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(height: AppSpace.s8),
                      Text(
                        f.user.nickname,
                        style: t(AppFontSize.f11, c: AppColor.textFaint),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    ),
  );
}

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard({required this.context, required this.s});

  final BuildContext context;
  final AppState s;

  @override
  Widget build(BuildContext _) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('공개 설정', style: t(AppFontSize.f14, w: FontWeight.w700)),
            const Spacer(),
            Pill(
              s.shareScope,
              bg: s.shareScope == '비공개'
                  ? AppColor.surfaceSunken
                  : AppColor.info.withValues(alpha: 0.15),
              fg: s.shareScope == '비공개' ? AppColor.textFaint : AppColor.info,
            ),
          ],
        ),
        const SizedBox(height: AppSpace.s4),
        Text(
          '친구에게 보여줄 범위를 직접 고를 수 있어요',
          style: t(AppFontSize.f11, c: AppColor.textFaint),
        ),
        const SizedBox(height: AppSpace.s14),
        SegmentedRow(
          options: const ['비공개', '친구만', '전체 공개'],
          value: s.shareScope,
          onChanged: s.setShareScope,
        ),
        const SizedBox(height: AppSpace.s18),
        for (final k in AppState.friendVisibilityDesc.keys)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.s14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(k, style: t(AppFontSize.f13, w: FontWeight.w700)),
                      const SizedBox(height: AppSpace.s3),
                      Text(
                        AppState.friendVisibilityDesc[k]!,
                        style: t(AppFontSize.f11, c: AppColor.textFaint),
                      ),
                    ],
                  ),
                ),
                AppToggle(
                  value: s.friendVisibility[k] ?? false,
                  onChanged: () => s.toggleFriendVisibility(k),
                ),
              ],
            ),
          ),
        SunkenBox(
          child: Text(
            s.friendVisibilitySummary,
            style: t(AppFontSize.f11, c: AppColor.textMuted, h: 1.5),
          ),
        ),
        const SizedBox(height: AppSpace.s14),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  try {
                    await Clipboard.setData(
                      const ClipboardData(
                        text: 'https://dietapp.app/u/chaerin',
                      ),
                    ).timeout(const Duration(seconds: 1));
                  } catch (_) {
                    // 클립보드 접근이 막혔거나 응답이 없는 환경에서도 조용히 무시
                  }
                  if (context.mounted) toast(context, '프로필 링크를 복사했어요');
                },
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.s14),
                  decoration: BoxDecoration(
                    color: AppColor.surface,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: AppShadow.card,
                  ),
                  child: Text(
                    '프로필 링크 복사',
                    style: t(
                      AppFontSize.f13,
                      w: FontWeight.w700,
                      c: AppColor.text,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpace.s12),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  s.toggleGardenPublic();
                  toast(
                    context,
                    s.gardenPublic ? '정원을 공개했어요' : '정원을 비공개로 전환했어요',
                  );
                },
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.s14),
                  decoration: BoxDecoration(
                    color: AppColor.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '정원 공개하기',
                    style: t(
                      AppFontSize.f13,
                      w: FontWeight.w700,
                      c: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

// 챌린지 탭

List<Widget> _challengeTab(BuildContext context, AppState s) => [
  if (s.myChallenges.isNotEmpty) _ChallengeLeaderboardCard(s: s),
  _RewardTiersCard(),
  AppCard(
    color: AppColor.primaryTint,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '→ 정원 · 식물 성장 시스템으로 수렴',
          style: t(
            AppFontSize.f14,
            w: FontWeight.w800,
            c: AppColor.primaryDark,
          ),
        ),
        const SizedBox(height: AppSpace.s8),
        Text(
          '받은 아이템은 물 · 햇빛 · 영양 축에 그대로 쓰여요. 완주하면 친구에게 꽃 1회 선물이 열립니다.',
          style: t(AppFontSize.f12, c: AppColor.primaryDark, h: 1.5),
        ),
      ],
    ),
  ),
  AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('대칭 · 페널티 루프', style: t(AppFontSize.f14, w: FontWeight.w800)),
        const SizedBox(height: AppSpace.s8),
        Text(
          '챌린지 실패 시에는 약속한 친구에게 눈바디가 전송돼요. 정원 루프와는 별개 트리거입니다.',
          style: t(AppFontSize.f12, c: AppColor.textMuted, h: 1.5),
        ),
      ],
    ),
  ),
  if (s.myChallenges.isNotEmpty) ...[
    Padding(
      padding: const EdgeInsets.only(left: AppSpace.s4, bottom: AppSpace.s2),
      child: Text(
        '내 챌린지 ${s.myChallenges.length}',
        style: t(AppFontSize.f15, w: FontWeight.w800),
      ),
    ),
    for (final c in s.myChallenges) _MyChallengeCard(c: c, s: s),
  ],
  const Padding(
    padding: EdgeInsets.only(left: AppSpace.s4, bottom: AppSpace.s2),
    child: Text('참여할 수 있는 챌린지', style: TextStyle(fontWeight: FontWeight.w800)),
  ),
  for (final c in s.joinableChallenges)
    _JoinableChallengeCard(c: c, context: context, s: s),
  PrimaryButton(label: '챌린지 만들기', onTap: () => s.go('chNew')),
];

class _ChallengeLeaderboardCard extends StatelessWidget {
  const _ChallengeLeaderboardCard({required this.s});

  final AppState s;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.activeChallengeName,
                    style: t(AppFontSize.f15, w: FontWeight.w800),
                  ),
                  const SizedBox(height: AppSpace.s4),
                  Text(
                    '참여 ${s.activeChallengeProgress.length}명 · ${s.activeChallengePeriod} · 내 순위 ${s.myChallengeRank}위',
                    style: t(AppFontSize.f11, c: AppColor.textFaint),
                  ),
                ],
              ),
            ),
            Pill('참여 중', bg: AppColor.primaryTint, fg: AppColor.primaryDark),
          ],
        ),
        const SizedBox(height: AppSpace.s18),
        for (final r in s.challengeLeaderboard)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.s14),
            child: Row(
              children: [
                Container(
                  width: AppSpace.s22,
                  height: AppSpace.s22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: r.rank == 1
                        ? AppColor.primary
                        : AppColor.surfaceSunken,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${r.rank}',
                    style: t(
                      11,
                      w: FontWeight.w700,
                      c: r.rank == 1 ? Colors.white : AppColor.textFaint,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.s10),
                SizedBox(
                  width: AppSpace.s40,
                  child: Text(
                    r.user.nickname,
                    style: t(AppFontSize.f13, w: FontWeight.w700),
                  ),
                ),
                Expanded(child: ProgressBar(value: r.pct / 100)),
                const SizedBox(width: AppSpace.s10),
                SizedBox(
                  width: AppSpace.s36,
                  child: Text(
                    '${r.pct}%',
                    textAlign: TextAlign.right,
                    style: t(AppFontSize.f12, c: AppColor.textFaint),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

class _RewardTiersCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('보상 구조', style: t(AppFontSize.f15, w: FontWeight.w800)),
        const SizedBox(height: AppSpace.s6),
        Text(
          '모든 보상은 별도 화폐 없이 정원 아이템으로 통합돼요',
          style: t(AppFontSize.f11, c: AppColor.textFaint),
        ),
        const SizedBox(height: AppSpace.s16),
        for (final tier in AppState.challengeRewardTiers)
          Container(
            margin: const EdgeInsets.only(bottom: AppSpace.s10),
            padding: const EdgeInsets.all(AppSpace.s14),
            decoration: BoxDecoration(
              border: Border.all(color: AppColor.divider),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                IconTile(
                  tier.icon,
                  size: 40,
                  radius: 14,
                  bg: tier.tint,
                  fontSize: 18,
                ),
                const SizedBox(width: AppSpace.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tier.title,
                        style: t(AppFontSize.f13, w: FontWeight.w700),
                      ),
                      const SizedBox(height: AppSpace.s4),
                      Text(
                        tier.confirmed,
                        style: t(AppFontSize.f11, c: AppColor.textMuted),
                      ),
                      Text(
                        tier.bonus,
                        style: t(AppFontSize.f11, c: AppColor.textFaint),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

class _MyChallengeCard extends StatelessWidget {
  const _MyChallengeCard({required this.c, required this.s});

  final Challenge c;
  final AppState s;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      c.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t(AppFontSize.f14, w: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: AppSpace.s8),
                  if (c.isCreatedBy(s.currentUser.id))
                    Pill(
                      '내가 만듦',
                      bg: AppColor.primaryTint,
                      fg: AppColor.primaryDark,
                    ),
                ],
              ),
              const SizedBox(height: AppSpace.s4),
              Text(
                c.description,
                style: t(AppFontSize.f12, c: AppColor.textFaint),
              ),
              const SizedBox(height: AppSpace.s8),
              Text(
                '만든 사람 ${AppState.personById(c.creatorId).nickname} · ${c.peopleLabel} · ${c.period}',
                style: t(AppFontSize.f11, c: AppColor.textFaint),
              ),
            ],
          ),
        ),
        Text(c.icon, style: const TextStyle(fontSize: 24)),
      ],
    ),
  );
}

class _JoinableChallengeCard extends StatelessWidget {
  const _JoinableChallengeCard({
    required this.c,
    required this.context,
    required this.s,
  });

  final Challenge c;
  final BuildContext context;
  final AppState s;

  @override
  Widget build(BuildContext _) {
    final joined = c.isParticipant(s.currentUser.id);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            c.title,
                            style: t(AppFontSize.f15, w: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: AppSpace.s8),
                        Pill(
                          c.category,
                          bg: AppColor.info.withValues(alpha: 0.15),
                          fg: AppColor.info,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.s4),
                    Text(
                      c.description,
                      style: t(AppFontSize.f12, c: AppColor.textFaint),
                    ),
                  ],
                ),
              ),
              Text(c.icon, style: const TextStyle(fontSize: 26)),
            ],
          ),
          const SizedBox(height: AppSpace.s12),
          Row(
            children: [
              Pill(
                c.period,
                bg: AppColor.surfaceSunken,
                fg: AppColor.textMuted,
              ),
              const SizedBox(width: AppSpace.s8),
              Pill(
                c.peopleLabel,
                bg: AppColor.surfaceSunken,
                fg: AppColor.textMuted,
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s12),
          SunkenBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.rewardDescription,
                  style: t(AppFontSize.f12, w: FontWeight.w700),
                ),
                const SizedBox(height: AppSpace.s3),
                Text(
                  c.bonusDescription,
                  style: t(AppFontSize.f11, c: AppColor.textFaint),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.s12),
          GestureDetector(
            onTap: joined
                ? null
                : () {
                    s.joinChallenge(c.id);
                    toast(context, '"${c.title}"에 참여했어요');
                  },
            child: Container(
              width: double.infinity,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: AppSpace.s13),
              decoration: BoxDecoration(
                color: joined ? AppColor.surfaceSunken : AppColor.primarySoft,
                borderRadius: BorderRadius.circular(14),
                border: joined
                    ? null
                    : Border.all(color: AppColor.primary, width: 1.5),
              ),
              child: Text(
                joined ? '참여 중' : '참여하기',
                style: t(
                  13,
                  w: FontWeight.w700,
                  c: joined ? AppColor.textFaint : AppColor.primaryDark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 친구 추가 탭

/// 검색 결과 · 친구 목록처럼 진짜 계정(PublicProfile)을 _FriendRow에 보여줄 때 쓰는,
/// 색만 다른 임시 User. 진짜 사람은 데모 사람들처럼 정해진 이모지·색이 없어서다.
User _asRow(String uid, String nickname) => User(
  id: uid,
  nickname: nickname,
  emoji: '🙂',
  tint: AppColor.surfaceSunken,
);

List<Widget> _addFriendTab(BuildContext context, AppState s) => [
  AppCard(
    child: Row(
      children: [
        const Icon(Icons.search, color: AppColor.textFaint, size: 20),
        const SizedBox(width: AppSpace.s10),
        Expanded(
          child: AppTextField(
            value: s.friendSearchQuery,
            onChanged: s.setFriendSearchQuery,
            hint: '초대 코드 입력',
          ),
        ),
        GestureDetector(
          onTap: () {
            if (s.friendSearchQuery.trim().isEmpty) {
              toast(context, '초대 코드를 입력해 주세요');
              return;
            }
            s.searchFriendByCode();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.s16,
              vertical: AppSpace.s10,
            ),
            decoration: BoxDecoration(
              color: AppColor.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '검색',
              style: t(AppFontSize.f12, w: FontWeight.w700, c: Colors.white),
            ),
          ),
        ),
      ],
    ),
  ),
  if (s.friendSearchResult != null)
    _FriendRow(
      user: _asRow(s.friendSearchResult!.uid, s.friendSearchResult!.nickname),
      subtitle: '초대 코드로 찾음',
      trailing: _OutlineButton(
        label: '요청 보내기',
        onTap: () {
          final nickname = s.friendSearchResult!.nickname;
          s.sendFriendRequestToSearchResult();
          toast(context, '$nickname님에게 친구 요청을 보냈어요');
        },
      ),
    ),
  if (s.friendSearchNotFound)
    AppCard(
      child: Text(
        '이 코드로 찾은 사람이 없어요',
        style: t(AppFontSize.f12, c: AppColor.textFaint),
      ),
    ),
  _InviteCodeCard(context: context, s: s),
  if (s.incomingFriendRequests.isNotEmpty) ...[
    Padding(
      padding: const EdgeInsets.only(left: AppSpace.s4, bottom: AppSpace.s2),
      child: Text(
        '받은 요청 ${s.incomingFriendRequests.length}',
        style: t(AppFontSize.f15, w: FontWeight.w800),
      ),
    ),
    for (final r in s.incomingFriendRequests)
      _FriendRow(
        user: _asRow(
          r.fromUid,
          s.requesterProfiles[r.fromUid]?.nickname ?? '알 수 없음',
        ),
        subtitle: '친구 요청',
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _OutlineButton(label: '거절', onTap: () => s.declineFriendRequest(r)),
            const SizedBox(width: AppSpace.s8),
            _PillButton(
              label: '수락',
              active: true,
              onTap: () {
                final nickname =
                    s.requesterProfiles[r.fromUid]?.nickname ?? '친구';
                s.acceptFriendRequest(r);
                toast(context, '$nickname님의 친구 요청을 수락했어요');
              },
            ),
          ],
        ),
      ),
  ],
  if (s.realFriends.isNotEmpty) ...[
    Padding(
      padding: const EdgeInsets.only(left: AppSpace.s4, bottom: AppSpace.s2),
      child: Text(
        '내 친구 ${s.realFriends.length}',
        style: t(AppFontSize.f15, w: FontWeight.w800),
      ),
    ),
    for (final f in s.realFriends)
      _FriendRow(
        user: _asRow(f.uid, f.nickname),
        subtitle: '초대 코드로 추가된 친구',
        trailing: const SizedBox.shrink(),
      ),
  ],
  if (s.suggestedFriends.isNotEmpty) ...[
    const Padding(
      padding: EdgeInsets.only(left: AppSpace.s4, bottom: AppSpace.s2),
      child: Text('추천 친구', style: TextStyle(fontWeight: FontWeight.w800)),
    ),
    for (final f in s.suggestedFriends)
      _FriendRow(
        user: f.user,
        subtitle: f.desc,
        trailing: _OutlineButton(
          label: '+ 추가',
          onTap: () {
            s.addFriend(f.user.id);
            toast(context, '${f.user.nickname}님에게 친구 요청을 보냈어요');
          },
        ),
      ),
  ],
];

class _InviteCodeCard extends StatelessWidget {
  const _InviteCodeCard({required this.context, required this.s});

  final BuildContext context;
  final AppState s;

  @override
  Widget build(BuildContext _) => AppCard(
    color: AppColor.primaryTint,
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '내 초대 코드',
                style: t(AppFontSize.f12, c: AppColor.primaryDark),
              ),
              const SizedBox(height: AppSpace.s6),
              Text(
                s.inviteCode,
                style: t(
                  20,
                  w: FontWeight.w900,
                  c: AppColor.primaryDark,
                  sp: 1.2,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () async {
            try {
              await Clipboard.setData(
                ClipboardData(text: s.inviteCode),
              ).timeout(const Duration(seconds: 1));
            } catch (_) {
              // 클립보드 접근이 막혔거나 응답이 없는 환경에서도 조용히 무시
            }
            if (context.mounted) toast(context, '초대 코드를 복사했어요');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.s16,
              vertical: AppSpace.s10,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '복사',
              style: t(
                AppFontSize.f12,
                w: FontWeight.w700,
                c: AppColor.primaryDark,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

// 공용 조각 — 세 탭에서 반복되는 "친구 한 명" 행과 버튼 모양

/// 친구 활동 · 받은 요청 · 추천 친구에서 모두 쓰는 한 줄 (아이콘 + 이름 + 설명 + 우측 버튼).
class _FriendRow extends StatelessWidget {
  const _FriendRow({
    required this.user,
    required this.subtitle,
    required this.trailing,
  });

  final User user;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Row(
      children: [
        IconTile(user.emoji, size: 44, radius: 16, bg: user.tint, fontSize: 20),
        const SizedBox(width: AppSpace.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.nickname,
                style: t(AppFontSize.f14, w: FontWeight.w700),
              ),
              const SizedBox(height: AppSpace.s4),
              Text(subtitle, style: t(AppFontSize.f12, c: AppColor.textFaint)),
            ],
          ),
        ),
        trailing,
      ],
    ),
  );
}

/// 채워진 알약 버튼 (응원, 수락 등). [active]가 false면 완료 상태 색으로 흐리게 보여준다.
class _PillButton extends StatelessWidget {
  const _PillButton({required this.label, required this.active, this.onTap});

  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.s14,
        vertical: AppSpace.s10,
      ),
      decoration: BoxDecoration(
        color: active ? AppColor.primaryTint : AppColor.surfaceSunken,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: t(
          12,
          w: FontWeight.w700,
          c: active ? AppColor.primaryDark : AppColor.textFaint,
        ),
      ),
    ),
  );
}

/// 테두리만 있는 버튼 ("+ 추가").
class _OutlineButton extends StatelessWidget {
  const _OutlineButton({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.s14,
        vertical: AppSpace.s10,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColor.primary, width: 1.5),
      ),
      child: Text(
        label,
        style: t(AppFontSize.f12, w: FontWeight.w700, c: AppColor.primaryDark),
      ),
    ),
  );
}

/// 챌린지 생성 화면
class ChallengeNewScreen extends StatelessWidget {
  const ChallengeNewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return ScreenScroll(
      children: [
        SubHeader(emoji: '🏆', title: '챌린지 만들기', onBack: () => s.go('friends')),
        const AppCard(child: Text('목표 기간과 내용을 설정하여 새로운 챌린지를 만드세요.')),
        const SizedBox(height: AppSpace.s20),
        PrimaryButton(
          label: '만들기',
          onTap: () {
            s.createChallenge();
            toast(context, '새로운 챌린지가 생성되었습니다!');
          },
        ),
      ],
    );
  }
}
