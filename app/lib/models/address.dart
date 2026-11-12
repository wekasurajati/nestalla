class Address {
  final int id;
  final String label;
  final String recipientName;
  final String phone;
  final String address;
  final String district;
  final String city;
  final String province;
  final String postalCode;
  final double? latitude;
  final double? longitude;
  final bool isDefault;

  const Address({
    required this.id,
    required this.label,
    required this.recipientName,
    required this.phone,
    required this.address,
    required this.district,
    required this.city,
    required this.province,
    required this.postalCode,
    this.latitude,
    this.longitude,
    this.isDefault = false,
  });

  Address copyWith({
    int? id,
    String? label,
    String? recipientName,
    String? phone,
    String? address,
    String? district,
    String? city,
    String? province,
    String? postalCode,
    double? latitude,
    double? longitude,
    bool? isDefault,
  }) {
    return Address(
      id: id ?? this.id,
      label: label ?? this.label,
      recipientName: recipientName ?? this.recipientName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      district: district ?? this.district,
      city: city ?? this.city,
      province: province ?? this.province,
      postalCode: postalCode ?? this.postalCode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
