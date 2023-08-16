import 'package:foss_wallet/anonpay/anonpay_invoice_info.dart';
import 'package:foss_wallet/view_model/dashboard/action_list_item.dart';

class AnonpayTransactionListItem extends ActionListItem {
  AnonpayTransactionListItem({required this.transaction});

  final AnonpayInvoiceInfo transaction;

  @override
  DateTime get date => transaction.createdAt;
}
