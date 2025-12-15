import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class UsersListPage extends StatefulWidget {
  const UsersListPage({super.key});

  @override
  State<UsersListPage> createState() => _UsersListPageState();
}

class _UsersListPageState extends State<UsersListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Premium Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) =>
                  setState(() => _searchQuery = value.toLowerCase()),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar usuário...',
                prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ),
          ),
        ),

        // List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .orderBy('email')
                .limit(100)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final users =
                  snapshot.data?.docs.where((doc) {
                    if (_searchQuery.isEmpty) return true;
                    final data = doc.data() as Map<String, dynamic>;
                    final email = (data['email'] ?? '')
                        .toString()
                        .toLowerCase();
                    final name = (data['name'] ?? '').toString().toLowerCase();
                    return email.contains(_searchQuery) ||
                        name.contains(_searchQuery);
                  }).toList() ??
                  [];

              if (users.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhum usuário encontrado',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  final data = user.data() as Map<String, dynamic>;
                  return _buildUserCard(context, data, user.id);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard(
    BuildContext context,
    Map<String, dynamic> data,
    String id,
  ) {
    final email = data['email'] ?? 'Sem email';
    final name = data['name'] ?? data['displayName'] ?? 'Usuário';
    final isSuperAdmin = data['superAdmin'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: isSuperAdmin
              ? const Color(0xFF6366F1)
              : const Color(0xFF334155),
          child: Icon(
            isSuperAdmin ? Icons.admin_panel_settings : Icons.person,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          name.toString(),
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          email.toString(),
          style: TextStyle(color: Colors.grey[500]),
        ),
        trailing: isSuperAdmin
            ? const Chip(
                label: Text(
                  'Admin',
                  style: TextStyle(fontSize: 10, color: Colors.white),
                ),
                backgroundColor: Color(0xFF6366F1),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              )
            : null,
      ),
    );
  }
}
