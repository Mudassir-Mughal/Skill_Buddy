import 'package:flutter/material.dart';
import '../Service/api_service.dart';
import 'Chatpage.dart';
import 'theme.dart';

class ViewRequestsPage extends StatefulWidget {
  final String role;
  const ViewRequestsPage({Key? key, required this.role}) : super(key: key);

  @override
  State<ViewRequestsPage> createState() => _ViewRequestsPageState();
}

class _ViewRequestsPageState extends State<ViewRequestsPage> {
  String currentUserId = '';
  bool isLoading = true;
  late Future<List<Map<String, dynamic>>> receivedRequestsFuture;
  late Future<List<Map<String, dynamic>>> sentRequestsFuture;

  @override
  void initState() {
    super.initState();
    currentUserId = ApiService.currentUserId ?? '';
    receivedRequestsFuture = ApiService.getReceivedRequests(currentUserId);
    sentRequestsFuture = ApiService.getSentRequests(currentUserId);
    isLoading = false;
  }

  void refreshRequests() {
    setState(() {
      receivedRequestsFuture = ApiService.getReceivedRequests(currentUserId);
      sentRequestsFuture = ApiService.getSentRequests(currentUserId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final userRole = widget.role.toLowerCase();
    if (isLoading || currentUserId.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (userRole == 'student') {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: _customAppBar(title: 'Sent Requests', showTabs: false, context: context),
        body: _buildSentRequestsTab(currentUserId, context, sentRequestsFuture, refreshRequests),
      );
    } else if (userRole == 'instructor') {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: _customAppBar(title: 'Received Requests', showTabs: false, context: context),
        body: _buildReceivedRequestsTab(currentUserId, context, receivedRequestsFuture, refreshRequests),
      );
    } else {
      return DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: _customAppBar(title: '', showTabs: true, context: context),
          body: TabBarView(
            children: [
              _buildReceivedRequestsTab(currentUserId, context, receivedRequestsFuture, refreshRequests),
              _buildSentRequestsTab(currentUserId, context, sentRequestsFuture, refreshRequests),
            ],
          ),
        ),
      );
    }
  }

  PreferredSizeWidget _customAppBar({required String title, required bool showTabs, required BuildContext context}) {
    return PreferredSize(
      preferredSize: Size.fromHeight(showTabs ? 80 : 60),
      child: AppBar(
        automaticallyImplyLeading: Navigator.of(context).canPop(),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF4F5EE2)],
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
                    labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    tabs: [
                      Tab(icon: Icon(Icons.inbox_rounded), text: 'Received'),
                      Tab(icon: Icon(Icons.send_rounded), text: 'Sent'),
                    ],
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

Widget _buildReceivedRequestsTab(String currentUserId, BuildContext context, Future<List<Map<String, dynamic>>> receivedRequestsFuture, VoidCallback onRefresh) {
  return FutureBuilder<List<Map<String, dynamic>>>(
    future: receivedRequestsFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      final requests = snapshot.data ?? [];
      if (requests.isEmpty) {
        return _emptyState(icon: Icons.inbox_rounded, message: "No incoming requests.");
      }
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final request = requests[index];
          final requestId = request['_id'];
          final senderId = request['senderId'];
          final skillTitle = request['title'] ?? 'Unknown Skill';
          final status = request['status'] ?? 'pending';
          return FutureBuilder<Map<String, dynamic>?>(
            future: ApiService.getUserById(senderId),
            builder: (context, nameSnapshot) {
              if (!nameSnapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final senderName = nameSnapshot.data?['Fullname'] ?? 'Unknown User';
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
                      Text(skillTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(Icons.person_outline_rounded, size: 18, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text('From: $senderName',
                              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500, fontSize: 14),
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
                                await ApiService.declineRequest(requestId);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Request declined.')),
                                  );
                                  onRefresh();
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
                                await ApiService.acceptRequest(requestId);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Request accepted.')),
                                  );
                                  onRefresh();
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

Widget _buildSentRequestsTab(String currentUserId, BuildContext context, Future<List<Map<String, dynamic>>> sentRequestsFuture, VoidCallback onRefresh) {
  return FutureBuilder<List<Map<String, dynamic>>>(
    future: sentRequestsFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      final sentRequests = snapshot.data ?? [];
      if (sentRequests.isEmpty) {
        return _emptyState(icon: Icons.outbox_rounded, message: "No outgoing requests.");
      }
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        itemCount: sentRequests.length,
        itemBuilder: (context, index) {
          final request = sentRequests[index];
          final skillTitle = request['title'] ?? 'Unknown Skill';
          final receiverId = request['receiverId'];
          final status = request['status'] ?? 'pending';
          return FutureBuilder<Map<String, dynamic>?>(
            future: ApiService.getUserById(receiverId),
            builder: (context, nameSnapshot) {
              if (!nameSnapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final receiverName = nameSnapshot.data?['Fullname'] ?? 'Unknown User';
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
