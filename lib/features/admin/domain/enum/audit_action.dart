enum AuditArea {
  all(null, 'Tudo'),
  moderation('admin.', 'Moderação'),
  users('user.', 'Contas'),
  orders('order.', 'Pedidos'),
  payments('payment.', 'Pagamentos'),
  support('support.', 'Suporte'),
  documents('document.', 'Documentos'),
  customOrders('custom_order.', 'Sob medida');

  const AuditArea(this.prefix, this.label);

  final String? prefix;
  final String label;
}

const _auditActionLabels = {
  'admin.user_blocked': 'Conta bloqueada',
  'admin.user_suspended': 'Conta suspensa',
  'admin.user_reactivated': 'Conta reativada',
  'admin.ad_removed': 'Anúncio removido',
  'user.password_reset': 'Senha redefinida',
  'user.data_exported': 'Dados pessoais exportados',
  'user.account_deleted': 'Conta excluída',
  'order.discount_changed': 'Desconto do pedido alterado',
  'order.payment_captured_after_close': 'Pagamento após o fechamento',
  'payment.created': 'Pagamento criado',
  'payment.status_changed': 'Situação do pagamento alterada',
  'payment.refund_requested': 'Estorno solicitado',
  'payment.refund_refused': 'Estorno recusado',
  'support.ticket_opened': 'Chamado aberto',
  'support.ticket_assigned': 'Chamado assumido',
  'support.ticket_resolved': 'Chamado resolvido',
  'support.attachment_viewed': 'Anexo de chamado visto',
  'document.uploaded': 'Documento enviado',
  'document.viewed': 'Documento visto',
  'document.rejected': 'Documento recusado',
  'custom_order.requested': 'Pedido sob medida solicitado',
  'custom_order.checkout': 'Pedido sob medida fechado',
  'custom_order.order_paid': 'Pedido sob medida pago',
  'custom_order.order_cancelled': 'Pedido sob medida cancelado',
  'custom_order.order_released': 'Pedido sob medida liberado',
  'custom_order.photo_sent': 'Foto do pé enviada',
  'custom_order.photo_viewed': 'Foto do pé vista',
};

String auditActionLabel(String action) => _auditActionLabels[action] ?? action;
