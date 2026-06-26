// class RunTestData {
//   final List<String> userIds;
//   final List<int?> ages;
//   final List<String> genders;
//   final List<String> items;
//   final List<String> sampleTypes;

//   RunTestData({
//     required this.userIds,
//     required this.ages,
//     required this.genders,
//     required this.items,
//     required this.sampleTypes,
//   });

//   Map<String, dynamic> toJson() => {
//     'userIds': userIds,
//     'ages': ages,
//     'genders': genders,
//     'items': items,
//     'sampleTypes': sampleTypes,
//   };

//   factory RunTestData.fromJson(Map<String, dynamic> json) {
//     return RunTestData(
//       userIds: List<String>.from(json['userIds']),
//       ages: List<int?>.from(json['ages']),
//       genders: List<String>.from(json['genders']),
//       items: List<String>.from(json['items']),
//       sampleTypes: List<String>.from(json['sampleTypes']),
//     );
//   }
// }
class RunTestData {
  final String userId;
  final String item;
  final String sampleType;

  RunTestData({
    required this.userId,
    required this.item,
    required this.sampleType,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'item': item,
    'sampleType': sampleType,
  };

  factory RunTestData.fromJson(Map<String, dynamic> json) {
    return RunTestData(
      userId: json['userId'] ?? '',
      item: json['item'] ?? '',
      sampleType: json['sampleType'] ?? '',
    );
  }
}
