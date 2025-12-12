import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:magicslides/features/generator/data/generator_repository.dart';
import 'package:magicslides/features/generator/domain/presentation_request_model.dart';

final generatorRepositoryProvider = Provider<GeneratorRepository>((ref) {
  return GeneratorRepository();
});

class GeneratorNotifier
    extends StateNotifier<AsyncValue<Map<String, dynamic>?>> {
  final GeneratorRepository _repository;

  GeneratorNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> generate(PresentationRequest request) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.generatePresentation(request);
      if (result['status'] == 'success') {
        state = AsyncValue.data(result);
      } else {
        state = AsyncValue.error(
          result['message'] ?? 'Unknown error',
          StackTrace.current,
        );
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

final generatorProvider =
    StateNotifierProvider<GeneratorNotifier, AsyncValue<Map<String, dynamic>?>>(
      (ref) {
        return GeneratorNotifier(ref.watch(generatorRepositoryProvider));
      },
    );
