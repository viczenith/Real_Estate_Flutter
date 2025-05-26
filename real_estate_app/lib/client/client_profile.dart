import 'package:flutter/material.dart';

class ClientProfile extends StatefulWidget {
  const ClientProfile({super.key});

  @override
  _ClientProfileState createState() => _ClientProfileState();
}

class _ClientProfileState extends State<ClientProfile> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;

  final TextEditingController nameController = TextEditingController(text: "John Doe");
  final TextEditingController emailController = TextEditingController(text: "johndoe@example.com");
  final TextEditingController phoneController = TextEditingController(text: "+123456789");
  final TextEditingController aboutController = TextEditingController(text: "Write about yourself");
  final TextEditingController companyController = TextEditingController(text: "Real Estate Inc.");
  final TextEditingController jobController = TextEditingController(text: "Investor");
  final TextEditingController countryController = TextEditingController(text: "USA");
  final TextEditingController addressController = TextEditingController(text: "123 Main Street, New York");

  final TextEditingController oldPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF7F7F7),
      appBar: AppBar(
        title: Text("Client Profile", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileCard(),
            SizedBox(height: 20),
            _buildTabBar(),
            SizedBox(height: 20),
            IndexedStack(
              index: _selectedIndex,
              children: [
                _buildProfileDetails(),
                _buildEditProfile(),
                _buildChangePassword(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// **🔻 Profile Card (Top Left)**
  Widget _buildProfileCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(radius: 50, backgroundImage: AssetImage('assets/profile.jpg')),
            SizedBox(height: 10),
            Text(nameController.text, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(jobController.text, style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  /// **🔻 Tab Navigation**
  Widget _buildTabBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildTabButton("Details", 0),
        _buildTabButton("Edit Profile", 1),
        _buildTabButton("Change Password", 2),
      ],
    );
  }

  Widget _buildTabButton(String title, int index) {
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        decoration: BoxDecoration(
          color: _selectedIndex == index ? Colors.blueAccent : Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(title, style: TextStyle(color: _selectedIndex == index ? Colors.white : Colors.black)),
      ),
    );
  }

  /// **🔻 Profile Details View**
  Widget _buildProfileDetails() {
    return _buildInfoCard([
      _buildInfoRow("Full Name", nameController.text),
      _buildInfoRow("Company", companyController.text),
      _buildInfoRow("Job", jobController.text),
      _buildInfoRow("Country", countryController.text),
      _buildInfoRow("Address", addressController.text),
      _buildInfoRow("Phone", phoneController.text),
      _buildInfoRow("Email", emailController.text),
      _buildInfoRow("About", aboutController.text),
    ]);
  }

  /// **🔻 Edit Profile View**
  Widget _buildEditProfile() {
    return _buildForm([
      _buildProfileImageUploader(),
      _buildTextField("Full Name", nameController),
      _buildTextField("Company", companyController),
      _buildTextField("Job", jobController),
      _buildTextField("Country", countryController),
      _buildTextField("Address", addressController),
      _buildTextField("Phone", phoneController),
      _buildTextField("Email", emailController),
      _buildTextField("About", aboutController, maxLines: 3),
      _buildSaveButton("Save Changes"),
    ]);
  }

  /// **🔻 Change Password View**
  Widget _buildChangePassword() {
    return _buildForm([
      _buildPasswordField("Old Password", oldPasswordController),
      _buildPasswordField("New Password", newPasswordController),
      _buildPasswordField("Confirm Password", confirmPasswordController),
      _buildSaveButton("Update Password"),
    ]);
  }

  /// **🔻 Common Widgets**
  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value, style: TextStyle(color: Colors.grey[700]))),
        ],
      ),
    );
  }

  Widget _buildForm(List<Widget> children) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        obscureText: true,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildSaveButton(String text) {
    return Padding(
      padding: EdgeInsets.only(top: 20),
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
        child: Text(text),
      ),
    );
  }

  Widget _buildProfileImageUploader() {
    return Column(
      children: [
        CircleAvatar(radius: 50, backgroundImage: AssetImage('assets/profile.jpg')),
        SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: () {},
          icon: Icon(Icons.upload),
          label: Text("Upload New Image"),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
        ),
      ],
    );
  }
}
