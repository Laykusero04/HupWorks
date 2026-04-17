import 'package:equatable/equatable.dart';

abstract class ClientJobPostsEvent extends Equatable {
  const ClientJobPostsEvent();

  @override
  List<Object?> get props => [];
}

class JobPostsLoadRequested extends ClientJobPostsEvent {}

class JobPostCreateRequested extends ClientJobPostsEvent {
  final String title;
  final String description;
  final String? categoryId;
  final double? budgetMin;
  final double? budgetMax;
  final DateTime? deadline;

  const JobPostCreateRequested({
    required this.title,
    required this.description,
    this.categoryId,
    this.budgetMin,
    this.budgetMax,
    this.deadline,
  });

  @override
  List<Object?> get props => [title, description, categoryId, budgetMin, budgetMax, deadline];
}

class JobPostCloseRequested extends ClientJobPostsEvent {
  final String jobPostId;

  const JobPostCloseRequested({required this.jobPostId});

  @override
  List<Object?> get props => [jobPostId];
}
