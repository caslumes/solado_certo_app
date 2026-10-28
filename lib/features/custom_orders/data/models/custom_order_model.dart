import 'package:solado_certo_app/features/custom_orders/domain/entities/custom_order.dart';
import 'package:solado_certo_app/features/custom_orders/domain/entities/measurements.dart';
import 'package:solado_certo_app/features/custom_orders/domain/enum/arch_type.dart';
import 'package:solado_certo_app/features/custom_orders/domain/enum/custom_order_action.dart';
import 'package:solado_certo_app/features/custom_orders/domain/enum/custom_order_status.dart';

CustomOrderEntity customOrderFromJson(Map<String, dynamic> json) =>
    CustomOrderEntity(
      id: json['id'] as String,
      status: CustomOrderStatus.fromApi(json['status'] as String),
      advertisementId: json['advertisement_id'] as String,
      advertisementTitle: json['advertisement_title'] as String,
      coverUrl: json['cover_url'] as String?,
      buyerName: json['buyer_name'] as String,
      sellerName: json['seller_name'] as String,
      quotedPrice: switch (json['quoted_price']) {
        final String price => double.parse(price),
        _ => null,
      },
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

FootMeasurement footFromJson(Map<String, dynamic> json) => FootMeasurement(
  lengthCm: (json['length_cm'] as num).toDouble(),
  widthCm: (json['width_cm'] as num).toDouble(),
);

Measurements measurementsFromJson(Map<String, dynamic> json) => Measurements(
  left: footFromJson(json['left'] as Map<String, dynamic>),
  right: footFromJson(json['right'] as Map<String, dynamic>),
  archType: ArchType.fromApi(json['arch_type'] as String),
  shoeSize: json['shoe_size'] as int,
);

Map<String, dynamic> footToJson(FootMeasurement foot) => {
  'length_cm': foot.lengthCm,
  'width_cm': foot.widthCm,
};

Map<String, dynamic> measurementsToJson(Measurements measurements) => {
  'left': footToJson(measurements.left),
  'right': footToJson(measurements.right),
  'arch_type': measurements.archType.apiValue,
  'shoe_size': measurements.shoeSize,
};

CustomOrderActor _actorFromApi(Object? value) => switch (value) {
  'buyer' => CustomOrderActor.buyer,
  'seller' => CustomOrderActor.seller,
  _ => CustomOrderActor.system,
};

CustomOrderDetailEntity customOrderDetailFromJson(Map<String, dynamic> json) =>
    CustomOrderDetailEntity(
      request: customOrderFromJson(json),
      orderId: json['order_id'] as String?,
      measurements: measurementsFromJson(
        json['measurements'] as Map<String, dynamic>,
      ),
      technicalNotes: json['technical_notes'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
      adaptationInstructions: json['adaptation_instructions'] as String?,
      footPhotoUrl: json['foot_photo_url'] as String?,
      fittingReport: switch (json['fitting_report']) {
        final Map<String, dynamic> report => FittingReportEntity(
          id: report['id'] as String,
          url: report['url'] as String,
          createdAt: DateTime.parse(report['created_at'] as String),
        ),
        _ => null,
      },
      history: [
        for (final change in json['history'] as List? ?? const [])
          CustomOrderChangeEntity(
            from: switch (change['previous_status']) {
              final String from => CustomOrderStatus.fromApi(from),
              _ => null,
            },
            to: CustomOrderStatus.fromApi(change['status'] as String),
            changedBy: _actorFromApi(change['changed_by']),
            reason: change['reason'] as String?,
            createdAt: DateTime.parse(change['created_at'] as String),
          ),
      ],
      actions: {
        for (final action in json['actions'] as List? ?? const [])
          if (action is String) ?CustomOrderAction.fromApi(action),
      },
    );

CustomOrdersPageEntity customOrdersPageFromJson(Map<String, dynamic> json) =>
    CustomOrdersPageEntity(
      items: [
        for (final request in json['items'] as List? ?? const [])
          customOrderFromJson(request),
      ],
      currentPage: json['current_page'] as int,
      hasNext: json['has_next'] as bool,
    );

Map<String, dynamic> newCustomOrderToJson(NewCustomOrder request) => {
  'advertisement_id': request.advertisementId,
  'measurements': measurementsToJson(request.measurements),
  'technical_notes': ?request.technicalNotes,
};

Map<String, dynamic> complementToJson(CustomOrderComplement complement) => {
  'message': complement.message,
  if (complement.measurements case final measurements?)
    'measurements': measurementsToJson(measurements),
  'technical_notes': ?complement.technicalNotes,
};
