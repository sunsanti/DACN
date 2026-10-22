/// Price-list entry (bệnh / dịch vụ) set by the admin.
class Disease {
  final int id;
  final String name;
  final int price; // VND
  final bool active;
  final bool bhytCovered; // reimbursed by BHYT

  Disease({
    required this.id,
    required this.name,
    required this.price,
    required this.active,
    this.bhytCovered = true,
  });

  factory Disease.fromJson(Map<String, dynamic> json) => Disease(
        id: json['id'] as int,
        name: (json['name'] ?? '') as String,
        price: (json['price'] as num?)?.toInt() ?? 0,
        active: json['active'] as bool? ?? true,
        bhytCovered: json['bhytCovered'] as bool? ?? true,
      );
}

/// GET /diseases → fixed exam fee + price list.
class PriceList {
  final int examFee;
  final bool examFeeBhytCovered;
  final List<Disease> items;
  PriceList(this.examFee, this.items, {this.examFeeBhytCovered = true});

  factory PriceList.fromJson(Map<String, dynamic> json) => PriceList(
        (json['examFee'] as num?)?.toInt() ?? 0,
        (json['items'] as List).map((e) => Disease.fromJson(Map<String, dynamic>.from(e))).toList(),
        examFeeBhytCovered: json['examFeeBhytCovered'] as bool? ?? true,
      );
}

/// One line of an appointment bill (snapshot name + price).
class BillItem {
  final String name;
  final int price;
  final bool bhytCovered;
  BillItem(this.name, this.price, {this.bhytCovered = true});

  factory BillItem.fromJson(Map<String, dynamic> json) => BillItem(
        (json['name'] ?? '') as String,
        (json['price'] as num?)?.toInt() ?? 0,
        bhytCovered: json['bhytCovered'] as bool? ?? true,
      );
}
