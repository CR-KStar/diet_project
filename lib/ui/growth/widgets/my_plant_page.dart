// 나의 식물 — 3축 균형 · 회복 유예 · 품종 분화 · 내 정원 · 친구 정원 (+ 도감 탭)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:diet_project/app_state.dart';
import 'package:diet_project/ui/core/ui/themes/theme_tokens.dart';
import 'package:diet_project/common.dart';

import 'plant_dex_page.dart';

class PlantScreen extends StatelessWidget {
  const PlantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();

    return ScreenScroll(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: SubHeader(
                emoji: s.plantTab == '도감' ? '📖' : '🌱',
                title: s.plantTab == '도감' ? '식물 도감' : '나의 식물',
                onBack: () => s.go('home'),
              ),
            ),
            Text(
              s.plantTab == '도감'
                  ? '${s.dexOwned} / ${s.dexTotal}종'
                  : 'Lv.${s.plantLevel} · ${s.plantStage.name}',
              style: t(12, c: AppColor.textFaint),
            ),
          ],
        ),
        PillTabs(
          options: const ['식물', '도감'],
          value: s.plantTab,
          onChanged: (v) => s.setSub(() => s.plantTab = v),
        ),
        if (s.plantTab == '도감') const PlantDexTab() else const _PlantBody(),
      ],
    );
  }
}

// 고정 데이터

const _axisMeta = [
  (
    key: PlantAxis.water,
    name: '물',
    icon: '💧',
    source: '식단 기록',
    color: AppColor.info,
  ),
  (
    key: PlantAxis.sun,
    name: '햇빛',
    icon: '☀️',
    source: '운동 기록',
    color: Color(0xFFE8B33C),
  ),
  (
    key: PlantAxis.nutri,
    name: '영양',
    icon: '🧺',
    source: '수면 · 물 기록',
    color: AppColor.teal,
  ),
];

const _branches = [
  (emoji: '🌻', name: '해바라기', rarity: '일반', cond: '세 축을 골고루 · 균형 좋음'),
  (emoji: '🌵', name: '선인장', rarity: '일반', cond: '물이 적고 햇빛이 많을 때'),
  (emoji: '🍄', name: '이끼 고사리', rarity: '희귀', cond: '햇빛이 적고 물이 많을 때'),
  (emoji: '🌷', name: '무늬 튤립', rarity: '돌연변이', cond: '30일 연속 기록 + 균형 유지'),
];

const _careItems = [
  (
    name: '물 주기',
    icon: '💧',
    tint: Color(0xFFF0F5FF),
    desc: '식단 기록으로 충전 · 물 축 +10',
  ),
  (
    name: '햇빛 받기',
    icon: '☀️',
    tint: Color(0xFFFFF9E9),
    desc: '운동 기록으로 충전 · 햇빛 축 +15',
  ),
  (
    name: '영양 주기',
    icon: '🧺',
    tint: Color(0xFFF2F8F2),
    desc: '수면·물 기록으로 충전 · 영양 축 +20',
  ),
];

/// 보관함 아이템 메타 — key는 AppState.inventory의 키와 일치해야 해요.
const _inventoryItems = [
  (
    key: '물방울',
    icon: '💧',
    desc: '물 축 +8',
    tint: Color(0xFFEAF1FE),
    color: AppColor.info,
  ),
  (
    key: '희귀 씨앗',
    icon: '🌰',
    desc: '새 품종 심기',
    tint: Color(0xFFFBEDEA),
    color: Color(0xFFC0694A),
  ),
  (
    key: '전설 씨앗',
    icon: '✨',
    desc: '전설 품종 심기',
    tint: Color(0xFFF2F3F4),
    color: AppColor.textGhost,
  ),
  (
    key: '정원 장식',
    icon: '🏺',
    desc: '정원 화분 슬롯 +1',
    tint: Color(0xFFF7EFE3),
    color: Color(0xFF9C7B4E),
  ),
];

const _friendGardenSeed = [
  (id: 'u_jihyun', emoji: '🌻', meta: '해바라기 Lv.18 · 오늘 물 받음'),
  (id: 'u_minsu', emoji: '🪴', meta: '어린잎 Lv.9 · 이틀 쉬는 중'),
  (id: 'u_seoyeon', emoji: '🌸', meta: '꽃 Lv.20 · 정원 4개'),
];

bool _branchOn(AppState s, String name) => switch (name) {
  '해바라기' => s.balanced,
  '선인장' => !s.balanced && s.weakestAxis == PlantAxis.water,
  '이끼 고사리' => !s.balanced && s.weakestAxis == PlantAxis.sun,
  _ => false,
};

// 화면 본문

class _PlantBody extends StatelessWidget {
  const _PlantBody();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();

    return Column(
      children: [
        const _StatusCard(),
        const SizedBox(height: AppSpace.cardGap),
        if (s.wilting) ...[
          const _RecoveryCard(),
          const SizedBox(height: AppSpace.cardGap),
        ],
        const _BalanceCard(),
        const SizedBox(height: AppSpace.cardGap),
        const _CareCard(),
        const SizedBox(height: AppSpace.cardGap),
        const _BranchCard(),
        const SizedBox(height: AppSpace.cardGap),
        const _GardenCard(),
        const SizedBox(height: AppSpace.cardGap),
        const _InventoryCard(),
        const SizedBox(height: AppSpace.cardGap),
        const _GiftCard(),
        const SizedBox(height: AppSpace.cardGap),
        const _FriendGardenCard(),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            '식물의 상태는 기록 습관을 비춰주는 장치예요. 잘 자라지 않은 날도 평가가 아니라 신호일 뿐입니다.',
            textAlign: TextAlign.center,
            style: t(11, c: const Color(0xFFB2B9BE), h: 1.7),
          ),
        ),
      ],
    );
  }
}

/// 식물 상태 카드 — 단계 이모지, 무드, 경험치
class _StatusCard extends StatelessWidget {
  const _StatusCard();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final stage = s.plantStage;

    return AppCard(
      padding: 20,
      child: Row(
        children: [
          Container(
            width: 126,
            height: 126,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: s.wilting
                  ? const Color(0xFFFBF7EC)
                  : const Color(0xFFF2F8F2),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Transform.rotate(
              angle: s.wilting ? -0.21 : 0,
              child: Opacity(
                opacity: s.wilting ? 0.72 : 1,
                child: Text(
                  stage.emoji,
                  style: TextStyle(fontSize: stage.size),
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Pill(
                  s.plantMood,
                  bg: s.wilting
                      ? const Color(0xFFFFF8E8)
                      : s.balanced
                      ? AppColor.primaryTint
                      : AppColor.surfaceSunken,
                  fg: s.wilting
                      ? const Color(0xFFA5811C)
                      : s.balanced
                      ? AppColor.primaryDark
                      : AppColor.textMuted,
                  fontSize: 11,
                ),
                const SizedBox(height: 9),
                Text(
                  '${stage.name} 단계',
                  style: t(
                    17,
                    w: FontWeight.w900,
                    c: AppColor.textStrong,
                    sp: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  s.plantMessage,
                  style: t(12, c: AppColor.textMuted, h: 1.6),
                ),
                const SizedBox(height: 12),
                ProgressBar(
                  value: (s.plantExp % 100) / 100,
                  color: s.wilting ? const Color(0xFFE8B33C) : AppColor.primary,
                  height: 8,
                ),
                const SizedBox(height: 7),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${s.plantExp} EXP',
                      style: t(11, c: AppColor.textFaint),
                    ),
                    Text(s.plantExpLeft, style: t(11, c: AppColor.textFaint)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 회복 유예 카드 — 시들었을 때만 보인다
class _RecoveryCard extends StatelessWidget {
  const _RecoveryCard();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return AppCard(
      color: const Color(0xFFFFFCF3),
      border: const Color(0xFFFBE9BE),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '잎이 조금 처졌어요',
                      style: t(
                        13,
                        w: FontWeight.w700,
                        c: const Color(0xFF8A6B12),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '기록을 ${s.missedDays}일 쉬었어요. ${s.graceLeft}일 안에 돌보면 지금 크기 그대로 회복돼요.',
                      style: t(12, c: const Color(0xFF9C8542), h: 1.6),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SmallButton(
                label: '회복 돌보기',
                bg: const Color(0xFFE8B33C),
                fg: Colors.white,
                onTap: () {
                  s.revive();
                  toast(context, '잎이 다시 펴졌어요 · 오늘부터 이어서 자라요');
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          ProgressBar(
            value: s.graceLeft / 3,
            color: const Color(0xFFE8B33C),
            height: 5,
            track: const Color(0xFFF5E7C4),
          ),
          const SizedBox(height: 7),
          Text(
            '시들어도 사라지지 않아요. 돌아오면 그대로 이어서 자라요.',
            style: t(10, c: const Color(0xFFB29751)),
          ),
        ],
      ),
    );
  }
}

/// 성장 균형 카드 — 물 · 햇빛 · 영양 3축
class _BalanceCard extends StatelessWidget {
  const _BalanceCard();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('성장 균형', style: t(14, w: FontWeight.w700)),
              const Spacer(),
              Pill(
                s.balanced ? '균형 좋음' : '조금 치우침',
                bg: s.balanced ? AppColor.primaryTint : AppColor.surfaceSunken,
                fg: s.balanced ? AppColor.primaryDark : AppColor.textFaint,
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text('기록 종류마다 자라는 부분이 달라요', style: t(11, c: AppColor.textGhost)),
          const SizedBox(height: 15),
          Row(
            children: [
              for (final a in _axisMeta)
                Expanded(
                  child: Column(
                    children: [
                      Ring(
                        size: 68,
                        thickness: 8,
                        track: AppColor.divider,
                        segments: [
                          (value: s.axisScore[a.key]! / 100, color: a.color),
                        ],
                        center: Container(
                          width: 52,
                          height: 52,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: AppColor.surface,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            a.icon,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(a.name, style: t(12, w: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text(a.source, style: t(10, c: AppColor.textFaint)),
                      const SizedBox(height: 5),
                      Text(
                        '${s.axisScore[a.key]}%',
                        style: t(
                          12,
                          w: FontWeight.w700,
                          c: s.weakestAxis == a.key && !s.balanced
                              ? a.color
                              : AppColor.text,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 15),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Text(s.balanceHint, style: t(12, c: AppColor.textMuted, h: 1.6)),
        ],
      ),
    );
  }
}

/// 오늘 돌보기 카드 — 물 주기 · 햇빛 받기 · 영양 주기
class _CareCard extends StatelessWidget {
  const _CareCard();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('오늘 돌보기', style: t(14, w: FontWeight.w700)),
          const SizedBox(height: 5),
          Text('기록을 남기면 돌보기가 충전돼요', style: t(11, c: AppColor.textGhost)),
          const SizedBox(height: 14),
          for (final c in _careItems) _CareRow(item: c, s: s),
        ],
      ),
    );
  }
}

class _CareRow extends StatelessWidget {
  const _CareRow({required this.item, required this.s});

  final ({String name, String icon, Color tint, String desc}) item;
  final AppState s;

  @override
  Widget build(BuildContext context) {
    final left = s.cares[item.name]!;
    final done = left == 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: done ? AppColor.surfaceSunken : AppColor.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: done ? AppColor.divider : const Color(0xFFEDF2EE),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            IconTile(
              item.icon,
              size: 42,
              radius: 14,
              bg: item.tint,
              fontSize: 19,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: t(13, w: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(
                    '${item.desc} · 남은 $left회',
                    style: t(11, c: AppColor.textFaint),
                  ),
                ],
              ),
            ),
            SmallButton(
              label: done ? '완료' : item.name,
              bg: done ? AppColor.divider : AppColor.primary,
              fg: done ? AppColor.textGhost : Colors.white,
              onTap: done
                  ? null
                  : () {
                      s.care(item.name);
                      toast(
                        context,
                        '${item.name} 완료 · +${DietRules.careExp[item.name]} EXP',
                      );
                    },
            ),
          ],
        ),
      ),
    );
  }
}

/// 품종 분화 카드 — 지금 균형이 유지되면 자랄 품종
class _BranchCard extends StatelessWidget {
  const _BranchCard();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('이대로 자라면', style: t(14, w: FontWeight.w700)),
          const SizedBox(height: 5),
          Text('지금 균형이 유지되면 아래 품종으로 자라요', style: t(11, c: AppColor.textGhost)),
          const SizedBox(height: 14),
          for (final b in _branches)
            _BranchRow(item: b, on: _branchOn(s, b.name)),
        ],
      ),
    );
  }
}

class _BranchRow extends StatelessWidget {
  const _BranchRow({required this.item, required this.on});

  final ({String emoji, String name, String rarity, String cond}) item;
  final bool on;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: AppDeco.selectableCard(selected: on),
      child: Row(
        children: [
          Opacity(
            opacity: on ? 1 : 0.45,
            child: IconTile(
              item.emoji,
              size: 44,
              radius: 14,
              bg: AppColor.surfaceSunken,
              fontSize: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(item.name, style: t(13, w: FontWeight.w700)),
                    const SizedBox(width: 7),
                    Pill(
                      item.rarity,
                      bg: item.rarity == '돌연변이'
                          ? const Color(0xFFF1ECFF)
                          : item.rarity == '희귀'
                          ? const Color(0xFFEAF1FF)
                          : AppColor.surfaceSunken,
                      fg: item.rarity == '돌연변이'
                          ? const Color(0xFF6A54A8)
                          : item.rarity == '희귀'
                          ? const Color(0xFF3C63C0)
                          : AppColor.textFaint,
                      fontSize: 9,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(item.cond, style: t(11, c: AppColor.textFaint, h: 1.5)),
              ],
            ),
          ),
          Pill(
            on ? '현재 경로' : '미개방',
            bg: on ? AppColor.primary : AppColor.surfaceSunken,
            fg: on ? Colors.white : AppColor.textGhost,
          ),
        ],
      ),
    ),
  );
}

/// 내 정원 카드 — 화분 그리드 + 계절 한정 안내
class _GardenCard extends StatelessWidget {
  const _GardenCard();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final stage = s.plantStage;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('내 정원', style: t(14, w: FontWeight.w700)),
              const Spacer(),
              GestureDetector(
                onTap: () => s.setSub(() => s.plantTab = '도감'),
                child: Text(
                  '도감 ${s.dexOwned} / ${s.dexTotal} ›',
                  style: t(11, w: FontWeight.w700, c: AppColor.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
              for (final g in [
                (emoji: '🌸', label: '벚꽃', kind: 'done'),
                (emoji: '🌿', label: '몬스테라', kind: 'done'),
                (emoji: '🌵', label: '선인장', kind: 'done'),
                (emoji: stage.emoji, label: '키우는 중', kind: 'active'),
                (emoji: '🥀', label: '기록으로', kind: 'memorial'),
                (emoji: '?', label: '빈 화분', kind: 'empty'),
                (emoji: '?', label: '빈 화분', kind: 'empty'),
                (emoji: '?', label: '빈 화분', kind: 'empty'),
              ])
                Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: switch (g.kind) {
                      'active' => AppColor.primaryTint,
                      'done' => const Color(0xFFF2F8F2),
                      'memorial' => const Color(0xFFF7F7F8),
                      _ => const Color(0xFFFAFBFB),
                    },
                    borderRadius: BorderRadius.circular(16),
                    border: switch (g.kind) {
                      'active' => Border.all(
                        color: AppColor.primary,
                        width: 1.5,
                      ),
                      'empty' => Border.all(
                        color: AppColor.disabled,
                        width: 1.5,
                      ),
                      _ => null,
                    },
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Opacity(
                        opacity: g.kind == 'memorial' ? 0.5 : 1,
                        child: Text(
                          g.emoji,
                          style: TextStyle(fontSize: g.emoji == '?' ? 15 : 24),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        g.label,
                        style: t(
                          8,
                          c: g.emoji == '?'
                              ? AppColor.disabled
                              : AppColor.textFaint,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          SunkenBox(
            padding: 13,
            radius: 18,
            color: const Color(0xFFF7F4FF),
            child: Row(
              children: [
                const Text('🍁', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '가을 한정 · 단풍 화분',
                        style: t(
                          12,
                          w: FontWeight.w700,
                          c: const Color(0xFF5B4A8A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '9월 30일까지 완주하면 정원에 남아요',
                        style: t(11, c: const Color(0xFF8578AD)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 11),
          Text(
            '떠나보낸 식물도 “지난 식물 기록”으로 남아요. 다시 심으면 그 기록에서 이어집니다.',
            style: t(11, c: AppColor.textGhost, h: 1.6),
          ),
        ],
      ),
    );
  }
}

/// 보관함 카드 — 챌린지 보상 아이템 사용
class _InventoryCard extends StatelessWidget {
  const _InventoryCard();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('보관함', style: t(14, w: FontWeight.w700)),
              const Spacer(),
              Text('챌린지 보상으로 모여요', style: t(11, c: AppColor.textGhost)),
            ],
          ),
          const SizedBox(height: 5),
          Text('아이템을 쓰면 해당 축이 바로 채워져요', style: t(11, c: AppColor.textGhost)),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.9,
            children: [
              for (final it in _inventoryItems) _InventoryTile(item: it, s: s),
            ],
          ),
        ],
      ),
    );
  }
}

class _InventoryTile extends StatelessWidget {
  const _InventoryTile({required this.item, required this.s});

  final ({String key, String icon, String desc, Color tint, Color color}) item;
  final AppState s;

  @override
  Widget build(BuildContext context) {
    final count = s.inventory[item.key] ?? 0;
    final active = count > 0;
    return GestureDetector(
      onTap: active
          ? () {
              s.useInventoryItem(item.key);
              toast(context, '“${item.key}” 사용 · ${item.desc}');
            }
          : () => toast(context, '보유한 “${item.key}”이 없어요'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColor.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColor.divider, width: 1.5),
        ),
        child: Row(
          children: [
            Opacity(
              opacity: active ? 1 : 0.5,
              child: IconTile(
                item.icon,
                size: 36,
                radius: 18,
                bg: item.tint,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.key,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t(13, w: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.desc,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t(10, c: AppColor.textFaint),
                  ),
                ],
              ),
            ),
            Text(
              '$count',
              style: t(
                17,
                w: FontWeight.w900,
                c: active ? item.color : AppColor.textGhost,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 꽃 선물하기 카드
class _GiftCard extends StatelessWidget {
  const _GiftCard();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return AppCard(
      color: const Color(0xFFF5F1FC),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🌷', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      '꽃 선물하기',
                      style: t(
                        14,
                        w: FontWeight.w900,
                        c: const Color(0xFF6A54A8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  '챌린지를 완주해서 선물권 ${s.giftTickets}회가 열렸어요. 친구 정원에 꽃을 심어줄 수 있어요.',
                  style: t(11, c: const Color(0xFF8578AD), h: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: s.giftTickets > 0
                ? () {
                    s.sendGiftFlower();
                    toast(context, '친구 정원에 꽃을 선물했어요 🌷');
                  }
                : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              decoration: BoxDecoration(
                color: s.giftTickets > 0 ? AppColor.purple : AppColor.disabled,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '선물하기',
                style: t(
                  13,
                  w: FontWeight.w700,
                  c: s.giftTickets > 0 ? Colors.white : AppColor.textGhost,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 친구 정원 카드 — 친구 식물에 물 주기
class _FriendGardenCard extends StatelessWidget {
  const _FriendGardenCard();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('친구 정원', style: t(14, w: FontWeight.w700)),
              const Spacer(),
              Text(
                '오늘 물 주기 ${s.wateredFriends.length} / ${DietRules.dailyFriendWatering}',
                style: t(11, c: AppColor.textFaint),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '서로 물을 주면 둘 다 +${DietRules.friendWateringExp} EXP를 받아요',
            style: t(11, c: AppColor.textGhost),
          ),
          const SizedBox(height: 14),
          for (final f in _friendGardenSeed) _FriendGardenRow(item: f, s: s),
        ],
      ),
    );
  }
}

class _FriendGardenRow extends StatelessWidget {
  const _FriendGardenRow({required this.item, required this.s});

  final ({String id, String emoji, String meta}) item;
  final AppState s;

  @override
  Widget build(BuildContext context) {
    final friend = AppState.personById(item.id);
    final done = s.wateredFriends.contains(item.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: SunkenBox(
        padding: 11,
        color: const Color(0xFFF9FBF9),
        child: Row(
          children: [
            IconTile(
              item.emoji,
              size: 42,
              radius: 14,
              bg: const Color(0xFFF2F8F2),
              fontSize: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(friend.nickname, style: t(13, w: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(item.meta, style: t(11, c: AppColor.textFaint)),
                ],
              ),
            ),
            SmallButton(
              label: done ? '물 줬어요' : '물 주기',
              bg: done ? AppColor.divider : AppColor.primaryTint,
              fg: done ? AppColor.textGhost : AppColor.primaryDark,
              onTap: done
                  ? null
                  : () {
                      s.waterFriend(item.id);
                      toast(
                        context,
                        '${friend.nickname}님 식물에 물을 줬어요 · 둘 다 +5 EXP',
                      );
                    },
            ),
          ],
        ),
      ),
    );
  }
}
