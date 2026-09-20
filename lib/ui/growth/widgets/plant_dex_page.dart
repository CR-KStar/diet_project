// 식물 도감 — my_plant_page.dart의 PlantScreen에서 '도감' 탭으로 전환

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:diet_project/app_state.dart';
import 'package:diet_project/ui/core/ui/themes/theme_tokens.dart';
import 'package:diet_project/common.dart';

class PlantDexTab extends StatelessWidget {
  const PlantDexTab({super.key});

  static const _tierColor = {
    '일반': AppColor.textFaint,
    '희귀': Color(0xFF3C63C0),
    '전설': Color(0xFF6A54A8),
  };
  static const _tierRatio = {'일반': '60%', '희귀': '30%', '전설': '10%'};

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final pick = s.dexSelected;

    return Column(children: [
      // 진행률
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Text('수집 진행률 ', style: t(14, w: FontWeight.w700)),
            Text('변이 포함', style: t(11, w: FontWeight.w500, c: AppColor.textGhost)),
            const Spacer(),
            Text('${s.dexPct}', style: t(22, w: FontWeight.w900, c: AppColor.primary)),
            Text('%', style: t(12, c: AppColor.textFaint)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            for (final tier in const ['일반', '희귀', '전설'])
              Expanded(
                flex: s.dexTierCount(tier).own,
                child: Container(
                  height: 9,
                  margin: const EdgeInsets.only(right: 3),
                  decoration: BoxDecoration(
                    color: _tierColor[tier],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            Expanded(
              flex: s.dexTotal - s.dexOwned,
              child: Container(
                height: 9,
                decoration: BoxDecoration(
                  color: AppColor.divider,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          for (final tier in const ['일반', '희귀', '전설'])
                () {
              final g = s.dexTierCount(tier);
              return Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: Row(children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: _tierColor[tier],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(width: 74, child: Text(tier, style: t(12, w: FontWeight.w700))),
                  Expanded(child: ProgressBar(value: g.own / g.all, color: _tierColor[tier]!, height: 6)),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 52,
                    child: Text('${g.own} / ${g.all}',
                        textAlign: TextAlign.right, style: t(11, c: AppColor.textMuted)),
                  ),
                  SizedBox(
                    width: 36,
                    child: Text(_tierRatio[tier]!,
                        textAlign: TextAlign.right, style: t(10, c: AppColor.textGhost)),
                  ),
                ]),
              );
            }(),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Text('베이스 ${AppState.dexBase.length}종 × 색상 변이를 합쳐 총 ${s.dexTotal}종. 시즌 업데이트로 계속 늘어나요.',
              style: t(11, c: AppColor.textFaint, h: 1.6)),
        ]),
      ),
      const SizedBox(height: AppSpace.cardGap),

      PillTabs(
        options: const ['전체', '일반', '희귀', '전설'],
        value: s.dexTab,
        onChanged: s.setDexTab,
      ),
      const SizedBox(height: AppSpace.cardGap),

      // 그리드
      GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.92,
        children: s.dexFiltered.map((d) {
          final sel = d == pick;
          return GestureDetector(
            onTap: () => s.setDexPick(d),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
              decoration: BoxDecoration(
                color: AppColor.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppShadow.card,
                border: Border.all(color: sel ? AppColor.primary : Colors.transparent, width: 1.5),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Opacity(
                  opacity: d.owned ? 1 : 0.3,
                  child: ColorFiltered(
                    colorFilter: d.owned
                        ? const ColorFilter.mode(Colors.transparent, BlendMode.dst)
                        : const ColorFilter.matrix([
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0, 0, 0, 1, 0,
                    ]),
                    child: Text(d.emoji, style: const TextStyle(fontSize: 30)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(d.owned ? d.name : '???',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t(11,
                        w: FontWeight.w700,
                        c: d.owned ? AppColor.text : const Color(0xFFB2B9BE))),
                const SizedBox(height: 4),
                Text(d.tier + (d.variants.length > 1 ? ' ·${d.variants.length}' : ''),
                    style: t(9, c: _tierColor[d.tier]!)),
              ]),
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: AppSpace.cardGap),

      // 선택 종 상세
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(pick.owned ? pick.name : '미획득 식물', style: t(14, w: FontWeight.w700)),
          const SizedBox(height: 5),
          Text('해금 조건', style: t(11, c: AppColor.textGhost)),
          const SizedBox(height: 14),
          Row(children: [
            Container(
              width: 80,
              height: 80,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: pick.owned ? const Color(0xFFF2F8F2) : AppColor.surfaceSunken,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Opacity(
                opacity: pick.owned ? 1 : 0.35,
                child: Text(pick.emoji, style: const TextStyle(fontSize: 34)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Pill(pick.tier, bg: _tierColor[pick.tier]!, fg: Colors.white, fontSize: 9),
                  const SizedBox(width: 7),
                  Text('획득률 ${_tierRatio[pick.tier]}', style: t(11, c: AppColor.textFaint)),
                ]),
                const SizedBox(height: 8),
                Text(pick.condition, style: t(12, c: AppColor.textMuted, h: 1.6)),
                const SizedBox(height: 10),
                ProgressBar(
                  value: pick.progress / 100,
                  color: pick.owned ? AppColor.primary : _tierColor[pick.tier]!,
                  height: 6,
                ),
                const SizedBox(height: 6),
                Text(pick.owned ? '획득 완료' : '조건 진행 ${pick.progress}%',
                    style: t(10, c: AppColor.textGhost)),
              ]),
            ),
          ]),
          const SizedBox(height: 14),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final (i, v) in pick.variants.indexed)
                Pill(v,
                    bg: pick.owned && i == 0 ? AppColor.primaryTint : AppColor.surfaceSunken,
                    fg: pick.owned && i == 0 ? AppColor.primaryDark : AppColor.textGhost),
            ],
          ),
        ]),
      ),
      const SizedBox(height: AppSpace.cardGap),

      // 시즌 한정
      AppCard(
        color: const Color(0xFFF7F4FF),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('이번 시즌 한정',
                style: t(13, w: FontWeight.w700, c: const Color(0xFF5B4A8A))),
            const Spacer(),
            Text('9월 30일까지',
                style: t(11, w: FontWeight.w700, c: const Color(0xFF8578AD))),
          ]),
          const SizedBox(height: 13),
          Row(children: [
            for (final p in const [
              ('🍁', '단풍 화분', '9월 기록 20일'),
              ('🌰', '도토리 나무', '가을 챌린지 완주'),
              ('🎃', '호박 넝쿨', '균형 유지 14일'),
            ])
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: AppColor.surface,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(children: [
                    Text(p.$1, style: const TextStyle(fontSize: 24)),
                    const SizedBox(height: 7),
                    Text(p.$2, textAlign: TextAlign.center, style: t(11, w: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(p.$3,
                        textAlign: TextAlign.center,
                        style: t(9, c: const Color(0xFF8578AD))),
                  ]),
                ),
              ),
          ]),
          const SizedBox(height: 13),
          Text('시즌이 끝나면 도감에는 남지만 다시 획득할 수 없어요. 다음 시즌엔 새 3종이 열립니다.',
              style: t(11, c: const Color(0xFF8578AD), h: 1.6)),
        ]),
      ),
      const SizedBox(height: AppSpace.cardGap),

      // 희귀도 규칙
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Text('희귀도 규칙 ', style: t(14, w: FontWeight.w700)),
            Text('비율은 변이 포함 기준', style: t(11, w: FontWeight.w500, c: AppColor.textGhost)),
          ]),
          const SizedBox(height: 14),
          for (final r in const [
            ('일반', '3~7일 안에 개화. 축 균형 조건 없음 · 전체의 60%', AppColor.textMuted),
            ('희귀', '10~14일 꾸준함 + 특정 축 편중/균형 조건 · 전체의 30%', Color(0xFF3C63C0)),
            ('전설 · 한정', '30일 연속 기록, 챌린지 완주, 시즌 기간 등 특수 조건 · 10% 이하', Color(0xFF6A54A8)),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(
                  width: 58,
                  child: Text(r.$1, style: t(11, w: FontWeight.w700, c: r.$3)),
                ),
                Expanded(child: Text(r.$2, style: t(11, c: AppColor.textFaint, h: 1.6))),
              ]),
            ),
        ]),
      ),
    ]);
  }
}
