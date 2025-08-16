import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:real_estate_app/admin/admin_add_estate_plot_size.dart';
import 'package:real_estate_app/admin/admin_add_estate_plot_number.dart';
import 'admin/theme_provider.dart';

// Shared pages
import 'shared/onboarding.dart';
import 'shared/login.dart';
import 'shared/choose_role.dart';

// Admin side
import 'admin/admin_dashboard.dart';
import 'admin/admin_clients.dart';
import 'admin/admin_marketers.dart';
import 'admin/allocate_plot.dart';
import 'admin/add_estate.dart';
import 'admin/view_estate.dart';
import 'admin/add_estate_plots.dart';
import 'admin/register_client_marketer.dart';
// ignore: unused_import
import 'admin/admin_chat.dart';
import 'admin/admin_chat_list.dart';
import 'admin/send_notification.dart';
import 'admin/settings.dart';

// Others
import 'admin/others/estate_allocation_details.dart';
// import 'admin/others/edit_estate_plot.dart';

// Client side
import 'client/client_dashboard.dart';
import 'client/client_profile.dart';
import 'client/client_property_list.dart';
import 'client/client_request_property.dart';
import 'client/client_view_requests.dart';
import 'client/client_chat_admin.dart';
import 'client/property_details.dart';

// Marketer side
import 'marketer/marketer_dashboard.dart';
import 'marketer/marketer_clients.dart';
import 'marketer/marketer_commission.dart';
import 'marketer/marketer_notifications.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Real Estate Management System',

      // Default Light Theme (Muted Theme Mode)
      theme: ThemeData(
        fontFamily: '.SF Pro Text',
        brightness: Brightness.light,
      ),

      initialRoute: '/',
      routes: {
        '/': (context) => const DynamicLandingPage(),
        // '/': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/choose-role': (context) => const ChooseRoleScreen(),

        // Client side routes
        '/client-dashboard': (context) {
          final token = ModalRoute.of(context)?.settings.arguments as String?;
          return ClientDashboard(token: token ?? '');
        },
        '/client-profile': (context) {
          final token = ModalRoute.of(context)?.settings.arguments as String?;
          return ClientProfile(token: token ?? '');
        },

        '/client-property-list': (context) {
          final token = ModalRoute.of(context)?.settings.arguments as String?;
          return ClientPropertyList(token: token ?? '');
        },
        '/client-request-property': (context) {
          final token = ModalRoute.of(context)?.settings.arguments as String?;
          return ClientRequestProperty(token: token ?? '');
        },
        '/client-view-requests': (context) {
          final token = ModalRoute.of(context)?.settings.arguments as String?;
          return ClientViewRequests(token: token ?? '');
        },

        '/client-chat-admin': (context) {
          final token = ModalRoute.of(context)?.settings.arguments as String?;
          return ClientChatAdmin(token: token ?? '');
        },
        '/client-property-details': (context) {
          final token = ModalRoute.of(context)?.settings.arguments as String?;
          return PropertyDetailsPage(token: token ?? '');
        },

        // Admin side routes
        '/admin-dashboard': (context) {
          final token = ModalRoute.of(context)?.settings.arguments as String?;
          return token != null && token.isNotEmpty
              ? AdminDashboard(token: token)
              : const ErrorScreen();
        },
        '/admin-clients': (context) {
          final token = ModalRoute.of(context)?.settings.arguments as String?;
          return AdminClients(token: token ?? '');
        },
        '/admin-marketers': (context) {
          final token = ModalRoute.of(context)?.settings.arguments as String?;
          return AdminMarketers(token: token ?? '');
        },
        '/allocate-plot': (context) {
          final token = ModalRoute.of(context)?.settings.arguments as String?;
          return AllocatePlot(token: token ?? '');
        },
        '/add-plot-size': (context) {
          final token = ModalRoute.of(context)?.settings.arguments as String?;
          return AddEstatePlotSize(token: token ?? '');
        },
        '/add-plot-number': (context) {
          final token = ModalRoute.of(context)?.settings.arguments as String?;
          return AddEstatePlotNumber(token: token ?? '');
        },
        '/add-estate': (context) {
          final token = ModalRoute.of(context)?.settings.arguments as String?;
          return AddEstate(token: token ?? '');
        },
        '/view-estate': (context) {
          final token = ModalRoute.of(context)?.settings.arguments as String?;
          return token != null && token.isNotEmpty
              ? ViewEstate(token: token)
              : const ErrorScreen();
        },
        '/add-estate-plots': (context) {
          final token = ModalRoute.of(context)?.settings.arguments as String?;
          return AddEstatePlots(token: token ?? '');
        },
        '/register-client-marketer': (context) {
          final token = ModalRoute.of(context)?.settings.arguments as String?;
          return RegisterClientMarketer(token: token ?? '');
        },
        '/admin-chat-list': (context) {
          final token = ModalRoute.of(context)?.settings.arguments as String?;
          return AdminChatListScreen(token: token ?? '');
        },
        '/send-notification': (context) {
          final token = ModalRoute.of(context)?.settings.arguments as String?;
          return SendNotification(token: token ?? '');
        },
        '/admin-settings': (context) {
          final token = ModalRoute.of(context)?.settings.arguments as String?;
          return AdminSettings(token: token ?? '');
        },
        '/estate-allocation-details': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, String>?;
          return EstateAllocationDetails(
            token: args?['token'] ?? '',
            estateId: args?['estateId'] ?? '',
            estatePlot: args?['estatePlot'] ?? '',
          );
        },
        // '/edit-estate-plot': (context) {
        //   final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        //   if (args == null) {
        //     return const ErrorScreen();
        //   }
        //   return EditEstatePlotScreen(
        //     estatePlot: args['estatePlot'],
        //     token: args['token'] as String,
        //   );
        // },

        // Marketer side routes
        '/marketer-dashboard': (context) {
          final token = ModalRoute.of(context)?.settings.arguments as String?;
          return MarketerDashboard(token: token ?? '');
        },
        '/marketer-clients': (context) => const MarketerClients(),
        '/marketer-commission': (context) => const MarketerCommission(),
        '/marketer-notifications': (context) => const MarketerNotifications(),
      },
    );
  }
}

// Error screen for missing tokens
class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Error: No token provided. Please log in.',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
