import 'package:solado_certo_app/features/custom_orders/domain/enum/arch_type.dart';

class FootMeasurement {
  static const minLength = 10.0;
  static const maxLength = 35.0;
  static const minWidth = 4.0;
  static const maxWidth = 15.0;

  final double lengthCm;
  final double widthCm;

  const FootMeasurement({required this.lengthCm, required this.widthCm});

  @override
  bool operator ==(Object other) =>
      other is FootMeasurement &&
      other.lengthCm == lengthCm &&
      other.widthCm == widthCm;

  @override
  int get hashCode => Object.hash(lengthCm, widthCm);
}

class Measurements {
  static const minShoeSize = 15;
  static const maxShoeSize = 50;

  final FootMeasurement left;
  final FootMeasurement right;
  final ArchType archType;
  final int shoeSize;

  const Measurements({
    required this.left,
    required this.right,
    required this.archType,
    required this.shoeSize,
  });

  @override
  bool operator ==(Object other) =>
      other is Measurements &&
      other.left == left &&
      other.right == right &&
      other.archType == archType &&
      other.shoeSize == shoeSize;

  @override
  int get hashCode => Object.hash(left, right, archType, shoeSize);
}
