import 'dart:async';
import 'package:invoiceninja_flutter/ui/app/snackbar_row.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:invoiceninja_flutter/redux/ui/ui_actions.dart';
import 'package:invoiceninja_flutter/utils/completers.dart';
import 'package:invoiceninja_flutter/ui/document/document_screen.dart';
import 'package:invoiceninja_flutter/utils/localization.dart';
import 'package:redux/redux.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:invoiceninja_flutter/redux/document/document_actions.dart';
import 'package:invoiceninja_flutter/data/models/document_model.dart';
import 'package:invoiceninja_flutter/data/models/models.dart';
import 'package:invoiceninja_flutter/ui/document/view/document_view.dart';
import 'package:invoiceninja_flutter/redux/app/app_state.dart';

class DocumentViewScreen extends StatelessWidget {
  const DocumentViewScreen({Key key}) : super(key: key);
  static const String route = '/document/view';

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, DocumentViewVM>(
      converter: (Store<AppState> store) {
        return DocumentViewVM.fromStore(store);
      },
      builder: (context, vm) {
        return DocumentView(
          viewModel: vm,
        );
      },
    );
  }
}

class DocumentViewVM {
  DocumentViewVM({
    @required this.state,
    @required this.document,
    @required this.company,
    @required this.onEntityAction,
    @required this.onEditPressed,
    @required this.onBackPressed,
    @required this.onRefreshed,
    @required this.isSaving,
    @required this.isLoading,
    @required this.isDirty,
  });

  factory DocumentViewVM.fromStore(Store<AppState> store) {
    final state = store.state;
    final document =
        state.documentState.map[state.documentUIState.selectedId] ??
            DocumentEntity(id: state.documentUIState.selectedId);

    Future<Null> _handleRefresh(BuildContext context) {
      final completer = snackBarCompleter(
          context, AppLocalization.of(context).refreshComplete);
      store.dispatch(
          LoadDocument(completer: completer, documentId: document.id));
      return completer.future;
    }

    return DocumentViewVM(
      state: state,
      company: state.selectedCompany,
      isSaving: state.isSaving,
      isLoading: state.isLoading,
      isDirty: document.isNew,
      document: document,
      onEditPressed: (BuildContext context) {
        final Completer<DocumentEntity> completer = Completer<DocumentEntity>();
        store.dispatch(EditDocument(
            document: document, context: context, completer: completer));
        completer.future.then((document) {
          Scaffold.of(context).showSnackBar(SnackBar(
              content: SnackBarRow(
            message: AppLocalization.of(context).updatedDocument,
          )));
        });
      },
      onRefreshed: (context) => _handleRefresh(context),
      onBackPressed: () {
        if (state.uiState.currentRoute.contains(DocumentScreen.route)) {
          store.dispatch(UpdateCurrentRoute(DocumentScreen.route));
        }
      },
      onEntityAction: (BuildContext context, EntityAction action) =>
          handleDocumentAction(context, document, action),
    );
  }

  final AppState state;
  final DocumentEntity document;
  final CompanyEntity company;
  final Function(BuildContext, EntityAction) onEntityAction;
  final Function(BuildContext) onEditPressed;
  final Function onBackPressed;
  final Function(BuildContext) onRefreshed;
  final bool isSaving;
  final bool isLoading;
  final bool isDirty;
}
