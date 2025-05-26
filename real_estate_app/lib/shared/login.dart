// import 'dart:math';
// import 'package:flutter/material.dart';

// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   _LoginScreenState createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
//   late AnimationController _bgController;
//   late Animation<Color?> _bgAnimation;
//   late AnimationController _particleController;
//   late List<Offset> _particles;

//   @override
//   void initState() {
//     super.initState();

//     // **🔹 Redirect to "Choose Role" Screen After Login**
//     Future.delayed(Duration(seconds: 2), () {
//       Navigator.pushReplacementNamed(context, '/choose-role');
//     });

//     // Background Animation
//     _bgController = AnimationController(
//       vsync: this,
//       duration: Duration(seconds: 6),
//     )..repeat(reverse: true);
    
//     _bgAnimation = ColorTween(
//       begin: Colors.blueGrey.shade900,
//       end: Colors.black,
//     ).animate(_bgController);

//     // Floating Particles
//     _particleController = AnimationController(
//       vsync: this,
//       duration: Duration(seconds: 4),
//     )..repeat(reverse: true);

//     _particles = List.generate(20, (index) {
//       return Offset(Random().nextDouble() * 400, Random().nextDouble() * 800);
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(
//       animation: _bgAnimation,
//       builder: (context, child) {
//         return Scaffold(
//           backgroundColor: _bgAnimation.value, // Animated background
//           body: Stack(
//             children: [
//               // Floating Particles
//               Positioned.fill(
//                 child: CustomPaint(
//                   painter: ParticlePainter(_particles, _particleController.value),
//                 ),
//               ),
              
//               Center(
//                 child: Container(
//                   width: 380,
//                   padding: EdgeInsets.all(20),
//                   decoration: BoxDecoration(
//                     color: Colors.white.withOpacity(0.1), // Glassmorphism effect
//                     borderRadius: BorderRadius.circular(20),
//                     border: Border.all(color: Colors.white.withOpacity(0.2)),
//                     boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20)],
//                   ),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Image.asset('assets/logo.png', height: 80), 
//                       SizedBox(height: 10),
//                       Text("Welcome to Lior & Eliora Properties",
//                           style: TextStyle(
//                               fontFamily: '.SF Pro Text',
//                               fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
//                       SizedBox(height: 10),

//                       // Email Field
//                       TextField(
//                         style: TextStyle(color: Colors.white),
//                         decoration: InputDecoration(
//                           labelText: "Email",
//                           labelStyle: TextStyle(color: Colors.white70),
//                           enabledBorder: UnderlineInputBorder(
//                             borderSide: BorderSide(color: Colors.white70),
//                           ),
//                           focusedBorder: UnderlineInputBorder(
//                             borderSide: BorderSide(color: Colors.blueAccent),
//                           ),
//                         ),
//                       ),
                      
//                       SizedBox(height: 10),

//                       // Password Field
//                       TextField(
//                         obscureText: true,
//                         style: TextStyle(color: Colors.white),
//                         decoration: InputDecoration(
//                           labelText: "Password",
//                           labelStyle: TextStyle(color: Colors.white70),
//                           enabledBorder: UnderlineInputBorder(
//                             borderSide: BorderSide(color: Colors.white70),
//                           ),
//                           focusedBorder: UnderlineInputBorder(
//                             borderSide: BorderSide(color: Colors.blueAccent),
//                           ),
//                         ),
//                       ),

//                       SizedBox(height: 20),

//                       // Login Button with Hover Animation
//                       MouseRegion(
//                         onEnter: (_) => setState(() {}),
//                         child: ElevatedButton(
//                           onPressed: () {
//                             Navigator.pushReplacementNamed(context, '/choose-role'); // ✅ Redirects to role selection
//                           },
//                           style: ElevatedButton.styleFrom(
//                             padding: EdgeInsets.symmetric(horizontal: 50, vertical: 12),
//                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
//                             backgroundColor: Colors.blueAccent,
//                             shadowColor: Colors.blue.withOpacity(0.5),
//                             elevation: 10,
//                           ),
//                           child: Text("Log In", style: TextStyle(fontSize: 18, color: Colors.white)),
//                         ),
//                       ),

//                       SizedBox(height: 10),

//                       // Forgot Password
//                       TextButton(
//                         onPressed: () {},
//                         child: Text("Forgot Password?", style: TextStyle(color: Colors.white70)),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   @override
//   void dispose() {
//     _bgController.dispose();
//     _particleController.dispose();
//     super.dispose();
//   }
// }

// // Floating Particles Animation
// class ParticlePainter extends CustomPainter {
//   final List<Offset> particles;
//   final double animationValue;

//   ParticlePainter(this.particles, this.animationValue);

//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()..color = Colors.white.withOpacity(0.2);
//     for (var i = 0; i < particles.length; i++) {
//       final Offset p = particles[i];
//       final double dx = p.dx + (sin(animationValue * 2 * pi) * 20);
//       final double dy = p.dy + (cos(animationValue * 2 * pi) * 20);
//       canvas.drawCircle(Offset(dx, dy), 3, paint);
//     }
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
// }



// File: lib/pages/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'package:real_estate_app/core/api_service.dart';
import 'package:real_estate_app/admin/admin_dashboard.dart';
import 'package:real_estate_app/client/client_dashboard.dart';
import 'package:real_estate_app/marketer/marketer_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1.0, curve: Curves.fastOutSlowIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _loading = true;
      });
      try {
        // Use the email field as username.
        String token = await ApiService()
            .login(_emailController.text.trim(), _passwordController.text);
        // Retrieve the user's profile to check their role.
        Map<String, dynamic> profile = await ApiService().getUserProfile(token);
        String role = profile['role'] ?? '';
        // Navigate to the corresponding dashboard based on role.
        if (role == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => AdminDashboard(token: token)),
          );
        } else if (role == 'client') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => ClientDashboard(token: token)),
          );
        } else if (role == 'marketer') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => MarketerDashboard(token: token)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User role is not defined.')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $e')),
        );
      } finally {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.shade800,
                  Colors.purple.shade600,
                ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: FadeTransition(
                  opacity: _opacityAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        margin: const EdgeInsets.all(24),
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Hero(
                                tag: 'app-logo',
                                child: Image.asset(
                                  'assets/logo.png',
                                  height: 80,
                                  width: 80,
                                ),
                              ),
                              const SizedBox(height: 30),
                              TextFormField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.email),
                                  labelText: 'Email',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: true,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.lock),
                                  labelText: 'Password',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 25),
                              _loading
                                  ? const CircularProgressIndicator()
                                  : AnimatedButton(
                                      onPressed: _handleLogin,
                                      animation: _controller,
                                    ),
                              const SizedBox(height: 20),
                              TextButton(
                                onPressed: () =>
                                    Navigator.pushNamed(context, '/forgot-password'),
                                child: Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    color: Colors.blue.shade800,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class AnimatedButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Animation<double> animation;

  const AnimatedButton({
    super.key,
    required this.onPressed,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.scale(
          scale: animation.value,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade800,
              padding:
                  const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 5,
              shadowColor: Colors.blue.shade200,
            ),
            child: const Text(
              'Sign In',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
}
