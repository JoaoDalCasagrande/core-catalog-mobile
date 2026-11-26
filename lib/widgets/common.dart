import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class AlertBanner extends StatelessWidget {
  const AlertBanner(this.message, {super.key, this.isError = true});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isError ? AppColors.alertBg : AppColors.bgBrandTint,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isError ? const Color(0xFFE3B5B5) : AppColors.borderSubtle,
        ),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 15,
          color: isError ? AppColors.alertText : AppColors.textPrimary,
        ),
      ),
    );
  }
}

class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppText.pageTitle),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(subtitle!, style: AppText.subtitle),
        ],
      ],
    );
  }
}

class CategoryTag extends StatelessWidget {
  const CategoryTag(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.bgBrandTint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.name,
    this.url,
    this.size = 44,
  });

  final String name;
  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: AppColors.bgBrandTint,
      child: Text(
        initialsOf(name.isEmpty ? '?' : name),
        style: TextStyle(
          fontFamily: AppFonts.condensed,
          fontWeight: FontWeight.w600,
          fontSize: size * 0.38,
          color: AppColors.brand,
        ),
      ),
    );

    final link = url?.trim() ?? '';
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: link.isEmpty
            ? initials
            : Image.network(
                link,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => initials,
              ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppText.secondary)),
          Text(value, style: AppText.label),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState(this.message, {super.key, this.loading = false});

  final String message;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        children: [
          if (loading) ...[
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppText.subtitle,
          ),
        ],
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.busyLabel,
    this.icon,
  });

  final String label;
  final String? busyLabel;
  final bool busy;
  final IconData? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final text = Text(busy ? (busyLabel ?? label) : label);
    final style = FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      textStyle: const TextStyle(
        fontFamily: AppFonts.sans,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
    final onTap = busy ? null : onPressed;
    if (icon == null) {
      return FilledButton(style: style, onPressed: onTap, child: text);
    }
    return FilledButton.icon(
      style: style,
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: text,
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final style = OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(48),
      foregroundColor: AppColors.textPrimary,
      side: const BorderSide(color: AppColors.borderStrong),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      textStyle: const TextStyle(
        fontFamily: AppFonts.sans,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
    if (icon == null) {
      return OutlinedButton(
          style: style, onPressed: onPressed, child: Text(label));
    }
    return OutlinedButton.icon(
      style: style,
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
    );
  }
}

class RowActions extends StatelessWidget {
  const RowActions({super.key, required this.onEdit, required this.onDelete});

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Editar',
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined, color: AppColors.brand),
        ),
        IconButton(
          tooltip: 'Excluir',
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline, color: AppColors.alertText),
        ),
      ],
    );
  }
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Excluir',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.alertText),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

void showSnack(BuildContext context, String message, {bool error = false}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      backgroundColor: error ? AppColors.alertText : AppColors.textPrimary,
      duration: Duration(seconds: error ? 5 : 3),
    ),
  );
}
