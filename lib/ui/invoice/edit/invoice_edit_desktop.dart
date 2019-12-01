import 'package:flutter/widgets.dart';
import 'package:invoiceninja_flutter/constants.dart';
import 'package:invoiceninja_flutter/data/models/entities.dart';
import 'package:invoiceninja_flutter/redux/client/client_selectors.dart';
import 'package:invoiceninja_flutter/ui/app/entity_dropdown.dart';
import 'package:invoiceninja_flutter/ui/app/form_card.dart';
import 'package:invoiceninja_flutter/ui/app/forms/date_picker.dart';
import 'package:invoiceninja_flutter/ui/app/forms/decorated_form_field.dart';
import 'package:invoiceninja_flutter/ui/invoice/edit/invoice_edit_details_vm.dart';
import 'package:invoiceninja_flutter/utils/completers.dart';
import 'package:invoiceninja_flutter/utils/formatting.dart';
import 'package:invoiceninja_flutter/utils/localization.dart';

class InvoiceEditDesktop extends StatefulWidget {
  const InvoiceEditDesktop({
    Key key,
    @required this.viewModel,
    this.isQuote = false,
  }) : super(key: key);

  final EntityEditDetailsVM viewModel;
  final bool isQuote;

  @override
  InvoiceEditDesktopState createState() => InvoiceEditDesktopState();
}

class InvoiceEditDesktopState extends State<InvoiceEditDesktop> {
  final _invoiceNumberController = TextEditingController();
  final _poNumberController = TextEditingController();
  final _discountController = TextEditingController();
  final _partialController = TextEditingController();
  final _custom1Controller = TextEditingController();
  final _custom2Controller = TextEditingController();
  final _surcharge1Controller = TextEditingController();
  final _surcharge2Controller = TextEditingController();
  final _designController = TextEditingController();

  List<TextEditingController> _controllers = [];
  final _debouncer = Debouncer();

  @override
  void didChangeDependencies() {
    _controllers = [
      _invoiceNumberController,
      _poNumberController,
      _discountController,
      _partialController,
      _custom1Controller,
      _custom2Controller,
      _surcharge1Controller,
      _surcharge2Controller,
      _designController,
    ];

    _controllers
        .forEach((dynamic controller) => controller.removeListener(_onChanged));

    final invoice = widget.viewModel.invoice;
    _invoiceNumberController.text = invoice.number;
    _poNumberController.text = invoice.poNumber;
    _discountController.text = formatNumber(invoice.discount, context,
        formatNumberType: FormatNumberType.input);
    _partialController.text = formatNumber(invoice.partial, context,
        formatNumberType: FormatNumberType.input);
    _custom1Controller.text = invoice.customValue1;
    _custom2Controller.text = invoice.customValue2;
    _surcharge1Controller.text = formatNumber(invoice.customSurcharge1, context,
        formatNumberType: FormatNumberType.input);
    _surcharge2Controller.text = formatNumber(invoice.customSurcharge2, context,
        formatNumberType: FormatNumberType.input);
    _designController.text =
        invoice.designId != null ? kInvoiceDesigns[invoice.designId] : '';
    _controllers
        .forEach((dynamic controller) => controller.addListener(_onChanged));

    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _controllers.forEach((controller) {
      controller.removeListener(_onChanged);
      controller.dispose();
    });

    super.dispose();
  }

  void _onChanged() {
    _debouncer.run(() {
      final invoice = widget.viewModel.invoice.rebuild((b) => b
        ..number = widget.viewModel.invoice.isNew
            ? ''
            : _invoiceNumberController.text.trim()
        ..poNumber = _poNumberController.text.trim()
        ..discount = parseDouble(_discountController.text)
        ..partial = parseDouble(_partialController.text)
        ..customValue1 = _custom1Controller.text.trim()
        ..customValue2 = _custom2Controller.text.trim()
        ..customSurcharge1 = parseDouble(_surcharge1Controller.text)
        ..customSurcharge2 = parseDouble(_surcharge2Controller.text));
      if (invoice != widget.viewModel.invoice) {
        widget.viewModel.onChanged(invoice);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalization.of(context);
    final viewModel = widget.viewModel;
    final invoice = viewModel.invoice;
    final company = viewModel.company;

    return ListView(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: FormCard(
                children: <Widget>[
                  if (invoice.isNew)
                    EntityDropdown(
                      key: ValueKey('__client_${invoice.clientId}__'),
                      entityType: EntityType.client,
                      labelText: localization.client,
                      entityId: invoice.clientId,
                      entityList: memoizedDropdownClientList(
                          viewModel.clientMap, viewModel.clientList),
                      validator: (String val) => val.trim().isEmpty
                          ? AppLocalization.of(context).pleaseSelectAClient
                          : null,
                      onSelected: (client) {
                        viewModel.onClientChanged(invoice, client);
                      },
                      onAddPressed: (completer) {
                        viewModel.onAddClientPressed(context, completer);
                      },
                    )
                ],
              ),
            ),
            Expanded(
              child: FormCard(
                children: <Widget>[
                  DatePicker(
                    validator: (String val) => val.trim().isEmpty
                        ? AppLocalization.of(context).pleaseSelectADate
                        : null,
                    labelText: widget.isQuote
                        ? localization.quoteDate
                        : localization.invoiceDate,
                    selectedDate: invoice.date,
                    onSelected: (date) {
                      viewModel.onChanged(invoice.rebuild((b) => b..date = date));
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: FormCard(
                children: <Widget>[
                  DecoratedFormField(
                    controller: _invoiceNumberController,
                    label: widget.isQuote
                        ? localization.quoteNumber
                        : localization.invoiceNumber,
                    validator: (String val) => val.trim().isEmpty
                        ? AppLocalization.of(context).pleaseEnterAnInvoiceNumber
                        : null,
                  ),
                ],
              ),
            ),
          ],
        )
      ],
    );
  }
}