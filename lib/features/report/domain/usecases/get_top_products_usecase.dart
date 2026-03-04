import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../entities/top_product_entity.dart';
import '../repositories/report_repository.dart';

class GetTopProductsParams extends Equatable {
  final DateTime start;
  final DateTime end;
  final int limit;

  const GetTopProductsParams({
    required this.start,
    required this.end,
    this.limit = 5,
  });

  @override
  List<Object?> get props => [start, end, limit];
}

@injectable
class GetTopProductsUseCase {
  final ReportRepository _repository;

  GetTopProductsUseCase(this._repository);

  Future<Either<Failure, List<TopProductEntity>>> call(
      GetTopProductsParams params) {
    return _repository.getTopProducts(
      params.start,
      params.end,
      limit: params.limit,
    );
  }
}
