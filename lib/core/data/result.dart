/// Type [Result<T>] : encapsulation fonctionnelle du résultat d'une opération
/// asynchrone, similaire à Rust ou au pattern Railway Oriented Programming.
///
/// À utiliser systématiquement dans les repositories pour éviter les `try/catch`
/// dupliqués dans les widgets consommateurs.
library;

import '../errors/app_exception.dart';

/// Sealed class représentant soit un succès ([Success]) soit un échec ([Failure]).
sealed class Result<T> {
  const Result();

  /// Construit un succès.
  const factory Result.success(T value) = Success<T>;

  /// Construit un échec.
  const factory Result.failure(AppException exception) = Failure<T>;

  /// Patron de visite : applique [onSuccess] ou [onFailure] selon le cas.
  R when<R>({
    required R Function(T value) success,
    required R Function(AppException exception) failure,
  }) {
    final self = this;
    return switch (self) {
      Success<T>(:final value) => success(value),
      Failure<T>(:final exception) => failure(exception),
    };
  }

  /// Transforme la valeur en cas de succès.
  Result<R> map<R>(R Function(T value) transform) {
    return when(
      success: (v) => Success<R>(transform(v)),
      failure: (e) => Failure<R>(e),
    );
  }

  /// Chaîne une opération asynchrone retournant un [Result].
  Future<Result<R>> flatMap<R>(Future<Result<R>> Function(T value) transform) async {
    return when(
      success: transform,
      failure: (e) async => Failure<R>(e),
    );
  }

  /// Renvoie la valeur si succès, ou null en cas d'échec.
  T? get valueOrNull => when(success: (v) => v, failure: (_) => null);

  /// Renvoie l'exception si échec, ou null en cas de succès.
  AppException? get exceptionOrNull =>
      when(success: (_) => null, failure: (e) => e);
}

/// Cas succès.
final class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;

  @override
  bool operator ==(Object other) => other is Success<T> && other.value == value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => 'Success($value)';
}

/// Cas échec.
final class Failure<T> extends Result<T> {
  const Failure(this.exception);
  final AppException exception;

  @override
  bool operator ==(Object other) =>
      other is Failure<T> && other.exception == exception;
  @override
  int get hashCode => exception.hashCode;
  @override
  String toString() => 'Failure($exception)';
}
