import 'package:solado_certo_app/features/support/domain/enum/support_ticket_category.dart';
import 'package:solado_certo_app/features/support/domain/enum/support_ticket_status.dart';

class SupportTicketEntity {
  final String id;
  final SupportTicketCategory category;
  final SupportTicketStatus status;
  final String subject;
  final String? orderId;
  final String? orderNumber;
  final DateTime openedAt;
  final DateTime updatedAt;

  const SupportTicketEntity({
    required this.id,
    required this.category,
    required this.status,
    required this.subject,
    this.orderId,
    this.orderNumber,
    required this.openedAt,
    required this.updatedAt,
  });
}

class SupportMessageEntity {
  final String id;
  final String senderName;
  final bool mine;
  final String message;
  final String? attachmentUrl;
  final DateTime createdAt;

  const SupportMessageEntity({
    required this.id,
    required this.senderName,
    required this.mine,
    required this.message,
    this.attachmentUrl,
    required this.createdAt,
  });
}

class SupportTicketDetailEntity {
  final SupportTicketEntity ticket;
  final String description;
  final String? resolution;
  final bool canReply;
  final List<SupportMessageEntity> messages;

  const SupportTicketDetailEntity({
    required this.ticket,
    required this.description,
    this.resolution,
    required this.canReply,
    required this.messages,
  });
}

class SupportTicketsPageEntity {
  final List<SupportTicketEntity> items;
  final int currentPage;
  final bool hasNext;

  const SupportTicketsPageEntity({
    required this.items,
    required this.currentPage,
    required this.hasNext,
  });
}

class NewSupportTicket {
  final SupportTicketCategory category;
  final String subject;
  final String description;
  final String? orderId;

  const NewSupportTicket({
    required this.category,
    required this.subject,
    required this.description,
    this.orderId,
  });
}
