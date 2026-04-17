import 'package:equatable/equatable.dart';

import '../../../../data/models/job_post_model.dart';

abstract class ClientJobPostsState extends Equatable {
  const ClientJobPostsState();

  @override
  List<Object?> get props => [];
}

class JobPostsInitial extends ClientJobPostsState {}

class JobPostsLoading extends ClientJobPostsState {}

class JobPostsLoaded extends ClientJobPostsState {
  final List<JobPost> jobPosts;

  const JobPostsLoaded({required this.jobPosts});

  @override
  List<Object?> get props => [jobPosts];
}

class JobPostCreateSuccess extends ClientJobPostsState {}

class JobPostsError extends ClientJobPostsState {
  final String message;

  const JobPostsError(this.message);

  @override
  List<Object?> get props => [message];
}
