class GenevieveMasterCore {
  bool isProcessing = false;

  Future<T> executeCognitiveLoop<T>(dynamic query, Future<T> Function() loopAction) async {
    isProcessing = true;
    final res = await loopAction();
    isProcessing = false;
    return res;
  }
}
