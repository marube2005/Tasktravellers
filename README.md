# Travelers App - Software Product Documentation

Version: 1.0 (MVP)  
Date: 18 Oct 2025  
Product: Travelers App (Kenya)

## 1) Problem Statement

### 1.1 Core Problem
Kenya's PSV and sacco transport ecosystem lacks a trusted, real-time way to match passenger demand (especially group and remote-area travel) with available vehicles. Current coordination is often informal (calls, stage inquiries, WhatsApp, brokers), creating avoidable friction.

Key failures:
- Coordination failure for groups: no single place to confirm capacity, pricing, timing, and accountability.
- Availability and pricing uncertainty for remote travelers: inconsistent schedules and fare volatility.
- Trust and accountability gaps: passengers struggle to identify legitimate providers; providers face no-shows and disputes.

Travelers App addresses this through on-demand matching, provider verification, OTP-confirmed rides, and post-ride payment settlement.

### 1.2 Key Challenges
- Group travel coordination for students and event travelers.
- Remote and peri-urban access reliability.
- Low trust and weak accountability in existing informal workflows.
- No centralized demand-capacity matching layer for saccos and PSVs.

### 1.3 Target Users
- Primary: students (18-25), remote-area residents, event and group travelers.
- Secondary: sacco operators and PSV drivers seeking higher occupancy.
- Context: Kenya, mobile-first, smartphone users, intermittent connectivity.

## 2) Goals and Success Metrics

### 2.1 MVP Goals
- Enable on-demand matching between passengers and verified providers.
- Simplify group travel through pooling and invite sharing.
- Improve trust through verification and accountability features.
- Enable smooth post-ride settlement via PayHero.

### 2.2 Success Metrics
- Activation: signup + first search completion.
- Matching: time-to-match, match rate, cancellation rate.
- Group pooling: rides created, average group size, fill rate.
- Trust: disputes per 100 rides, verification completion rate.
- Payments: completion rate, failed payment rate, refund rate.
- Retention: 7-day and 30-day passenger retention.

## 3) Scope

### 3.1 In Scope (MVP)
- Passenger and sacco registration.
- Provider document submission and verification workflow.
- Ride search, on-demand matching, OTP confirmation.
- In-app chat basics.
- Real-time ride tracking and status updates.
- Post-ride PayHero payments.
- Notifications and safety basics (SOS, emergency contact).
- Limited offline behavior (cache recent searches and sync later).

### 3.2 Out of Scope (Post-MVP)
- Personal vehicle driver workflows.
- Advanced analytics and route optimization.
- Full web admin dashboard beyond Supabase/manual review tooling.
- International expansion.

### 3.3 Assumptions and Constraints
- Intermittent connectivity is expected.
- PSV operations require regulatory compliance (including NTSA-related docs).
- Payments remain post-ride in MVP to reduce prepayment friction.

## 4) Solution Overview

### 4.1 Value Proposition
- Passengers: affordable real-time rides for solo or group travel.
- Providers: improved occupancy and earnings via structured matching.

### 4.2 Differentiators
- Group pooling and invite-based coordination.
- On-demand matching (without reservation-heavy flows).
- Verification-driven trust layer.
- Post-ride cashless settlement via PayHero.

## 5) User Roles and Permissions

### 5.1 Roles
- Passenger (MVP): search, request, join/create groups, chat, track, rate, pay.
- Sacco operator (MVP): manage availability, accept/decline/counter offers, view earnings.
- Personal vehicle driver: future phase.

### 5.2 Access Control
- Role-based guards restrict provider dashboard features from passengers.
- Provider verification status controls badges and certain visibility/priority behavior.

## 6) User Journeys

### 6.1 Passenger Journeys
- Search and match: set route/time/group size, view options, confirm via OTP.
- Create group ride: create pool, share invite, trigger provider offers at minimum pax.
- Post-ride: rate provider and pay via PayHero.

### 6.2 Provider Journeys
- Registration and verification: submit sacco details/docs, await review.
- Accept and execute: receive nearby requests, accept/decline/counter, complete ride.

## 7) Requirements

### 7.1 Functional Requirements
- Role-based onboarding and verification.
- Ride discovery and real-time matching.
- Group pooling with invite links and minimum size logic.
- Provider dashboards for availability and request handling.
- In-app chat and ride lifecycle management.
- OTP confirmation and ride state transitions.
- Ratings/feedback and dispute basics.
- PayHero initiation and transaction state tracking.
- Notifications and safety actions (SOS, emergency contact).

### 7.2 Non-Functional Requirements
- Performance: fast search and low-latency updates.
- Reliability: stable realtime behavior with reconnect handling.
- Security: least privilege, secure document access, robust auth.
- Privacy: minimal PII exposure and retention controls.
- Scalability: support route/city growth with efficient queries.
- Accessibility: readable UI and low-friction flows.

## 8) Product Design Notes

### 8.1 Key MVP Screens
- Passenger Home/Search
- Create Group Ride
- Ride Results and Ride Details (tracking + chat)
- Sacco Dashboard (requests + availability)
- Profile and Verification Status
- Post-ride Payment + Rating

### 8.2 Edge Cases
- Network loss during matching or payment.
- Provider cancel after acceptance.
- Passenger no-show and disputes.
- Verification resubmission and suspicious activity review.
- Offline cache reconciliation on reconnect.

## 9) Technical Design

### 9.1 High-Level Architecture
- Mobile app: Flutter (Android, iOS, and Web support in current repo)
- Backend: Supabase (PostgreSQL, Auth, Realtime, Storage)
- Integrations: PayHero API, Google Maps APIs/SDKs
- Deployment: Supabase backend + app stores/web distribution

### 9.2 Core Components
| Component | Technology | Purpose |
| --- | --- | --- |
| Auth | Supabase Auth | Registration, login, sessions, roles |
| DB | Supabase PostgreSQL | Users, rides, validations, transactions |
| Realtime | Supabase Realtime | Matching updates and notifications |
| Storage | Supabase Storage | Verification document storage |
| Payments | PayHero | Post-ride settlement and commission |
| Maps | Google Maps | Geolocation, tracking, routing |

### 9.3 Minimum Data Models
- User
- VerificationDocument
- RideRequest
- GroupRide
- Offer
- Trip
- Transaction
- RatingReview
- DisputeReport

Each model must include explicit lifecycle states and audit fields where relevant.

### 9.4 API Surface (Examples)
- Supabase Auth flows (signup/login/session).
- Ride discovery with location radius filtering.
- Offer acceptance/counter actions.
- Payment initiation and transaction status updates.

## 10) Security, Privacy, and Trust
- JWT session management with Supabase Auth.
- RLS policies for strict data partitioning.
- Restricted visibility for verification documents.
- Action logging/audit trail for disputes and approvals.
- Data minimization and controlled retention.
- Verified provider badges, ratings, and reporting workflows.

## 11) Payments (PayHero)

### 11.1 Core Flow
- Ride completes.
- Passenger receives PayHero payment prompt (QR or deep link).
- App records transaction state and commission (target: 5%).

### 11.2 Failure and Refund Handling
- Retry flow for failed payments.
- Refund paths for clear, policy-backed cases.
- Manual review for complex disputes.

## 12) Delivery Plan

### 12.1 Milestones (Estimate)
- Design and wireframes: 2 weeks
- Backend setup: 3 weeks
- Frontend build: 4 weeks
- Testing and launch prep: 2 weeks
- Total: ~11 weeks

### 12.2 Ownership
- Product: scope, prioritization, acceptance criteria
- Engineering: architecture, implementation, security
- Design: UX/UI and usability testing
- QA: test plans and release gates
- Ops/Support: incident and user support readiness

## 13) Quality and Release

### 13.1 Test Strategy
- Unit tests for pricing, eligibility, and state transitions.
- Integration tests for auth, matching, and payment pathways.
- End-to-end tests for core user journeys.
- Security validation for RLS and document access controls.

### 13.2 Release Strategy
- Controlled beta pilot with selected users and partner saccos.
- Feature-flagged rollout for high-risk realtime/payment paths.
- Rollback plan for matching/payment incidents.

## 14) Operations
- Monitor match latency, failure rates, and payment success.
- Track disputes, verification SLAs, and incident trends.
- Maintain runbooks for realtime outages, callback failures, and fraud flags.

## 15) Risks and Mitigations
- Adoption risk: pilot with student groups and sacco partners.
- Verification bottlenecks: selective automation + manual final review.
- Payment friction: clear in-app guidance and fallback policy.
- Cost/scalability risk: index optimization and subscription governance.

## 16) Post-MVP Roadmap
- Personal vehicle driver role and verification.
- Smarter pricing and pooling optimization.
- Route suggestions and frequent rider loyalty features.
- Optional compliance data integrations where feasible.

## 17) Contact and Change Tracking
- Product/Support contact: add official support email.
- Feedback channel: in-app feedback form or support page.
- Change tracking: GitHub repository history and release notes.
