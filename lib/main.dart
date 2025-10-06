import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart'; // Allowed package for custom fonts
import 'package:animations/animations.dart'; // Allowed package for transitions

/// ----------------------
/// Data Model for App User
/// ----------------------
class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String role;
  final String? phoneNumber; // Added phone number

  AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.phoneNumber, // Make nullable for existing mock users or if not provided
  });
}

/// ----------------------
/// Data Model for Notification
/// ----------------------
class NotificationItem {
  final String id;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final String targetRole; // e.g., 'student', 'teacher', 'admin', 'all'

  NotificationItem({
    required this.id,
    required this.senderName,
    required this.message,
    required this.timestamp,
    required this.targetRole,
  });
}

/// ----------------------
/// Mock Authentication Service
/// ----------------------
class AuthService extends ChangeNotifier {
  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;

  // Mock database for registered users
  final Map<String, AppUser> _registeredUsers = <String, AppUser>{};
  int _nextUid = 1;
  int _nextNotificationId = 1;

  final List<NotificationItem> _notifications = <NotificationItem>[];
  List<NotificationItem> get notifications => List<NotificationItem>.unmodifiable(_notifications);

  // All available roles, including admin, for internal system use
  static const List<String> availableRoles = <String>['student', 'teacher', 'admin'];

  // Roles available for users to select during registration
  static List<String> get userSelectableRoles =>
      availableRoles.where((String role) => role != 'admin').toList();

  AuthService() {
    // Initialize with some mock users for demonstration
    _registeredUsers['test@example.com'] = AppUser(
      uid: 'mock-uid-1',
      email: 'test@example.com',
      displayName: 'Test Student',
      role: 'student',
      phoneNumber: '111-222-3333',
    );
    _registeredUsers['teacher@example.com'] = AppUser(
      uid: 'mock-uid-2',
      email: 'teacher@example.com',
      displayName: 'Teacher Name',
      role: 'teacher',
      phoneNumber: '444-555-6666',
    );
    _registeredUsers['manojarya0207@gmail.com'] = AppUser(
      uid: 'mock-uid-3',
      email: 'manojarya0207@gmail.com',
      displayName: 'manojarya0207',
      role: 'admin',
      phoneNumber: '777-888-9999',
    );
    _nextUid = 4; // Start UIDs from next available

    // Initialize with some mock notifications
    _notifications.add(NotificationItem(
      id: 'n-1',
      senderName: 'Admin',
      message: 'Welcome to the EdTech platform! Explore your dashboard.',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      targetRole: 'all',
    ));
    _notifications.add(NotificationItem(
      id: 'n-2',
      senderName: 'Prof. Johnson',
      message: 'New assignment posted for Calculus I. Due next week!',
      timestamp: DateTime.now().subtract(const Duration(hours: 10)),
      targetRole: 'student',
    ));
    _notifications.add(NotificationItem(
      id: 'n-3',
      senderName: 'EdTech Team',
      message: 'System maintenance scheduled for Saturday. Services may be briefly interrupted.',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      targetRole: 'all',
    ));
    _nextNotificationId = 4;
  }

  /// Register a new user with email and password.
  /// Returns an error message string if registration fails, null otherwise.
  Future<String?> registerWithEmail({
    required String email,
    required String password,
    required String name,
    required String role,
    required String? phoneNumber, // Now required as a parameter, can be null if not provided
  }) async {
    // Simulate network delay
    await Future<void>.delayed(const Duration(milliseconds: 500));

    if (_registeredUsers.containsKey(email)) {
      return 'Email already registered.';
    }
    if (password.length < 6) {
      return 'Password should be at least 6 characters.';
    }
    // Validate against all available roles, including 'admin', for internal consistency
    if (!availableRoles.contains(role)) {
      return 'Invalid role specified.';
    }

    final AppUser newUser = AppUser(
      uid: 'mock-uid-${_nextUid++}',
      email: email,
      displayName: name,
      role: role,
      phoneNumber: phoneNumber, // Store the provided phone number
    );
    _registeredUsers[email] = newUser;
    _currentUser = newUser;
    notifyListeners();
    return null; // Success
  }

  /// Sign in a user with email and password.
  /// Returns an error message string if sign-in fails, null otherwise.
  Future<String?> signInWithEmail({
    required String email,
    required String password, // In mock, only email existence is checked
  }) async {
    // Simulate network delay
    await Future<void>.delayed(const Duration(milliseconds: 500));

    if (!_registeredUsers.containsKey(email)) {
      return 'No user found for that email.';
    }
    // For a mock, we assume the password is correct if the email exists.
    _currentUser = _registeredUsers[email];
    notifyListeners();
    return null; // Success
  }

  /// Simulate Google sign-in.
  /// Returns an error message string if sign-in fails, null otherwise.
  Future<String?> signInWithGoogle({String defaultRole = 'student'}) async {
    // Simulate network delay
    await Future<void>.delayed(const Duration(milliseconds: 500));

    const String mockEmail = 'google_mock_user@example.com';
    AppUser? user = _registeredUsers[mockEmail];

    if (user == null) {
      // Create a new mock Google user if not already registered
      user = AppUser(
        uid: 'mock-uid-google',
        email: mockEmail,
        displayName: 'Google Mock User',
        role: defaultRole,
        phoneNumber: null, // Google sign-in doesn't provide phone in this mock
      );
      _registeredUsers[mockEmail] = user;
    }
    _currentUser = user;
    notifyListeners();
    return null; // Success
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    // Simulate network delay
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
    notifyListeners();
  }

  /// For admin purposes: get a list of all registered users.
  /// In a real application, this would have proper authorization checks.
  List<AppUser> getAllUsers() {
    return _registeredUsers.values.toList();
  }

  /// For admin purposes: delete a user by email.
  /// In a real application, this would have proper authorization checks.
  void deleteUserByEmail(String email) {
    _registeredUsers.remove(email);
    // If the deleted user was the current user, log them out
    if (_currentUser?.email == email) {
      _currentUser = null;
    }
    notifyListeners();
  }

  /// Sends a new notification.
  Future<void> sendNotification({
    required String senderName,
    required String message,
    required String targetRole,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400)); // Simulate delay
    final NotificationItem newNotification = NotificationItem(
      id: 'n-${_nextNotificationId++}',
      senderName: senderName,
      message: message,
      timestamp: DateTime.now(),
      targetRole: targetRole,
    );
    _notifications.insert(0, newNotification); // Add to the beginning to show latest first
    notifyListeners();
  }

  /// Returns notifications relevant to the current user's role.
  List<NotificationItem> getNotificationsForUser(AppUser user) {
    return _notifications
        .where((NotificationItem n) => n.targetRole == 'all' || n.targetRole == user.role)
        .toList();
  }
}

/// ----------------------
/// Main Application Setup
/// ----------------------
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    // Using a more muted seedColor for a less 'colorful' feel
    final ColorScheme colorScheme = ColorScheme.fromSeed(seedColor: Colors.blueGrey.shade700);
    return ChangeNotifierProvider<AuthService>(
      create: (BuildContext context) => AuthService(),
      builder: (BuildContext context, Widget? child) {
        return MaterialApp(
          title: 'EdTech Authentication',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: colorScheme,
            // Integrate GoogleFonts for a professional typography
            textTheme: GoogleFonts.latoTextTheme(Theme.of(context).textTheme).copyWith(
              headlineSmall: GoogleFonts.lato(
                textStyle: Theme.of(context).textTheme.headlineSmall,
                fontWeight: FontWeight.bold,
              ),
              headlineMedium: GoogleFonts.lato(
                textStyle: Theme.of(context).textTheme.headlineMedium,
                fontWeight: FontWeight.bold,
              ),
              titleLarge: GoogleFonts.lato(
                textStyle: Theme.of(context).textTheme.titleLarge,
                fontWeight: FontWeight.bold,
              ),
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: colorScheme.inversePrimary,
              foregroundColor: colorScheme.onPrimaryContainer,
            ),
            cardTheme: CardThemeData(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              margin: EdgeInsets.zero,
            ),
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          debugShowCheckedModeBanner: false,
          home: const AuthGate(),
        );
      },
    );
  }
}

/// ----------------------
/// Authentication Gate
/// ----------------------
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    final AuthService authService = context.watch<AuthService>();
    if (authService.currentUser == null) {
      return const LoginPage();
    }
    return HomePage(user: authService.currentUser!);
  }
}

/// ----------------------
/// Helper for showing SnackBar messages
/// ----------------------
void _showSnackBar(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}

/// ----------------------
/// Login Page
/// ----------------------
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _loginEmail() async {
    final String email = _emailCtrl.text.trim();
    final String pass = _passCtrl.text.trim();
    if (email.isEmpty || pass.isEmpty) {
      if (!mounted) return;
      return _showSnackBar(context, 'Please provide email & password');
    }

    setState(() => _loading = true);
    final AuthService authService = context.read<AuthService>();
    final String? error = await authService.signInWithEmail(email: email, password: pass);
    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      _showSnackBar(context, error);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() => _loading = true);
    final AuthService authService = context.read<AuthService>();
    final String? error = await authService.signInWithGoogle();
    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      _showSnackBar(context, error);
    }
  }

  void _goRegister() {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) =>
            const RegisterPage(),
        transitionsBuilder: (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child,
        ) {
          return SharedAxisTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            transitionType: SharedAxisTransitionType.horizontal,
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant, // Added for "under color"
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.school, size: 100, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'Welcome to EdTech!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: <Widget>[
                      TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _loginEmail,
                          child: _loading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Login'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _loading ? null : _googleSignIn,
                          icon: const Icon(Icons.account_circle),
                          label: const Text('Sign in with Google'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _goRegister,
                        child: const Text('Don\'t have an account? Register here.', style: TextStyle(fontSize: 14)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ----------------------
/// Register Page (Email) with Role selection
/// ----------------------
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController(); // New: phone number controller
  // Initialize with the first role from userSelectableRoles, which excludes 'admin'.
  String _role = AuthService.userSelectableRoles.first;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _passCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose(); // Dispose phone controller
    super.dispose();
  }

  Future<void> _register() async {
    final String name = _nameCtrl.text.trim();
    final String email = _emailCtrl.text.trim();
    final String pass = _passCtrl.text.trim();
    final String phone = _phoneCtrl.text.trim(); // Get phone number

    if (name.isEmpty || email.isEmpty || pass.isEmpty || phone.isEmpty) {
      if (!mounted) return;
      return _showSnackBar(context, 'All fields required');
    }

    setState(() => _loading = true);
    final AuthService authService = context.read<AuthService>();
    final String? error = await authService.registerWithEmail(
      email: email,
      password: pass,
      name: name,
      role: _role,
      phoneNumber: phone, // Pass phone number to service
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      _showSnackBar(context, error);
    } else {
      _showSnackBar(context, 'Registered successfully!');
      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant, // Added for "under color"
      appBar: AppBar(title: const Text('Create Account')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.person_add, size: 80, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'Join EdTech Today!',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: <Widget>[
                      TextField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _phoneCtrl, // New: phone number field
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          prefixIcon: Icon(Icons.phone),
                          hintText: 'e.g., 123-456-7890',
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _role,
                        decoration: const InputDecoration(
                          labelText: 'Role',
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: AuthService.userSelectableRoles.map<DropdownMenuItem<String>>((String role) {
                          return DropdownMenuItem<String>(
                            value: role,
                            child: Text(role[0].toUpperCase() + role.substring(1)),
                          );
                        }).toList(),
                        onChanged: (String? v) => setState(() {
                          if (v != null) _role = v;
                        }),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _register,
                          child: _loading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Register'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ----------------------
/// Home Page Content Widgets (Role-Agnostic)
/// ----------------------

class UserDashboardPage extends StatelessWidget {
  final AppUser user;
  final VoidCallback onRefresh;
  final bool isLoading;

  const UserDashboardPage({
    super.key,
    required this.user,
    required this.onRefresh,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Card(
            // Reduced padding for smaller welcome box
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Welcome, ${user.displayName}!',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8), // Reduced spacing
                  Text(
                    'Your role: ${user.role[0].toUpperCase() + user.role.substring(1)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16), // Reduced spacing
                  Row(
                    children: <Widget>[
                      Icon(Icons.calendar_today, size: 20, color: Theme.of(context).colorScheme.secondary),
                      const SizedBox(width: 8),
                      Text('Today\'s quick summary', style: Theme.of(context).textTheme.titleSmall),
                    ],
                  ),
                  const SizedBox(height: 8), // Reduced spacing
                  Text('No new assignments due today. Keep up the great work!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic, color: Colors.grey)),
                  const SizedBox(height: 16), // Reduced spacing
                  Align(
                    alignment: Alignment.bottomRight,
                    child: TextButton.icon(
                      onPressed: onRefresh,
                      icon: isLoading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(Icons.refresh, size: 20, color: Theme.of(context).colorScheme.primary),
                      label: Text(isLoading ? 'Refreshing...' : 'Refresh Data'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Upcoming Activities',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              children: const <Widget>[
                ListTile(
                  leading: Icon(Icons.event),
                  title: Text('Team Meeting'),
                  subtitle: Text('Tomorrow, 10:00 AM'),
                  trailing: Chip(label: Text('High')),
                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.assignment),
                  title: Text('Project Alpha Submission'),
                  subtitle: Text('Next Friday'),
                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.school),
                  title: Text('New Course: Advanced AI'),
                  subtitle: Text('Starts next month'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class UserProfilePage extends StatelessWidget {
  final AppUser user;

  const UserProfilePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          CircleAvatar(
            radius: 60,
            backgroundImage: const NetworkImage('https://www.gstatic.com/flutter-onestack-prototype/genui/example_1.jpg'), // Placeholder image
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 20),
          Text(
            user.displayName,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            user.email,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
          ),
          if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              user.phoneNumber!,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            ),
          ],
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildProfileInfoRow(context, Icons.badge, 'UID', user.uid),
                  const Divider(),
                  _buildProfileInfoRow(context, Icons.person_outline, 'Role', user.role[0].toUpperCase() + user.role.substring(1)),
                  const Divider(),
                  _buildProfileInfoRow(context, Icons.verified_user, 'Account Status', 'Active'),
                  if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) ...<Widget>[
                    const Divider(),
                    _buildProfileInfoRow(context, Icons.phone, 'Phone Number', user.phoneNumber!),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                _showSnackBar(context, 'Edit profile feature coming soon!');
              },
              icon: const Icon(Icons.edit),
              label: const Text('Edit Profile'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: <Widget>[
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 4),
                Text(value, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AppSettingsPage extends StatelessWidget {
  const AppSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'General Settings',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: Icon(Icons.notifications, color: Theme.of(context).colorScheme.primary),
                  title: const Text('Notifications'),
                  trailing: Switch(
                    value: true,
                    onChanged: (bool value) {
                      _showSnackBar(context, 'Notifications switched ${value ? 'on' : 'off'}');
                    },
                  ),
                ),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  leading: Icon(Icons.language, color: Theme.of(context).colorScheme.primary),
                  title: const Text('Language'),
                  trailing: DropdownButton<String>(
                    value: 'English',
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        _showSnackBar(context, 'Language changed to $newValue');
                      }
                    },
                    items: <String>['English', 'Spanish', 'French']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(value: value, child: Text(value));
                    }).toList(),
                  ),
                ),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  leading: Icon(Icons.security, color: Theme.of(context).colorScheme.primary),
                  title: const Text('Security'),
                  onTap: () {
                    _showSnackBar(context, 'Security settings opened!');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'About',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: <Widget>[
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Version'),
                  trailing: Text('1.0.0'),
                ),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  leading: Icon(Icons.description, color: Theme.of(context).colorScheme.primary),
                  title: const Text('Terms of Service'),
                  onTap: () => _showSnackBar(context, 'Terms of Service opened!'),
                ),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  leading: Icon(Icons.privacy_tip, color: Theme.of(context).colorScheme.primary),
                  title: const Text('Privacy Policy'),
                  onTap: () => _showSnackBar(context, 'Privacy Policy opened!'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ----------------------
/// Role-Specific Pages
/// ----------------------

class StudentCoursesPage extends StatelessWidget {
  final AppUser user;
  const StudentCoursesPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'My Courses',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: <Widget>[
                _buildCourseTile(context, 'Introduction to Programming', 'Dr. Smith', 'In Progress'),
                const Divider(indent: 16, endIndent: 16),
                _buildCourseTile(context, 'Calculus I', 'Prof. Johnson', 'Completed'),
                const Divider(indent: 16, endIndent: 16),
                _buildCourseTile(context, 'History of Art', 'Ms. Davis', 'Upcoming'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Enroll in New Courses',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.add_box),
                  title: const Text('Advanced Data Structures'),
                  subtitle: const Text('Available now'),
                  trailing: ElevatedButton(onPressed: () => _showSnackBar(context, 'Enrolling...'), child: const Text('Enroll')),
                ),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.add_box),
                  title: const Text('Machine Learning Fundamentals'),
                  subtitle: const Text('Starts next month'),
                  trailing: ElevatedButton(onPressed: () => _showSnackBar(context, 'Enrolling...'), child: const Text('Enroll')),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCourseTile(BuildContext context, String title, String teacher, String status) {
    return ListTile(
      leading: const Icon(Icons.book),
      title: Text(title),
      subtitle: Text('Teacher: $teacher'),
      trailing: Chip(label: Text(status)),
      onTap: () => _showSnackBar(context, 'Opened course: $title'),
    );
  }
}

/// ----------------------
/// Student Notifications Page
/// ----------------------
class StudentNotificationsPage extends StatelessWidget {
  final AppUser user;
  const StudentNotificationsPage({super.key, required this.user});

  String _formatNotificationTime(DateTime timestamp) {
    final Duration diff = DateTime.now().difference(timestamp);
    if (diff.inDays > 0) {
      return '${diff.inDays} days ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} hours ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} minutes ago';
    } else {
      return 'just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthService authService = context.watch<AuthService>();
    final List<NotificationItem> notifications = authService.getNotificationsForUser(user);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: Text(
            'Your Notifications',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Expanded(
          child: notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(Icons.notifications_off, size: 60, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No new notifications', style: Theme.of(context).textTheme.titleMedium),
                      Text('Check back later for updates!',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: notifications.length,
                  itemBuilder: (BuildContext context, int index) {
                    final NotificationItem notification = notifications[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: Icon(Icons.notifications_active, color: Theme.of(context).colorScheme.onPrimaryContainer),
                        ),
                        title: Text(
                          notification.message,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                            '${notification.senderName} • ${_formatNotificationTime(notification.timestamp)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
                        onTap: () {
                          _showSnackBar(context, 'Notification from ${notification.senderName}: ${notification.message}');
                        },
                      ),
                    );
                  },
                  separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 8),
                ),
        ),
      ],
    );
  }
}

class TeacherManagementPage extends StatefulWidget {
  final AppUser user;
  const TeacherManagementPage({super.key, required this.user});

  @override
  State<TeacherManagementPage> createState() => _TeacherManagementPageState();
}

class _TeacherManagementPageState extends State<TeacherManagementPage> {
  // Method to show notification sending dialog
  Future<void> _showSendNotificationDialog() async {
    final TextEditingController messageController = TextEditingController();
    String? selectedTargetRole = 'student'; // Default target for teachers

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Send New Notification'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: messageController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    hintText: 'Enter your notification message here...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedTargetRole,
                  decoration: const InputDecoration(
                    labelText: 'Target Audience',
                    prefixIcon: Icon(Icons.people),
                    border: OutlineInputBorder(),
                  ),
                  items: <String>['student', 'all'].map<DropdownMenuItem<String>>((String role) {
                    return DropdownMenuItem<String>(
                      value: role,
                      child: Text(role[0].toUpperCase() + role.substring(1) + (role == 'all' ? ' Users' : 's')),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    selectedTargetRole = value;
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (messageController.text.trim().isNotEmpty && selectedTargetRole != null) {
                  Navigator.of(dialogContext).pop(true);
                } else {
                  _showSnackBar(dialogContext, 'Please enter a message and select a target.');
                }
              },
              child: const Text('Send'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      if (!mounted) return;
      _showSnackBar(context, 'Sending notification...');
      final AuthService authService = context.read<AuthService>();
      await authService.sendNotification(
        senderName: widget.user.displayName,
        message: messageController.text.trim(),
        targetRole: selectedTargetRole!,
      );
      if (!mounted) return;
      _showSnackBar(context, 'Notification sent successfully!');
    }
    messageController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'My Classes',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: <Widget>[
                _buildClassTile(context, 'Introduction to Programming', 25),
                const Divider(indent: 16, endIndent: 16),
                _buildClassTile(context, 'Database Systems', 18),
                const Divider(indent: 16, endIndent: 16),
                _buildClassTile(context, 'Web Development Basics', 30),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Pending Tasks',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.assignment),
                  title: const Text('Grade Programming Assignments'),
                  subtitle: const Text('Due: End of week'),
                  trailing: ElevatedButton(onPressed: () => _showSnackBar(context, 'Grading...'), child: const Text('Grade')),
                ),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.message),
                  title: const Text('Respond to student emails'),
                  subtitle: const Text('5 unread'),
                  trailing: ElevatedButton(onPressed: () => _showSnackBar(context, 'Opening Inbox...'), child: const Text('View')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showSendNotificationDialog,
              icon: const Icon(Icons.send),
              label: const Text('Send New Notification'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassTile(BuildContext context, String className, int studentCount) {
    return ListTile(
      leading: const Icon(Icons.class_),
      title: Text(className),
      subtitle: Text('$studentCount Students'),
      trailing: IconButton(
        icon: const Icon(Icons.arrow_forward),
        onPressed: () => _showSnackBar(context, 'View class: $className'),
      ),
      onTap: () => _showSnackBar(context, 'Opened class: $className'),
    );
  }
}

class AdminManagementPage extends StatefulWidget {
  final AppUser user;
  const AdminManagementPage({super.key, required this.user});

  @override
  State<AdminManagementPage> createState() => _AdminManagementPageState();
}

class _AdminManagementPageState extends State<AdminManagementPage> {
  List<AppUser> _allUsers = <AppUser>[];
  bool _isLoadingUsers = false;

  @override
  void initState() {
    super.initState();
    _loadAllUsers();
  }

  Future<void> _loadAllUsers() async {
    setState(() => _isLoadingUsers = true);
    await Future<void>.delayed(const Duration(milliseconds: 700)); // Simulate network
    final AuthService authService = context.read<AuthService>();
    setState(() {
      _allUsers = authService.getAllUsers();
      _isLoadingUsers = false;
    });
  }

  Future<void> _deleteUser(String uid, String email, String displayName) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete user "$displayName" ($email)? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      _showSnackBar(context, 'Deleting $displayName...');
      final AuthService authService = context.read<AuthService>();
      authService.deleteUserByEmail(email); // Use the public delete method
      setState(() {
        _allUsers.removeWhere((AppUser user) => user.uid == uid);
      });
      _showSnackBar(context, '$displayName deleted successfully.');
    }
  }

  // Method to show notification sending dialog
  Future<void> _showSendNotificationDialog() async {
    final TextEditingController messageController = TextEditingController();
    String? selectedTargetRole = 'all'; // Default target for admins is 'all'

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Send New Notification'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: messageController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    hintText: 'Enter your notification message here...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedTargetRole,
                  decoration: const InputDecoration(
                    labelText: 'Target Audience',
                    prefixIcon: Icon(Icons.people),
                    border: OutlineInputBorder(),
                  ),
                  items: <String>['all', 'student', 'teacher', 'admin']
                      .map<DropdownMenuItem<String>>((String role) {
                    return DropdownMenuItem<String>(
                      value: role,
                      child: Text(role[0].toUpperCase() + role.substring(1) + (role == 'all' ? ' Users' : 's')),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    selectedTargetRole = value;
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (messageController.text.trim().isNotEmpty && selectedTargetRole != null) {
                  Navigator.of(dialogContext).pop(true);
                } else {
                  _showSnackBar(dialogContext, 'Please enter a message and select a target.');
                }
              },
              child: const Text('Send'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      if (!mounted) return;
      _showSnackBar(context, 'Sending notification...');
      final AuthService authService = context.read<AuthService>();
      await authService.sendNotification(
        senderName: widget.user.displayName,
        message: messageController.text.trim(),
        targetRole: selectedTargetRole!,
      );
      if (!mounted) return;
      _showSnackBar(context, 'Notification sent successfully!');
    }
    messageController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'User Management',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: _isLoadingUsers
                  ? const Center(child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ))
                  : Column(
                      children: _allUsers.map<Widget>((AppUser user) {
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(user.displayName[0]),
                          ),
                          title: Text(user.displayName),
                          subtitle: Text('${user.email} (${user.role})' + (user.phoneNumber != null && user.phoneNumber!.isNotEmpty ? ' / ${user.phoneNumber}' : '')),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteUser(user.uid, user.email, user.displayName),
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isLoadingUsers ? null : _loadAllUsers,
              icon: _isLoadingUsers
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.refresh),
              label: Text(_isLoadingUsers ? 'Loading Users...' : 'Refresh User List'),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'System Statistics',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: <Widget>[
                  _buildStatRow(context, Icons.people, 'Total Users', '${_allUsers.length}'),
                  const Divider(),
                  _buildStatRow(context, Icons.school, 'Total Courses', '15'),
                  const Divider(),
                  _buildStatRow(context, Icons.task, 'Active Sessions', '78'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showSendNotificationDialog,
              icon: const Icon(Icons.send),
              label: const Text('Send New Notification'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: <Widget>[
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          const Spacer(),
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
        ],
      ),
    );
  }
}

/// ----------------------
/// Home Page (simple) with Bottom Navigation
/// ----------------------
class HomePage extends StatefulWidget {
  final AppUser user;
  const HomePage({super.key, required this.user});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  bool _isLoadingRefresh = false; // Separate loading state for dashboard refresh

  late List<Widget> _pages; // Not final, as it's built dynamically
  late List<String> _pageTitles; // Not final, as it's built dynamically
  late List<BottomNavigationBarItem> _bottomNavBarItems; // Not final, as it's built dynamically

  @override
  void initState() {
    super.initState();
    _initializeRoleSpecificContent(widget.user.role);
  }

  // New method to initialize content based on role
  void _initializeRoleSpecificContent(String userRole) {
    _pageTitles = <String>[];
    _pages = <Widget>[];
    _bottomNavBarItems = <BottomNavigationBarItem>[];

    // Common pages for all users
    _pageTitles.add('Dashboard');
    _pages.add(UserDashboardPage(user: widget.user, onRefresh: _refreshDashboard, isLoading: _isLoadingRefresh));
    _bottomNavBarItems.add(const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'));

    _pageTitles.add('Profile');
    _pages.add(UserProfilePage(user: widget.user));
    _bottomNavBarItems.add(const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'));

    // Role-specific pages
    if (userRole == 'student') {
      _pageTitles.add('My Courses');
      _pages.add(StudentCoursesPage(user: widget.user));
      _bottomNavBarItems.add(const BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Courses'));
      // New: Student Notifications page
      _pageTitles.add('Notifications');
      _pages.add(StudentNotificationsPage(user: widget.user));
      _bottomNavBarItems.add(const BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Alerts'));
    } else if (userRole == 'teacher') {
      _pageTitles.add('Manage Classes');
      _pages.add(TeacherManagementPage(user: widget.user));
      _bottomNavBarItems.add(const BottomNavigationBarItem(icon: Icon(Icons.class_), label: 'Classes'));
    } else if (userRole == 'admin') {
      // Admin specific content, kept separate
      _pageTitles.add('Admin Panel');
      _pages.add(AdminManagementPage(user: widget.user));
      _bottomNavBarItems.add(const BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Admin'));
    }

    // Common settings page for all
    _pageTitles.add('Settings');
    _pages.add(const AppSettingsPage());
    _bottomNavBarItems.add(const BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'));

    // Reset selected index if the number of tabs changes or role changes
    // Only reset if current index is out of bounds for the new list, or if it makes sense to start over.
    if (_selectedIndex >= _pages.length) {
      _selectedIndex = 0;
    }
  }

  Future<void> _refreshDashboard() async {
    setState(() => _isLoadingRefresh = true);
    // In a real app, this would refresh user data or dashboard specific data
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    setState(() => _isLoadingRefresh = false);
    _showSnackBar(context, 'Dashboard data refreshed!');
    // Re-initialize the dashboard page to reflect potential refresh
    _pages[0] = UserDashboardPage(user: widget.user, onRefresh: _refreshDashboard, isLoading: _isLoadingRefresh);
  }

  Future<void> _signOut() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to log out of your account?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
              child: const Text('Logout', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      final AuthService authService = context.read<AuthService>();
      await authService.signOut();
      if (!mounted) return;
      _showSnackBar(context, 'Successfully logged out.');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-initialize content if the user object (specifically the role) changes.
    // Also, if _isLoadingRefresh changes, the dashboard page needs to be rebuilt,
    // which happens via _initializeRoleSpecificContent implicitly by passing the new isLoading state.
    if (widget.user.role != oldWidget.user.role) {
      _initializeRoleSpecificContent(widget.user.role);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant, // Added for "under color"
      appBar: AppBar(
        title: Text(_pageTitles[_selectedIndex]),
        actions: <Widget>[
          IconButton(onPressed: _signOut, icon: const Icon(Icons.logout)),
        ],
      ),
      body: PageTransitionSwitcher(
        transitionBuilder: (
          Widget child,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
        ) {
          return FadeThroughTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            child: child,
          );
        },
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: _bottomNavBarItems,
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
        onTap: _onItemTapped,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}