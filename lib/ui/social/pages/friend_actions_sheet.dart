import 'package:diet_project/ui/core/ui/icons/app_icons.dart';
import 'package:diet_project/ui/core/ui/themes/theme_tokens.dart';
import 'package:diet_project/ui/core/ui/widgets/widgets.dart';
import 'package:diet_project/ui/social/pages/report_sheet.dart';
import 'package:diet_project/ui/social/viewmodel/friend_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// 친구 한 명(또는 받은 요청의 상대)에 대한 메뉴 — 친구 끊기 · 차단 · 신고.
class FriendActionsSheet extends StatelessWidget {
  const FriendActionsSheet({
    super.key,
    required this.uid,
    required this.nickname,
    required this.isFriend,
  });

  final String uid;
  final String nickname;

  /// 이미 친구일 때만 '친구 끊기'를 보여준다.
  final bool isFriend;

  /// 메뉴를 아래에서 올린다.
  static Future<void> show(
    BuildContext context, {
    required String uid,
    required String nickname,
    required bool isFriend,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        FriendActionsSheet(uid: uid, nickname: nickname, isFriend: isFriend),
  );

  @override
  Widget build(BuildContext context) {
    final friends = context.read<FriendViewModel>();
    final navigator = Navigator.of(context);
    // 시트가 닫힌 뒤에도 안내를 띄울 수 있게, 시트 밖의 context를 미리 잡아 둔다.
    final host = navigator.context;

    return SheetScaffold(
      title: nickname,
      leading: const Icon(AppIcons.friends, color: AppColor.primary),
      onClose: navigator.pop,
      child: Column(
        children: [
          if (isFriend)
            _ActionRow(
              label: '친구 끊기',
              desc: '서로의 친구 목록에서 사라져요',
              onTap: () async {
                final ok = await confirmDialog(
                  context,
                  title: '$nickname님과 친구를 끊을까요?',
                  message: '서로의 친구 목록과 활동에서 보이지 않게 돼요. 다시 친구가 되려면 새로 요청해야 해요.',
                  confirmLabel: '친구 끊기',
                  destructive: true,
                );
                if (!ok) return;
                navigator.pop();
                final done = await friends.removeFriend(uid);
                if (done && host.mounted) {
                  toast(host, '$nickname님과 친구를 끊었어요');
                }
              },
            ),
          _ActionRow(
            label: '차단하기',
            desc: '이 사람의 활동과 요청이 보이지 않아요',
            onTap: () async {
              final ok = await confirmDialog(
                context,
                title: '$nickname님을 차단할까요?',
                message:
                    '${isFriend ? '친구 관계가 끊기고, ' : ''}이 사람의 활동과 친구 요청이 보이지 않아요. '
                    '차단은 상대에게 알려지지 않고, 언제든 풀 수 있어요.',
                confirmLabel: '차단',
                destructive: true,
              );
              if (!ok) return;
              navigator.pop();
              final done = await friends.blockUser(uid, nickname);
              if (done && host.mounted) {
                toast(host, '$nickname님을 차단했어요');
              }
            },
          ),
          _ActionRow(
            label: '신고하기',
            desc: '부적절한 닉네임 · 괴롭힘 · 스팸을 운영자에게 알려요',
            color: AppColor.alertText,
            onTap: () {
              navigator.pop();
              showModalBottomSheet<void>(
                context: host,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => ReportSheet(uid: uid, nickname: nickname),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.label,
    required this.desc,
    required this.onTap,
    this.color = AppColor.textStrong,
  });

  final String label;
  final String desc;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: t(AppFontSize.f15, w: FontWeight.w700, c: color),
          ),
          const SizedBox(height: AppSpace.s3),
          Text(desc, style: t(AppFontSize.f12, c: AppColor.textFaint)),
        ],
      ),
    ),
  );
}
