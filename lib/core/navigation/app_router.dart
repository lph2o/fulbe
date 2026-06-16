// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import '../../features/home/create_post_screen.dart';
import '../../features/home/feed_screen.dart';
import '../../features/home/bookmarks_screen.dart';
import '../../features/profile/edit_profile_screen.dart';
import '../../features/profile/followers_list_screen.dart';
import '../../features/profile/profile_screen.dart' show PublicProfileScreen;
import '../../features/events/create_event_screen.dart';
import '../../features/events/event_detail_screen.dart';
import '../../features/events/my_events_screen.dart';
import '../../features/events/ticket_history_screen.dart';
import '../../core/data/models/chapter.dart';
import '../../core/data/models/event.dart';
import '../../features/chapter/chapter_detail_screen.dart';
import '../../features/jobs/create_job_screen.dart';
import '../../features/marketplace/create_service_screen.dart';
import 'package:flutter/material.dart';
import '../../features/onboarding/welcome_screen.dart';
import '../../features/onboarding/auth_gate.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/library/library_screen.dart';
import '../../features/jobs/jobs_screen.dart';
import '../../features/finances/finances_screen.dart';
import '../../features/learning/learning_screen.dart';
import '../../features/messages/messages_screen.dart';
import '../../features/messages/incoming_call_screen.dart';
import '../../features/messages/outgoing_call_screen.dart';
import '../../features/messages/active_call_screen.dart';
import '../../features/messages/group_incoming_call_screen.dart';
import '../../features/messages/group_outgoing_call_screen.dart';
import '../../features/messages/group_active_call_screen.dart';
import '../../core/services/call_service.dart';
import '../../core/services/group_call_service.dart';
import '../../features/events/events_screen.dart';
import '../../features/marketplace/marketplace_screen.dart';
import '../navigation/main_shell.dart';

abstract class AppRoutes {
  static const authGate = '/';
  static const welcome = '/welcome';
  static const auth = '/auth';
  static const home = '/home';
  static const feed = '/feed';
  static const map = '/map';
  static const directory = '/directory';
  static const marketplace = '/marketplace';
  static const profile = '/profile';
  static const editProfile = '/edit-profile';
  static const publicProfile = '/public-profile';
  static const library = '/library';
  static const jobs = '/jobs';
  static const finances = '/finances';
  static const learn = '/learn';
  static const messages = '/messages';
  static const events = '/events';
  static const createPost = '/create-post';
  static const createEvent = '/create-event';
  static const eventDetail = '/event-detail';
  static const myEvents = '/my-events';
  static const ticketHistory = '/ticket-history';
  static const createJob = '/create-job';
  static const createService = '/create-service';
  static const chapterDetail = '/chapter-detail';
  static const bookmarks = '/bookmarks';
  static const followersList = '/followers-list';
  static const incomingCall = '/incoming-call';
  static const outgoingCall = '/outgoing-call';
  static const activeCall = '/active-call';
  static const groupIncomingCall = '/group-incoming-call';
  static const groupOutgoingCall = '/group-outgoing-call';
  static const groupActiveCall = '/group-active-call';
}

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case AppRoutes.authGate:
      return _fadeRoute(AuthGate());
    case AppRoutes.welcome:
      return _fadeRoute(WelcomeScreen());
    case AppRoutes.auth:
      return _fadeRoute(AuthScreen());
    case AppRoutes.home:
      return _fadeRoute(MainShell(initialIndex: 0));
    case AppRoutes.map:
      return _fadeRoute(MainShell(initialIndex: 1));
    case AppRoutes.directory:
      return _fadeRoute(MainShell(initialIndex: 3));
    case AppRoutes.marketplace:
      return MaterialPageRoute(builder: (_) => MarketplaceScreen());
    case AppRoutes.profile:
      return _fadeRoute(MainShell(initialIndex: 4));
    case AppRoutes.publicProfile:
      final memberId = settings.arguments as String;
      return _slideUpRoute(PublicProfileScreen(memberId: memberId));
    case AppRoutes.library:
      return MaterialPageRoute(builder: (_) => LibraryScreen());
    case AppRoutes.jobs:
      return MaterialPageRoute(builder: (_) => const JobsScreen());
    case AppRoutes.finances:
      return MaterialPageRoute(builder: (_) => const FinancesScreen());
    case AppRoutes.learn:
      return MaterialPageRoute(builder: (_) => const LearningScreen());
    case AppRoutes.messages:
      return MaterialPageRoute(builder: (_) => const MessagesScreen());
    case AppRoutes.events:
      return MaterialPageRoute(builder: (_) => const EventsScreen());
    case AppRoutes.feed:
      return _fadeRoute(const FeedScreen());
    case AppRoutes.editProfile:
      return _slideUpRoute(const EditProfileScreen());
    case AppRoutes.createPost:
      final eventData = settings.arguments as Map<String, String>?;
      return _slideUpRoute(CreatePostScreen(eventData: eventData));
    case AppRoutes.createEvent:
      final event = settings.arguments as Event?;
      return _slideUpRoute(CreateEventScreen(existingEvent: event));
    case AppRoutes.eventDetail:
      final eventId = settings.arguments as String;
      return MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: eventId));
    case AppRoutes.myEvents:
      return _slideUpRoute(MyEventsScreen());
    case AppRoutes.ticketHistory:
      return _slideUpRoute(const TicketHistoryScreen());
    case AppRoutes.createJob:
      return _slideUpRoute(CreateJobScreen());
    case AppRoutes.createService:
      return _slideUpRoute(CreateServiceScreen());
    case AppRoutes.chapterDetail:
      final chapter = settings.arguments as Chapter;
      return _slideUpRoute(ChapterDetailScreen(chapter: chapter));
    case AppRoutes.bookmarks:
      return _slideUpRoute(const BookmarksScreen());
    case AppRoutes.followersList:
      final args = settings.arguments
          as ({String memberId, String memberName, FollowListMode mode});
      return _slideUpRoute(FollowersListScreen(
        memberId: args.memberId,
        memberName: args.memberName,
        mode: args.mode,
      ));
    case AppRoutes.incomingCall:
      final args = settings.arguments as Map<String, dynamic>;
      final callData = args['callData'] as CallData?;
      if (callData != null) {
        return _fadeRoute(IncomingCallScreen(
          callData: callData,
          callerName: args['callerName'] as String? ?? callData.callerId,
          callerAvatarUrl: args['callerAvatarUrl'] as String?,
          onAccept: () => CallService.instance.acceptCall(callData),
          onReject: () => CallService.instance.rejectCall(callData),
        ));
      }
      // Fallback: construit CallData depuis les champs bruts (ex: tap notification)
      final callInviteId = args['callInviteId'] as String? ?? '';
      final channelName = args['channelName'] as String? ?? '';
      final callerId = args['callerId'] as String? ?? '';
      final calleeId = args['calleeId'] as String? ?? '';
      final conversationId = args['conversationId'] as String? ?? '';
      final callType = args['callType'] == 'video' ? CallType.video : CallType.audio;
      final fallbackCallData = CallData(
        callInviteId: callInviteId,
        channelName: channelName,
        callerId: callerId,
        calleeId: calleeId,
        conversationId: conversationId,
        callType: callType,
        status: CallStatus.ringing,
      );
      return _fadeRoute(IncomingCallScreen(
        callData: fallbackCallData,
        callerName: args['callerName'] as String? ?? callerId,
        callerAvatarUrl: args['callerAvatarUrl'] as String?,
        onAccept: () => CallService.instance.acceptCall(fallbackCallData),
        onReject: () => CallService.instance.rejectCall(fallbackCallData),
      ));
    case AppRoutes.outgoingCall:
      final args = settings.arguments as Map<String, dynamic>;
      return _fadeRoute(OutgoingCallScreen(
        callData: args['callData'] as CallData,
        calleeName: args['calleeName'] as String,
        calleeAvatarUrl: args['calleeAvatarUrl'] as String?,
        onCancel: args['onCancel'] as VoidCallback,
      ));
    case AppRoutes.activeCall:
      final args = settings.arguments as Map<String, dynamic>;
      return _fadeRoute(ActiveCallScreen(
        callData: args['callData'] as CallData,
        remoteName: args['remoteName'] as String,
        remoteAvatarUrl: args['remoteAvatarUrl'] as String?,
        onEndCall: args['onEndCall'] as VoidCallback,
      ));
    case AppRoutes.groupIncomingCall:
      final args = settings.arguments as Map<String, dynamic>;
      return _fadeRoute(GroupIncomingCallScreen(
        callData: args['callData'] as GroupCallData,
        callerName: args['callerName'] as String? ?? (args['callData'] as GroupCallData).callerId,
        callerAvatarUrl: args['callerAvatarUrl'] as String?,
        onAccept: args['onAccept'] as VoidCallback,
        onReject: args['onReject'] as VoidCallback,
      ));
    case AppRoutes.groupOutgoingCall:
      final args = settings.arguments as Map<String, dynamic>;
      return _fadeRoute(GroupOutgoingCallScreen(
        callData: args['callData'] as GroupCallData,
        participantNames: (args['participantNames'] as List<dynamic>).cast<String>(),
        onCancel: args['onCancel'] as VoidCallback,
      ));
    case AppRoutes.groupActiveCall:
      final args = settings.arguments as Map<String, dynamic>;
      return _fadeRoute(GroupActiveCallScreen(
        callData: args['callData'] as GroupCallData,
        onEndCall: args['onEndCall'] as VoidCallback,
      ));
    default:
      return _fadeRoute(AuthGate());
  }
}

PageRouteBuilder _fadeRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (_, animation, __) => page,
    transitionsBuilder: (_, animation, __, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}

PageRouteBuilder _slideUpRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (_, animation, __) => page,
    transitionsBuilder: (_, animation, __, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        )),
        child: FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 350),
  );
}
