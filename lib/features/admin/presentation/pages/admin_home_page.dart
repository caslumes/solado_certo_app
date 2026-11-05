import 'package:flutter/material.dart';
import 'package:solado_certo_app/features/admin/presentation/components/admin_list_view.dart';
import 'package:solado_certo_app/features/admin/presentation/pages/admin_ads_page.dart';
import 'package:solado_certo_app/features/admin/presentation/pages/admin_audit_page.dart';
import 'package:solado_certo_app/features/admin/presentation/pages/admin_indicators_page.dart';
import 'package:solado_certo_app/features/admin/presentation/pages/admin_orders_page.dart';
import 'package:solado_certo_app/features/admin/presentation/pages/admin_payments_page.dart';
import 'package:solado_certo_app/features/admin/presentation/pages/admin_support_page.dart';
import 'package:solado_certo_app/features/admin/presentation/pages/admin_users_page.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const AdminHomePage());

  static final _sections = <(IconData, String, String, Route<void> Function())>[
    (
      Icons.insights_outlined,
      'Indicadores',
      'Pedidos, pagamentos, contas e chamados do período',
      AdminIndicatorsPage.route,
    ),
    (
      Icons.support_agent,
      'Suporte',
      'Fila de chamados: assumir, responder e encerrar',
      AdminSupportPage.route,
    ),
    (
      Icons.people_outline,
      'Usuários',
      'Bloquear, suspender e reativar contas',
      AdminUsersPage.route,
    ),
    (
      Icons.storefront_outlined,
      'Anúncios',
      'Remover anúncios do catálogo',
      AdminAdsPage.route,
    ),
    (
      Icons.receipt_long_outlined,
      'Pedidos',
      'Consultar pedidos de todos os vendedores',
      AdminOrdersPage.route,
    ),
    (
      Icons.payments_outlined,
      'Pagamentos',
      'Consultar pagamentos e estornos recusados',
      AdminPaymentsPage.route,
    ),
    (
      Icons.history,
      'Auditoria',
      'Registro das ações críticas',
      AdminAuditPage.route,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AdminScaffold(
      title: 'Administração',
      body: ListView.separated(
        itemCount: _sections.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final (icon, title, subtitle, route) = _sections[index];
          return ListTile(
            leading: Icon(icon),
            title: Text(title, style: textTheme.bodyMedium),
            subtitle: Text(subtitle, style: textTheme.bodySmall),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(route()),
          );
        },
      ),
    );
  }
}
