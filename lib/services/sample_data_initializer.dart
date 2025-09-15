import 'package:cloud_firestore/cloud_firestore.dart';

/// Sample data initialization for PortCare Firebase database
/// Run this once to populate the database with test data
class SampleDataInitializer {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialize all sample data
  Future<void> initializeSampleData() async {
    try {
      await _initializeBooths();
      await _initializeDoctors();
      await _initializeUsers();
      print('Sample data initialized successfully');
    } catch (e) {
      print('Error initializing sample data: $e');
    }
  }

  /// Initialize sample booths
  Future<void> _initializeBooths() async {
    final booths = [
      {
        'id': 'booth_001',
        'name': 'City General Hospital - Booth A1',
        'code': 'CGH_A1_001',
        'description':
            'Primary care consultation booth with basic diagnostic equipment',
        'location': {
          'latitude': 12.9716,
          'longitude': 77.5946,
          'address': '123 MG Road, Bangalore, Karnataka 560001',
          'landmark': 'Near Brigade Road',
        },
        'status': 'available',
        'availableServices': ['consultation', 'blood_pressure', 'temperature'],
        'equipment': ['Blood Pressure Monitor', 'Thermometer', 'Stethoscope'],
        'operatingHours': {
          'monday': {'open': '09:00', 'close': '18:00'},
          'tuesday': {'open': '09:00', 'close': '18:00'},
          'wednesday': {'open': '09:00', 'close': '18:00'},
          'thursday': {'open': '09:00', 'close': '18:00'},
          'friday': {'open': '09:00', 'close': '18:00'},
          'saturday': {'open': '10:00', 'close': '16:00'},
          'sunday': {'open': 'closed', 'close': 'closed'},
        },
        'contactNumber': '+91-80-1234-5678',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      {
        'id': 'booth_002',
        'name': 'Metro Medical Center - Booth B2',
        'code': 'MMC_B2_002',
        'description':
            'Advanced diagnostic booth with ECG and basic lab testing',
        'location': {
          'latitude': 12.9784,
          'longitude': 77.6408,
          'address': '456 Residency Road, Bangalore, Karnataka 560025',
          'landmark': 'Opposite Richmond Town',
        },
        'status': 'available',
        'availableServices': ['consultation', 'ecg', 'blood_test', 'x_ray'],
        'equipment': [
          'ECG Machine',
          'Blood Test Kit',
          'X-Ray Scanner',
          'Ultrasound',
        ],
        'operatingHours': {
          'monday': {'open': '08:00', 'close': '20:00'},
          'tuesday': {'open': '08:00', 'close': '20:00'},
          'wednesday': {'open': '08:00', 'close': '20:00'},
          'thursday': {'open': '08:00', 'close': '20:00'},
          'friday': {'open': '08:00', 'close': '20:00'},
          'saturday': {'open': '09:00', 'close': '18:00'},
          'sunday': {'open': '10:00', 'close': '14:00'},
        },
        'contactNumber': '+91-80-8765-4321',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      {
        'id': 'booth_003',
        'name': 'Downtown Clinic - Booth C1',
        'code': 'DTC_C1_003',
        'description': 'Specialized pediatric and maternity care booth',
        'location': {
          'latitude': 12.9830,
          'longitude': 77.6131,
          'address': '789 Commercial Street, Bangalore, Karnataka 560001',
          'landmark': 'Near Central Business District',
        },
        'status': 'occupied',
        'availableServices': ['pediatric_care', 'maternity', 'vaccination'],
        'equipment': ['Pediatric Scale', 'Prenatal Monitor', 'Vaccination Kit'],
        'operatingHours': {
          'monday': {'open': '09:00', 'close': '17:00'},
          'tuesday': {'open': '09:00', 'close': '17:00'},
          'wednesday': {'open': '09:00', 'close': '17:00'},
          'thursday': {'open': '09:00', 'close': '17:00'},
          'friday': {'open': '09:00', 'close': '17:00'},
          'saturday': {'open': '10:00', 'close': '15:00'},
          'sunday': {'open': 'closed', 'close': 'closed'},
        },
        'contactNumber': '+91-80-5555-1234',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
    ];

    for (final booth in booths) {
      await _firestore
          .collection('booths')
          .doc(booth['id'] as String)
          .set(booth);
    }
  }

  /// Initialize sample doctors
  Future<void> _initializeDoctors() async {
    final doctors = [
      {
        'id': 'doc_001',
        'name': 'Dr. Sarah Johnson',
        'email': 'sarah.johnson@portcare.com',
        'specialty': 'General Medicine',
        'qualification': 'MBBS, MD',
        'experience': 8,
        'rating': 4.8,
        'reviewCount': 156,
        'bio':
            'Experienced general physician with 8 years of practice. Specializes in preventive care and chronic disease management.',
        'languages': ['English', 'Hindi'],
        'availability': {
          'monday': ['09:00-12:00', '14:00-17:00'],
          'tuesday': ['09:00-12:00', '14:00-17:00'],
          'wednesday': ['09:00-12:00', '14:00-17:00'],
          'thursday': ['09:00-12:00', '14:00-17:00'],
          'friday': ['09:00-12:00', '14:00-17:00'],
          'saturday': ['10:00-14:00'],
          'sunday': [],
        },
        'consultationFee': 500,
        'profileImageUrl': null,
        'isActive': true,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      {
        'id': 'doc_002',
        'name': 'Dr. Rajesh Kumar',
        'email': 'rajesh.kumar@portcare.com',
        'specialty': 'Cardiology',
        'qualification': 'MBBS, MD, DM (Cardiology)',
        'experience': 12,
        'rating': 4.9,
        'reviewCount': 203,
        'bio':
            'Senior cardiologist specializing in preventive cardiology and heart disease management.',
        'languages': ['English', 'Hindi', 'Kannada'],
        'availability': {
          'monday': ['10:00-13:00', '15:00-18:00'],
          'tuesday': ['10:00-13:00', '15:00-18:00'],
          'wednesday': ['10:00-13:00'],
          'thursday': ['10:00-13:00', '15:00-18:00'],
          'friday': ['10:00-13:00', '15:00-18:00'],
          'saturday': ['11:00-15:00'],
          'sunday': [],
        },
        'consultationFee': 800,
        'profileImageUrl': null,
        'isActive': true,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      {
        'id': 'doc_003',
        'name': 'Dr. Priya Sharma',
        'email': 'priya.sharma@portcare.com',
        'specialty': 'Pediatrics',
        'qualification': 'MBBS, DCH',
        'experience': 6,
        'rating': 4.7,
        'reviewCount': 89,
        'bio':
            'Dedicated pediatrician focused on child health, vaccination, and developmental care.',
        'languages': ['English', 'Hindi'],
        'availability': {
          'monday': ['09:00-12:00', '14:00-16:00'],
          'tuesday': ['09:00-12:00', '14:00-16:00'],
          'wednesday': ['09:00-12:00', '14:00-16:00'],
          'thursday': ['09:00-12:00', '14:00-16:00'],
          'friday': ['09:00-12:00', '14:00-16:00'],
          'saturday': ['10:00-13:00'],
          'sunday': [],
        },
        'consultationFee': 400,
        'profileImageUrl': null,
        'isActive': true,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
    ];

    for (final doctor in doctors) {
      await _firestore
          .collection('doctors')
          .doc(doctor['id'] as String)
          .set(doctor);
    }
  }

  /// Initialize sample users (for testing purposes)
  Future<void> _initializeUsers() async {
    // Note: In production, users are created through Firebase Auth
    // This is just for reference/testing
    final users = [
      {
        'id': 'test_user_001',
        'email': 'test@example.com',
        'name': 'Test User',
        'phoneNumber': '+91-9876543210',
        'dateOfBirth': '1990-01-01',
        'gender': 'other',
        'bloodGroup': 'O+',
        'emergencyContact': {
          'name': 'Emergency Contact',
          'phoneNumber': '+91-9876543211',
          'relationship': 'Family',
        },
        'medicalHistory': ['No known allergies', 'Hypertension'],
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
    ];

    for (final user in users) {
      await _firestore.collection('users').doc(user['id'] as String).set(user);
    }
  }
}
