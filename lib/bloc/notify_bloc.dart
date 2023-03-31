import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'notify_event.dart';
part 'notify_state.dart';

class NotifyBloc extends Bloc<NotifyEvent, NotifyState> {
  NotifyBloc() : super(NotifyInitial()) {
    on<NotifyFiredEvent>((event, emit) {
      emit(NotifyFired(event.title, event.body, event.type));
    });
  }
}
