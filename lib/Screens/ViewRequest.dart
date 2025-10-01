import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'Chatpage.dart';
import 'theme.dart';

class ViewRequestsPage extends StatelessWidget {
  final String role;

  const ViewRequestsPage({Key? key, required this.role}) : super(key: key);

  @override
  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final userRole = role.toLowerCase();

    if (userRole == 'student') {
      // Only show Sent Requests
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: _customAppBar(
          title: 'Sent Requests',
          showTabs: false,
          context: context,
        ),
        body: _buildSentRequestsTab(currentUserId, context),
      );
    } else if (userRole == 'instructor') {
      // Only show Received Requests
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: _customAppBar(
          title: 'Received Requests',
          showTabs: false,
          context: context,
        ),
        body: _buildReceivedRequestsTab(currentUserId, context),
      );
    } else if (userRole == 'both') {
      // Show both tabs
      return DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: _customAppBar(
            title: '',
            showTabs: true,
            context: context,
          ),
          body: TabBarView(
            children: [
              _buildReceivedRequestsTab(currentUserId, context),
              _buildSentRequestsTab(currentUserId, context),
            ],
          ),
        ),
      );
    } else {
      // Fallback: show both tabs (or handle other roles gracefully)
      return DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: _customAppBar(
            title: '',
            showTabs: true,
            context: context,
          ),
          body: TabBarView(
            children: [
              _buildReceivedRequestsTab(currentUserId, context),
              _buildSentRequestsTab(currentUserId, context),
            ],
          ),
        ),
      );
    }
  }

  PreferredSizeWidget _customAppBar({
    required String title,
    required bool showTabs,
    required BuildContext context,
  }) {
    return PreferredSize(
      preferredSize: Size.fromHeight(showTabs ? 80 : 60),
      child: AppBar(
        automaticallyImplyLeading: Navigator.of(context).canPop(),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF6C63FF),
                Color(0xFF4F5EE2),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        centerTitle: true,
        title: Padding(
          padding: const EdgeInsets.only(top: 16.0, bottom: 4.0),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 22,
              letterSpacing: 0.5,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.transparent,
        bottom: showTabs
            ? PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.transparent,
            child: const TabBar(
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(color: Colors.white, width: 3),
                insets: EdgeInsets.symmetric(horizontal: 30),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle:
              TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              tabs: [
                Tab(
                  icon: Icon(Icons.inbox_rounded),
                  text: 'Received',
                ),
                Tab(
                  icon: Icon(Icons.send_rounded),
                  text: 'Sent',
                ),
              ],
            ),
          ),
        )
            : null,
      ),
    );
  }
}
// RECEIVED REQUESTS TAB (fixed layout)
Widget _buildReceivedRequestsTab(String currentUserId, BuildContext context) {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('requests')
        .where('receiverId', isEqualTo: currentUserId)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return _emptyState(
          icon: Icons.inbox_rounded,
          message: "No incoming requests.",
        );
      }
      final requests = snapshot.data!.docs;
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final request = requests[index];
          final requestId = request.id;
          final senderId = request['senderId'];
          final skillTitle = request['title'] ?? 'Unknown Skill';
          final status = request['status'] ?? 'pending';
          return FutureBuilder<String>(
            future: getSenderName(senderId),
            builder: (context, nameSnapshot) {
              if (!nameSnapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final senderName = nameSnapshot.data!;
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Skill Title
                      Text(
                        skillTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Sender info and chat/status
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(Icons.person_outline_rounded, size: 18, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'From: $senderName',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),




                          if (status == "accepted") _statusChip(status),
                          if (status == "accepted")
                            IconButton(
                              icon: const Icon(Icons.chat_bubble, color: Color(0xFF6C63FF)),
                              tooltip: "Chat",
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatPage(
                                      currentUserId: currentUserId,
                                      peerId: senderId,
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Accept/Decline only if not accepted
                      if (status != "accepted")
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              icon: const Icon(Icons.close, size: 18),
                              label: const Text('Decline'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red[500],
                                side: BorderSide(color: Colors.red[200]!),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () async {
                                await handleDecline(requestId);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Request declined.')),
                                  );
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.check, size: 18),
                              label: const Text('Accept'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              onPressed: () async {
                                await handleAccept(requestId, senderId, skillTitle);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Request accepted.')),
                                  );
                                  await Future.delayed(const Duration(milliseconds: 300));
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChatPage(
                                        currentUserId: currentUserId,
                                        peerId: senderId,
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    },
  );
}
// SENT REQUESTS TAB
Widget _buildSentRequestsTab(String currentUserId, BuildContext context) {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('requests')
        .where('senderId', isEqualTo: currentUserId)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return _emptyState(
          icon: Icons.outbox_rounded,
          message: "No outgoing requests.",
        );
      }
      final sentRequests = snapshot.data!.docs;
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        itemCount: sentRequests.length,
        itemBuilder: (context, index) {
          final request = sentRequests[index];
          final skillTitle = request['title'] ?? 'Unknown Skill';
          final receiverId = request['receiverId'];
          final status = request['status'] ?? 'pending';
          return FutureBuilder<String>(
            future: getSenderName(receiverId),
            builder: (context, nameSnapshot) {
              if (!nameSnapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final receiverName = nameSnapshot.data!;
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Icon(Icons.send_rounded, color: AppColors.primary),
                  ),
                  title: Text(
                    skillTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  // Prevent overflow by using a column for subtitle
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person_outline_rounded, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'To: $receiverName',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _statusChip(status),
                            if (status == "accepted") ...[
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.chat_bubble, color: Color(0xFF6C63FF)),
                                tooltip: "Chat",
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChatPage(
                                        currentUserId: currentUserId,
                                        peerId: receiverId,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    },
  );
}

Widget _statusChip(String status) {
  if (status == "accepted") {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border.all(color: Colors.green.shade400),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green[700], size: 17),
          const SizedBox(width: 4),
          Text(
            "Accepted",
            style: TextStyle(
              color: Colors.green[700],
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  } else {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange.shade400),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(Icons.hourglass_top_rounded, color: Colors.orange[700], size: 17),
          const SizedBox(width: 4),
          Text(
            "Pending",
            style: TextStyle(
              color: Colors.orange[700],
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

Widget _emptyState({required IconData icon, required String message}) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 74, color: Colors.grey[300]),
        const SizedBox(height: 20),
        Text(
          message,
          style: TextStyle(
            fontSize: 17,
            color: Colors.grey[500],
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
      ],
    ),
  );
}

// --- Improved RequestCard Widget with status support ---
class RequestCard extends StatelessWidget {
  final String skillTitle;
  final String senderName;
  final Widget? chatIcon;
  final String status; // "pending" or "accepted"
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final bool isReceived; // so that status chip shows "From:" or "To:"

  const RequestCard({
    Key? key,
    required this.skillTitle,
    required this.senderName,
    required this.status,
    this.chatIcon,
    this.onAccept,
    this.onDecline,
    this.isReceived = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isAccepted = status == "accepted";
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.09),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Skill Title Row + Chat Icon
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.13),
                  child: Icon(Icons.school_rounded, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    skillTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                if (chatIcon != null) chatIcon!,
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.person_outline_rounded, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  isReceived ? 'From: $senderName' : 'To: $senderName',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 10),
                _statusChip(status),
              ],
            ),
            const SizedBox(height: 20),
            if (!isAccepted)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Decline'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red[500],
                      side: BorderSide(color: Colors.red[200]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: onDecline,
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: onAccept,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// --- Logic Section ---
Future<void> handleAccept(String requestId, String senderId, String skillTitle) async {
  final receiverId = FirebaseAuth.instance.currentUser!.uid;
  // Update status to accepted
  await FirebaseFirestore.instance.collection('requests').doc(requestId).update({
    'status': 'accepted',
  });
  // Send messages
  await FirebaseFirestore.instance.collection('messages').add({
    'senderId': receiverId,
    'receiverId': senderId,
    'message': 'Your request for "$skillTitle" has been accepted.',
    'timestamp': FieldValue.serverTimestamp(),
  });
  await FirebaseFirestore.instance.collection('messages').add({
    'senderId': senderId,
    'receiverId': receiverId,
    'message': 'You accepted the request for "$skillTitle".',
    'timestamp': FieldValue.serverTimestamp(),
  });
}

Future<void> handleDecline(String requestId) async {
  await FirebaseFirestore.instance.collection('requests').doc(requestId).delete();
}

Future<String> getSenderName(String senderId) async {
  final userDoc = await FirebaseFirestore.instance.collection('users').doc(senderId).get();
  return userDoc.data()?['Fullname'] ?? 'Unknown User';
}