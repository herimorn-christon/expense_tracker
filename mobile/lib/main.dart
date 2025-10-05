import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker_mobile/core/network/api_client.dart';
import 'package:expense_tracker_mobile/data/services/auth_service.dart';
import 'package:expense_tracker_mobile/data/services/expense_service.dart';
import 'package:expense_tracker_mobile/data/services/category_service.dart';
import 'package:expense_tracker_mobile/data/services/ai_service.dart';
import 'package:expense_tracker_mobile/data/services/dashboard_service.dart';
import 'package:expense_tracker_mobile/data/services/budget_service.dart';
import 'package:expense_tracker_mobile/presentation/providers/auth_provider.dart';
import 'package:expense_tracker_mobile/presentation/screens/login_screen.dart';
import 'package:expense_tracker_mobile/presentation/screens/dashboard_screen.dart';
import 'package:expense_tracker_mobile/presentation/viewmodels/expense_form_viewmodel.dart';
import 'package:expense_tracker_mobile/presentation/viewmodels/expense_list_viewmodel.dart';
import 'package:expense_tracker_mobile/presentation/viewmodels/ai_insights_viewmodel.dart';
import 'package:expense_tracker_mobile/presentation/viewmodels/category_viewmodel.dart';
import 'package:expense_tracker_mobile/presentation/viewmodels/dashboard_viewmodel.dart';
import 'package:expense_tracker_mobile/presentation/viewmodels/budget_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  const storage = FlutterSecureStorage();
  final apiClient = ApiClient(storage);

  final authService = AuthService(apiClient, storage);
  final expenseService = ExpenseService(apiClient);
  final categoryService = CategoryService(apiClient);
  final dashboardService = DashboardService(apiClient);
  final aiService = AIService(apiClient);
  final budgetService = BudgetService(apiClient);

  // Initialize providers
  final authProvider = AuthProvider(authService, storage);
  await authProvider.initialize();

  final expenseListViewModel = ExpenseListViewModel(expenseService, categoryService);
  final dashboardViewModel = DashboardViewModel(dashboardService);
  final aiInsightsViewModel = AIInsightsViewModel(aiService);
  final categoryViewModel = CategoryViewModel(categoryService);
  final budgetViewModel = BudgetViewModel(budgetService);

  final expenseFormViewModel = ExpenseFormViewModel(expenseService, categoryService);

  runApp(MyApp(
    authProvider: authProvider,
    authService: authService,
    expenseService: expenseService,
    categoryService: categoryService,
    dashboardService: dashboardService,
    budgetService: budgetService,
    aiService: aiService,
    expenseFormViewModel: expenseFormViewModel,
    expenseListViewModel: expenseListViewModel,
    dashboardViewModel: dashboardViewModel,
    aiInsightsViewModel: aiInsightsViewModel,
    categoryViewModel: categoryViewModel,
    budgetViewModel: budgetViewModel,
  ));
}

class MyApp extends StatelessWidget {
  final AuthProvider authProvider;
  final AuthService authService;
  final ExpenseService expenseService;
  final CategoryService categoryService;
  final DashboardService dashboardService;
  final BudgetService budgetService;
  final ExpenseFormViewModel expenseFormViewModel;
  final ExpenseListViewModel expenseListViewModel;
  final DashboardViewModel dashboardViewModel;
  final AIInsightsViewModel aiInsightsViewModel;
  final CategoryViewModel categoryViewModel;
  final BudgetViewModel budgetViewModel;
  final AIService aiService;

  const MyApp({
    super.key,
    required this.authProvider,
    required this.authService,
    required this.expenseService,
    required this.categoryService,
    required this.dashboardService,
    required this.budgetService,
    required this.aiService,
    required this.expenseFormViewModel,
    required this.expenseListViewModel,
    required this.dashboardViewModel,
    required this.aiInsightsViewModel,
    required this.categoryViewModel,
    required this.budgetViewModel,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        Provider<AuthService>.value(value: authService),
        Provider<ExpenseService>.value(value: expenseService),
        Provider<CategoryService>.value(value: categoryService),
        Provider<DashboardService>.value(value: dashboardService),
        Provider<BudgetService>.value(value: budgetService),
        Provider<AIService>.value(value: aiService),
        ChangeNotifierProvider<ExpenseFormViewModel>.value(value: expenseFormViewModel),
        ChangeNotifierProvider<ExpenseListViewModel>.value(value: expenseListViewModel),
        ChangeNotifierProvider<DashboardViewModel>.value(value: dashboardViewModel),
        ChangeNotifierProvider<AIInsightsViewModel>.value(value: aiInsightsViewModel),
        ChangeNotifierProvider<CategoryViewModel>.value(value: categoryViewModel),
        ChangeNotifierProvider<BudgetViewModel>.value(value: budgetViewModel),
      ],
      child: MaterialApp(
        title: 'Expense Tracker',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
            ),
          ),
        ),
        home: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            if (authProvider.isLoading) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (authProvider.isAuthenticated) {
              return const DashboardScreen();
            }

            return const LoginScreen();
          },
        ),
      ),
    );
  }
}
