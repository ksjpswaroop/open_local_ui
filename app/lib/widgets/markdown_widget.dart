import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_highlight/themes/atom-one-dark.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_highlight/themes/atom-one-light.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:open_local_ui/helpers/snackbar.dart';
import 'package:unicons/unicons.dart';
import 'package:url_launcher/url_launcher.dart';

class MessageMarkdownWidget extends StatelessWidget {
  final String message;

  const MessageMarkdownWidget(
    this.message, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AdaptiveTheme.of(context).mode.isDark;

    return MarkdownWidget(
      data: message,
      shrinkWrap: true,
      config: MarkdownConfig(
        configs: [
          isDark
              ? PreConfig.darkConfig.copy(
                  textStyle: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                  ),
                  theme: atomOneDarkTheme,
                  wrapper: (child, code, language) =>
                      CodeWrapperWidget(child, code, language),
                )
              : const PreConfig().copy(
                  textStyle: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                  ),
                  theme: atomOneLightTheme,
                  wrapper: (child, code, language) =>
                      CodeWrapperWidget(child, code, language),
                ),
          LinkConfig(
            style: const TextStyle(
              color: Colors.blue,
              decoration: TextDecoration.underline,
            ),
            onTap: (url) {
              try {
                launchUrl(Uri.parse(url));
              } catch (e) {
                SnackBarHelper.showSnackBar(
                  AppLocalizations.of(context)!.somethingWentWrongSnackbarText,
                  SnackBarType.error,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class CodeWrapperWidget extends StatefulWidget {
  final Widget child;
  final String text;
  final String language;

  const CodeWrapperWidget(this.child, this.text, this.language, {super.key});

  @override
  State<CodeWrapperWidget> createState() => _CodeWrapperState();
}

class _CodeWrapperState extends State<CodeWrapperWidget> {
  @override
  void initState() {
    super.initState();
  }

  void _copyMessage() {
    Clipboard.setData(ClipboardData(text: widget.text));

    SnackBarHelper.showSnackBar(
      AppLocalizations.of(context)!.codeCopiedSnackbarText,
      SnackBarType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Align(
          alignment: Alignment.topRight,
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.language.isNotEmpty)
                  SelectionContainer.disabled(
                    child: Container(
                      margin: const EdgeInsets.only(right: 2),
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: AdaptiveTheme.of(context).theme.dividerColor,
                        ),
                      ),
                      child: Text(widget.language),
                    ),
                  ),
                IconButton(
                  icon: const Icon(UniconsLine.copy),
                  onPressed: () => _copyMessage(),
                ),
              ],
            ),
          ),
        )
      ],
    );
  }
}
