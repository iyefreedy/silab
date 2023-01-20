import 'package:flutter/material.dart';
import 'package:silab/pages/admin/create_room_page.dart';
import 'package:silab/pages/admin/create_tool_page.dart';
import 'package:silab/pages/admin/edit_room_page.dart';
import 'package:silab/pages/admin/edit_tool_page.dart';
import 'package:silab/pages/admin/loans_page.dart';
import 'package:silab/pages/admin/pdf/create_damaged_tool_report_pdf.dart';
import 'package:silab/pages/admin/pdf/create_tool_report_pdf.dart';
import 'package:silab/pages/admin/pdf/create_loan_report_pdf.dart.dart';
import 'package:silab/pages/admin/pdf/create_room_report_pdf.dart';
import 'package:silab/pages/admin/report/damaged_tool_report.dart';
import 'package:silab/pages/admin/report/loan_report_page.dart';
import 'package:silab/pages/admin/report/room_report_page.dart';
import 'package:silab/pages/admin/report/tool_report_page.dart';
import 'package:silab/pages/admin/rooms_page.dart';
import 'package:silab/pages/admin/tools_page.dart';
import 'package:silab/pages/admin/users_page.dart';
import 'package:silab/pages/create_loan_page.dart';
import 'package:silab/pages/home_page.dart';
import 'package:silab/pages/user/tools_view.dart';

import '../constants/route_constants.dart';

Route<MaterialPageRoute> onGenerateRoute(RouteSettings settings) {
  switch (settings.name) {
    case homeRoute:
      return MaterialPageRoute(
        builder: (context) => const HomePage(),
        settings: settings,
      );

    case adminRoomsRoute:
      return MaterialPageRoute(
        builder: (context) => const RoomsPage(),
        settings: settings,
      );
    case adminCreateRoomRoute:
      return MaterialPageRoute(
        builder: (context) => const CreateRoomPage(),
        settings: settings,
      );
    case adminEditRoomRoute:
      return MaterialPageRoute(
        builder: (context) => const EditRoomPage(),
        settings: settings,
      );
    case adminToolsRoute:
      return MaterialPageRoute(
        builder: (context) => const ToolsPage(),
        settings: settings,
      );
    case adminCreateToolRoute:
      return MaterialPageRoute(
        builder: (context) => const CreateToolPage(),
        settings: settings,
      );
    case adminEditToolRoute:
      return MaterialPageRoute(
        builder: (context) => const EditToolPage(),
        settings: settings,
      );
    case createLoanRoute:
      return MaterialPageRoute(
        builder: (context) => const CreateLoanPage(),
        settings: settings,
      );
    case adminLoansRoute:
      return MaterialPageRoute(
        builder: (context) => const LoansPage(),
        settings: settings,
      );
    case adminUsersRoute:
      return MaterialPageRoute(
        builder: (context) => const UsersPage(),
        settings: settings,
      );
    case adminLoanReportRoute:
      return MaterialPageRoute(
        builder: (context) => const LoanReportPage(),
        settings: settings,
      );
    case adminToolReportRoute:
      return MaterialPageRoute(
        builder: (context) => const ToolReportPage(),
        settings: settings,
      );
    case adminDamagedToolReportRoute:
      return MaterialPageRoute(
        builder: (context) => const DamagedToolReport(),
        settings: settings,
      );
    case adminRoomReportRoute:
      return MaterialPageRoute(
        builder: (context) => const RoomReportPage(),
        settings: settings,
      );
    case pdfViewToolRoute:
      return MaterialPageRoute(
        builder: (context) => const CreateToolReportPdf(),
        settings: settings,
      );
    case pdfViewLoanRoute:
      return MaterialPageRoute(
        builder: (context) {
          LoanArgument args = settings.arguments as LoanArgument;

          return CreateLoanReportPdf(argument: args);
        },
        settings: settings,
      );
    case pdfViewDamagedToolRoute:
      return MaterialPageRoute(
        builder: (context) => const CreateDamagedToolReportPdf(),
        settings: settings,
      );
    case pdfViewRoomRoute:
      return MaterialPageRoute(
        builder: (context) => const CreateRoomReportPdfRoute(),
        settings: settings,
      );
    // Users
    case toolsRoute:
      return MaterialPageRoute(
        builder: (context) => const ToolsView(),
        settings: settings,
      );

    default:
      return MaterialPageRoute(
        builder: (context) => const Scaffold(
          body: Center(child: Text('Not Found')),
        ),
      );
  }
}

final routes = [
  // Admin
  homeRoute,
  adminRoomsRoute,
  adminCreateRoomRoute,
  adminEditRoomRoute,
  adminToolsRoute,
  adminCreateToolRoute,
  adminEditToolRoute,
  createLoanRoute,
  adminLoansRoute,
  adminUsersRoute,
  adminLoanReportRoute,
  adminToolReportRoute,
  adminDamagedToolReportRoute,
  adminRoomReportRoute,
  pdfViewLoanRoute,
  pdfViewRoomRoute,
  // Users
  toolsRoute,
];
