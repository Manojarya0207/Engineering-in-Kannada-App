import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart'; // Allowed package for custom fonts
import 'package:animations/animations.dart'; // Allowed package for transitions
import 'package:collection/collection.dart'; // Allowed package for extensions like firstWhereOrNull

/// ----------------------
/// Data Model for App User
/// ----------------------
class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String role;
  final String? phoneNumber;

  AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.phoneNumber,
  });

  /// Creates a new AppUser instance with updated fields.
  AppUser copyWith({
    String? displayName,
    String? email,
    String? phoneNumber,
  }) {
    return AppUser(
      uid: uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }
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

  // Mock database for registered users, keyed by email
  final Map<String, AppUser> _registeredUsers = <String, AppUser>{};
  int _nextUid = 1;
  int _nextNotificationId = 1;

  final List<NotificationItem> _notifications = <NotificationItem>[];
  List<NotificationItem> get notifications => List<NotificationItem>.unmodifiable(_notifications);

  // Map: userId -> set of userIds they follow
  final Map<String, Set<String>> _following = <String, Set<String>>{};
  // Map: userId -> set of userIds that follow them
  final Map<String, Set<String>> _followers = <String, Set<String>>{};

  // All available roles, including admin, for internal system use
  static const List<String> availableRoles = <String>['student', 'teacher', 'admin'];

  // Roles available for users to select during registration
  static List<String> get userSelectableRoles =>
      availableRoles.where((String role) => role != 'admin').toList();

  AuthService() {
    // Initialize with some mock users for demonstration
    final AppUser studentUser = AppUser(
      uid: 'mock-uid-1',
      email: 'test@example.com',
      displayName: 'Test Student',
      role: 'student',
      phoneNumber: '111-222-3333',
    );
    final AppUser teacherUser = AppUser(
      uid: 'mock-uid-2',
      email: 'teacher@example.com',
      displayName: 'Teacher Name',
      role: 'teacher',
      phoneNumber: '444-555-6666',
    );
    final AppUser adminUser = AppUser(
      uid: 'mock-uid-3',
      email: 'manojarya0207@gmail.com',
      displayName: 'manojarya0207',
      role: 'admin',
      phoneNumber: '777-888-9999',
    );
    final AppUser googleMockUser = AppUser(
      uid: 'mock-uid-google',
      email: 'google_mock_user@example.com',
      displayName: 'Google Mock User',
      role: 'student',
      phoneNumber: null,
    );

    _registeredUsers[studentUser.email] = studentUser;
    _registeredUsers[teacherUser.email] = teacherUser;
    _registeredUsers[adminUser.email] = adminUser;
    _registeredUsers[googleMockUser.email] = googleMockUser;
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

    // Initialize connection maps for mock users
    for (final AppUser user in _registeredUsers.values) {
      _ensureUserInConnections(user.uid);
    }

    // Example: Test Student follows Teacher
    _following['mock-uid-1']!.add('mock-uid-2');
    _followers['mock-uid-2']!.add('mock-uid-1');

    // Example: Admin follows Test Student
    _following['mock-uid-3']!.add('mock-uid-1');
    _followers['mock-uid-1']!.add('mock-uid-3');

    // Example: Teacher follows Google Mock User
    _following['mock-uid-2']!.add('mock-uid-google');
    _followers['mock-uid-google']!.add('mock-uid-2');
  }

  /// Helper to ensure a user's UID exists in the connections maps.
  void _ensureUserInConnections(String uid) {
    _following.putIfAbsent(uid, () => <String>{});
    _followers.putIfAbsent(uid, () => <String>{});
  }

  /// Register a new user with email and password.
  /// Returns an error message string if registration fails, null otherwise.
  Future<String?> registerWithEmail({
    required String email,
    required String password,
    required String name,
    required String role,
    required String? phoneNumber,
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
      phoneNumber: phoneNumber,
    );
    _registeredUsers[email] = newUser;
    _currentUser = newUser;
    _ensureUserInConnections(newUser.uid); // Initialize connection sets for new user
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
        phoneNumber: null,
      );
      _registeredUsers[mockEmail] = user;
      _ensureUserInConnections(user.uid); // Initialize connection sets for new user
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

  /// Updates the profile of a user.
  Future<String?> updateUserProfile({
    required String uid,
    String? displayName,
    String? email,
    String? phoneNumber,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    final AppUser? existingUser =
        _registeredUsers.values.firstWhereOrNull((AppUser user) => user.uid == uid);

    if (existingUser == null) {
      return 'User not found.';
    }

    // If email is changing, check for conflicts with other users
    if (email != null && email != existingUser.email && _registeredUsers.containsKey(email)) {
      return 'Email already taken by another user.';
    }

    final AppUser updatedUser = existingUser.copyWith(
      displayName: displayName,
      email: email,
      phoneNumber: phoneNumber,
    );

    // If email changed, remove the old entry and add with the new email as key
    if (email != null && email != existingUser.email) {
      _registeredUsers.remove(existingUser.email);
      _registeredUsers[email] = updatedUser;
    } else {
      // Update existing entry (replace AppUser object)
      _registeredUsers[existingUser.email] = updatedUser;
    }

    // Update current user if it's the one being edited
    if (_currentUser?.uid == uid) {
      _currentUser = updatedUser;
    }
    notifyListeners();
    return null;
  }

  /// Follows a target user.
  Future<String?> followUser({required String followerUid, required String targetUid}) async {
    if (followerUid == targetUid) return 'Cannot follow yourself.';
    if (!_registeredUsers.values.any((AppUser u) => u.uid == followerUid)) return 'Follower user not found.';
    if (!_registeredUsers.values.any((AppUser u) => u.uid == targetUid)) return 'Target user not found.';

    await Future<void>.delayed(const Duration(milliseconds: 300));
    _ensureUserInConnections(followerUid);
    _ensureUserInConnections(targetUid);

    final bool added = _following[followerUid]!.add(targetUid);
    if (added) {
      _followers[targetUid]!.add(followerUid);
      notifyListeners();
    }
    return null;
  }

  /// Unfollows a target user.
  Future<String?> unfollowUser({required String followerUid, required String targetUid}) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _ensureUserInConnections(followerUid);
    _ensureUserInConnections(targetUid);

    final bool removed = _following[followerUid]!.remove(targetUid);
    if (removed) {
      _followers[targetUid]!.remove(followerUid);
      notifyListeners();
    }
    return null;
  }

  /// Gets the UIDs of users that a given user is following.
  Set<String> getFollowingUids(String uid) {
    _ensureUserInConnections(uid);
    return Set<String>.unmodifiable(_following[uid]!);
  }

  /// Gets the UIDs of users who are following a given user.
  Set<String> getFollowerUids(String uid) {
    _ensureUserInConnections(uid);
    return Set<String>.unmodifiable(_followers[uid]!);
  }

  /// Helper to get AppUser objects from a set of UIDs.
  List<AppUser> getUsersFromUids(Set<String> uids) {
    return _registeredUsers.values.where((AppUser user) => uids.contains(user.uid)).toList();
  }

  /// For admin purposes: get a list of all registered users.
  List<AppUser> getAllUsers() {
    return _registeredUsers.values.toList();
  }

  /// For admin purposes: delete a user by email.
  void deleteUserByEmail(String email) {
    final AppUser? userToDelete = _registeredUsers[email];
    if (userToDelete == null) return;

    _registeredUsers.remove(email);

    // Clean up followers/following data
    _following.remove(userToDelete.uid);
    _followers.remove(userToDelete.uid);
    for (final Set<String> uids in _following.values) {
      uids.remove(userToDelete.uid);
    }
    for (final Set<String> uids in _followers.values) {
      uids.remove(userToDelete.uid);
    }

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
              headlineMedium: GoogleFonts.lato(
                textStyle: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 24), // Reduced from ~28
                fontWeight: FontWeight.bold,
              ),
              headlineSmall: GoogleFonts.lato(
                textStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 20), // Reduced from ~24
                fontWeight: FontWeight.bold,
              ),
              titleLarge: GoogleFonts.lato(
                textStyle: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18), // Reduced from ~22
                fontWeight: FontWeight.bold,
              ),
              titleMedium: GoogleFonts.lato(
                textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14), // Reduced from ~16
              ),
              titleSmall: GoogleFonts.lato(
                textStyle: Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 12), // Reduced from ~14
              ),
              bodyLarge: GoogleFonts.lato(
                textStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 14), // Reduced from ~16
              ),
              bodyMedium: GoogleFonts.lato(
                textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12), // Reduced from ~14
              ),
              bodySmall: GoogleFonts.lato(
                textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10), // Reduced from ~12
              ),
              labelLarge: GoogleFonts.lato(
                textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 12), // Reduced from ~14
              ),
              labelMedium: GoogleFonts.lato(
                textStyle: Theme.of(context).textTheme.labelMedium?.copyWith(fontSize: 10), // Reduced from ~12
              ),
              labelSmall: GoogleFonts.lato(
                textStyle: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 9), // Reduced from ~11
              ),
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: colorScheme.inversePrimary,
              foregroundColor: colorScheme.onPrimaryContainer,
              // Potentially adjust title text style here if needed, but it should pick up titleLarge
              titleTextStyle: GoogleFonts.lato(
                textStyle: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
                color: colorScheme.onPrimaryContainer,
              ),
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
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16), // Reduced vertical padding
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14), // Reduced vertical padding
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), // Reduced font size
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14), // Reduced vertical padding
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), // Reduced font size
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
                        child: Text('Don\'t have an account? Register here.', style: Theme.of(context).textTheme.bodyMedium), // Adjusted from hardcoded 14
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
  final TextEditingController _phoneCtrl = TextEditingController();
  String _role = AuthService.userSelectableRoles.first;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _passCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final String name = _nameCtrl.text.trim();
    final String email = _emailCtrl.text.trim();
    final String pass = _passCtrl.text.trim();
    final String phone = _phoneCtrl.text.trim();

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
      phoneNumber: phone,
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
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
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
                        controller: _phoneCtrl,
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
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.event),
                  title: Text('Team Meeting', style: Theme.of(context).textTheme.bodyLarge),
                  subtitle: Text('Tomorrow, 10:00 AM', style: Theme.of(context).textTheme.bodySmall),
                  trailing: Chip(label: Text('High', style: Theme.of(context).textTheme.labelMedium)),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.assignment),
                  title: Text('Project Alpha Submission', style: Theme.of(context).textTheme.bodyLarge),
                  subtitle: Text('Next Friday', style: Theme.of(context).textTheme.bodySmall),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.school),
                  title: Text('New Course: Advanced AI', style: Theme.of(context).textTheme.bodyLarge),
                  subtitle: Text('Starts next month', style: Theme.of(context).textTheme.bodySmall),
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
/// Edit Profile Page (New)
/// ----------------------
class EditProfilePage extends StatefulWidget {
  final AppUser user;
  const EditProfilePage({super.key, required this.user});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController _displayNameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _displayNameCtrl = TextEditingController(text: widget.user.displayName);
    _emailCtrl = TextEditingController(text: widget.user.email);
    _phoneCtrl = TextEditingController(text: widget.user.phoneNumber ?? '');
  }

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final String newDisplayName = _displayNameCtrl.text.trim();
    final String newEmail = _emailCtrl.text.trim();
    final String newPhoneNumber = _phoneCtrl.text.trim();

    if (newDisplayName.isEmpty || newEmail.isEmpty) {
      if (!mounted) return;
      return _showSnackBar(context, 'Display Name and Email cannot be empty.');
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(newEmail)) {
      if (!mounted) return;
      return _showSnackBar(context, 'Please enter a valid email address.');
    }

    setState(() => _loading = true);
    final AuthService authService = context.read<AuthService>();
    final String? error = await authService.updateUserProfile(
      uid: widget.user.uid,
      displayName: newDisplayName,
      email: newEmail,
      phoneNumber: newPhoneNumber.isNotEmpty ? newPhoneNumber : null,
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      _showSnackBar(context, error);
    } else {
      _showSnackBar(context, 'Profile updated successfully!');
      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    controller: _displayNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Display Name',
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
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number (Optional)',
                      prefixIcon: Icon(Icons.phone),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _saveProfile,
                      child: _loading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ----------------------
/// User Connections Page (New)
/// ----------------------
class UserConnectionsPage extends StatefulWidget {
  final AppUser user;
  const UserConnectionsPage({super.key, required this.user});

  @override
  State<UserConnectionsPage> createState() => _UserConnectionsPageState();
}

class _UserConnectionsPageState extends State<UserConnectionsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchCtrl.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchCtrl.text.trim().toLowerCase();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AuthService authService = context.watch<AuthService>();
    final List<AppUser> allUsers = authService.getAllUsers();
    final Set<String> followingUids = authService.getFollowingUids(widget.user.uid);
    final Set<String> followerUids = authService.getFollowerUids(widget.user.uid);

    final List<AppUser> followingUsers = authService.getUsersFromUids(followingUids);
    final List<AppUser> followersUsers = authService.getUsersFromUids(followerUids);

    // Filter users for search based on display name or email
    final List<AppUser> searchableUsers = allUsers
        .where((AppUser user) =>
            user.uid != widget.user.uid &&
            (user.displayName.toLowerCase().contains(_searchQuery) ||
                user.email.toLowerCase().contains(_searchQuery)))
        .toList();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      appBar: AppBar(
        title: const Text('Connections'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const <Tab>[
            Tab(text: 'Following'),
            Tab(text: 'Followers'),
          ],
        ),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                labelText: 'Search users to follow',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            Expanded(
              child: searchableUsers.isEmpty
                  ? Center(
                      child: Text(
                        'No users found for "$_searchQuery".',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    )
                  : ListView.builder(
                      itemCount: searchableUsers.length,
                      itemBuilder: (BuildContext context, int index) {
                        final AppUser targetUser = searchableUsers[index];
                        final bool isFollowing = followingUids.contains(targetUser.uid);
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                          child: ListTile(
                            leading: CircleAvatar(child: Text(targetUser.displayName[0], style: Theme.of(context).textTheme.labelLarge)),
                            title: Text(targetUser.displayName, style: Theme.of(context).textTheme.bodyLarge),
                            subtitle: Text(targetUser.email, style: Theme.of(context).textTheme.bodySmall),
                            trailing: isFollowing
                                ? OutlinedButton(
                                    onPressed: () async {
                                      final String? error = await authService.unfollowUser(
                                          followerUid: widget.user.uid, targetUid: targetUser.uid);
                                      if (!mounted) return;
                                      if (error != null) _showSnackBar(context, error);
                                    },
                                    child: const Text('Unfollow'),
                                  )
                                : ElevatedButton(
                                    onPressed: () async {
                                      final String? error = await authService.followUser(
                                          followerUid: widget.user.uid, targetUid: targetUser.uid);
                                      if (!mounted) return;
                                      if (error != null) _showSnackBar(context, error);
                                    },
                                    child: const Text('Follow'),
                                  ),
                          ),
                        );
                      },
                    ),
            )
          else
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: <Widget>[
                  _buildConnectionList(context, followingUsers, 'No one followed yet.'),
                  _buildConnectionList(context, followersUsers, 'No followers yet.'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConnectionList(BuildContext context, List<AppUser> users, String emptyMessage) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.person_off, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(emptyMessage, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      );
    }
    final AuthService authService = context.read<AuthService>();
    final Set<String> followingUids = authService.getFollowingUids(widget.user.uid);

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (BuildContext context, int index) {
        final AppUser connectionUser = users[index];
        final bool isFollowing = followingUids.contains(connectionUser.uid);
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: ListTile(
            leading: CircleAvatar(child: Text(connectionUser.displayName[0], style: Theme.of(context).textTheme.labelLarge)),
            title: Text(connectionUser.displayName, style: Theme.of(context).textTheme.bodyLarge),
            subtitle: Text(connectionUser.email, style: Theme.of(context).textTheme.bodySmall),
            trailing: connectionUser.uid == widget.user.uid // Don't show button for self
                ? null
                : isFollowing
                    ? OutlinedButton(
                        onPressed: () async {
                          final String? error = await authService.unfollowUser(
                              followerUid: widget.user.uid, targetUid: connectionUser.uid);
                          if (!mounted) return;
                          if (error != null) _showSnackBar(context, error);
                        },
                        child: const Text('Unfollow'),
                      )
                    : ElevatedButton(
                        onPressed: () async {
                          final String? error = await authService.followUser(
                              followerUid: widget.user.uid, targetUid: connectionUser.uid);
                          if (!mounted) return;
                          if (error != null) _showSnackBar(context, error);
                        },
                        child: const Text('Follow'),
                      ),
            onTap: () {
              // Optionally navigate to connectionUser's profile
              _showSnackBar(context, 'View profile for ${connectionUser.displayName}');
            },
          ),
        );
      },
    );
  }
}

class UserProfilePage extends StatelessWidget {
  final AppUser user;

  const UserProfilePage({super.key, required this.user});

  void _navigateToEditProfile(BuildContext context, AppUser user) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => EditProfilePage(user: user),
      ),
    );
  }

  void _navigateToConnections(BuildContext context, AppUser user) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => UserConnectionsPage(user: user),
      ),
    );
  }

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
              onPressed: () => _navigateToEditProfile(context, user),
              icon: const Icon(Icons.edit),
              label: const Text('Edit Profile'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _navigateToConnections(context, user),
              icon: const Icon(Icons.people),
              label: const Text('Manage Connections'),
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
  final VoidCallback onLogout; // New: Callback for logout button
  const AppSettingsPage({super.key, required this.onLogout});

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
                  title: Text('Notifications', style: Theme.of(context).textTheme.bodyLarge),
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
                  title: Text('Language', style: Theme.of(context).textTheme.bodyLarge),
                  trailing: DropdownButton<String>(
                    value: 'English',
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        _showSnackBar(context, 'Language changed to $newValue');
                      }
                    },
                    items: <String>['English', 'Spanish', 'French']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(value: value, child: Text(value, style: Theme.of(context).textTheme.bodyMedium));
                    }).toList(),
                  ),
                ),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  leading: Icon(Icons.security, color: Theme.of(context).colorScheme.primary),
                  title: Text('Security', style: Theme.of(context).textTheme.bodyLarge),
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
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text('Version', style: Theme.of(context).textTheme.bodyLarge),
                  trailing: Text('1.0.0', style: Theme.of(context).textTheme.bodyMedium),
                ),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  leading: Icon(Icons.description, color: Theme.of(context).colorScheme.primary),
                  title: Text('Terms of Service', style: Theme.of(context).textTheme.bodyLarge),
                  onTap: () => _showSnackBar(context, 'Terms of Service opened!'),
                ),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  leading: Icon(Icons.privacy_tip, color: Theme.of(context).colorScheme.primary),
                  title: Text('Privacy Policy', style: Theme.of(context).textTheme.bodyLarge),
                  onTap: () => _showSnackBar(context, 'Privacy Policy opened!'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30), // Added spacing before logout button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onLogout, // Call the logout callback
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
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
                  title: Text('Advanced Data Structures', style: Theme.of(context).textTheme.bodyLarge),
                  subtitle: Text('Available now', style: Theme.of(context).textTheme.bodySmall),
                  trailing: ElevatedButton(onPressed: () => _showSnackBar(context, 'Enrolling...'), child: const Text('Enroll')),
                ),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.add_box),
                  title: Text('Machine Learning Fundamentals', style: Theme.of(context).textTheme.bodyLarge),
                  subtitle: Text('Starts next month', style: Theme.of(context).textTheme.bodySmall),
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
      title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
      subtitle: Text('Teacher: $teacher', style: Theme.of(context).textTheme.bodySmall),
      trailing: Chip(label: Text(status, style: Theme.of(context).textTheme.labelMedium)),
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
          title: Text('Send New Notification', style: Theme.of(dialogContext).textTheme.titleLarge),
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
                      child: Text(role[0].toUpperCase() + role.substring(1) + (role == 'all' ? ' Users' : 's'), style: Theme.of(dialogContext).textTheme.bodyMedium),
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
                  title: Text('Grade Programming Assignments', style: Theme.of(context).textTheme.bodyLarge),
                  subtitle: Text('Due: End of week', style: Theme.of(context).textTheme.bodySmall),
                  trailing: ElevatedButton(onPressed: () => _showSnackBar(context, 'Grading...'), child: const Text('Grade')),
                ),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.message),
                  title: Text('Respond to student emails', style: Theme.of(context).textTheme.bodyLarge),
                  subtitle: Text('5 unread', style: Theme.of(context).textTheme.bodySmall),
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
      title: Text(className, style: Theme.of(context).textTheme.bodyLarge),
      subtitle: Text('$studentCount Students', style: Theme.of(context).textTheme.bodySmall),
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
          title: Text('Confirm Deletion', style: Theme.of(dialogContext).textTheme.titleLarge),
          content: Text('Are you sure you want to delete user "$displayName" ($email)? This action cannot be undone.', style: Theme.of(dialogContext).textTheme.bodyMedium),
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
          title: Text('Send New Notification', style: Theme.of(dialogContext).textTheme.titleLarge),
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
                      child: Text(role[0].toUpperCase() + role.substring(1) + (role == 'all' ? ' Users' : 's'), style: Theme.of(dialogContext).textTheme.bodyMedium),
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
                            child: Text(user.displayName[0], style: Theme.of(context).textTheme.labelLarge),
                          ),
                          title: Text(user.displayName, style: Theme.of(context).textTheme.bodyLarge),
                          subtitle: Text('${user.email} (${user.role})' + (user.phoneNumber != null && user.phoneNumber!.isNotEmpty ? ' / ${user.phoneNumber}' : ''), style: Theme.of(context).textTheme.bodySmall),
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
    // Ensure the UserProfilePage receives the latest user data via the provider.
    // The profile page will now watch for user changes itself if needed,
    // or rely on its parent (HomePage) being rebuilt.
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
    _pages.add(AppSettingsPage(onLogout: _signOut)); // Pass the signOut callback here
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
          title: Text('Confirm Logout', style: Theme.of(dialogContext).textTheme.titleLarge),
          content: Text('Are you sure you want to log out of your account?', style: Theme.of(dialogContext).textTheme.bodyMedium),
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
    // Re-initialize content if the user object (specifically the role or any part of user) changes.
    // Since AppUser is immutable, any change means a new instance, so direct comparison `widget.user != oldWidget.user` would be enough.
    // However, specifically checking role also works. More robust to rebuild pages with current user data.
    if (widget.user.role != oldWidget.user.role || widget.user.uid != oldWidget.user.uid) {
      _initializeRoleSpecificContent(widget.user.role);
    } else {
      // Even if the user object itself has changed (e.g., display name updated), but role is same,
      // the existing _pages list might still hold old user references.
      // Rebuilding just the `UserProfilePage` and `UserDashboardPage` if the user object itself is new.
      // The `_initializeRoleSpecificContent` already rebuilds all pages.
      // So, if the user object changes, even without role change, a full re-init is necessary to pass the new user to sub-pages.
      // Alternatively, the sub-pages could `context.watch<AuthService>().currentUser` directly.
      // For consistency, let's keep the _initializeRoleSpecificContent call here.
      // Given that `didUpdateWidget` is called only if the *parent* widget's properties change,
      // and `HomePage` itself gets a new `user` if `AuthGate` rebuilds it with a new `currentUser`,
      // `_initializeRoleSpecificContent` should be called.
      // Let's refine `_initializeRoleSpecificContent` to ensure `UserDashboardPage` and `UserProfilePage` always get `widget.user`.
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
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                // Navigate to Profile page (index 1) when avatar is tapped
                setState(() {
                  _selectedIndex = 1;
                });
              },
              child: CircleAvatar(
                radius: 20,
                backgroundImage: const NetworkImage('https://www.gstatic.com/flutter-onestack-prototype/genui/example_1.jpg'), // Placeholder image
                backgroundColor: Theme.of(context).colorScheme.primary, // Fallback background
              ),
            ),
          ),
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
        selectedLabelStyle: Theme.of(context).textTheme.labelLarge, // Ensure label style is consistent
        unselectedLabelStyle: Theme.of(context).textTheme.labelMedium, // Ensure label style is consistent
      ),
    );
  }
}