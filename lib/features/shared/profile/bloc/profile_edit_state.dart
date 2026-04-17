import 'package:equatable/equatable.dart';

import '../../../../data/models/profile_model.dart';

abstract class ProfileEditState extends Equatable {
  const ProfileEditState();

  @override
  List<Object?> get props => [];
}

class ProfileEditInitial extends ProfileEditState {}

class ProfileEditLoading extends ProfileEditState {}

class ProfileEditLoaded extends ProfileEditState {
  final Profile profile;

  const ProfileEditLoaded({required this.profile});

  @override
  List<Object?> get props => [profile];
}

class ProfileEditUpdating extends ProfileEditState {}

class ProfileEditSuccess extends ProfileEditState {}

class ProfileEditError extends ProfileEditState {
  final String message;

  const ProfileEditError(this.message);

  @override
  List<Object?> get props => [message];
}
