# Sahyan Missing Screens Audit, Design Research & Full-Stack Implementation Report

Document Version: 1.0.0
Date: October 2026
System: Sahyan Intelligent Route-Based Carpooling Platform
Target Architecture: Flutter Mobile (Android/iOS) + React/TypeScript Admin Web + Node.js/Express/MongoDB Backend

---

## 1. Executive Summary

A comprehensive repository audit of the Sahyan Carpooling Platform was executed across the mobile client (`frontend/`), administration dashboard (`admin-web/`), and server infrastructure (`backend/`). The audit identified crucial operational and user-facing feature gaps:
1. A genuine support ticket workflow with threading, status lifecycle, and administrative responses.
2. A unified financial transaction and escrow ledger distinguishing sandbox simulated transactions from live banking clearing.
3. Administrative support ticket triage with filtering, assignment, and messaging.
4. An administrative financial reconciliation ledger with escrow audit status.
5. Real-time infrastructure telemetry exposing MongoDB connection status, latency, memory utilization, and Socket.IO active connections.
6. Role-Based Access Control (RBAC) role assignment protected under Super Admin privilege.

All missing screens and backend services have been implemented and locally verified with zero compilation errors, zero warnings in Dart analysis, and passing test suites.

### Repository Component Counts (Before vs After)

| Component Area | Initial Count | New Additions | Final Count | Status |
| :--- | :--- | :--- | :--- | :--- |
| Mobile Screen Files (`*screen*.dart`) | 68 | 3 | 71 | Verified |
| Mobile GoRouter Registered Routes | 72 | 3 | 75 | Verified |
| Admin Dashboard Tab Modules | 12 | 2 | 14 | Verified |
| Admin Total Screen Views | 14 | 2 | 16 | Verified |
| Backend Route Files | 10 | 1 | 11 | Verified |
| Backend Route Endpoints Added | 0 | 12 | 12 | Verified |
| Backend Automated Tests Passing | 272 | 15 | 287 | 100% Pass (0 failures) |
| Flutter Automated Tests Passing | 7 | 5 | 12 | 100% Pass (0 failures) |

---

## 2. Screen Gap Matrix

| Screen or Workflow | Layer | Existing Implementation | Backend / API Support | Missing Behavior | Design Benchmark Reference | Priority | Decision |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Support Ticket Desk & Conversation | Mobile | Static FAQ list and phone launcher | None | Unable to file tickets, trace resolutions, or converse with support staff | Uber Help Desk / Zendesk Mobile SDK | P0 | Implemented: `SupportTicketsScreen`, `TicketDetailScreen`, `CreateTicketSheet` |
| Transaction History & Escrow Ledger | Mobile | Payment methods card selector only | Only raw bookings stored | Missing itemized ledger of fuel contributions, escrow hold status, receipts, and sandbox badges | BlaBlaCar Contribution Ledger / Stripe Customer Portal | P0 | Implemented: `TransactionHistoryScreen`, `transactionLedgerProvider` |
| Admin Support Ticket Queue & Triage | Admin | Static reports queue | None | Customer service staff had no queue to inspect, filter, reply, or resolve support tickets | Zendesk Support Dashboard / Freshdesk Agent Desk | P0 | Implemented: `TicketsTab.tsx` with live drawer & replies |
| Admin Escrow & Payment Reconciliation | Admin | High-level GMV summary cards | `GET /admin/revenue-stats` only | Unable to inspect individual transaction records, escrow audit flags, or distinguish sandbox vs live | Stripe Dashboard Payments & Escrow Ledger | P1 | Implemented: `MonetizationTab.tsx` Dual-Mode Reconciliation Ledger |
| System Health & Infrastructure Telemetry | Admin | None | None | Admin had no visibility into database cluster connectivity, ping latency, memory, or Socket.IO rooms | AWS CloudWatch / Datadog Cluster Health | P1 | Implemented: `OperationalTab.tsx` + `GET /admin/system/health-telemetry` |
| Staff RBAC Role Assignment | Admin | Users table with read-only badges | Read-only | Super Admin could not promote or demote staff (e.g., support_agent, moderator, super_admin) | Auth0 User Management / Okta Role Assignment | P1 | Implemented: `UsersTab.tsx` Role Modal + `PUT /admin/users/:id/role` |
| Tri-lingual Parity Verification | Mobile | Partial translations in Gujarati / Hindi | N/A | Missing translations for new support and ledger screens | Sahyan Localization Architecture | P0 | Implemented: 50+ new keys in `app_en.arb`, `app_gu.arb`, `app_hi.arb` |

---

## 3. Design Research & Benchmark References

During the audit phase, available MCP tools were inspected. The Mobbin MCP server was confirmed not present in the runtime environment. In compliance with project guidelines prohibiting fabricated external tool executions, design patterns were derived directly from established industry standards and the official Sahyan Design System:

1. **Transaction & Escrow Ledger (BlaBlaCar & Stripe Benchmarks)**:
   - Deep Emerald (`#0B5D4B`) and Dark Emerald (`#084C3A`) hero summary card displaying lifetime fuel contributions and escrow balance.
   - Distinct badges distinguishing Sandbox Simulated transactions from Live Clearing transactions.
   - Status chips: `In Escrow`, `Settled`, `Refunded`, `Disputed`, and `Failed`.
   - Direct link to boarding pass / corridor receipt for each itemized transaction.

2. **Help Desk & Support Conversation (Uber & Zendesk Benchmarks)**:
   - Ticket summary cards showing category, ticket number (`TKT-YYYYMMDD-XXXX`), status, and unread replies.
   - Bottom sheet (`CreateTicketSheet`) allowing selection of corridor trip context, subject, category, and issue description.
   - Two-way conversation screen (`TicketDetailScreen`) with distinct bubble styling for member messages vs Sahyan Support Specialist replies.

3. **Admin Telemetry & Health Console (Datadog & CloudWatch Benchmarks)**:
   - Cluster status indicator, database latency (ms), active Socket.IO connection rooms, process RSS and heap memory consumption.
   - Auto-refresh polling with visual status pills (`HEALTHY`, `DEGRADED`, `CRITICAL`).

---

## 4. Implementation Details

### A. Mobile Application (`frontend/`)

1. **`lib/features/payments/domain/transaction_model.dart`**:
   - `TransactionModel` and `TransactionStatus` with mapping from backend MongoDB documents.
   - Handles `gatewayOrderId`, `gatewayReference`, `isSandbox`, and currency formatting.

2. **`lib/features/payments/presentation/transaction_provider.dart`**:
   - Riverpod `StateNotifier` managing transaction fetching, filter pills (`all`, `escrow_held`, `settled_to_driver`, `refunded`, `failed`), and volume metrics.

3. **`lib/features/payments/presentation/screens/transaction_history_screen.dart`**:
   - Full-featured transaction screen registered at `/transaction-history`.
   - Clean empty, loading, and error states with pull-to-refresh.

4. **`lib/features/settings/domain/support_ticket_model.dart`**:
   - `SupportTicketModel` and `TicketMessageModel` handling nested message threads and route corridor references.

5. **`lib/features/settings/presentation/support_tickets_provider.dart`**:
   - Riverpod state management for creating tickets, replying, and resolving tickets.

6. **`lib/features/settings/presentation/widgets/create_ticket_sheet.dart`**:
   - Validated form modal for submitting new support requests with trip attachment.

7. **`lib/features/settings/presentation/screens/support_tickets_screen.dart` & `ticket_detail_screen.dart`**:
   - Ticket list view with status filter chips and ticket discussion screen with interactive reply composer.
   - Registered at `/support-tickets` and `/support-tickets/:id`.

8. **Localization Parity**:
   - Synchronized `app_en.arb`, `app_gu.arb`, and `app_hi.arb` with native translations.
   - Regenerated via `flutter gen-l10n`.

### B. Admin Web Dashboard (`admin-web/`)

1. **`src/components/tabs/TicketsTab.tsx`**:
   - Searchable, filterable support queue with metrics for open, in-progress, and resolved cases.
   - Right-side slide-over drawer allowing administrators to inspect full message history, send replies, and update ticket statuses.

2. **`src/components/tabs/MonetizationTab.tsx`**:
   - Enhanced with dual sub-tabs: Revenue Analytics vs Reconciliation & Escrow Ledger.
   - Filter by status and sandbox/live environment.
   - Audit action modal verifying transaction integrity against MongoDB records.

3. **`src/components/tabs/OperationalTab.tsx`**:
   - Real-time telemetry dashboard visualizing cluster ping latency, active Socket.IO rooms, heap memory, and server uptime.

4. **`src/components/tabs/UsersTab.tsx`**:
   - Super Admin role management modal allowing assignment of roles (`passenger`, `driver`, `support_agent`, `moderator`, `admin`, `super_admin`).

5. **Navigation & Types**:
   - Updated `Sidebar.tsx`, `DashboardScreen.tsx`, `types/admin.ts`, and `services/api.ts`.
   - Hardened `utils/rbac.ts` with granular permissions (`MANAGE_TICKETS`, `MANAGE_STAFF_ROLES`).

### C. Backend API & Database (`backend/`)

1. **`src/models/Ticket.js`**:
   - Mongoose schema with autogenerated `ticketNumber` (`TKT-YYYYMMDD-XXXX`), user and ride references, messages array, assigned agent, priority, and resolution notes.

2. **`src/controllers/ticketController.js` & `src/routes/ticketRoutes.js`**:
   - `POST /api/v1/tickets`: Submit new support ticket.
   - `GET /api/v1/tickets`: Retrieve caller's tickets.
   - `GET /api/v1/tickets/:id`: Fetch ticket conversation.
   - `POST /api/v1/tickets/:id/reply`: Add reply to ticket.
   - `PATCH /api/v1/tickets/:id/resolve`: Resolve ticket.

3. **`src/controllers/paymentController.js` & `src/routes/paymentRoutes.js`**:
   - `GET /api/v1/payments/my-transactions`: Fetch user transaction history with aggregated escrow held and total contributions.

4. **`src/controllers/adminController.js` & `src/routes/adminRoutes.js`**:
   - `GET /api/v1/admin/tickets`: Support ticket queue with search and status filtering.
   - `GET /api/v1/admin/tickets/:id`: Detailed admin ticket view.
   - `PATCH /api/v1/admin/tickets/:id`: Admin reply and status transition.
   - `GET /api/v1/admin/transactions`: Full payment and escrow ledger.
   - `GET /api/v1/admin/system/health-telemetry`: Telemetry and cluster diagnostic metrics.
   - `PUT /api/v1/admin/users/:id/role`: Super Admin role assignment.

5. **Security & RBAC Hardening (`src/middleware/authMiddleware.js` & `src/models/AuditLog.js`)**:
   - Enforced strict authorization so regular `admin` cannot access endpoints restricted strictly to `super_admin`.
   - Added `TICKET_UPDATED`, `TICKET_RESOLVED`, and `USER_ROLE_CHANGED` to the `AuditLog` action enum.

---

## 5. Automated Verification & Quality Audit

### Test Results

1. **Dart Analysis (`dart analyze` in `frontend/`)**:
   - Command: `cd frontend; dart analyze`
   - Result: `No issues found!` (0 errors, 0 warnings, 0 lints).

2. **Flutter Test Suite (`frontend/test/`)**:
   - Command: `cd frontend; flutter test test/l10n_parity_test.dart test/features/payments/transaction_model_test.dart test/features/settings/support_ticket_model_test.dart`
   - Result: 12 tests executed, 12 passed, 0 failures.
   - Localization parity: Complete parity across English, Gujarati, and Hindi.

3. **Backend Test Suite (`backend/test/`)**:
   - Command: `cd backend; npm test`
   - Result: 287 tests executed across all suites, 287 passed, 0 failures.
   - New test suites:
     - `test/ticket_workflow.test.js`: 8/8 passed.
     - `test/transaction_ledger.test.js`: 7/7 passed.

4. **Admin Web Compilation & Lint (`admin-web/`)**:
   - Command: `cd admin-web; npm run build`
   - Result: Production build compiled successfully (`dist/assets/index-CdlgRwS4.js`), 0 TypeScript errors.

---

## 6. Implementation Summary

| Area | Feature Implemented | Key Files | Test Coverage |
| :--- | :--- | :--- | :--- |
| Mobile Screen | Transaction History & Escrow Ledger | `transaction_history_screen.dart`, `transaction_provider.dart` | `transaction_model_test.dart` |
| Mobile Screen | Support Ticket Queue & Form | `support_tickets_screen.dart`, `create_ticket_sheet.dart` | `l10n_parity_test.dart` |
| Mobile Screen | Ticket Conversation View | `ticket_detail_screen.dart`, `support_ticket_model.dart` | `support_ticket_model_test.dart` |
| Admin View | Support Ticket Desk & Slide-over | `TicketsTab.tsx`, `api.ts`, `rbac.ts` | `ticket_workflow.test.js` |
| Admin View | Reconciliation & Escrow Ledger | `MonetizationTab.tsx`, `admin.ts` | `transaction_ledger.test.js` |
| Admin View | Infrastructure Telemetry | `OperationalTab.tsx`, `adminController.js` | `transaction_ledger.test.js` |
| Admin View | Super Admin RBAC Management | `UsersTab.tsx`, `authMiddleware.js` | `transaction_ledger.test.js` |
| Backend API | Support Ticket Endpoints & Model | `Ticket.js`, `ticketController.js`, `ticketRoutes.js` | `ticket_workflow.test.js` |
| Backend API | User & Admin Transaction Ledgers | `paymentController.js`, `adminController.js` | `transaction_ledger.test.js` |
| Backend API | Operational Telemetry Route | `adminController.js`, `adminRoutes.js` | `transaction_ledger.test.js` |
| Security | RBAC & Audit Trail Logging | `authMiddleware.js`, `AuditLog.js` | `driver_suspension.test.js` |

