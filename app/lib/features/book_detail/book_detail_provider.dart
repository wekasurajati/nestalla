import 'package:flutter/widgets.dart';

import '../../models/book.dart';
import '../../repositories/book_repository.dart';

class BookDetailProvider extends ChangeNotifier {
  static const _notFoundMessage = 'Book not found';

  BookDetailProvider(this._repository);

  final BookRepository _repository;

  Book? _book;
  bool _isLoading = false;
  bool _isNotFound = false;
  String? _errorMessage;
  int _requestVersion = 0;

  Book? get book => _book;
  bool get isLoading => _isLoading;
  bool get isNotFound => _isNotFound;
  String? get errorMessage => _errorMessage;

  Future<void> load(int id) async {
    final version = ++_requestVersion;
    _isLoading = true;
    _isNotFound = false;
    _errorMessage = null;
    _book = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (version == _requestVersion) {
        notifyListeners();
      }
    });

    try {
      final book = await _repository.getBookById(id);
      if (version != _requestVersion) return;
      _book = book;
      _isNotFound = book == null;
    } catch (error) {
      if (version != _requestVersion) return;
      final message = error.toString().replaceFirst('Exception: ', '');
      if (message.contains(_notFoundMessage)) {
        _isNotFound = true;
      } else {
        _errorMessage = message;
      }
    } finally {
      if (version == _requestVersion) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }
}
