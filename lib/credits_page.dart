import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_credit_page.dart';
import 'credit_detail_page.dart';
import 'package:intl/intl.dart';

class CreditsPage extends StatefulWidget {
  @override
  _CreditsPageState createState() => _CreditsPageState();
}

class _CreditsPageState extends State<CreditsPage> {
  Future<List<dynamic>>? _creditsFuture;
  List<dynamic> credits = [];
  String selectedFuelType = 'Все';
  String selectedStatus = 'Все';

  @override
  void initState() {
    super.initState();
    _creditsFuture = fetchCredits();
    _creditsFuture!.then((value) => setState(() {
      credits = value;
    }));
  }

  Future<List<dynamic>> fetchCredits() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      throw Exception('Токен не найден');
    }

    final response = await http.get(
      Uri.parse('https://servicepro.pythonanywhere.com/api/credits/'),
      headers: <String, String>{
        HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else if (response.statusCode == 401) {
      throw Exception('Ошибка авторизации');
    } else {
      throw Exception('Не удалось загрузить кредиты');
    }
  }

  List<dynamic> getFilteredCredits() {
    return credits.where((credit) {
      final fuelTypeMatches = selectedFuelType == 'Все' ||
          credit['fuel_type'] == selectedFuelType;
      final statusMatches = selectedStatus == 'Все' ||
          (selectedStatus == 'Открыт' && credit['is_closed'] == false) ||
          (selectedStatus == 'Закрыт' && credit['is_closed'] == true);
      return fuelTypeMatches && statusMatches;
    }).toList();
  }

  String formatDate(String dateStr) {
    DateTime parsedDate = DateTime.parse(dateStr);
    return DateFormat('dd.MM.yyyy').format(parsedDate);
  }

  bool isPaymentDateClose(String dateStr) {
    DateTime currentDate = DateTime.now();
    DateTime paymentDate = DateTime.parse(dateStr);
    Duration difference = paymentDate.difference(currentDate);

    return difference.inDays <= 5;
  }

  Future<void> _refreshCredits() async {
    setState(() {
      _creditsFuture = fetchCredits();
      _creditsFuture!.then((value) => credits = value);
    });
  }

  Future<void> closeCredit(int creditId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      throw Exception('Токен не найден');
    }

    final response = await http.patch(
      Uri.parse('https://servicepro.pythonanywhere.com/api/credits/$creditId/close/'),
      headers: <String, String>{
        HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return;
    } else {
      throw Exception('Не удалось закрыть кредит');
    }
  }

  Future<void> deleteCredit(int creditId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      throw Exception('Токен не найден');
    }

    final response = await http.delete(
      Uri.parse('https://servicepro.pythonanywhere.com/api/credits/$creditId/'),
      headers: <String, String>{
        HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 204) {
      throw Exception('Не удалось удалить кредит');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text('Кредиты', style: TextStyle(color: Colors.white)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Icon(Icons.local_gas_station, color: Colors.white),
                DropdownButton<String>(
                  value: selectedFuelType,
                  dropdownColor: Colors.black87,
                  iconEnabledColor: Colors.white,
                  underline: SizedBox(),
                  items: <String>['Все', 'Метан', 'Пропан'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      selectedFuelType = newValue!;
                    });
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                DropdownButton<String>(
                  value: selectedStatus,
                  dropdownColor: Colors.black87,
                  iconEnabledColor: Colors.white,
                  underline: SizedBox(),
                  items: <String>['Все', 'Открыт', 'Закрыт'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      selectedStatus = newValue!;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF212121), Color(0xFF6E4B4B)],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF212121), Color(0xFF6E4B4B)],
          ),
        ),
        child: FutureBuilder<List<dynamic>>(
          future: _creditsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, color: Colors.red, size: 40),
                    SizedBox(height: 14),
                    Text('Ошибка: ${snapshot.error}', style: TextStyle(fontSize: 15)),
                  ],
                ),
              );
            } else if (snapshot.hasData) {
              final filteredCredits = getFilteredCredits();
              return RefreshIndicator(
                onRefresh: _refreshCredits,
                child: Stack(
                  children: [
                    ListView.builder(
                      itemCount: filteredCredits.length,
                      itemBuilder: (context, index) {
                        final credit = filteredCredits[index];
                        final isCloseToDeadline = isPaymentDateClose(credit['next_payment_date']);

                        return Dismissible(
                          key: UniqueKey(),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            alignment: AlignmentDirectional.centerEnd,
                            color: Colors.red,
                            child: Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (direction) async {
                            final creditId = credit['id'];
                            setState(() {
                              credits.removeAt(index);
                            });
                            try {
                              await deleteCredit(creditId);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Кредит удален'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Ошибка удаления'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              setState(() {
                                _creditsFuture = fetchCredits();
                              });
                            }
                          },
                          child: Card(
                            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 5,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isCloseToDeadline
                                      ? [Colors.redAccent, Colors.red]
                                      : [Colors.white, Colors.purple.shade50],
                                ),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: ListTile(
                                leading: Icon(Icons.account_balance_wallet, color: Colors.deepPurple),
                                title: Text(
                                  credit['debtor_name'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.5,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 5),
                                    Row(
                                      children: [
                                        Icon(Icons.directions_car, color: Colors.grey, size: 15),
                                        SizedBox(width: 5),
                                        Text('Номер авто: ${credit['car_number']}', style: TextStyle(fontSize: 13)),
                                      ],
                                    ),
                                    SizedBox(height: 5),
                                    credit['is_closed'] == false
                                        ? Row(
                                      children: [
                                        Icon(Icons.attach_money, color: Colors.grey, size: 15),
                                        SizedBox(width: 5),
                                        Text('${credit['monthly_payment']} UZS', style: TextStyle(fontSize: 13)),
                                      ],
                                    )
                                        : SizedBox(),
                                    SizedBox(height: 5),
                                    credit['is_closed'] == false
                                        ? Row(
                                      children: [
                                        Icon(Icons.calendar_today, color: Colors.grey, size: 15),
                                        SizedBox(width: 5),
                                        Text('${formatDate(credit['next_payment_date'])}', style: TextStyle(fontSize: 13)),
                                      ],
                                    )
                                        : Row(
                                      children: [
                                        Icon(Icons.check_circle, color: Colors.green, size: 15),
                                        SizedBox(width: 5),
                                        Text('Кредит закрыт', style: TextStyle(fontSize: 15)),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: credit['is_closed'] == false
                                    ? IconButton(
                                  icon: Icon(Icons.check, color: Colors.green),
                                  onPressed: () async {
                                    final creditId = credit['id'];
                                    try {
                                      await closeCredit(creditId);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Кредит закрыт'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                      setState(() {
                                        credit['is_closed'] = true;
                                      });
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Ошибка закрытия кредита'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                )
                                    : null,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => CreditDetailPage(credit: credit),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    Positioned(
                      bottom: 15,
                      right: 15,
                      child: FloatingActionButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => AddCreditPage(),
                            ),
                          );
                        },
                        backgroundColor: Colors.white,
                        child: Icon(Icons.add, color: Colors.black),
                      ),
                    ),
                  ],
                ),
              );
            } else {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 60),
                    SizedBox(height: 16),
                    Text('Нет данных', style: TextStyle(fontSize: 18)),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
