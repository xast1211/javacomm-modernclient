import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../data/models/protocol/chat_models.dart';
import '../../core/debug/global_debug.dart';

// Events
abstract class UserListEvent extends Equatable {
  const UserListEvent();
  @override
  List<Object> get props => [];
}

class LoadUserList extends UserListEvent {}

class UserListUpdated extends UserListEvent {
  final List<UserOnline> users;
  const UserListUpdated(this.users);
  @override
  List<Object> get props => [users];
}

// States
abstract class UserListState extends Equatable {
  const UserListState();
  @override
  List<Object> get props => [];
}

class UserListInitial extends UserListState {}
class UserListLoading extends UserListState {}
class UserListLoaded extends UserListState {
  final List<UserOnline> users;
  const UserListLoaded(this.users);
  @override
  List<Object> get props => [users];
}
class UserListError extends UserListState {
  final String message;
  const UserListError(this.message);
}

// Bloc
class UserListBloc extends Bloc<UserListEvent, UserListState> {
  final ChatRepository chatRepository;

  UserListBloc({required this.chatRepository}) : super(UserListInitial()) {
    on<LoadUserList>(_onLoadUserList);
    on<UserListUpdated>((event, emit) {
      emit(UserListLoaded(event.users));
    });

    // Listen to repository stream
    chatRepository.onlineUsers.listen((users) {
      GlobalDebug.add('Bloc: Received ${users.length} users from Repo');
      add(UserListUpdated(users));
    });
  }

  void _onLoadUserList(LoadUserList event, Emitter<UserListState> emit) {
    emit(UserListLoading());
    
    // Check cache first
    final cached = chatRepository.lastUsers;
    if (cached.isNotEmpty) {
       GlobalDebug.add('Bloc: Loaded ${cached.length} cached users');
       emit(UserListLoaded(cached));
    }
    
    chatRepository.requestOnlineUsers();
  }
}
