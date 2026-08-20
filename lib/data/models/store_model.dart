class Store {
  final String id;
  final String name;
  final String logo;
  final String ownerName;
  final String currency;
  final String language;
  final bool zakatEnabled;
  final String themeColor;
  final String setupDate;
  final String? phone;
  final String? email;
  final String? address;
  final String? taxId;

  Store({
    this.id = '',
    required this.name,
    this.logo = '',
    this.ownerName = '',
    this.currency = 'ETB',
    this.language = 'English',
    this.zakatEnabled = false,
    this.themeColor = '#2196F3',
    this.setupDate = '',
    this.phone,
    this.email,
    this.address,
    this.taxId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'logo': logo,
      'ownerName': ownerName,
      'currency': currency,
      'language': language,
      'zakatEnabled': zakatEnabled,
      'themeColor': themeColor,
      'phone': phone,
      'email': email,
      'address': address,
      'taxId': taxId,
      'setupDate': setupDate,
    };
  }

  factory Store.fromMap(Map<String, dynamic> map) {
    return Store(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      logo: map['logo'] ?? '',
      ownerName: map['ownerName'] ?? '',
      currency: map['currency'] ?? 'ETB',
      language: map['language'] ?? 'English',
      zakatEnabled: map['zakatEnabled'] ?? false,
      themeColor: map['themeColor'] ?? '#2196F3',
      phone: map['phone'],
      email: map['email'],
      address: map['address'],
      taxId: map['taxId'],
      setupDate: map['setupDate'] ?? '',
    );
  }
}