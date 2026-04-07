import '../model/chat_model.dart';

List<ChatModel> maanGetChatList() {
  List<ChatModel> list = [];
  list.add(ChatModel(title: 'Prince Mahmud', subTitle: 'hello', image: "https://assets.iqonic.design/old-themeforest-images/prokit/datingApp/Image.9.jpg"));
  list.add(ChatModel(title: 'Tahmid Tarongo', subTitle: 'How ypu doing?', image: "https://assets.iqonic.design/old-themeforest-images/prokit/datingApp/Image.2.jpg"));
  list.add(ChatModel(title: 'Tawhid Khan', subTitle: 'About what Course?', image: "https://assets.iqonic.design/old-themeforest-images/prokit/datingApp/Image.1.jpg"));
  list.add(ChatModel(title: 'Lucifer MrngStar', subTitle: 'hello', image: "https://assets.iqonic.design/old-themeforest-images/prokit/datingApp/Image.3.jpg"));
  list.add(ChatModel(title: 'Eliyahou Amoyelle', subTitle: 'How ypu doing?', image: "https://assets.iqonic.design/old-themeforest-images/prokit/datingApp/Image.4.jpg"));
  list.add(ChatModel(title: 'Tony Stark', subTitle: 'About what Course?', image: "https://assets.iqonic.design/old-themeforest-images/prokit/datingApp/Image.6.jpg"));
  list.add(ChatModel(title: 'Tom Holland', subTitle: 'hello', image: "https://assets.iqonic.design/old-themeforest-images/prokit/datingApp/Image.5.jpg"));
  list.add(ChatModel(title: 'Salma Hayek', subTitle: 'How ypu doing?', image: "https://assets.iqonic.design/old-themeforest-images/prokit/datingApp/Image.7.jpg"));
  list.add(ChatModel(title: 'Nora fatehi', subTitle: 'About what Course?', image: "https://assets.iqonic.design/old-themeforest-images/prokit/datingApp/Image.8.jpg"));
  return list;
}

List<InboxData> maanInboxChatDataList() {
  List<InboxData> list = [];
  list.add(InboxData(id: 0, message: 'yeah,,'));
  list.add(InboxData(id: 1, message: 'Have you taken your medicine?'));
  list.add(InboxData(id: 1, message: 'sorry but i can\'t find your home number'));
  list.add(InboxData(id: 0, message: 'Please knock on dor'));
  list.add(InboxData(id: 0, message: 'I am home waiting for you'));
  list.add(InboxData(id: 0, message: 'Hi Miranda'));
  list.add(InboxData(id: 1, message: 'I am on my way to your home visit'));
  return list;
}
