import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';

class AccessManagementScreen extends StatefulWidget {
  const AccessManagementScreen({super.key});

  @override
  State<AccessManagementScreen> createState() => _AccessManagementScreenState();
}

class _AccessManagementScreenState extends State<AccessManagementScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _isAdminRole = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _showAddMemberDialog(BuildContext context) {
    _phoneController.clear();
    _nameController.clear();
    _isAdminRole = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Thêm Thành Viên'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên hiển thị',
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại (VD: 098...)',
                      prefixIcon: Icon(Icons.phone),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Quyền Quản Trị (Admin)'),
                    subtitle: const Text('Có thể thêm/xóa người khác'),
                    value: _isAdminRole,
                    onChanged: (val) {
                      setState(() {
                        _isAdminRole = val;
                      });
                    },
                    activeColor: AppColors.primaryGreen,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_phoneController.text.trim().isEmpty || _nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin!')),
                      );
                      return;
                    }
                    
                    // Normalize phone
                    String phone = _phoneController.text.trim().replaceAll(RegExp(r'[\s\-()]'), '');
                    if (phone.startsWith('0')) {
                      phone = '+84${phone.substring(1)}';
                    } else if (!phone.startsWith('+')) {
                      phone = '+84$phone';
                    }

                    try {
                      await FirebaseFirestore.instance.collection('allowed_phones').doc(phone).set({
                        'name': _nameController.text.trim(),
                        'role': _isAdminRole ? 'admin' : 'member',
                        'addedAt': FieldValue.serverTimestamp(),
                      });
                      if (context.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Thêm thành viên thành công!')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Lỗi: $e')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
                  child: const Text('Lưu'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _deleteMember(String phone, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa Thành Viên'),
        content: Text('Bạn có chắc chắn muốn xóa "$name" ($phone) khỏi danh sách truy cập? Người này sẽ bị đăng xuất ngay lập tức.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance.collection('allowed_phones').doc(phone).delete();
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã xóa thành viên!')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final currentUserPhone = auth.phoneNumber;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Thành Viên'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMemberDialog(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Thêm'),
        backgroundColor: AppColors.primaryGreen,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('allowed_phones').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('Chưa có thành viên nào.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final phone = doc.id;
              final name = data['name'] ?? 'Chưa đặt tên';
              final role = data['role'] ?? 'member';
              final isMe = phone == currentUserPhone;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: role == 'admin' ? AppColors.primaryGreen.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                  child: Icon(
                    role == 'admin' ? Icons.admin_panel_settings : Icons.person,
                    color: role == 'admin' ? AppColors.primaryGreen : Colors.grey,
                  ),
                ),
                title: Text('$name ${isMe ? "(Bạn)" : ""}'),
                subtitle: Text(phone),
                trailing: isMe ? null : IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _deleteMember(phone, name),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
