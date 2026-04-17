import 'dart:io';

import 'package:equatable/equatable.dart';

abstract class ProfileEditEvent extends Equatable {
  const ProfileEditEvent();

  @override
  List<Object?> get props => [];
}

class ProfileLoadRequested extends ProfileEditEvent {}

class ProfileUpdateRequested extends ProfileEditEvent {
  final Map<String, dynamic> updates;

  const ProfileUpdateRequested({required this.updates});

  @override
  List<Object?> get props => [updates];
}

class ProfileImageUploadRequested extends ProfileEditEvent {
  final File imageFile;

  const ProfileImageUploadRequested({required this.imageFile});

  @override
  List<Object?> get props => [imageFile];
}
