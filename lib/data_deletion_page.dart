import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class DataDeletionPage extends StatefulWidget {
  const DataDeletionPage({super.key});

  @override
  State<DataDeletionPage> createState() => _DataDeletionPageState();
}

class _DataDeletionPageState extends State<DataDeletionPage> {
  final TextEditingController _mobileController =
  TextEditingController(text: "+60167413625");
  final TextEditingController _subjectController =
  TextEditingController(text: "Data Deletion");
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final formattedDate = DateFormat('dd.MM.yyyy').format(DateTime.now());
    _dateController.text = "Data DeletionRequest : $formattedDate";
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Show loading spinner
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      // SMTP credentials - replace with your actual settings
      final smtpServer = SmtpServer(
        'mail.firstshot.my', // e.g., smtp.gmail.com or mail.yourdomain.com
        port: 465,
        ssl: true,
        username: 'postman@firstshot.my',
        password: 'Doik1123!@#', // or Gmail app password
      );

      final message = Message()
        ..from = const Address('admin@firstshot.my', 'FirstShot App')
        ..recipients.add('suthesan@gmail.com')
        ..subject = _subjectController.text
        ..text = '''
Mobile: ${_mobileController.text}
Date: ${_dateController.text}
Subject: ${_subjectController.text}

Message:
${_messageController.text}
''';

      try {
        await send(message, smtpServer);

        if (!mounted) return;
        Navigator.pop(context); // close loading dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Request Sent"),
            content: const Text("Your request has been emailed to FirstShot admin."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back
                },
                child: const Text("OK"),
              ),
            ],
          ),
        );
      } catch (e) {
        Navigator.pop(context); // close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to send email: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFD),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Icon(Icons.lock_outline, color: Colors.green, size: 36),
                ],
              ),

              const SizedBox(height: 10),

              // SVG Logo
              Center(
                child: SvgPicture.asset(
                  'assets/images/datadelete.svg',
                  height: 80,
                ),
              ),

              const SizedBox(height: 20),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Mobile
                    TextFormField(
                      controller: _mobileController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: "Mobile No",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Date (read-only)
                    TextFormField(
                      controller: _dateController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Subject
                    TextFormField(
                      controller: _subjectController,
                      decoration: const InputDecoration(
                        labelText: "Subject",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                      value == null || value.isEmpty ? "Enter subject" : null,
                    ),
                    const SizedBox(height: 16),

                    // Message
                    TextFormField(
                      controller: _messageController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: "Describe your reason...",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                      value == null || value.isEmpty ? "Enter description" : null,
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      "By providing this consent, I formally request that FirstShot delete all my personal data from its servers within ten (10) working days.",
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                      textAlign: TextAlign.justify,
                    ),

                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4997D0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: const Text(
                        "Request for data deletion",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
