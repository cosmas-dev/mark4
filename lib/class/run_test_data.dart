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
  final String userName;
  final String age;
  final String gender;
  final String item;
  final String sampleType;

  RunTestData({
    required this.userName,
    required this.age,
    required this.gender,
    required this.item,
    required this.sampleType,
  });

  Map<String, dynamic> toJson() => {
    'userName': userName,
    'age': age,
    'gender': gender,
    'item': item,
    'sampleType': sampleType,
  };

  factory RunTestData.fromJson(Map<String, dynamic> json) {
    return RunTestData(
      userName: json['userName'] ?? '',
      age: json['age'] ?? '',
      gender: json['gender'] ?? '',
      item: json['item'] ?? '',
      sampleType: json['sampleType'] ?? '',
    );
  }
}
