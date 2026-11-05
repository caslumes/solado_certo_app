import 'package:solado_certo_app/features/support/domain/enum/support_ticket_category.dart';
import 'package:solado_certo_app/features/support/domain/enum/support_ticket_status.dart';

class SupportTicketEntity {
  final String id;
  final SupportTicketCategory category;
  final SupportTicketStatus status;
  final String subject;
  final String? orderId;
  final String? orderNumber;
  final bool assignedToMe;
  final DateTime openedAt;
  final DateTime updatedAt;

  const SupportTicketEntity({
    required this.id,
    required this.category,
    required this.status,
    required this.subject,
    this.orderId,
    this.orderNumber,
    this.assignedToMe = false,
    required this.openedAt,
    required this.updatedAt,
  });
}

class SupportQueueItemEntity {
  final SupportTicketEntity ticket;
  final String openedBy;
  final String? assignedTo;

  const SupportQueueItemEntity({
    required this.ticket,
    required this.openedBy,
    this.assignedTo,
  });
}

class SupportQueuePageEntity {
  final List<SupportQueueItemEntity> items;
  final int currentPage;
  final bool hasNext;

  const SupportQueuePageEntity({
    required this.items,
    required this.currentPage,
    required this.hasNext,
  });
}

enum SupportQueueFilter {
  active('Em aberto'),
  unassigned('Sem responsável'),
  mine('Comigo'),
  resolved('Resolvidos');

  const SupportQueueFilter(this.label);

  final String label;
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
