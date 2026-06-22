import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../home/presentation/pages/home_shell_page.dart';
import '../../../places/presentation/places_map_focus.dart';
import '../../../study_near_me/presentation/controllers/study_near_me_controller.dart';
import '../../../study_near_me/presentation/widgets/study_near_me_results_sheet.dart';
import '../../data/models/assistant_action.dart';

/// Thực thi deep link từ phản hồi trợ lý.
abstract final class AssistantActionHandler {
  static Future<void> handle(BuildContext context, AssistantAction action) async {
    if (action is OpenPlaceAction) {
      if (action.placeId.isNotEmpty && context.mounted) {
        await context.push('/places/${action.placeId}');
      }
      return;
    }
    if (action is OpenDocumentAction) {
      if (action.documentId.isNotEmpty && context.mounted) {
        await context.push('/document/${action.documentId}');
      }
      return;
    }
    if (action is OpenStudyNearMeAction) {
      await _openStudyNearMe(context);
      return;
    }
    if (action is OpenMapAction) {
      homeShellKey.currentState?.switchTab(1);
      PlacesMapFocus.request(
        placeId: 'assistant-map',
        lat: action.lat,
        lng: action.lng,
        openSheet: false,
        zoom: 15,
        focusSource: PlacesMapFocusSource.map,
        pulse: false,
      );
    }
  }

  static Future<void> _openStudyNearMe(BuildContext context) async {
    homeShellKey.currentState?.switchTab(1);
    final ctrl = StudyNearMeController();
    final ok = await ctrl.loadNearby();
    if (!context.mounted) {
      ctrl.dispose();
      return;
    }
    if (!ok) {
      ctrl.dispose();
      return;
    }
    final result = ctrl.result;
    if (result != null && context.mounted) {
      await StudyNearMeResultsSheet.show(
        context,
        controller: ctrl,
        onRefresh: () => ctrl.loadNearby(),
      );
    }
    ctrl.dispose();
  }

  static String actionButtonLabel(BuildContext context, AssistantAction action) {
    final l10n = context.l10n;
    if (action is OpenPlaceAction) {
      return action.label ?? l10n.assistantActionOpenPlace;
    }
    if (action is OpenDocumentAction) {
      return action.label ?? l10n.assistantActionOpenDocument;
    }
    if (action is OpenStudyNearMeAction) {
      return l10n.studyNearMe;
    }
    if (action is OpenMapAction) {
      return action.label ?? l10n.assistantActionOpenMap;
    }
    return '';
  }
}
