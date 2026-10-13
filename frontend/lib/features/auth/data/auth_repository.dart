import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sahyan/core/network/api_client.dart';
import 'package:sahyan/core/storage/secure_storage_service.dart';
import 'package:sahyan/shared/models/user_model.dart';

abstract class AuthRepository {
  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  });

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  });

  Future<Map<String, dynamic>> sendOtp(String phone);

  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String otp,
  });

  Future<Map<String, dynamic>> forgotPassword(String email);

  Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String newPassword,
  });

  Future<UserModel> getProfile();
}

abstract class FirebaseAuthRepository extends AuthRepository {
  Future<void> sendFirebasePhoneOtp({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String errorMessage) onVerificationFailed,
    required void Function(PhoneAuthCredential credential)
    onVerificationCompleted,
    void Function(String verificationId)? onCodeAutoRetrievalTimeout,
    int? forceResendingToken,
  });

  Future<Map<String, dynamic>> verifyFirebasePhoneOtp({
    required String verificationId,
    required String smsCode,
    String? name,
  });

  Future<Map<String, dynamic>> signInWithGoogle();

  Future<Map<String, dynamic>> registerWithEmailPassword({
    required String name,
    required String email,
    required String password,
    String? phone,
  });

  Future<Map<String, dynamic>> signInWithEmailPassword({
    required String email,
    required String password,
  });

  Future<void> sendEmailVerification();

  Future<void> sendPasswordResetEmail(String email);

  Future<Map<String, dynamic>> linkPhoneCredential({
    required String verificationId,
    required String smsCode,
  });

  Future<Map<String, dynamic>> linkGoogleAccount();

  Future<Map<String, dynamic>> syncWithBackend({
    required String idToken,
    String? name,
    String? phone,
  });

  Future<void> signOut();
}

class AuthRepositoryImpl implements FirebaseAuthRepository {
  final ApiClient apiClient;
  final SecureStorageService storageService;
  final FirebaseAuth? firebaseAuth;
  final GoogleSignIn? googleSignIn;

  AuthRepositoryImpl({
    required this.apiClient,
    required this.storageService,
    this.firebaseAuth,
    this.googleSignIn,
  });

  FirebaseAuth get auth {
    try {
      return firebaseAuth ?? FirebaseAuth.instance;
    } catch (_) {
      throw StateError(
        'Firebase Authentication is not initialized on this platform or test environment.',
      );
    }
  }

  GoogleSignIn get activeGoogleSignIn => googleSignIn ?? GoogleSignIn();

  bool get isFirebaseAvailable {
    try {
      return firebaseAuth != null || FirebaseAuth.instance.app.name.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // -------------------------------------------------------------
  // Firebase Authentication Implementation
  // -------------------------------------------------------------

  @override
  Future<void> sendFirebasePhoneOtp({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String errorMessage) onVerificationFailed,
    required void Function(PhoneAuthCredential credential)
    onVerificationCompleted,
    void Function(String verificationId)? onCodeAutoRetrievalTimeout,
    int? forceResendingToken,
  }) async {
    final cleanPhone = phoneNumber.startsWith('+')
        ? phoneNumber
        : (phoneNumber.length == 10 ? '+91$phoneNumber' : phoneNumber);

    await auth.verifyPhoneNumber(
      phoneNumber: cleanPhone,
      timeout: const Duration(seconds: 60),
      forceResendingToken: forceResendingToken,
      verificationCompleted: (PhoneAuthCredential credential) {
        onVerificationCompleted(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        String msg = 'Phone number verification failed.';
        if (e.code == 'invalid-phone-number') {
          msg = 'Please enter a valid phone number with country code.';
        } else if (e.code == 'too-many-requests') {
          msg = 'Too many requests. Please wait a moment before trying again.';
        } else if (e.code == 'quota-exceeded') {
          msg =
              'SMS quota reached. Please use a test phone number or contact support.';
        } else if (e.message != null && e.message!.isNotEmpty) {
          msg = e.message!;
        }
        onVerificationFailed(msg);
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId, resendToken);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        onCodeAutoRetrievalTimeout?.call(verificationId);
      },
    );
  }

  @override
  Future<Map<String, dynamic>> verifyFirebasePhoneOtp({
    required String verificationId,
    required String smsCode,
    String? name,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    final userCredential = await auth.signInWithCredential(credential);
    final fbUser = userCredential.user;
    if (fbUser == null) {
      throw Exception('Phone verification failed: Missing Firebase user');
    }

    final idToken = await fbUser.getIdToken() ?? '';
    return await syncWithBackend(
      idToken: idToken,
      name: name ?? fbUser.displayName,
      phone: fbUser.phoneNumber,
    );
  }

  @override
  Future<Map<String, dynamic>> signInWithGoogle() async {
    final GoogleSignInAccount? account = await activeGoogleSignIn.signIn();
    if (account == null) {
      return {'cancelled': true};
    }

    final GoogleSignInAuthentication googleAuth = await account.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final UserCredential userCredential = await auth.signInWithCredential(
      credential,
    );
    final User? fbUser = userCredential.user;
    if (fbUser == null) {
      throw Exception('Google sign-in failed: Missing Firebase user');
    }

    final String idToken = await fbUser.getIdToken() ?? '';
    final syncResult = await syncWithBackend(
      idToken: idToken,
      name: fbUser.displayName,
      phone: fbUser.phoneNumber,
    );

    return {
      'user': syncResult['user'],
      'token': idToken,
      'isNewUser': syncResult['isNewUser'] ?? false,
      'cancelled': false,
    };
  }

  @override
  Future<Map<String, dynamic>> registerWithEmailPassword({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final userCredential = await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final fbUser = userCredential.user;
    if (fbUser == null) {
      throw Exception('Email registration failed: Missing Firebase user');
    }

    await fbUser.updateDisplayName(name.trim());
    await fbUser.sendEmailVerification();

    final idToken = await fbUser.getIdToken() ?? '';
    return await syncWithBackend(
      idToken: idToken,
      name: name.trim(),
      phone: phone,
    );
  }

  @override
  Future<Map<String, dynamic>> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final userCredential = await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final fbUser = userCredential.user;
    if (fbUser == null) {
      throw Exception('Email login failed: Missing Firebase user');
    }

    final idToken = await fbUser.getIdToken() ?? '';
    return await syncWithBackend(
      idToken: idToken,
      name: fbUser.displayName,
      phone: fbUser.phoneNumber,
    );
  }

  @override
  Future<void> sendEmailVerification() async {
    final currentUser = auth.currentUser;
    if (currentUser != null && !currentUser.emailVerified) {
      await currentUser.sendEmailVerification();
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await auth.sendPasswordResetEmail(email: email.trim());
  }

  @override
  Future<Map<String, dynamic>> linkPhoneCredential({
    required String verificationId,
    required String smsCode,
  }) async {
    final currentUser = auth.currentUser;
    if (currentUser == null) {
      throw Exception(
        'No authenticated user session found to link credentials.',
      );
    }

    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    try {
      await currentUser.linkWithCredential(credential);
      final idToken = await currentUser.getIdToken() ?? '';
      await apiClient.post(
        '/auth/link-provider',
        body: {'providerId': 'phone', 'providerUid': currentUser.uid},
      );
      return await syncWithBackend(
        idToken: idToken,
        phone: currentUser.phoneNumber,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'provider-already-linked') {
        throw Exception('This phone number is already linked to your account.');
      } else if (e.code == 'credential-already-in-use') {
        throw Exception(
          'This phone number is already linked to another Sahyān account.',
        );
      }
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> linkGoogleAccount() async {
    final currentUser = auth.currentUser;
    if (currentUser == null) {
      throw Exception(
        'No authenticated user session found to link credentials.',
      );
    }

    final GoogleSignInAccount? account = await activeGoogleSignIn.signIn();
    if (account == null) {
      return {'cancelled': true};
    }

    final GoogleSignInAuthentication googleAuth = await account.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    try {
      await currentUser.linkWithCredential(credential);
      final idToken = await currentUser.getIdToken() ?? '';
      await apiClient.post(
        '/auth/link-provider',
        body: {'providerId': 'google.com', 'providerUid': currentUser.uid},
      );
      return await syncWithBackend(idToken: idToken);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'provider-already-linked') {
        throw Exception('Google is already linked to your account.');
      } else if (e.code == 'credential-already-in-use') {
        throw Exception(
          'This Google account is already linked to another Sahyān profile.',
        );
      }
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> syncWithBackend({
    required String idToken,
    String? name,
    String? phone,
  }) async {
    apiClient.setAuthToken(idToken);
    final body = <String, dynamic>{};
    if (name != null && name.trim().isNotEmpty) body['name'] = name.trim();
    if (phone != null && phone.trim().isNotEmpty) body['phone'] = phone.trim();

    final response = await apiClient.post('/auth/firebase-sync', body: body);

    final user = UserModel.fromJson(response['user']);
    await storageService.saveToken(idToken);
    await storageService.saveUser(user);

    return {
      'user': user,
      'token': idToken,
      'isNewUser': response['isNewUser'] ?? false,
    };
  }

  @override
  Future<void> signOut() async {
    try {
      if (isFirebaseAvailable) {
        await auth.signOut();
      }
    } catch (_) {}
    try {
      await activeGoogleSignIn.signOut();
    } catch (_) {}
    apiClient.setAuthToken(null);
    await storageService.clearSession();
  }

  // -------------------------------------------------------------
  // Legacy / Direct API Endpoints
  // -------------------------------------------------------------

  @override
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final cleanPhone = phone.length == 10 ? '+91$phone' : phone;
    final response = await apiClient.post(
      '/auth/register',
      body: {
        'name': name,
        'email': email,
        'phone': cleanPhone,
        'password': password,
      },
    );

    final token = response['accessToken'] as String?;
    final user = UserModel.fromJson(response['user']);

    if (token != null) {
      apiClient.setAuthToken(token);
      await storageService.saveToken(token);
      await storageService.saveUser(user);
    }

    final result = <String, dynamic>{'user': user};
    if (token != null) {
      result['token'] = token;
    }
    return result;
  }

  @override
  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  }) async {
    final response = await apiClient.post(
      '/auth/login',
      body: {'identifier': identifier, 'password': password},
    );

    final token = response['accessToken'] as String;
    final user = UserModel.fromJson(response['user']);

    apiClient.setAuthToken(token);
    await storageService.saveToken(token);
    await storageService.saveUser(user);

    return {'token': token, 'user': user};
  }

  @override
  Future<Map<String, dynamic>> sendOtp(String phone) async {
    return await apiClient.post('/auth/send-otp', body: {'phone': phone});
  }

  @override
  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    final response = await apiClient.post(
      '/auth/verify-otp',
      body: {'phone': phone, 'otp': otp},
    );

    final token = response['accessToken'] as String;
    final user = UserModel.fromJson(response['user']);

    apiClient.setAuthToken(token);
    await storageService.saveToken(token);
    await storageService.saveUser(user);

    return {'token': token, 'user': user};
  }

  @override
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    return await apiClient.post(
      '/auth/forgot-password',
      body: {'email': email},
    );
  }

  @override
  Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    return await apiClient.post(
      '/auth/reset-password',
      body: {
        'token': token,
        'newPassword': newPassword,
        'password': newPassword,
      },
    );
  }

  @override
  Future<UserModel> getProfile() async {
    try {
      final response = await apiClient.get('/users/profile');
      final user = UserModel.fromJson(response['data']);
      await storageService.saveUser(user);
      return user;
    } catch (e) {
      if (e is ApiException && e.statusCode == 401) {
        rethrow;
      }
      final storedUser = await storageService.getUser();
      if (storedUser != null) return storedUser;
      rethrow;
    }
  }
}
