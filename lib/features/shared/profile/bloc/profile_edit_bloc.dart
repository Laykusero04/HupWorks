import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../../data/repositories/profile_repository.dart';
import 'profile_edit_event.dart';
import 'profile_edit_state.dart';

class ProfileEditBloc extends Bloc<ProfileEditEvent, ProfileEditState> {
  final ProfileRepository _profileRepository;

  ProfileEditBloc({required ProfileRepository profileRepository})
      : _profileRepository = profileRepository,
        super(ProfileEditInitial()) {
    on<ProfileLoadRequested>(_onLoadRequested);
    on<ProfileUpdateRequested>(_onUpdateRequested);
    on<ProfileImageUploadRequested>(_onImageUploadRequested);
  }

  Future<void> _onLoadRequested(ProfileLoadRequested event, Emitter<ProfileEditState> emit) async {
    emit(ProfileEditLoading());
    try {
      final profile = await _profileRepository.getProfile();
      if (profile == null) {
        emit(const ProfileEditError('Profile not found'));
        return;
      }
      emit(ProfileEditLoaded(profile: profile));
    } on Failure catch (e) {
      emit(ProfileEditError(e.message));
    } catch (e) {
      emit(ProfileEditError(e.toString()));
    }
  }

  Future<void> _onUpdateRequested(ProfileUpdateRequested event, Emitter<ProfileEditState> emit) async {
    emit(ProfileEditUpdating());
    try {
      await _profileRepository.updateProfile(event.updates);
      emit(ProfileEditSuccess());
    } on Failure catch (e) {
      emit(ProfileEditError(e.message));
    } catch (e) {
      emit(ProfileEditError(e.toString()));
    }
  }

  Future<void> _onImageUploadRequested(ProfileImageUploadRequested event, Emitter<ProfileEditState> emit) async {
    emit(ProfileEditUpdating());
    try {
      await _profileRepository.uploadProfileImage(event.imageFile);
      emit(ProfileEditSuccess());
    } on Failure catch (e) {
      emit(ProfileEditError(e.message));
    } catch (e) {
      emit(ProfileEditError(e.toString()));
    }
  }
}
