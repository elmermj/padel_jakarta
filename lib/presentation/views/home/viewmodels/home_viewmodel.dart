import 'dart:async';

import 'package:flutter/material.dart';
import 'package:paddle_jakarta/app/app.bottomsheets.dart';
import 'package:paddle_jakarta/app/app.dialogs.dart';
import 'package:paddle_jakarta/app/app.locator.dart';
import 'package:paddle_jakarta/app/app.router.dart';
import 'package:paddle_jakarta/domain/use_cases/home/logout.dart';
import 'package:paddle_jakarta/presentation/common/app_strings.dart';
import 'package:paddle_jakarta/services/theme_service.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

part 'home_viewmodel.state.dart';
part 'home_viewmodel.functions.dart';

class HomeViewModel extends BaseViewModel {
  final _dialogService = locator<DialogService>();
  final _bottomSheetService = locator<BottomSheetService>();
  final _navigationService = locator<NavigationService>();
  final _logout = locator<Logout>();
  final themeService = locator<ThemeService>();

  int indexState = 0;

  bool isDeletingCache = false;
  double progress = 1.0;

  void showDialog() {
    _dialogService.showCustomDialog(
      variant: DialogType.infoAlert,
      title: 'Stacked Rocks!',
    );
  }

  void showBottomSheet() {
    _bottomSheetService.showCustomSheet(
      variant: BottomSheetType.notice,
      title: ksHomeBottomSheetTitle,
      description: ksHomeBottomSheetDescription,
    );
  }

  switchHomeState({required int index}){
    indexState = index;
    rebuildUi();
  }

  Future<void> logout() async {
    setBusy(true);

    final result = await _logout();

    result.fold(
      (failure) {
        setBusy(false);
        _dialogService.showCustomDialog(
          variant: DialogType.infoAlert,
          title: 'Stacked Rocks!',
        );
      },
      (_) {
        setBusy(false);
        _navigationService.clearStackAndShow(Routes.authView);
      },
    );
  }

}
