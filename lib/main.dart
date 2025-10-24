import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

// Providers
import 'providers/auth_provider.dart';

// Screens
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/home_screen.dart';
import 'screens/checkin_screen.dart';
import 'screens/queue_status_screen.dart';
import 'screens/appointments_screen.dart';
import 'screens/book_appointment_screen.dart'; // Import the new screen
import 'screens/profile_screen.dart';
import 'screens/medical_records_screen.dart';
import 'screens/doctor_dashboard_screen.dart';
import 'screens/create_referral_screen.dart';
import 'screens/referrals_list_screen.dart';
import 'screens/specialist_inbox_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/seen_patients_screen.dart';
import 'screens/schedule_referral_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MediSyncApp());
}

class MediSyncApp extends StatelessWidget {
  const MediSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        title: 'Medi-Sync',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: const Color(0xFF2563EB),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2563EB),
          ),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        home: const SplashScreen(),
        routes: {
          '/login': (_) => const LoginScreen(),
          '/signup': (_) => const SignupScreen(),
          '/reset_password': (_) => const ResetPasswordScreen(),
          '/home': (_) => const HomeScreen(),
          '/checkin': (_) => const CheckInScreen(),
          '/queue_status': (_) => const QueueStatusScreen(),
          '/appointments': (_) => const AppointmentsScreen(),
          '/book_appointment': (_) => const BookAppointmentScreen(), // Add the new route
          '/profile': (_) => const ProfileScreen(),
          '/medical_records': (_) => const MedicalRecordsScreen(),
          '/doctor_dashboard': (_) => const DoctorDashboardScreen(),
          '/create_referral': (_) => const CreateReferralScreen(),
          '/referrals': (_) => const ReferralsListScreen(),
          '/specialist_inbox': (_) => const SpecialistInboxScreen(),
          '/admin_dashboard': (_) => const AdminDashboardScreen(),
          '/seen_patients': (_) => const SeenPatientsScreen(),
          '/schedule_referral': (_) => const ScheduleReferralScreen(),
        },
      ),
    );
  }
}
