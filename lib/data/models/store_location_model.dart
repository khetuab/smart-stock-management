/// A physical branch / showroom of the shop, pinned on the illustrated
/// Ethiopia map. Lives in a dedicated 'StoreLocations' sheet — a brand-new
/// tab that no existing feature reads or writes, so adding it is purely
/// additive to the Google Sheets backend.
class StoreLocation {
  final String id;
  final String name;
  final String city;
  final String region;
  final double lat;
  final double lng;
  final String phone;
  final String hours;
  final String address;
  final bool isMain;
  final String createdAt;

  const StoreLocation({
    this.id = '',
    required this.name,
    this.city = '',
    this.region = '',
    required this.lat,
    required this.lng,
    this.phone = '',
    this.hours = '',
    this.address = '',
    this.isMain = false,
    this.createdAt = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'city': city,
        'region': region,
        'lat': lat,
        'lng': lng,
        'phone': phone,
        'hours': hours,
        'address': address,
        'isMain': isMain ? '1' : '0',
        'createdAt': createdAt,
      };

  factory StoreLocation.fromMap(Map<String, dynamic> map) => StoreLocation(
        id: map['id']?.toString() ?? '',
        name: map['name']?.toString() ?? '',
        city: map['city']?.toString() ?? '',
        region: map['region']?.toString() ?? '',
        lat: double.tryParse(map['lat']?.toString() ?? '') ?? 9.03,
        lng: double.tryParse(map['lng']?.toString() ?? '') ?? 38.74,
        phone: map['phone']?.toString() ?? '',
        hours: map['hours']?.toString() ?? '',
        address: map['address']?.toString() ?? '',
        isMain: (map['isMain']?.toString() ?? '0') == '1' ||
            (map['isMain']?.toString() ?? '').toLowerCase() == 'true',
        createdAt: map['createdAt']?.toString() ?? '',
      );

  /// Row order must match [LocationsController.headers].
  List<dynamic> toRow() => [
        id,
        name,
        city,
        region,
        lat,
        lng,
        phone,
        hours,
        address,
        isMain ? '1' : '0',
        createdAt,
      ];

  StoreLocation copyWith({
    String? id,
    String? name,
    String? city,
    String? region,
    double? lat,
    double? lng,
    String? phone,
    String? hours,
    String? address,
    bool? isMain,
    String? createdAt,
  }) {
    return StoreLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      city: city ?? this.city,
      region: region ?? this.region,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      phone: phone ?? this.phone,
      hours: hours ?? this.hours,
      address: address ?? this.address,
      isMain: isMain ?? this.isMain,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Google Maps directions/search link — opened via url_launcher.
  String get mapsUrl =>
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
}

/// Client-side mock branches shown until the owner adds real ones in the
/// admin panel (they take precedence the moment the sheet has any row).
const List<StoreLocation> kMockStoreLocations = [
  StoreLocation(
    id: 'MOCK-AA',
    name: 'Ethio Sadat Mejlis — Flagship Showroom',
    city: 'Addis Ababa',
    region: 'Addis Ababa',
    lat: 9.0305,
    lng: 38.7449,
    phone: '+251 900 000 001',
    hours: 'Mon–Sat 8:30 AM – 8:00 PM',
    address: 'Bole Road, near Alem Cinema, Addis Ababa',
    isMain: true,
  ),
  StoreLocation(
    id: 'MOCK-AD',
    name: 'Sadat Mejlis Adama Branch',
    city: 'Adama',
    region: 'Oromia',
    lat: 8.5408,
    lng: 39.2708,
    phone: '+251 900 000 002',
    hours: 'Mon–Sat 8:30 AM – 7:30 PM',
    address: 'Main Road, Adama',
  ),
  StoreLocation(
    id: 'MOCK-DD',
    name: 'Sadat Mejlis Dire Dawa Branch',
    city: 'Dire Dawa',
    region: 'Dire Dawa',
    lat: 9.5931,
    lng: 41.8661,
    phone: '+251 900 000 003',
    hours: 'Mon–Sat 8:30 AM – 7:30 PM',
    address: 'Kezira, Dire Dawa',
  ),
  StoreLocation(
    id: 'MOCK-BD',
    name: 'Sadat Mejlis Bahir Dar Branch',
    city: 'Bahir Dar',
    region: 'Amhara',
    lat: 11.5936,
    lng: 37.3908,
    phone: '+251 900 000 004',
    hours: 'Mon–Sat 8:30 AM – 7:00 PM',
    address: 'Giyon, Bahir Dar',
  ),
  StoreLocation(
    id: 'MOCK-HW',
    name: 'Sadat Mejlis Hawassa Branch',
    city: 'Hawassa',
    region: 'Sidama',
    lat: 7.0608,
    lng: 38.4784,
    phone: '+251 900 000 005',
    hours: 'Mon–Sat 8:30 AM – 7:30 PM',
    address: 'Lake Side Road, Hawassa',
  ),
  StoreLocation(
    id: 'MOCK-MK',
    name: 'Sadat Mejlis Mekelle Branch',
    city: 'Mekelle',
    region: 'Tigray',
    lat: 13.4967,
    lng: 39.4753,
    phone: '+251 900 000 006',
    hours: 'Mon–Sat 8:30 AM – 7:00 PM',
    address: 'Hawelti, Mekelle',
  ),
  StoreLocation(
    id: 'MOCK-JR',
    name: 'Sadat Mejlis Jimma Branch',
    city: 'Jimma',
    region: 'Oromia',
    lat: 7.6751,
    lng: 36.8336,
    phone: '+251 900 000 007',
    hours: 'Mon–Sat 8:30 AM – 7:00 PM',
    address: 'Merkato Area, Jimma',
  ),
  StoreLocation(
    id: 'MOCK-GD',
    name: 'Sadat Mejlis Gondar Branch',
    city: 'Gondar',
    region: 'Amhara',
    lat: 12.6095,
    lng: 37.4664,
    phone: '+251 900 000 008',
    hours: 'Mon–Sat 8:30 AM – 7:00 PM',
    address: 'Piassa, Gondar',
  ),
];
