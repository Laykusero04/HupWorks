import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../../data/repositories/job_post_repository.dart';
import 'client_job_posts_event.dart';
import 'client_job_posts_state.dart';

class ClientJobPostsBloc extends Bloc<ClientJobPostsEvent, ClientJobPostsState> {
  final JobPostRepository _jobPostRepository;

  ClientJobPostsBloc({required JobPostRepository jobPostRepository})
      : _jobPostRepository = jobPostRepository,
        super(JobPostsInitial()) {
    on<JobPostsLoadRequested>(_onLoadRequested);
    on<JobPostCreateRequested>(_onCreateRequested);
    on<JobPostCloseRequested>(_onCloseRequested);
  }

  Future<void> _onLoadRequested(JobPostsLoadRequested event, Emitter<ClientJobPostsState> emit) async {
    emit(JobPostsLoading());
    try {
      final jobPosts = await _jobPostRepository.getClientJobPosts();
      emit(JobPostsLoaded(jobPosts: jobPosts));
    } on Failure catch (e) {
      emit(JobPostsError(e.message));
    } catch (e) {
      emit(JobPostsError(e.toString()));
    }
  }

  Future<void> _onCreateRequested(JobPostCreateRequested event, Emitter<ClientJobPostsState> emit) async {
    emit(JobPostsLoading());
    try {
      await _jobPostRepository.createJobPost(
        title: event.title,
        description: event.description,
        categoryId: event.categoryId,
        budgetMin: event.budgetMin,
        budgetMax: event.budgetMax,
        deadline: event.deadline,
      );
      emit(JobPostCreateSuccess());
      final jobPosts = await _jobPostRepository.getClientJobPosts();
      emit(JobPostsLoaded(jobPosts: jobPosts));
    } on Failure catch (e) {
      emit(JobPostsError(e.message));
    } catch (e) {
      emit(JobPostsError(e.toString()));
    }
  }

  Future<void> _onCloseRequested(JobPostCloseRequested event, Emitter<ClientJobPostsState> emit) async {
    try {
      await _jobPostRepository.closeJobPost(event.jobPostId);
      final jobPosts = await _jobPostRepository.getClientJobPosts();
      emit(JobPostsLoaded(jobPosts: jobPosts));
    } on Failure catch (e) {
      emit(JobPostsError(e.message));
    } catch (e) {
      emit(JobPostsError(e.toString()));
    }
  }
}
