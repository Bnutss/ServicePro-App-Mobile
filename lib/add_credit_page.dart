import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddCreditPage extends StatefulWidget {
  @override
  _AddCreditPageState createState() => _AddCreditPageState();
}

class _AddCreditPageState extends State<AddCreditPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _debtorNameController = TextEditingController();
  final TextEditingController _carNumberController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _initialPaymentController = TextEditingController();
  final TextEditingController _debtorPhoneController = TextEditingController();

  String _selectedFuelType = 'Метан';
  final List<String> _fuelTypes = ['Метан', 'Пропан'];

  double _creditTerm = 12;

  String _formatNumber(String value) {
    if (value.isEmpty) return '';
    final number = int.tryParse(value.replaceAll(' ', '')) ?? 0;
    final formatter = NumberFormat('#,###');
    return formatter.format(number).replaceAll(',', ' ');
  }

  String _removeFormatting(String value) {
    return value.replaceAll(' ', '');
  }

  Future<void> _submitCredit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) {
      throw Exception('Токен не найден');
    }

    final response = await http.post(
      Uri.parse('https://servicepro.pythonanywhere.com/api/credits/'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'debtor_name': _debtorNameController.text,
        'car_number': _carNumberController.text,
        'price': _removeFormatting(_priceController.text),
        'initial_payment': _removeFormatting(_initialPaymentController.text),
        'debtor_phone': _debtorPhoneController.text,
        'fuel_type': _selectedFuelType,
        'credit_term': _creditTerm.toInt(),
      }),
    );

    if (response.statusCode == 201) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при добавлении кредита')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Добавить Кредит', style: TextStyle(color: Colors.white)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF212121), Color(0xFF6E4B4B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.blue.shade50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: _debtorNameController,
                  decoration: InputDecoration(
                    labelText: 'Имя должника',
                    prefixIcon: Icon(Icons.person),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Пожалуйста, введите имя должника';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _carNumberController,
                  decoration: InputDecoration(
                    labelText: 'Номер автомобиля',
                    prefixIcon: Icon(Icons.directions_car),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  maxLength: 20,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Пожалуйста, введите номер автомобиля';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  decoration: InputDecoration(
                    labelText: 'Цена',
                    prefixIcon: Icon(Icons.attach_money),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _priceController.value = _priceController.value.copyWith(
                      text: _formatNumber(value),
                      selection: TextSelection.collapsed(offset: _formatNumber(value).length),
                    );
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Пожалуйста, введите цену';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _initialPaymentController,
                  decoration: InputDecoration(
                    labelText: 'Первоначальная предоплата',
                    prefixIcon: Icon(Icons.account_balance_wallet),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _initialPaymentController.value = _initialPaymentController.value.copyWith(
                      text: _formatNumber(value),
                      selection: TextSelection.collapsed(offset: _formatNumber(value).length),
                    );
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Пожалуйста, введите первоначальную предоплату';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _debtorPhoneController,
                  decoration: InputDecoration(
                    labelText: 'Телефон должника',
                    prefixIcon: Icon(Icons.phone),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Пожалуйста, введите номер телефона';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedFuelType,
                  decoration: InputDecoration(
                    labelText: 'Тип топлива',
                    prefixIcon: Icon(Icons.local_gas_station),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedFuelType = newValue!;
                    });
                  },
                  items: _fuelTypes.map((fuelType) {
                    return DropdownMenuItem(
                      value: fuelType,
                      child: Text(fuelType),
                    );
                  }).toList(),
                ),
                SizedBox(height: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Срок кредита: ${_creditTerm.toInt()} месяцев', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Colors.blueAccent,
                        inactiveTrackColor: Colors.blue.shade100,
                        trackHeight: 4.0,
                        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12.0),
                        thumbColor: Colors.blueAccent,
                        overlayColor: Colors.blueAccent.withAlpha(32),
                        overlayShape: RoundSliderOverlayShape(overlayRadius: 28.0),
                        tickMarkShape: RoundSliderTickMarkShape(),
                        activeTickMarkColor: Colors.blueAccent,
                        inactiveTickMarkColor: Colors.blue.shade200,
                        valueIndicatorShape: PaddleSliderValueIndicatorShape(),
                        valueIndicatorColor: Colors.blueAccent,
                        valueIndicatorTextStyle: TextStyle(color: Colors.white),
                      ),
                      child: Slider(
                        value: _creditTerm,
                        min: 1,
                        max: 36,
                        divisions: 35,
                        label: _creditTerm.toInt().toString(),
                        onChanged: (newValue) {
                          setState(() {
                            _creditTerm = newValue;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Align(
                  alignment: Alignment.center,
                  child: ElevatedButton.icon(
                    onPressed: _submitCredit,
                    icon: Icon(Icons.add, size: 30, color: Colors.white),
                    label: Text('Добавить', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 15),
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
