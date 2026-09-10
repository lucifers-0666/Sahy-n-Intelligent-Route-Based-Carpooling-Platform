enum VehicleCategoryGroup {
  car,
  twoWheeler,
  threeWheeler,
  utility,
}

extension VehicleCategoryGroupExtension on VehicleCategoryGroup {
  String get displayName {
    switch (this) {
      case VehicleCategoryGroup.car:
        return 'Cars & Crossovers';
      case VehicleCategoryGroup.twoWheeler:
        return 'Two-Wheelers';
      case VehicleCategoryGroup.threeWheeler:
        return 'Three-Wheelers';
      case VehicleCategoryGroup.utility:
        return 'Commercial & Utility';
    }
  }
}

enum VehicleType {
  // Cars
  sedan,
  hatchback,
  suv,
  muv,
  crossover,
  luxurySedan,
  electricCar,

  // Two-wheelers
  motorcycle,
  scooter,
  electricScooter,
  bicycle,
  electricBicycle,

  // Three-wheelers
  autoRickshaw,
  electricAutoRickshaw,

  // Larger / utility vehicles
  van,
  miniVan,
  pickupTruck,
  tempo,
  miniBus,
}

extension VehicleTypeExtension on VehicleType {
  String get code {
    switch (this) {
      case VehicleType.sedan:
        return 'sedan';
      case VehicleType.hatchback:
        return 'hatchback';
      case VehicleType.suv:
        return 'suv';
      case VehicleType.muv:
        return 'muv';
      case VehicleType.crossover:
        return 'crossover';
      case VehicleType.luxurySedan:
        return 'luxury_sedan';
      case VehicleType.electricCar:
        return 'electric_car';
      case VehicleType.motorcycle:
        return 'motorcycle';
      case VehicleType.scooter:
        return 'scooter';
      case VehicleType.electricScooter:
        return 'electric_scooter';
      case VehicleType.bicycle:
        return 'bicycle';
      case VehicleType.electricBicycle:
        return 'electric_bicycle';
      case VehicleType.autoRickshaw:
        return 'auto_rickshaw';
      case VehicleType.electricAutoRickshaw:
        return 'electric_auto_rickshaw';
      case VehicleType.van:
        return 'van';
      case VehicleType.miniVan:
        return 'mini_van';
      case VehicleType.pickupTruck:
        return 'pickup_truck';
      case VehicleType.tempo:
        return 'tempo';
      case VehicleType.miniBus:
        return 'mini_bus';
    }
  }

  String get displayName {
    switch (this) {
      case VehicleType.sedan:
        return 'Sedan';
      case VehicleType.hatchback:
        return 'Hatchback';
      case VehicleType.suv:
        return 'SUV';
      case VehicleType.muv:
        return 'MUV / MPV';
      case VehicleType.crossover:
        return 'Crossover';
      case VehicleType.luxurySedan:
        return 'Luxury Sedan';
      case VehicleType.electricCar:
        return 'Electric Car (EV)';
      case VehicleType.motorcycle:
        return 'Motorcycle';
      case VehicleType.scooter:
        return 'Scooter';
      case VehicleType.electricScooter:
        return 'Electric Scooter';
      case VehicleType.bicycle:
        return 'Bicycle';
      case VehicleType.electricBicycle:
        return 'Electric Bicycle';
      case VehicleType.autoRickshaw:
        return 'Auto Rickshaw';
      case VehicleType.electricAutoRickshaw:
        return 'Electric Auto';
      case VehicleType.van:
        return 'Passenger Van';
      case VehicleType.miniVan:
        return 'Mini Van';
      case VehicleType.pickupTruck:
        return 'Pickup Truck';
      case VehicleType.tempo:
        return 'Tempo / SCV';
      case VehicleType.miniBus:
        return 'Mini Bus';
    }
  }

  VehicleCategoryGroup get categoryGroup {
    switch (this) {
      case VehicleType.sedan:
      case VehicleType.hatchback:
      case VehicleType.suv:
      case VehicleType.muv:
      case VehicleType.crossover:
      case VehicleType.luxurySedan:
      case VehicleType.electricCar:
        return VehicleCategoryGroup.car;

      case VehicleType.motorcycle:
      case VehicleType.scooter:
      case VehicleType.electricScooter:
      case VehicleType.bicycle:
      case VehicleType.electricBicycle:
        return VehicleCategoryGroup.twoWheeler;

      case VehicleType.autoRickshaw:
      case VehicleType.electricAutoRickshaw:
        return VehicleCategoryGroup.threeWheeler;

      case VehicleType.van:
      case VehicleType.miniVan:
      case VehicleType.pickupTruck:
      case VehicleType.tempo:
      case VehicleType.miniBus:
        return VehicleCategoryGroup.utility;
    }
  }

  int get defaultSeatCapacity {
    switch (this) {
      case VehicleType.sedan:
      case VehicleType.hatchback:
      case VehicleType.crossover:
      case VehicleType.luxurySedan:
      case VehicleType.electricCar:
        return 4;
      case VehicleType.suv:
        return 6;
      case VehicleType.muv:
        return 7;
      case VehicleType.motorcycle:
      case VehicleType.scooter:
      case VehicleType.electricScooter:
      case VehicleType.bicycle:
      case VehicleType.electricBicycle:
        return 1;
      case VehicleType.autoRickshaw:
      case VehicleType.electricAutoRickshaw:
        return 3;
      case VehicleType.van:
        return 7;
      case VehicleType.miniVan:
        return 6;
      case VehicleType.pickupTruck:
        return 2;
      case VehicleType.tempo:
        return 3;
      case VehicleType.miniBus:
        return 14;
    }
  }

  bool get isElectric {
    switch (this) {
      case VehicleType.electricCar:
      case VehicleType.electricScooter:
      case VehicleType.electricBicycle:
      case VehicleType.electricAutoRickshaw:
        return true;
      default:
        return false;
    }
  }

  bool get isTwoWheeler => categoryGroup == VehicleCategoryGroup.twoWheeler;
  bool get isThreeWheeler => categoryGroup == VehicleCategoryGroup.threeWheeler;
  bool get isCar => categoryGroup == VehicleCategoryGroup.car;
  bool get isUtility => categoryGroup == VehicleCategoryGroup.utility;

  static VehicleType fromString(String? raw) {
    if (raw == null || raw.trim().isEmpty) return VehicleType.sedan;
    final clean = raw
        .trim()
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll('-', '_')
        .replaceAll('/', '_');

    switch (clean) {
      case 'sedan':
        return VehicleType.sedan;
      case 'hatchback':
        return VehicleType.hatchback;
      case 'suv':
        return VehicleType.suv;
      case 'muv':
      case 'mpv':
      case 'muv_mpv':
        return VehicleType.muv;
      case 'crossover':
        return VehicleType.crossover;
      case 'luxurysedan':
      case 'luxury_sedan':
      case 'luxury':
        return VehicleType.luxurySedan;
      case 'electriccar':
      case 'electric_car':
      case 'ev':
      case 'ev_car':
        return VehicleType.electricCar;
      case 'motorcycle':
      case 'bike':
        return VehicleType.motorcycle;
      case 'scooter':
        return VehicleType.scooter;
      case 'electricscooter':
      case 'electric_scooter':
      case 'ev_scooter':
        return VehicleType.electricScooter;
      case 'bicycle':
      case 'cycle':
        return VehicleType.bicycle;
      case 'electricbicycle':
      case 'electric_bicycle':
      case 'ev_bicycle':
      case 'ebike':
        return VehicleType.electricBicycle;
      case 'autorickshaw':
      case 'auto_rickshaw':
      case 'auto':
      case 'rickshaw':
        return VehicleType.autoRickshaw;
      case 'electricautorickshaw':
      case 'electric_auto_rickshaw':
      case 'electric_auto':
      case 'e_rickshaw':
      case 'erickshaw':
        return VehicleType.electricAutoRickshaw;
      case 'van':
      case 'passenger_van':
        return VehicleType.van;
      case 'minivan':
      case 'mini_van':
        return VehicleType.miniVan;
      case 'pickuptruck':
      case 'pickup_truck':
      case 'pickup':
        return VehicleType.pickupTruck;
      case 'tempo':
      case 'scv':
      case 'small_commercial':
        return VehicleType.tempo;
      case 'minibus':
      case 'mini_bus':
      case 'bus':
        return VehicleType.miniBus;
      default:
        // Partial fallback
        if (clean.contains('bike') || clean.contains('motor')) {
          return VehicleType.motorcycle;
        }
        if (clean.contains('scoot')) {
          return clean.contains('elec')
              ? VehicleType.electricScooter
              : VehicleType.scooter;
        }
        if (clean.contains('auto') || clean.contains('rickshaw')) {
          return clean.contains('elec')
              ? VehicleType.electricAutoRickshaw
              : VehicleType.autoRickshaw;
        }
        if (clean.contains('suv')) return VehicleType.suv;
        if (clean.contains('hatch')) return VehicleType.hatchback;
        if (clean.contains('van')) return VehicleType.van;
        if (clean.contains('bus')) return VehicleType.miniBus;
        return VehicleType.sedan;
    }
  }
}
