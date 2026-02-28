import 'package:equatable/equatable.dart';

abstract class QueryState extends Equatable {
  const QueryState();

  @override
  List<Object?> get props => [];
}

class QueryInitial extends QueryState {
  const QueryInitial();
}

class QueryLoading extends QueryState {
  const QueryLoading();
}

class QuerySuccess extends QueryState {
  final Map<String, dynamic> result;

  const QuerySuccess({required this.result});

  @override
  List<Object?> get props => [result];
}

class QueryOcrSuccess extends QueryState {
  final List<Map<String, dynamic>> extractedAccounts;

  const QueryOcrSuccess({required this.extractedAccounts});

  @override
  List<Object?> get props => [extractedAccounts];
}

class QueryError extends QueryState {
  final String message;

  const QueryError({required this.message});

  @override
  List<Object?> get props => [message];
}
