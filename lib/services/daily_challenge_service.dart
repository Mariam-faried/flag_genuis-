import 'package:cloud_functions/cloud_functions.dart';

class DailyChallengeService {
  DailyChallengeService({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  Future<Map<String, dynamic>> startDailyChallenge() async {
    final callable = _functions.httpsCallable('startDailyChallenge');
    final result = await callable.call();
    return _asMap(result.data);
  }

  Future<Map<String, dynamic>> submitDailyChallengeAnswer({
    required String dateKey,
    String? selectedAnswer,
  }) async {
    final callable = _functions.httpsCallable('submitDailyChallengeAnswer');
    final payload = <String, dynamic>{
      'dateKey': dateKey,
      'selectedAnswer': selectedAnswer,
    };
    final result = await callable.call(payload);
    return _asMap(result.data);
  }

  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return <String, dynamic>{};
  }
}
