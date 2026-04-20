import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../pages/login_page.dart';
import '../pages/my_bookings_page.dart';
import '../pages/profile_page.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  String selectedRoom = "Conference Room A";
  DateTime selectedDate = DateTime.now();
  TimeOfDay? selectedTime;
  bool _isLoading = false;

  final List<Map<String, dynamic>> rooms = [
    {
      "name": "Conference Room A",
      "capacity": "8 Seats",
      "time": "10 AM - 12 PM",
      "image":
          "https://images.unsplash.com/photo-1497366754035-f200968a6e72?w=1200",
    },
    {
      "name": "Meeting Room B",
      "capacity": "6 Seats",
      "time": "2 PM - 4 PM",
      "image":
          "https://images.unsplash.com/photo-1497366412874-3415097a27e7?w=1200",
    },
    {
      "name": "Team Sync Room",
      "capacity": "10 Seats",
      "time": "4 PM - 6 PM",
      "image":
          "https://images.unsplash.com/photo-1504384308090-c894fdcc538d?w=1200",
    },
  ];

  Future<void> bookRoom() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      return;
    }

    if (selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final timeText = selectedTime!.format(context);

    try {
      final dateText =
          "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

      final existingBookings = await FirebaseFirestore.instance
          .collection('bookings')
          .where('room', isEqualTo: selectedRoom)
          .where('date', isEqualTo: dateText)
          .get();

      if (existingBookings.docs.isNotEmpty) {
        if (!mounted) return;
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Room already booked for this date')),
        );
        setState(() => _isLoading = false);
        return;
      }

      await FirebaseFirestore.instance.collection('bookings').add({
        'room': selectedRoom,
        'date': dateText,
        'time': timeText,
        'timestamp': FieldValue.serverTimestamp(),
        'userEmail': user.email,
        'status': 'Confirmed',
      });

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 34,
                  backgroundColor: Color(0xFFE2F8EC),
                  child: Icon(
                    Icons.check_circle,
                    color: Color(0xFF1FA463),
                    size: 42,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Booking Confirmed!",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "$selectedRoom booked for ${selectedTime!.format(context)} on "
                  "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2F6BFF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text("Done"),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Booking failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<DateTime> get next7Days =>
      List.generate(7, (index) => DateTime.now().add(Duration(days: index)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Container(
        height: 74,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _BottomNavItem(
              icon: Icons.home_rounded,
              label: "Home",
              active: true,
              onTap: () {},
            ),
            _BottomNavItem(
              icon: Icons.book_online_rounded,
              label: "Bookings",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyBookingsPage()),
                );
              },
            ),
            _BottomNavItem(
              icon: Icons.calendar_month_rounded,
              label: "Calendar",
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Calendar page coming soon")),
                );
              },
            ),
            _BottomNavItem(
              icon: Icons.person_outline_rounded,
              label: "Profile",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                );
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      _buildDateSelector(),
                      const SizedBox(height: 18),
                      _buildRoomsTitle(),
                      const SizedBox(height: 12),
                      ...rooms.map((room) => _buildRoomCard(room)),
                      const SizedBox(height: 22),
                      _buildQuickActions(),
                      const SizedBox(height: 22),
                      _buildLiveBookings(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2F6BFF), Color(0xFF4FA3FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Book a Room",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Color.fromRGBO(255, 255, 255, 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.notifications_none,
                    color: Colors.white, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: next7Days.map((date) {
                final selected = date.day == selectedDate.day &&
                    date.month == selectedDate.month &&
                    date.year == selectedDate.year;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedDate = date;
                    });
                  },
                  child: Container(
                    width: 42,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF2F6BFF)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _weekday(date.weekday),
                          style: TextStyle(
                            fontSize: 11,
                            color: selected ? Colors.white : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${date.day}",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: selected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Row(
      children: [
        Expanded(
          child: _infoChip(
            icon: Icons.calendar_month_rounded,
            title:
                "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (picked != null) {
                setState(() => selectedTime = picked);
              }
            },
            child: _infoChip(
              icon: Icons.access_time_rounded,
              title: selectedTime == null
                  ? "Pick time"
                  : selectedTime!.format(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoomsTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        Text(
          "Available Rooms",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1D2340),
          ),
        ),
        Text(
          "View All",
          style: TextStyle(
            color: Color(0xFF2F6BFF),
            fontWeight: FontWeight.w600,
          ),
        )
      ],
    );
  }

  Widget _buildRoomCard(Map<String, dynamic> room) {
    final roomName = room["name"] as String;
    final selected = selectedRoom == roomName;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 6,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: Image.network(
                room["image"],
                width: double.infinity,
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        roomName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1C2240),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedRoom = roomName;
                        });
                      },
                      child: Icon(
                        selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: const Color(0xFF2F6BFF),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _smallMeta(Icons.people_alt_outlined, room["capacity"]),
                    const SizedBox(width: 14),
                    _smallMeta(Icons.schedule_rounded, room["time"]),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : bookRoom,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2F6BFF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading && selectedRoom == roomName
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.3,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "Book Now",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _featureCard(
            icon: Icons.flash_on_rounded,
            color: const Color(0xFFFFB703),
            title: "Fast Booking",
            subtitle: "1 tap booking flow",
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _featureCard(
            icon: Icons.design_services_rounded,
            color: const Color(0xFF00C2A8),
            title: "Modern UI",
            subtitle: "Clean premium design",
          ),
        ),
      ],
    );
  }

  Widget _buildLiveBookings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                "My Bookings",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1D2340),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MyBookingsPage(),
                  ),
                );
              },
              child: const Text("Open"),
            ),
          ],
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('bookings')
              .orderBy('timestamp', descending: true)
              .limit(3)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ));
            }

            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return _emptyState();
            }

            return Column(
              children: docs.map((doc) {
                final data = (doc.data() as Map<String, dynamic>?) ?? {};
                final room = data['room'] ?? 'Meeting Room';
                final date = data['date'] ?? 'N/A';
                final time = data['time'] ?? 'N/A';
                final status = data['status'] ?? 'Confirmed';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.05),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          "https://images.unsplash.com/photo-1497366754035-f200968a6e72?w=500",
                          height: 64,
                          width: 64,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              room.toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "$date • $time",
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      _statusChip(status.toString()),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        )
      ],
    );
  }

  Widget _infoChip({required IconData icon, required String title}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF2F6BFF), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF1D2340),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallMeta(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF6A728B)),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFF6A728B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _featureCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.045),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Color.fromRGBO((color.r * 255).round(),
                (color.g * 255).round(), (color.b * 255).round(), 0.14),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          )
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          Icon(Icons.event_available_rounded,
              size: 42, color: Color(0xFF2F6BFF)),
          SizedBox(height: 10),
          Text(
            "No bookings yet",
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          SizedBox(height: 4),
          Text(
            "Book a room to see your upcoming meetings here.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    Color bg;
    Color fg;

    switch (status.toLowerCase()) {
      case 'pending':
        bg = const Color(0xFFFFF3D6);
        fg = const Color(0xFFD98B00);
        break;
      case 'confirmed':
        bg = const Color(0xFFE2F8EC);
        fg = const Color(0xFF1FA463);
        break;
      default:
        bg = const Color(0xFFE9F0FF);
        fg = const Color(0xFF2F6BFF);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  String _weekday(int day) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[day - 1];
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF2F6BFF) : Colors.grey;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 12),
            )
          ],
        ),
      ),
    );
  }
}
