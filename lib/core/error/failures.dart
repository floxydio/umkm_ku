import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

/// Failure originating from a remote server / Supabase.
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Terjadi kesalahan pada server.']);
}

/// Failure originating from local database (Drift).
class LocalFailure extends Failure {
  const LocalFailure([super.message = 'Gagal mengakses data lokal.']);
}

/// Failure due to no / poor network connectivity.
class NetworkFailure extends Failure {
  const NetworkFailure(
      [super.message = 'Tidak ada koneksi internet. Periksa jaringan Anda.']);
}

/// Failure originating from authentication (invalid credentials, session expired, etc.).
class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Autentikasi gagal. Silakan masuk kembali.']);
}

/// Failure due to invalid user input or business-rule violation.
class ValidationFailure extends Failure {
  const ValidationFailure(String message) : super(message);
}

/// Failure when a free-tier limit is exceeded.
class LimitExceededFailure extends Failure {
  const LimitExceededFailure(String message) : super(message);
}

/// Catch-all for unexpected failures.
class UnexpectedFailure extends Failure {
  const UnexpectedFailure(
      [super.message = 'Terjadi kesalahan yang tidak diketahui.']);
}
