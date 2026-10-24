import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/swipe/domain/action_label.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/trash/domain/delete_mode.dart';
import 'package:kfm/l10n/generated/app_localizations_en.dart';

void main() {
  final l = AppLocalizationsEn();

  test('every action type has a label', () {
    expect(actionLabel(l, SwipeAction.trash), '→ Trash');
    expect(
      actionLabel(l, SwipeAction.trash, deleteMode: DeleteMode.permanent),
      '→ Delete',
    );
    expect(actionLabel(l, SwipeAction.keep), '→ Kept');
    expect(
      actionLabel(
        l,
        const SwipeAction(
          SwipeActionType.moveTo,
          targetFolder: '/storage/emulated/0/Pictures/Holiday/',
        ),
      ),
      '→ Holiday',
    );
    expect(
      actionLabel(
        l,
        const SwipeAction(
          SwipeActionType.copyTo,
          targetFolder: r'C:\Pics\Cats',
        ),
      ),
      '⧉ Cats',
    );
    expect(
      actionLabel(
        l,
        const SwipeAction(SwipeActionType.addTag),
        tagName: 'beach',
      ),
      '# beach',
    );
    expect(actionLabel(l, const SwipeAction(SwipeActionType.addTag)), '# ');
    expect(
      actionLabel(l, const SwipeAction(SwipeActionType.favorite)),
      '★ Favorite',
    );
    expect(
      actionLabel(l, const SwipeAction(SwipeActionType.renameBatch)),
      '→ Rename batch',
    );
    expect(
      actionLabel(
        l,
        const SwipeAction(SwipeActionType.sendToDevice),
        deviceName: 'PC',
      ),
      '→ PC',
    );
  });

  test('long folder names are shortened to 24 characters', () {
    final label = actionLabel(
      l,
      const SwipeAction(
        SwipeActionType.moveTo,
        targetFolder: '/s/A very very long holiday folder name',
      ),
    );
    expect(label.length, lessThanOrEqualTo(2 + 24));
    expect(label, endsWith('…'));
  });
}
