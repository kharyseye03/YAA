import 'package:flutter/material.dart';

class NotifItem {
  const NotifItem({
    this.icon,
    this.iconBg,
    this.iconColor,
    this.avatarPath,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.isUnread,
    this.actionLabel,
  });

  final IconData? icon;
  final Color? iconBg;
  final Color? iconColor;
  final String? avatarPath;
  final String title;
  final String subtitle;
  final String time;
  final bool isUnread;
  final String? actionLabel;
}