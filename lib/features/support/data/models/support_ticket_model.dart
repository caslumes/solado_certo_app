import 'package:solado_certo_app/features/support/domain/entities/support_ticket.dart';
import 'package:solado_certo_app/features/support/domain/enum/support_ticket_category.dart';
import 'package:solado_certo_app/features/support/domain/enum/support_ticket_status.dart';

SupportTicketEntity supportTicketFromJson(Map<String, dynamic> json) =>
    SupportTicketEntity(
      id: json['id'] as String,
      category: SupportTicketCategory.fromApi(json['category'] as String),
      status: SupportTicketStatus.fromApi(json['status'] as String),
      subject: json['subject'] as String,
      orderId: json['order_id'] as String?,
      orderNumber: json['order_number'] as String?,
      assignedToMe: json['assigned_to_me'] as bool? ?? false,
      openedAt: DateTime.parse(json['opened_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

SupportMessageEntity supportMessageFromJson(Map<String, dynamic> json) =>
    SupportMessageEntity(
      id: json['id'] as String,
      senderName: json['sender_name'] as String,
      mine: json['mine'] as bool,
      message: json['message'] as String,
      attachmentUrl: json['attachment_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

SupportTicketDetailEntity supportTicketDetailFromJson(
  Map<String, dynamic> json,
) => SupportTicketDetailEntity(
  ticket: supportTicketFromJson(json),
  description: json['description'] as String,
  resolution: json['resolution'] as String?,
  canReply: json['can_reply'] as bool,
  messages: [
    for (final message in json['messages'] as List? ?? const [])
      supportMessageFromJson(message),
  ],
);

SupportTicketsPageEntity supportTicketsPageFromJson(
  Map<String, dynamic> json,
) => SupportTicketsPageEntity(
  items: [
    for (final ticket in json['items'] as List? ?? const [])
      supportTicketFromJson(ticket),
  ],
  currentPage: json['current_page'] as int,
  hasNext: json['has_next'] as bool,
);

SupportQueuePageEntity supportQueuePageFromJson(Map<String, dynamic> json) =>
    SupportQueuePageEntity(
      items: [
        for (final item in json['items'] as List? ?? const [])
          SupportQueueItemEntity(
            ticket: supportTicketFromJson(item),
            openedBy: (item['opened_by'] as Map)['name'] as String,
            assignedTo: (item['assigned_to'] as Map?)?['name'] as String?,
          ),
      ],
      currentPage: json['current_page'] as int,
      hasNext: json['has_next'] as bool,
    );

String supportQueueQuery(SupportQueueFilter filter) => switch (filter) {
  SupportQueueFilter.active => 'status=active',
  SupportQueueFilter.unassigned => 'status=active&assigned=none',
  SupportQueueFilter.mine => 'status=active&assigned=me',
  SupportQueueFilter.resolved => 'status=resolved',
};

Map<String, dynamic> newSupportTicketToJson(NewSupportTicket ticket) => {
  'category': ticket.category.apiValue,
  'subject': ticket.subject,
  'description': ticket.description,
  'order_id': ticket.orderId,
};
