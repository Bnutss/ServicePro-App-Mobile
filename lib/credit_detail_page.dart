import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CreditDetailPage extends StatelessWidget {
  final Map<String, dynamic> credit;

  CreditDetailPage({required this.credit});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Детали кредита',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF212121), Color(0xFF6E4B4B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.purple.shade50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: credit['is_closed'] == true
            ? _buildClosedCreditMessage()
            : _buildCreditDetails(),
      ),
    );
  }

  Widget _buildClosedCreditMessage() {
    return Center(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 15,
        margin: EdgeInsets.all(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.close, size: 50, color: Colors.red),
              SizedBox(height: 15),
              Text(
                'Кредит закрыт',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
              ),
              SizedBox(height: 10),
              Text(
                'Дополнительная информация не доступна.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreditDetails() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(height: 30),
        Center(
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 15,
            margin: EdgeInsets.all(12.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      credit['debtor_name'],
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 15),
                  _buildCreditDetailRow(Icons.directions_car, 'Номер авто', credit['car_number']),
                  _buildCreditDetailRow(Icons.phone, 'Телефон', credit['debtor_phone']),
                  _buildCreditDetailRow(Icons.attach_money, 'Цена', '${credit['price']} UZS'),
                  _buildCreditDetailRow(Icons.savings, 'Первоначальный взнос', '${credit['initial_payment']} UZS'),
                  _buildCreditDetailRow(Icons.local_gas_station, 'Тип топлива', credit['fuel_type']),
                  _buildCreditDetailRow(Icons.calendar_today, 'Срок кредита', '${credit['credit_term']} месяцев'),
                  _buildCreditDetailRow(
                    credit['is_closed'] == true ? Icons.check_circle : Icons.cancel,
                    'Статус',
                    credit['is_closed'] == true ? 'Закрыт' : 'Открыт',
                    color: credit['is_closed'] == true ? Colors.green : Colors.red,
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => _makePhoneCall(credit['debtor_phone']),
                icon: Icon(Icons.phone, color: Colors.white, size: 22),
                label: Text(
                  'Позвонить',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black54,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 11.0, horizontal: 16.0),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _sendMessage(
                  credit['debtor_phone'],
                  credit['debtor_name'],
                  credit['car_number'],
                  credit['fuel_type'],
                ),
                icon: Icon(Icons.message, color: Colors.white, size: 22),
                label: Text(
                  'Сообщение',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black54,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 11.0, horizontal: 16.0),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCreditDetailRow(IconData icon, String title, String value, {Color color = Colors.black87}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.black54, size: 24),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    await launchUrl(launchUri);
  }

  Future<void> _sendMessage(String phoneNumber, String debtorName, String carNumber, String fuelType) async {
    final String message = 'Уважаемый(ая) $debtorName, просим погасить кредит за авто $carNumber, тип топлива: $fuelType.';
    final Uri messageUri = Uri(
      scheme: 'sms',
      path: phoneNumber,
      query: 'body=$message',
    );
    await launchUrl(messageUri);
  }
}
