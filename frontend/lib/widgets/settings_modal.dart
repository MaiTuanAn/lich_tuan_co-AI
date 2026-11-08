import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/calendar_provider.dart';

class SettingsModal extends StatefulWidget {
  const SettingsModal({super.key});

  @override
  State<SettingsModal> createState() => _SettingsModalState();
}

class _SettingsModalState extends State<SettingsModal> {
  int _selectedTabIndex = 0;

  final List<String> _tabs = [
    'General',
    'Calendar & Timezone',
    'AI Assistant',
    'Notifications',
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalendarProvider>();
    final isDark = provider.isDarkMode;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        width: 680,
        height: 460,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            // Cột Menu 4 Tab bên trái (Không có Account)
            Container(
              width: 210,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Settings',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  ...List.generate(_tabs.length, (index) {
                    final isSelected = _selectedTabIndex == index;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => setState(() => _selectedTabIndex = index),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFC7D2FE)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _tabs[index],
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected
                                  ? const Color(0xFF1E1B4B)
                                  : (isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

            // Khu vực Nội dung bên phải
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tiêu đề Tab + Nút đóng X
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_tabs[_selectedTabIndex]} Settings',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // Nội dung theo từng Tab
                    Expanded(
                      child: SingleChildScrollView(
                        child: _buildTabContent(provider),
                      ),
                    ),

                    // Nút Cancel & Save Changes ở đáy
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: () {
                            provider.notifySettingsUpdated();
                            Navigator.pop(context);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Save Changes'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(CalendarProvider provider) {
    switch (_selectedTabIndex) {
      case 0:
        return _buildGeneralTab(provider);
      case 1:
        return _buildCalendarTimezoneTab(provider);
      case 2:
        return _buildAiAssistantTab(provider);
      case 3:
      default:
        return _buildNotificationsTab(provider);
    }
  }

  // TAB 1: GENERAL (Chuyển đổi Light Mode / Dark Mode tức thì)
  Widget _buildGeneralTab(CalendarProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Application Theme', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Row(
          children: [
            _themeCard(
              title: 'Light Mode',
              icon: Icons.wb_sunny_outlined,
              selected: provider.themeMode == ThemeMode.light,
              onTap: () => provider.setThemeMode(ThemeMode.light),
            ),
            const SizedBox(width: 12),
            _themeCard(
              title: 'Dark Mode',
              icon: Icons.nightlight_round,
              selected: provider.themeMode == ThemeMode.dark,
              onTap: () => provider.setThemeMode(ThemeMode.dark),
            ),
            const SizedBox(width: 12),
            _themeCard(
              title: 'System Default',
              icon: Icons.brightness_medium,
              selected: provider.themeMode == ThemeMode.system,
              onTap: () => provider.setThemeMode(ThemeMode.system),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('App Language'),
            DropdownButton<String>(
              value: provider.appLanguage,
              items: ['Tiếng Việt', 'English']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => provider.appLanguage = v!),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Date Format'),
            DropdownButton<String>(
              value: provider.dateFormat,
              items: ['DD/MM/YYYY', 'MM/DD/YYYY', 'YYYY-MM-DD']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => provider.dateFormat = v!),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Use 24-Hour Time Format (14:00)'),
          value: provider.use24HourFormat,
          onChanged: (v) => setState(() => provider.use24HourFormat = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Start App on System Boot'),
          value: provider.startOnBoot,
          onChanged: (v) => setState(() => provider.startOnBoot = v),
        ),
      ],
    );
  }

  Widget _themeCard({
    required String title,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? Colors.indigo : Colors.grey.shade400,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 26),
              const SizedBox(height: 6),
              Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  // TAB 2: CALENDAR & TIMEZONE
  Widget _buildCalendarTimezoneTab(CalendarProvider provider) {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          initialValue: provider.defaultViewName,
          decoration: const InputDecoration(labelText: 'Default View', border: OutlineInputBorder()),
          items: ['Week', 'Day', 'Month'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => provider.defaultViewName = v!),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: provider.startDayOfWeek,
          decoration: const InputDecoration(labelText: 'Start Day of Week', border: OutlineInputBorder()),
          items: ['Monday', 'Sunday'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => provider.startDayOfWeek = v!),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: provider.timezone,
          decoration: const InputDecoration(labelText: 'Timezone', border: OutlineInputBorder()),
          items: ['Asia/Ho_Chi_Minh (GMT+7)', 'UTC (GMT+0)']
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) => setState(() => provider.timezone = v!),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: provider.defaultDuration,
          decoration: const InputDecoration(labelText: 'Default Event Duration', border: OutlineInputBorder()),
          items: ['30 mins', '60 mins', '90 mins']
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) => setState(() => provider.defaultDuration = v!),
        ),
      ],
    );
  }

  // TAB 3: AI ASSISTANT (Bảo mật API Key phía Backend + BYOK)
  Widget _buildAiAssistantTab(CalendarProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.radio_button_checked, color: Colors.indigo),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('System Managed (Default)', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('Connected securely via Backend Server', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('Active', style: TextStyle(color: Colors.green.shade800, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const Divider(),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Use Custom API Key (BYOK - Advanced)', style: TextStyle(fontSize: 13.5)),
                value: provider.useCustomApiKey,
                onChanged: (v) => setState(() => provider.useCustomApiKey = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Conflict Auto-Resolution'),
          value: provider.conflictAutoResolution,
          onChanged: (v) => setState(() => provider.conflictAutoResolution = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Smart Free Slot Suggestions'),
          value: provider.smartSlotSuggestions,
          onChanged: (v) => setState(() => provider.smartSlotSuggestions = v),
        ),
      ],
    );
  }

  // TAB 4: NOTIFICATIONS
  Widget _buildNotificationsTab(CalendarProvider provider) {
    return Column(
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Desktop Push Notifications'),
          value: provider.desktopPushNoti,
          onChanged: (v) => setState(() => provider.desktopPushNoti = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Sound Alerts'),
          value: provider.soundAlerts,
          onChanged: (v) => setState(() => provider.soundAlerts = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Daily Morning Briefing (07:30 AM)'),
          value: provider.dailyBriefing,
          onChanged: (v) => setState(() => provider.dailyBriefing = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Conflict Alerts'),
          subtitle: const Text('Instant alert when overlapping schedules detected'),
          value: provider.conflictAlerts,
          onChanged: (v) => setState(() => provider.conflictAlerts = v),
        ),
      ],
    );
  }
}
