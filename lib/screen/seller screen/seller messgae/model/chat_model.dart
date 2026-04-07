import 'package:flutter/material.dart';

class ChatModel {
  String? title;
  String? subTitle;
  String? image;
  IconData? icon;
  bool? isCheckList;
  Color? color;

  ChatModel({this.title, this.subTitle, this.image, this.color, this.isCheckList = false, this.icon});
}

class InboxData {
  int? id;
  String? message;

  InboxData({this.id, this.message});
}
